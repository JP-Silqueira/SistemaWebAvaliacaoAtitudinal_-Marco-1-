import type { Student } from "@/types/domain";
import { MOCK_STUDENTS } from "@/lib/data/students";

/** Latência simulada em milissegundos (faixa obrigatória: 500 a 1000 ms). */
const MOCK_DELAY_MS = 650;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

/**
 * Retorna todos os estudantes com latência simulada.
 * Sempre devolve uma cópia defensiva para evitar mutação do array mock original.
 */
export async function listStudents(): Promise<Student[]> {
  await delay(MOCK_DELAY_MS);
  return MOCK_STUDENTS.map((student) => ({ ...student }));
}

/**
 * Busca um estudante pelo identificador UUID com latência simulada.
 * Retorna uma cópia do estudante encontrado ou `null` quando inexistente.
 */
export async function getStudent(id: string): Promise<Student | null> {
  await delay(MOCK_DELAY_MS);
  const found = MOCK_STUDENTS.find((student) => student.id === id);
  return found ? { ...found } : null;
}
