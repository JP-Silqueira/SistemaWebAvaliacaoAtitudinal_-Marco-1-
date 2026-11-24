import Link from "next/link";

export default function HomePage() {
  return (
    <main className="mx-auto flex w-full max-w-4xl flex-1 flex-col justify-center gap-6 px-6 py-16">
      <header className="space-y-3">
        <p className="text-xs font-semibold uppercase tracking-widest text-sky-700">
          EduAtitude — Marco 1
        </p>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">
          Sistema Web de Avaliação Atitudinal
        </h1>
        <p className="max-w-2xl text-base leading-relaxed text-slate-600">
          Modelo de domínio e interface mock para acompanhamento socioemocional
          e atitudinal contínuo na Educação Básica, estruturado sob as
          diretrizes BNCC, Kindbegrip/CASEL, MTSS e LGPD.
        </p>
      </header>

      <nav aria-label="Acesso rápido do Marco 1" className="flex flex-wrap gap-3">
        <Link
          href="/lab/students"
          className="inline-flex items-center justify-center rounded-lg bg-sky-700 px-5 py-2.5 text-sm font-medium text-white transition-colors hover:bg-sky-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-700"
        >
          Acessar Listagem de Estudantes
        </Link>
      </nav>
    </main>
  );
}
