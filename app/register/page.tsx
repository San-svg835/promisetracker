"use client"

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { authService } from '@/lib/auth-service'

export default function RegisterPage() {
  const router = useRouter()
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [role, setRole] = useState<'citizen' | 'admin'>('citizen')
  const [ward, setWard] = useState('Ward 12 · Indiranagar')
  const [error, setError] = useState('')

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    try {
      if (password.length < 8) throw new Error('Use at least 8 characters for your password.')
      if (password !== confirm) throw new Error('Passwords do not match.')
      const session = await authService.registerAsync({ name, email, password, ward, role })
      if (session.user.role === 'admin') router.push('/admin')
      else router.push('/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Registration failed')
    }
  }

  return (
    <main className="page-wrap narrow-wrap">
      <div className="page-heading">
        <div>
          <div className="eyebrow">CREATE ACCOUNT</div>
          <h1>Get started</h1>
          <p>Create your PromiseTrack account to begin reporting.</p>
        </div>
      </div>
      <section className="card auth-card">
        <form onSubmit={submit} className="auth-form">
          <label>Full Name
            <input required value={name} onChange={e => setName(e.target.value)} />
          </label>
          <label>Email address
            <input required type="email" value={email} onChange={e => setEmail(e.target.value)} />
          </label>
          <label>Password
            <input required type="password" value={password} onChange={e => setPassword(e.target.value)} />
          </label>
          <label>Confirm Password
            <input required type="password" value={confirm} onChange={e => setConfirm(e.target.value)} />
          </label>
          <label>Ward / Constituency
            <input value={ward} onChange={e => setWard(e.target.value)} />
          </label>
          <label>What type of user are you?
            <select value={role} onChange={e => setRole(e.target.value as 'citizen' | 'admin')}>
              <option value="citizen">Citizen</option>
              <option value="admin">Admin / Local Representative</option>
            </select>
          </label>
          {error && <div role="alert" className="form-error">{error}</div>}
          <div className="form-row">
            <button className="primary-button" type="submit">Create account</button>
            <button type="button" className="secondary-button" onClick={() => router.push('/login')}>Back to login</button>
          </div>
        </form>
      </section>
    </main>
  )
}
