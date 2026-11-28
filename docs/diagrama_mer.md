# EduAtitude — Diagrama MER (Modelo Entidade-Relacionamento)

Documentação do **MER (Modelo Entidade-Relacionamento)** do sistema EduAtitude (PostgreSQL / Supabase), refletindo as tabelas, relacionamentos, restrições, índices e triggers atualmente implementados no repositório.

> [!NOTE]
> **Fontes de verdade inspecionadas:**
> - Esquema SQL: [20261127222000_initial_schema.sql](../supabase/migrations/20261127222000_initial_schema.sql)
> - Tipos de domínio: [domain.ts](../src/types/domain.ts)

---

## Modelo Entidade-Relacionamento (PostgreSQL / Supabase)

Representa as **9 tabelas**, chaves primárias (`UUID`), chaves estrangeiras com políticas `ON DELETE`, restrições `UNIQUE`/`CHECK` e a trilha imutável de auditoria LGPD definidas na migration inicial.

```mermaid
erDiagram
    school_classes ||--o{ students : "possui (ON DELETE RESTRICT)"
    students ||--o{ attitude_evaluations : "recebe (ON DELETE CASCADE)"
    teachers ||--o{ attitude_evaluations : "registra (ON DELETE RESTRICT)"
    attitude_categories ||--o{ attitude_evaluations : "classifica (ON DELETE RESTRICT)"
    students ||--o{ self_evaluations : "preenche (ON DELETE CASCADE)"
    attitude_categories ||--o{ self_evaluations : "dimensao (ON DELETE RESTRICT)"
    students ||--o{ intervention_plans : "recebe plano (ON DELETE CASCADE)"
    attitude_categories ||--o{ intervention_plans : "dimensao alvo (ON DELETE RESTRICT)"
    students ||--o{ dialogue_requests : "abre dialogo (ON DELETE CASCADE)"
    attitude_evaluations |o--o{ dialogue_requests : "contextualiza (ON DELETE SET NULL)"
    students |o--o{ audit_logs : "audita LGPD (ON DELETE SET NULL)"

    school_classes {
        uuid id PK "DEFAULT gen_random_uuid()"
        text name "NOT NULL"
        text segment "CHECK fundamental_1 | fundamental_2 | high_school"
        text grade "NOT NULL"
        integer school_year "NOT NULL"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    teachers {
        uuid id PK "DEFAULT gen_random_uuid()"
        text name "NOT NULL"
        text email UK "NOT NULL UNIQUE"
        text specialty "NOT NULL"
        boolean active "NOT NULL DEFAULT true"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    attitude_categories {
        uuid id PK "DEFAULT gen_random_uuid()"
        text code UK "CHECK 5 dimensoes BNCC/CASEL"
        text name "NOT NULL"
        text description "NOT NULL"
        text casel_category "NOT NULL"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    students {
        uuid id PK "DEFAULT gen_random_uuid()"
        uuid school_class_id FK "NOT NULL -> school_classes(id)"
        text name "NOT NULL"
        text registration UK "NOT NULL UNIQUE"
        text status "DEFAULT active | CHECK active, inactive, transferred"
        numeric attendance_rate "NUMERIC(5,2) DEFAULT 100.00 | CHECK 0..100"
        integer missing_assignments "DEFAULT 0 | CHECK >= 0"
        text guardian_name "NOT NULL"
        text guardian_email "NOT NULL"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    attitude_evaluations {
        uuid id PK "DEFAULT gen_random_uuid()"
        uuid student_id FK "NOT NULL -> students(id)"
        uuid teacher_id FK "NOT NULL -> teachers(id)"
        uuid category_id FK "NOT NULL -> attitude_categories(id)"
        text polarity "CHECK positive | growth_opportunity | neutral"
        integer score "CHECK BETWEEN 1 AND 5"
        text note "NULL"
        timestamptz evaluated_at "NOT NULL DEFAULT now()"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    self_evaluations {
        uuid id PK "DEFAULT gen_random_uuid()"
        uuid student_id FK "NOT NULL -> students(id) | UQ composta"
        uuid category_id FK "NOT NULL -> attitude_categories(id) | UQ composta"
        text period_label "NOT NULL | UQ(student_id, category_id, period_label)"
        integer score "CHECK BETWEEN 1 AND 5"
        text reflection_text "NOT NULL"
        timestamptz submitted_at "NOT NULL DEFAULT now()"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    intervention_plans {
        uuid id PK "DEFAULT gen_random_uuid()"
        uuid student_id FK "NOT NULL -> students(id)"
        uuid target_category_id FK "NOT NULL -> attitude_categories(id)"
        text tier "CHECK tier_1 | tier_2 | tier_3"
        text title "NOT NULL"
        text strategy "NOT NULL"
        text responsible_name "NOT NULL"
        date start_date "NOT NULL"
        date review_date "NOT NULL | CHECK review_date >= start_date"
        text status "DEFAULT planned | CHECK planned..completed"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    dialogue_requests {
        uuid id PK "DEFAULT gen_random_uuid()"
        uuid student_id FK "NOT NULL -> students(id)"
        uuid evaluation_id FK "NULL -> attitude_evaluations(id)"
        text author_type "CHECK student | guardian"
        text author_name "NOT NULL"
        text message "NOT NULL"
        text response "NULL"
        text responded_by "NULL"
        text status "DEFAULT open | CHECK open..resolved"
        timestamptz created_at "NOT NULL DEFAULT now()"
        timestamptz updated_at "NOT NULL DEFAULT now()"
    }

    audit_logs {
        uuid id PK "DEFAULT gen_random_uuid()"
        uuid student_id FK "NULL -> students(id)"
        uuid actor_id "NOT NULL"
        text actor_name "NOT NULL"
        text actor_role "CHECK teacher | coordinator | student | guardian | system"
        text action "NOT NULL"
        text resource "NOT NULL"
        text justification "NOT NULL"
        timestamptz created_at "NOT NULL DEFAULT now() | IMUTAVEL sem updated_at"
    }
```

### Resumo de Restrições, Índices e Triggers Implementados no Banco

| Mecanismo | Detalhes |
| :--- | :--- |
| **Unicidade (`UNIQUE`)** | `teachers(email)`, `attitude_categories(code)`, `students(registration)`, `self_evaluations(student_id, category_id, period_label)` |
| **Integridade (`CHECK`)** | Enumerações de domínio em todas as colunas categóricas; `attendance_rate BETWEEN 0 AND 100`; `missing_assignments >= 0`; `score BETWEEN 1 AND 5`; `review_date >= start_date` |
| **Índices (13)** | `idx_students_school_class_id`, `idx_students_status`, `idx_evaluations_student_id`, `idx_evaluations_teacher_id`, `idx_evaluations_category_id`, `idx_evaluations_evaluated_at`, `idx_self_evaluations_student_id`, `idx_self_evaluations_category_id`, `idx_interventions_student_tier`, `idx_interventions_target_category_id`, `idx_dialogues_student_status`, `idx_dialogues_evaluation_id`, `idx_audit_logs_student_created` |
| **Triggers** | `set_updated_at()` (`BEFORE UPDATE`) nas 8 tabelas mutáveis; `prevent_audit_log_mutation()` (`BEFORE UPDATE OR DELETE`) em `audit_logs`, permitindo apenas `student_id -> NULL` via `ON DELETE SET NULL` |
