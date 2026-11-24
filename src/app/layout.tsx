import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "EduAtitude — Sistema de Avaliação Atitudinal",
  description:
    "Sistema Web para Avaliação Atitudinal e Socioemocional na Educação Básica (BNCC, Kindbegrip/CASEL, MTSS e LGPD).",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-slate-50 text-slate-900">
        {children}
      </body>
    </html>
  );
}
