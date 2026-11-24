import { NextResponse } from "next/server";

/**
 * Proxy do Next.js (Cap. 6; autenticacao no Cap. 10).
 * No Next.js 16 substitui o middleware.ts.
 */
export function proxy() {
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
