"use client";

import { useEffect, useState } from "react";
import type { Student } from "@/types/domain";
import { listStudents } from "@/lib/data";
import { StudentCard } from "@/components/students/student-card";

type StudentsLoadState =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "success"; students: Student[] };

function isValidStudent(item: unknown): item is Student {
  if (typeof item !== "object" || item === null) {
    return false;
  }

  const record = item as Record<string, unknown>;
  return (
    typeof record.id === "string" &&
    typeof record.schoolClassId === "string" &&
    typeof record.name === "string" &&
    typeof record.registration === "string" &&
    (record.status === "active" ||
      record.status === "inactive" ||
      record.status === "transferred") &&
    typeof record.attendanceRate === "number" &&
    typeof record.missingAssignments === "number" &&
    typeof record.guardianName === "string" &&
    typeof record.guardianEmail === "string" &&
    typeof record.createdAt === "string" &&
    typeof record.updatedAt === "string"
  );
}

export default function StudentsPage() {
  const [state, setState] = useState<StudentsLoadState>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;

    async function loadStudents() {
      try {
        const data: unknown = await listStudents();
        if (!Array.isArray(data) || !data.every(isValidStudent)) {
          throw new Error(
            "Os dados de estudantes retornados estão incompletos ou em formato inválido."
          );
        }

        if (!cancelled) {
          setState({ status: "success", students: data });
        }
      } catch (err: unknown) {
        if (!cancelled) {
          const message =
            err instanceof Error
              ? err.message
              : "Não foi possível carregar a lista de estudantes.";
          setState({ status: "error", message });
        }
      }
    }

    void loadStudents();

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <main className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-6 px-6 py-10">
      <header className="space-y-2 border-b border-slate-200 pb-5">
        <p className="text-xs font-semibold uppercase tracking-widest text-sky-700">
          EduAtitude — Avaliação Atitudinal
        </p>
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 sm:text-3xl">
            Estudantes
          </h1>
          {state.status === "success" ? (
            <p className="text-sm text-slate-600">
              {state.students.length} estudantes listados
            </p>
          ) : null}
        </div>
        <p className="max-w-2xl text-sm text-slate-600">
          Listagem formativa de estudantes acompanhados no sistema, sem rankings
          ou classificações comparativas.
        </p>
      </header>

      {state.status === "loading" ? (
        <section
          role="status"
          aria-live="polite"
          className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white p-6 text-sm text-slate-700"
        >
          <span
            aria-hidden="true"
            className="h-4 w-4 animate-spin rounded-full border-2 border-sky-700 border-t-transparent"
          />
          <span>Carregando estudantes...</span>
        </section>
      ) : null}

      {state.status === "error" ? (
        <section
          role="alert"
          className="rounded-xl border border-rose-200 bg-rose-50 p-6 text-sm text-rose-900"
        >
          <h2 className="font-semibold">Erro ao carregar estudantes</h2>
          <p className="mt-1 text-rose-800">{state.message}</p>
        </section>
      ) : null}

      {state.status === "success" && state.students.length === 0 ? (
        <section
          role="status"
          aria-live="polite"
          className="rounded-xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-600"
        >
          <p className="font-medium text-slate-800">
            Nenhum estudante cadastrado.
          </p>
          <p className="mt-1">
            Quando houver registros vinculados às turmas, eles aparecerão aqui.
          </p>
        </section>
      ) : null}

      {state.status === "success" && state.students.length > 0 ? (
        <section aria-label="Lista de estudantes cadastrados">
          <ul className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {state.students.map((student) => (
              <li key={student.id}>
                <StudentCard student={student} />
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </main>
  );
}
