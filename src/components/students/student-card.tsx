"use client";

import type { Student, StudentStatus } from "@/types/domain";

export type StudentCardProps = {
  student: Student;
  onSelect?: (student: Student) => void;
};

const STATUS_LABELS: Record<StudentStatus, string> = {
  active: "Ativo",
  inactive: "Inativo",
  transferred: "Transferido",
};

const STATUS_STYLES: Record<
  StudentStatus,
  { badge: string; indicator: string }
> = {
  active: {
    badge: "bg-emerald-50 text-emerald-800 ring-1 ring-inset ring-emerald-200",
    indicator: "bg-emerald-600",
  },
  inactive: {
    badge: "bg-slate-100 text-slate-700 ring-1 ring-inset ring-slate-300",
    indicator: "bg-slate-500",
  },
  transferred: {
    badge: "bg-amber-50 text-amber-800 ring-1 ring-inset ring-amber-200",
    indicator: "bg-amber-600",
  },
};

export function StudentCard({ student, onSelect }: StudentCardProps) {
  const statusLabel = STATUS_LABELS[student.status];
  const statusStyle = STATUS_STYLES[student.status];

  return (
    <article
      aria-label={`Estudante ${student.name}`}
      className="flex flex-col justify-between gap-4 rounded-xl border border-slate-200 bg-white p-5 shadow-xs transition-shadow hover:shadow-sm"
    >
      <header className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 className="truncate text-base font-semibold text-slate-900">
            {student.name}
          </h2>
          <p className="mt-0.5 text-xs text-slate-500">
            Responsável: {student.guardianName}
          </p>
        </div>

        <span
          aria-label={`Status cadastral: ${statusLabel}`}
          className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${statusStyle.badge}`}
        >
          <span
            aria-hidden="true"
            className={`h-1.5 w-1.5 rounded-full ${statusStyle.indicator}`}
          />
          {statusLabel}
        </span>
      </header>

      <dl className="grid grid-cols-3 gap-3 border-t border-slate-100 pt-3 text-sm">
        <div>
          <dt className="text-xs font-medium text-slate-500">Matrícula</dt>
          <dd className="mt-0.5 font-mono text-xs font-medium text-slate-800">
            {student.registration}
          </dd>
        </div>

        <div>
          <dt className="text-xs font-medium text-slate-500">Frequência</dt>
          <dd className="mt-0.5 text-xs font-semibold text-slate-800">
            {student.attendanceRate}%
          </dd>
        </div>

        <div>
          <dt className="text-xs font-medium text-slate-500">Pendências</dt>
          <dd className="mt-0.5 text-xs font-semibold text-slate-800">
            {student.missingAssignments}
          </dd>
        </div>
      </dl>

      {onSelect ? (
        <footer className="border-t border-slate-100 pt-3">
          <button
            type="button"
            onClick={() => onSelect(student)}
            aria-label={`Selecionar estudante ${student.name}`}
            className="w-full rounded-lg border border-sky-200 bg-sky-50 px-3 py-2 text-xs font-medium text-sky-800 transition-colors hover:bg-sky-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-700"
          >
            Visualizar acompanhamento
          </button>
        </footer>
      ) : null}
    </article>
  );
}
