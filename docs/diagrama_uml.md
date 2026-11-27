# EduAtitude — Diagramas UML do Sistema

Documentação dos diagramas **UML** (Classes de Domínio, Enumerações, Arquitetura Implementada, Sequência e Máquina de Estados) gerados estritamente a partir dos arquivos, tipos, migração SQL e funcionalidades atualmente implementadas no repositório.

> [!NOTE]
> **Fontes de verdade inspecionadas:**
> - Tipos de domínio: [domain.ts](file:///c:/Users/claud/Desktop/projeto/src/types/domain.ts)
> - Camada mock e consultas: [students.ts](file:///c:/Users/claud/Desktop/projeto/src/lib/data/students.ts), [index.ts](file:///c:/Users/claud/Desktop/projeto/src/lib/data/index.ts)
> - Interface e roteamento: [layout.tsx](file:///c:/Users/claud/Desktop/projeto/src/app/layout.tsx), [page.tsx](file:///c:/Users/claud/Desktop/projeto/src/app/page.tsx), [students/page.tsx](file:///c:/Users/claud/Desktop/projeto/src/app/lab/students/page.tsx), [student-card.tsx](file:///c:/Users/claud/Desktop/projeto/src/components/students/student-card.tsx), [proxy.ts](file:///c:/Users/claud/Desktop/projeto/src/proxy.ts)
> - Esquema SQL: [20261127222000_initial_schema.sql](file:///c:/Users/claud/Desktop/projeto/supabase/migrations/20261127222000_initial_schema.sql)

---

## 1. UML — Diagrama de Classes de Domínio

Mapeamento fiel das 9 entidades, 10 enumerações (uniões de literais) e do contrato `ActionResult<T>` definidos em [domain.ts](file:///c:/Users/claud/Desktop/projeto/src/types/domain.ts).

```mermaid
classDiagram
    direction TB

    class SchoolClass {
        <<entity>>
        +id: string
        +name: string
        +segment: EducationSegment
        +grade: string
        +schoolYear: number
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class Student {
        <<entity - central>>
        +id: string
        +schoolClassId: string
        +name: string
        +registration: string
        +status: StudentStatus
        +attendanceRate: number
        +missingAssignments: number
        +guardianName: string
        +guardianEmail: string
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class Teacher {
        <<entity>>
        +id: string
        +name: string
        +email: string
        +specialty: string
        +active: boolean
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class AttitudeCategory {
        <<entity>>
        +id: string
        +code: DimensionCode
        +name: string
        +description: string
        +caselCategory: string
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class AttitudeEvaluation {
        <<entity>>
        +id: string
        +studentId: string
        +teacherId: string
        +categoryId: string
        +polarity: EvaluationPolarity
        +score: AttitudeScore
        +note: string?
        +evaluatedAt: IsoDateTimeString
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class SelfEvaluation {
        <<entity>>
        +id: string
        +studentId: string
        +categoryId: string
        +periodLabel: string
        +score: AttitudeScore
        +reflectionText: string
        +submittedAt: IsoDateTimeString
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class InterventionPlan {
        <<entity>>
        +id: string
        +studentId: string
        +targetCategoryId: string
        +tier: MtssRiskTier
        +title: string
        +strategy: string
        +responsibleName: string
        +startDate: IsoDateString
        +reviewDate: IsoDateString
        +status: InterventionStatus
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class DialogueRequest {
        <<entity>>
        +id: string
        +studentId: string
        +evaluationId: string?
        +authorType: DialogueAuthorType
        +authorName: string
        +message: string
        +response: string?
        +respondedBy: string?
        +status: DialogueStatus
        +createdAt: IsoDateTimeString
        +updatedAt: IsoDateTimeString
    }

    class AuditLog {
        <<immutable - LGPD>>
        +id: string
        +studentId: string?
        +actorId: string
        +actorName: string
        +actorRole: ActorRole
        +action: string
        +resource: string
        +justification: string
        +createdAt: IsoDateTimeString
    }

    class ActionResult~T~ {
        <<contract>>
        +ok: boolean
        +data: T?
        +error: string?
        +fieldErrors: Record~string, string[]~?
    }

    SchoolClass "1" --> "0..*" Student : possui
    Student "1" *-- "0..*" AttitudeEvaluation : recebe
    Teacher "1" --> "0..*" AttitudeEvaluation : registra
    AttitudeCategory "1" --> "0..*" AttitudeEvaluation : classifica
    Student "1" *-- "0..*" SelfEvaluation : preenche
    AttitudeCategory "1" --> "0..*" SelfEvaluation : dimensao
    Student "1" *-- "0..*" InterventionPlan : recebe intervencao
    AttitudeCategory "1" --> "0..*" InterventionPlan : dimensao alvo
    Student "1" *-- "0..*" DialogueRequest : abre dialogo
    AttitudeEvaluation "0..1" --> "0..*" DialogueRequest : contextualiza
    Student "0..1" --> "0..*" AuditLog : audita LGPD
```

### Enumerações de Domínio (`src/types/domain.ts`)

```mermaid
classDiagram
    direction LR

    class StudentStatus {
        <<enumeration>>
        active
        inactive
        transferred
    }

    class AttitudeScore {
        <<enumeration>>
        1
        2
        3
        4
        5
    }

    class EducationSegment {
        <<enumeration>>
        fundamental_1
        fundamental_2
        high_school
    }

    class DimensionCode {
        <<enumeration>>
        responsabilidade
        colaboracao
        autonomia
        participacao
        respeito
    }

    class EvaluationPolarity {
        <<enumeration>>
        positive
        growth_opportunity
        neutral
    }

    class MtssRiskTier {
        <<enumeration>>
        tier_1
        tier_2
        tier_3
    }

    class InterventionStatus {
        <<enumeration>>
        planned
        in_progress
        under_review
        completed
    }

    class DialogueAuthorType {
        <<enumeration>>
        student
        guardian
    }

    class DialogueStatus {
        <<enumeration>>
        open
        in_review
        answered
        resolved
    }

    class ActorRole {
        <<enumeration>>
        teacher
        coordinator
        student
        guardian
        system
    }
```

---

## 2. UML — Arquitetura e Módulos Atualmente Implementados

Mostra os componentes reais em execução no Marco 1 (Next.js 16 App Router + camada mock) e sua relação com a camada de banco de dados preparada na migration SQL.

```mermaid
classDiagram
    direction TB

    class NextProxy {
        <<proxy - src/proxy.ts>>
        +config.matcher: string[]
        +proxy() NextResponse
    }

    class RootLayout {
        <<layout - src/app/layout.tsx>>
        +metadata: Metadata
        +RootLayout(children) JSX
    }

    class HomePage {
        <<page - src/app/page.tsx>>
        +HomePage() JSX
    }

    class StudentsPage {
        <<client page - src/app/lab/students/page.tsx>>
        -state: StudentsLoadState
        -isValidStudent(item: unknown) boolean
        +StudentsPage() JSX
    }

    class StudentCard {
        <<client component - src/components/students/student-card.tsx>>
        -STATUS_LABELS: Record~StudentStatus, string~
        -STATUS_STYLES: Record~StudentStatus, Style~
        +StudentCard(props: StudentCardProps) JSX
    }

    class StudentCardProps {
        <<type>>
        +student: Student
        +onSelect(student: Student)? void
    }

    class DataQueryLayer {
        <<service - src/lib/data/index.ts>>
        -MOCK_DELAY_MS: 650
        -delay(ms: number) Promise~void~
        +listStudents() Promise~Student[]~
        +getStudent(id: string) Promise~Student?~
    }

    class MockStudentsStore {
        <<readonly data - src/lib/data/students.ts>>
        -CLASS_5A_ID: string
        -CLASS_8B_ID: string
        -CLASS_2EM_ID: string
        +MOCK_STUDENTS: readonly Student[]
    }

    class DomainTypes {
        <<types - src/types/domain.ts>>
        +9 Entidades
        +10 Enumeracoes
        +ActionResult~T~
    }

    class SupabaseSchemaMigration {
        <<sql - supabase/migrations/20261127222000_initial_schema.sql>>
        +9 Tabelas PostgreSQL
        +13 Indices
        +set_updated_at()
        +prevent_audit_log_mutation()
    }

    NextProxy ..> RootLayout : intercepta rotas
    RootLayout --> HomePage : renderiza "/"
    RootLayout --> StudentsPage : renderiza "/lab/students"
    HomePage ..> StudentsPage : Link "/lab/students"
    StudentsPage --> StudentCard : renderiza lista
    StudentCard --> StudentCardProps : recebe props
    StudentsPage ..> DataQueryLayer : chama listStudents()
    DataQueryLayer --> MockStudentsStore : copia defensiva
    MockStudentsStore ..> DomainTypes : tipado por Student
    StudentsPage ..> DomainTypes : valida com isValidStudent
    StudentCard ..> DomainTypes : usa Student e StudentStatus
    SupabaseSchemaMigration ..> DomainTypes : espelha modelo relacional
```

---

## 3. UML — Diagrama de Sequência (Funcionalidade Implementada `/lab/students`)

Detalha o fluxo completo de navegação, interceptação pelo proxy, consulta assíncrona com latência simulada (`650 ms`), validação em runtime via type guard e renderização dos cartões.

```mermaid
sequenceDiagram
    actor Usuario
    participant Proxy as NextProxy (src/proxy.ts)
    participant Home as HomePage (/)
    participant Page as StudentsPage (/lab/students)
    participant Data as DataQueryLayer (lib/data/index.ts)
    participant Mock as MOCK_STUDENTS (15 registros)
    participant Card as StudentCard

    Usuario->>Proxy: GET /
    Proxy-->>Home: NextResponse.next()
    Home-->>Usuario: Exibe pagina inicial com link "/lab/students"

    Usuario->>Proxy: Navega para /lab/students
    Proxy-->>Page: NextResponse.next()
    Page-->>Usuario: Renderiza estado "loading" (role="status")

    Page->>Data: listStudents()
    Data->>Data: await delay(650ms)
    Data->>Mock: Leitura de MOCK_STUDENTS
    Mock-->>Data: 15 objetos Student imutaveis
    Data-->>Page: Copia defensiva Student[]

    Page->>Page: Valida array com isValidStudent(item)

    alt Dados validos e students.length > 0
        Page->>Page: setState({ status: "success", students })
        loop Para cada student (key=student.id)
            Page->>Card: StudentCard({ student })
            Card-->>Page: article semantico + badge de status
        end
        Page-->>Usuario: Grade responsiva com 15 estudantes
    else Dados validos e students.length === 0
        Page->>Page: setState({ status: "success", students: [] })
        Page-->>Usuario: Estado vazio (role="status")
    else Erro de rede ou validacao invalida
        Page->>Page: setState({ status: "error", message })
        Page-->>Usuario: Alerta de erro (role="alert")
    end
```

---

## 4. UML — Diagrama de Estados da Interface (`StudentsPage`)

Representa a máquina de estados discriminada (`StudentsLoadState`) e o estado vazio derivado implementados em [students/page.tsx](file:///c:/Users/claud/Desktop/projeto/src/app/lab/students/page.tsx).

```mermaid
stateDiagram-v2
    [*] --> Loading : Montagem do componente / dispara useEffect

    Loading --> SuccessWithData : listStudents() ok + isValidStudent() + length > 0
    Loading --> SuccessEmpty : listStudents() ok + isValidStudent() + length == 0
    Loading --> Error : Excecao ou falha no type guard isValidStudent()
    Loading --> [*] : Desmontagem (cancelled = true)

    SuccessWithData --> [*] : Desmontagem
    SuccessEmpty --> [*] : Desmontagem
    Error --> [*] : Desmontagem

    note right of Loading
        Exibe spinner e texto
        "Carregando estudantes..."
        com role="status"
    end note

    note right of SuccessWithData
        Renderiza contagem e lista
        de componentes StudentCard
        sem rankings comparativos
    end note

    note right of Error
        Exibe painel de alerta
        com role="alert"
    end note
```
