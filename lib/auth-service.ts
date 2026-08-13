export type UserRole = 'citizen' | 'admin'

export type AuthUser = {
  id: string
  name: string
  email: string
  phone?: string
  ward?: string
  role: UserRole
  civicScore: number
}

export type AuthSession = {
  user: AuthUser
  remember: boolean
}

const SESSION_KEY = 'promisetrack-session'

const demoUsers: Array<AuthUser & { password: string }> = [
  { id: 'USR-001', name: 'Ananya Sharma', email: 'ananya@promisetrack.in', phone: '+91 98765 43210', ward: 'Ward 12 · Indiranagar', role: 'citizen', civicScore: 82, password: 'citizen123' },
  { id: 'ADM-001', name: 'Rohan Mehta', email: 'admin@promisetrack.in', phone: '+91 98765 11111', ward: 'Bengaluru Civic Operations', role: 'admin', civicScore: 96, password: 'admin123' },
]

export type AuthAdapter = {
  login?: (email: string, password: string) => Promise<AuthSession>
  register?: (payload: { name: string; email: string; password: string; phone?: string; ward?: string; role?: UserRole }) => Promise<AuthSession>
  current?: () => Promise<AuthSession | null>
  logout?: () => Promise<void>
}

let adapter: AuthAdapter | null = null

export const setAuthAdapter = (a: AuthAdapter | null) => { adapter = a }

function saveSession(session: AuthSession) {
  if (typeof window !== 'undefined') window.localStorage.setItem(SESSION_KEY, JSON.stringify(session))
}

function readSession(): AuthSession | null {
  if (typeof window === 'undefined') return null
  const stored = window.localStorage.getItem(SESSION_KEY)
  if (!stored) return null
  try { return JSON.parse(stored) as AuthSession } catch { return null }
}

export const authService = {
  // Backwards-compatible sync login (demo only)
  login(email: string, password: string, remember = true): AuthSession {
    const account = demoUsers.find(user => user.email.toLowerCase() === email.trim().toLowerCase() && user.password === password)
    if (!account) throw new Error('We could not match those details. Try a demo account or check your password.')
    const { password: _password, ...user } = account
    const session = { user, remember }
    saveSession(session)
    return session
  },

  // Backwards-compatible sync register (demo only)
  register(input: Omit<AuthUser, 'id' | 'civicScore'> & { password: string }): AuthSession {
    const session: AuthSession = { user: { id: `USR-${Date.now()}`, civicScore: 0, ...input }, remember: true }
    saveSession(session)
    return session
  },

  current(): AuthSession | null {
    return readSession()
  },

  logout() { if (typeof window !== 'undefined') window.localStorage.removeItem(SESSION_KEY) },

  // Async APIs for real backends (Firebase / Mongo-ready). These prefer an adapter when set.
  async loginAsync(email: string, password: string, remember = true): Promise<AuthSession> {
    if (adapter?.login) return adapter.login(email, password)
    // fallback to demo
    return Promise.resolve(this.login(email, password, remember))
  },

  async registerAsync(payload: { name: string; email: string; password: string; phone?: string; ward?: string; role?: UserRole }): Promise<AuthSession> {
    if (adapter?.register) return adapter.register(payload)
    // fallback to demo
    const session = this.register({ name: payload.name, email: payload.email, phone: payload.phone || '', ward: payload.ward || '', role: (payload.role as UserRole) || 'citizen', password: payload.password })
    return Promise.resolve(session)
  },

  async currentAsync(): Promise<AuthSession | null> {
    if (adapter?.current) return adapter.current()
    return Promise.resolve(this.current())
  },

  async logoutAsync(): Promise<void> {
    if (adapter?.logout) return adapter.logout()
    this.logout()
    return Promise.resolve()
  },
}

export const demoCredentials = {
  citizen: { email: 'ananya@promisetrack.in', password: 'citizen123' },
  admin: { email: 'admin@promisetrack.in', password: 'admin123' },
}
