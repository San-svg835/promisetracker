"use client"

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { authService } from '@/lib/auth-service'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    try {
      // Try async adapter first, fallback to demo sync
      const session = await authService.loginAsync(email, password)
      // redirect by role
      if (session.user.role === 'admin') router.push('/admin')
      else router.push('/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed')
    }
  }

  return (
    <main className="page-wrap narrow-wrap">
      <div className="page-heading">
        <div>
          <div className="eyebrow">SIGN IN</div>
          <h1>Welcome back</h1>
          <p>Sign in to keep track of issues in your ward.</p>
        </div>
      </div>
      <section className="card auth-card">
        <form onSubmit={submit} className="auth-form">
          <label>Email address
            <input required type="email" value={email} onChange={e => setEmail(e.target.value)} />
          </label>
          <label>Password
            <input required type="password" value={password} onChange={e => setPassword(e.target.value)} />
          </label>
          {error && <div role="alert" className="form-error">{error}</div>}
          <div className="form-row">
            <button className="primary-button" type="submit">Login</button>
            <button type="button" className="secondary-button" onClick={() => router.push('/register')}>Register</button>
          </div>
        </form>
      </section>
    </main>
  )
}
