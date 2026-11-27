-- ============================================================================
-- EduAtitude — Sistema Web de Avaliacao Atitudinal
-- Migration inicial do esquema PostgreSQL / Supabase
--
-- Referencias:
--   - DER: public/der.png
--   - UML: public/uml.png
--   - Tipos de dominio: src/types/domain.ts
--
-- Convencoes adotadas:
--   - Chaves primarias UUID com gen_random_uuid() (sem SERIAL)
--   - Timestamps sempre em TIMESTAMPTZ NOT NULL DEFAULT now()
--   - Notas discretas em INTEGER (1..5) e frequencia em NUMERIC(5,2) (sem FLOAT)
--   - Enumeracoes validadas via CHECK constraints explicitas
--   - Composicoes ligadas a students com ON DELETE CASCADE; referencias
--     opcionais com ON DELETE SET NULL; referencias estruturais com ON DELETE RESTRICT
--   - Trilha audit_logs imutavel (sem updated_at e protegida por trigger LGPD)
--   - Politicas de Row Level Security (RLS) serao aplicadas em migration posterior
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- Funcoes utilitarias de trigger
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Garante imutabilidade de audit_logs (LGPD), permitindo apenas a anulacao
-- automatica de student_id disparada pela FK ON DELETE SET NULL.
CREATE OR REPLACE FUNCTION public.prevent_audit_log_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND NEW.student_id IS NULL
     AND OLD.student_id IS NOT NULL
     AND NEW.id = OLD.id
     AND NEW.actor_id = OLD.actor_id
     AND NEW.actor_name = OLD.actor_name
     AND NEW.actor_role = OLD.actor_role
     AND NEW.action = OLD.action
     AND NEW.resource = OLD.resource
     AND NEW.justification = OLD.justification
     AND NEW.created_at = OLD.created_at THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'audit_logs e uma trilha imutavel (LGPD): operacao % nao permitida', TG_OP;
END;
$$;

-- ----------------------------------------------------------------------------
-- 1. school_classes (Turmas escolares)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.school_classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  segment TEXT NOT NULL
    CONSTRAINT chk_school_classes_segment
    CHECK (segment IN ('fundamental_1', 'fundamental_2', 'high_school')),
  grade TEXT NOT NULL,
  school_year INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.school_classes IS 'Turmas escolares que organizam os estudantes por segmento e ano letivo.';

-- ----------------------------------------------------------------------------
-- 2. teachers (Docentes avaliadores)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.teachers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL
    CONSTRAINT uq_teachers_email UNIQUE,
  specialty TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.teachers IS 'Docentes responsaveis pelo registro continuo das avaliacoes atitudinais.';

-- ----------------------------------------------------------------------------
-- 3. attitude_categories (Dimensoes socioemocionais BNCC / CASEL)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.attitude_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL
    CONSTRAINT uq_attitude_categories_code UNIQUE
    CONSTRAINT chk_attitude_categories_code
    CHECK (code IN ('responsabilidade', 'colaboracao', 'autonomia', 'participacao', 'respeito')),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  casel_category TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.attitude_categories IS 'As 5 dimensoes socioemocionais (BNCC / CASEL / Kindbegrip) avaliadas pelo sistema.';

-- ----------------------------------------------------------------------------
-- 4. students (Tabela central — Estudantes)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_class_id UUID NOT NULL
    CONSTRAINT fk_students_school_class
    REFERENCES public.school_classes (id)
    ON DELETE RESTRICT,
  name TEXT NOT NULL,
  registration TEXT NOT NULL
    CONSTRAINT uq_students_registration UNIQUE,
  status TEXT NOT NULL DEFAULT 'active'
    CONSTRAINT chk_students_status
    CHECK (status IN ('active', 'inactive', 'transferred')),
  attendance_rate NUMERIC(5,2) NOT NULL DEFAULT 100.00
    CONSTRAINT chk_students_attendance_rate
    CHECK (attendance_rate BETWEEN 0 AND 100),
  missing_assignments INTEGER NOT NULL DEFAULT 0
    CONSTRAINT chk_students_missing_assignments
    CHECK (missing_assignments >= 0),
  guardian_name TEXT NOT NULL,
  guardian_email TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.students IS 'Entidade central do dominio: estudantes acompanhados na avaliacao atitudinal e triagem MTSS.';

-- ----------------------------------------------------------------------------
-- 5. attitude_evaluations (Avaliacoes atitudinais docentes)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.attitude_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL
    CONSTRAINT fk_attitude_evaluations_student
    REFERENCES public.students (id)
    ON DELETE CASCADE,
  teacher_id UUID NOT NULL
    CONSTRAINT fk_attitude_evaluations_teacher
    REFERENCES public.teachers (id)
    ON DELETE RESTRICT,
  category_id UUID NOT NULL
    CONSTRAINT fk_attitude_evaluations_category
    REFERENCES public.attitude_categories (id)
    ON DELETE RESTRICT,
  polarity TEXT NOT NULL
    CONSTRAINT chk_attitude_evaluations_polarity
    CHECK (polarity IN ('positive', 'growth_opportunity', 'neutral')),
  score INTEGER NOT NULL
    CONSTRAINT chk_attitude_evaluations_score
    CHECK (score BETWEEN 1 AND 5),
  note TEXT NULL,
  evaluated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.attitude_evaluations IS 'Registros formativos que conectam professor, dimensao socioemocional e estudante.';

-- ----------------------------------------------------------------------------
-- 6. self_evaluations (Autoavaliacoes reflexivas dos estudantes)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.self_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL
    CONSTRAINT fk_self_evaluations_student
    REFERENCES public.students (id)
    ON DELETE CASCADE,
  category_id UUID NOT NULL
    CONSTRAINT fk_self_evaluations_category
    REFERENCES public.attitude_categories (id)
    ON DELETE RESTRICT,
  period_label TEXT NOT NULL,
  score INTEGER NOT NULL
    CONSTRAINT chk_self_evaluations_score
    CHECK (score BETWEEN 1 AND 5),
  reflection_text TEXT NOT NULL,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_self_evaluations_student_category_period
    UNIQUE (student_id, category_id, period_label)
);

COMMENT ON TABLE public.self_evaluations IS 'Autoavaliacoes reflexivas preenchidas pelos estudantes por dimensao e periodo.';

-- ----------------------------------------------------------------------------
-- 7. intervention_plans (Planos de intervencao pedagogica MTSS)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.intervention_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL
    CONSTRAINT fk_intervention_plans_student
    REFERENCES public.students (id)
    ON DELETE CASCADE,
  target_category_id UUID NOT NULL
    CONSTRAINT fk_intervention_plans_target_category
    REFERENCES public.attitude_categories (id)
    ON DELETE RESTRICT,
  tier TEXT NOT NULL
    CONSTRAINT chk_intervention_plans_tier
    CHECK (tier IN ('tier_1', 'tier_2', 'tier_3')),
  title TEXT NOT NULL,
  strategy TEXT NOT NULL,
  responsible_name TEXT NOT NULL,
  start_date DATE NOT NULL,
  review_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'planned'
    CONSTRAINT chk_intervention_plans_status
    CHECK (status IN ('planned', 'in_progress', 'under_review', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_intervention_plans_dates
    CHECK (review_date >= start_date)
);

COMMENT ON TABLE public.intervention_plans IS 'Planos estruturados de suporte socioemocional e pedagogico (EdInsights / MTSS).';

-- ----------------------------------------------------------------------------
-- 8. dialogue_requests (Canal etico de dialogo e contraditorio — LGPD)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.dialogue_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL
    CONSTRAINT fk_dialogue_requests_student
    REFERENCES public.students (id)
    ON DELETE CASCADE,
  evaluation_id UUID NULL
    CONSTRAINT fk_dialogue_requests_evaluation
    REFERENCES public.attitude_evaluations (id)
    ON DELETE SET NULL,
  author_type TEXT NOT NULL
    CONSTRAINT chk_dialogue_requests_author_type
    CHECK (author_type IN ('student', 'guardian')),
  author_name TEXT NOT NULL,
  message TEXT NOT NULL,
  response TEXT NULL,
  responded_by TEXT NULL,
  status TEXT NOT NULL DEFAULT 'open'
    CONSTRAINT chk_dialogue_requests_status
    CHECK (status IN ('open', 'in_review', 'answered', 'resolved')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.dialogue_requests IS 'Solicitacoes de dialogo e exercicio do direito ao contraditorio por estudantes ou responsaveis.';

-- ----------------------------------------------------------------------------
-- 9. audit_logs (Trilha imutavel de auditoria LGPD — sem updated_at)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NULL
    CONSTRAINT fk_audit_logs_student
    REFERENCES public.students (id)
    ON DELETE SET NULL,
  actor_id UUID NOT NULL,
  actor_name TEXT NOT NULL,
  actor_role TEXT NOT NULL
    CONSTRAINT chk_audit_logs_actor_role
    CHECK (actor_role IN ('teacher', 'coordinator', 'student', 'guardian', 'system')),
  action TEXT NOT NULL,
  resource TEXT NOT NULL,
  justification TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.audit_logs IS 'Trilha imutavel de auditoria para conformidade com a LGPD (sem updated_at).';

-- ----------------------------------------------------------------------------
-- Indices nas colunas de consulta frequente e chaves estrangeiras (DER)
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_students_school_class_id
  ON public.students (school_class_id);

CREATE INDEX IF NOT EXISTS idx_students_status
  ON public.students (status);

CREATE INDEX IF NOT EXISTS idx_evaluations_student_id
  ON public.attitude_evaluations (student_id);

CREATE INDEX IF NOT EXISTS idx_evaluations_teacher_id
  ON public.attitude_evaluations (teacher_id);

CREATE INDEX IF NOT EXISTS idx_evaluations_category_id
  ON public.attitude_evaluations (category_id);

CREATE INDEX IF NOT EXISTS idx_evaluations_evaluated_at
  ON public.attitude_evaluations (evaluated_at DESC);

CREATE INDEX IF NOT EXISTS idx_self_evaluations_student_id
  ON public.self_evaluations (student_id);

CREATE INDEX IF NOT EXISTS idx_self_evaluations_category_id
  ON public.self_evaluations (category_id);

CREATE INDEX IF NOT EXISTS idx_interventions_student_tier
  ON public.intervention_plans (student_id, tier);

CREATE INDEX IF NOT EXISTS idx_interventions_target_category_id
  ON public.intervention_plans (target_category_id);

CREATE INDEX IF NOT EXISTS idx_dialogues_student_status
  ON public.dialogue_requests (student_id, status);

CREATE INDEX IF NOT EXISTS idx_dialogues_evaluation_id
  ON public.dialogue_requests (evaluation_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_student_created
  ON public.audit_logs (student_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- Triggers de atualizacao automatica de updated_at (tabelas mutaveis)
-- ----------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_school_classes_updated_at ON public.school_classes;
CREATE TRIGGER trg_school_classes_updated_at
  BEFORE UPDATE ON public.school_classes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_teachers_updated_at ON public.teachers;
CREATE TRIGGER trg_teachers_updated_at
  BEFORE UPDATE ON public.teachers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_attitude_categories_updated_at ON public.attitude_categories;
CREATE TRIGGER trg_attitude_categories_updated_at
  BEFORE UPDATE ON public.attitude_categories
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_students_updated_at ON public.students;
CREATE TRIGGER trg_students_updated_at
  BEFORE UPDATE ON public.students
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_attitude_evaluations_updated_at ON public.attitude_evaluations;
CREATE TRIGGER trg_attitude_evaluations_updated_at
  BEFORE UPDATE ON public.attitude_evaluations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_self_evaluations_updated_at ON public.self_evaluations;
CREATE TRIGGER trg_self_evaluations_updated_at
  BEFORE UPDATE ON public.self_evaluations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_intervention_plans_updated_at ON public.intervention_plans;
CREATE TRIGGER trg_intervention_plans_updated_at
  BEFORE UPDATE ON public.intervention_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_dialogue_requests_updated_at ON public.dialogue_requests;
CREATE TRIGGER trg_dialogue_requests_updated_at
  BEFORE UPDATE ON public.dialogue_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ----------------------------------------------------------------------------
-- Trigger de imutabilidade LGPD em audit_logs
-- ----------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_audit_logs_immutable ON public.audit_logs;
CREATE TRIGGER trg_audit_logs_immutable
  BEFORE UPDATE OR DELETE ON public.audit_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_audit_log_mutation();
