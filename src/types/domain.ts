/**
 * Fonte da verdade dos tipos de domínio do EduAtitude — Sistema de Avaliação Atitudinal.
 *
 * Convenções (Marco 1):
 * - Uso de aliases `type` como padrão para entidades e contratos.
 * - Enumerações modeladas estritamente como uniões de literais.
 * - Tipagem estrita em todo o arquivo (valores externos tratados como `unknown`).
 * - Timestamps transportados como strings ISO 8601 UTC com sufixo `Z`.
 * - Toda entidade do UML (public/uml.png) e tabela do DER (public/der.png) possui um tipo correspondente.
 */

/** String de data/hora no padrão ISO 8601 UTC com sufixo `Z` (ex.: "2026-03-10T09:30:00.000Z"). */
export type IsoDateTimeString = string;

/** String de data calendário no padrão ISO 8601 (ex.: "2026-03-15"). */
export type IsoDateString = string;

/** Situação cadastral do estudante na instituição. */
export type StudentStatus = "active" | "inactive" | "transferred";

/** Escala formativa discreta de 1 a 5 (CASEL / Kindbegrip). */
export type AttitudeScore = 1 | 2 | 3 | 4 | 5;

/** Segmento da Educação Básica. */
export type EducationSegment =
  | "fundamental_1"
  | "fundamental_2"
  | "high_school";

/** Código identificador das 5 dimensões socioemocionais (BNCC / CASEL). */
export type DimensionCode =
  | "responsabilidade"
  | "colaboracao"
  | "autonomia"
  | "participacao"
  | "respeito";

/** Polaridade formativa de uma avaliação atitudinal (sem caráter punitivo). */
export type EvaluationPolarity = "positive" | "growth_opportunity" | "neutral";

/** Nível de suporte do Sistema de Alerta Precoce (EdInsights / MTSS). */
export type MtssRiskTier = "tier_1" | "tier_2" | "tier_3";

/** Estado de acompanhamento de um plano de intervenção pedagógica. */
export type InterventionStatus =
  | "planned"
  | "in_progress"
  | "under_review"
  | "completed";

/** Autor de uma solicitação no canal ético de diálogo e contraditório (LGPD). */
export type DialogueAuthorType = "student" | "guardian";

/** Situação de atendimento de uma solicitação de diálogo pedagógico. */
export type DialogueStatus = "open" | "in_review" | "answered" | "resolved";

/** Papel RBAC do ator registrado na trilha de auditoria LGPD. */
export type ActorRole =
  | "teacher"
  | "coordinator"
  | "student"
  | "guardian"
  | "system";

/** Turma escolar à qual os estudantes pertencem. */
export type SchoolClass = {
  id: string;
  name: string;
  segment: EducationSegment;
  grade: string;
  schoolYear: number;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Entidade central do domínio: estudante acompanhado na avaliação atitudinal. */
export type Student = {
  id: string;
  schoolClassId: string;
  name: string;
  registration: string;
  status: StudentStatus;
  /** Percentual de frequência escolar (0 a 100). */
  attendanceRate: number;
  /** Quantidade de tarefas pendentes no ciclo vigente. */
  missingAssignments: number;
  guardianName: string;
  guardianEmail: string;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Docente responsável pelo registro contínuo de avaliações atitudinais. */
export type Teacher = {
  id: string;
  name: string;
  email: string;
  specialty: string;
  active: boolean;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Dimensão/categoria de atitude avaliada (referencial CASEL e BNCC). */
export type AttitudeCategory = {
  id: string;
  code: DimensionCode;
  name: string;
  description: string;
  caselCategory: string;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Registro atitudinal que conecta professor, categoria e estudante em uma data. */
export type AttitudeEvaluation = {
  id: string;
  studentId: string;
  teacherId: string;
  categoryId: string;
  polarity: EvaluationPolarity;
  score: AttitudeScore;
  note: string | null;
  evaluatedAt: IsoDateTimeString;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Autoavaliação reflexiva preenchida pelo estudante por dimensão e período. */
export type SelfEvaluation = {
  id: string;
  studentId: string;
  categoryId: string;
  periodLabel: string;
  score: AttitudeScore;
  reflectionText: string;
  submittedAt: IsoDateTimeString;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Plano estruturado de apoio socioemocional e pedagógico (MTSS). */
export type InterventionPlan = {
  id: string;
  studentId: string;
  targetCategoryId: string;
  tier: MtssRiskTier;
  title: string;
  strategy: string;
  responsibleName: string;
  startDate: IsoDateString;
  reviewDate: IsoDateString;
  status: InterventionStatus;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Solicitação de diálogo e direito ao contraditório (LGPD) por aluno ou responsável. */
export type DialogueRequest = {
  id: string;
  studentId: string;
  evaluationId: string | null;
  authorType: DialogueAuthorType;
  authorName: string;
  message: string;
  response: string | null;
  respondedBy: string | null;
  status: DialogueStatus;
  createdAt: IsoDateTimeString;
  updatedAt: IsoDateTimeString;
};

/** Registro imutável de auditoria para conformidade com a LGPD (sem updatedAt). */
export type AuditLog = {
  id: string;
  studentId: string | null;
  actorId: string;
  actorName: string;
  actorRole: ActorRole;
  action: string;
  resource: string;
  justification: string;
  createdAt: IsoDateTimeString;
};

/**
 * Contrato padrão de retorno para todas as Server Actions do sistema.
 * Força o tratamento explícito de sucesso (`ok: true`) e erro (`ok: false`).
 */
export type ActionResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string; fieldErrors?: Record<string, string[]> };
