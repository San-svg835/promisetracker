"use client"

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { authService } from '@/lib/auth-service'

export default function LogoutPage() {
  const router = useRouter()
  useEffect(() => {
    authService.logout()
    router.replace('/')
  }, [router])
  return <main className="page-wrap"><div className="page-heading"><h1>Logging out…</h1></div></main>
}
