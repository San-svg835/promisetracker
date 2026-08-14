"use client"

import { useEffect } from 'react'
import { setAuthAdapter } from '@/lib/auth-service'

export default function FirebaseProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Dynamically import the firebase adapter on the client so the server build
    // does not require the `firebase` package to be installed.
    ;(async () => {
      try {
        const getConfig = () => ({
          apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || '',
          authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || '',
          projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || '',
          storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || '',
          messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '',
          appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '',
        })

        // Build an adapter that dynamically imports firebase client modules when used
        const adapter = {
          async login(email: string, password: string) {
            const { initializeApp, getApps } = await import('firebase/app')
            if (!getApps().length) initializeApp(getConfig())
            const { getAuth, signInWithEmailAndPassword, getIdTokenResult } = await import('firebase/auth')
            const auth = getAuth()
            const cred = await signInWithEmailAndPassword(auth, email, password)
            const user = cred.user
            try { const tokenRes = await getIdTokenResult(user); (user as any)._claims = tokenRes.claims } catch (e) {}
            return {
              user: { id: user.uid, name: user.displayName || user.email || 'Citizen', email: user.email || '', phone: user.phoneNumber || '', ward: '', role: ((user as any)._claims?.role || 'citizen'), civicScore: 0 },
              remember: true,
            }
          },
          async register(payload: any) {
            const { initializeApp, getApps } = await import('firebase/app')
            if (!getApps().length) initializeApp(getConfig())
            const { getAuth, createUserWithEmailAndPassword, updateProfile } = await import('firebase/auth')
            const auth = getAuth()
            const cred = await createUserWithEmailAndPassword(auth, payload.email, payload.password)
            const user = cred.user
            if (payload.name) await updateProfile(user, { displayName: payload.name })
            return { user: { id: user.uid, name: user.displayName || payload.name || user.email || 'Citizen', email: user.email || '', phone: user.phoneNumber || '', ward: payload.ward || '', role: 'citizen', civicScore: 0 }, remember: true }
          },
          async current() {
            const { initializeApp, getApps } = await import('firebase/app')
            if (!getApps().length) initializeApp(getConfig())
            const { getAuth, onAuthStateChanged, getIdTokenResult } = await import('firebase/auth')
            const auth = getAuth()
            return new Promise((resolve) => {
              const unsub = onAuthStateChanged(auth, async (user) => {
                unsub()
                if (!user) return resolve(null)
                try { const tokenRes = await getIdTokenResult(user); (user as any)._claims = tokenRes.claims } catch (e) {}
                resolve({ user: { id: user.uid, name: user.displayName || user.email || 'Citizen', email: user.email || '', phone: user.phoneNumber || '', ward: '', role: ((user as any)._claims?.role || 'citizen'), civicScore: 0 }, remember: true })
              })
            })
          },
          async logout() {
            const { initializeApp, getApps } = await import('firebase/app')
            if (!getApps().length) initializeApp(getConfig())
            const { getAuth, signOut } = await import('firebase/auth')
            const auth = getAuth()
            await signOut(auth)
          },
        }

        setAuthAdapter(adapter as any)
      } catch (e) {
        // If firebase isn't installed yet, fail silently — demo adapter remains.
        // Developer should run `npm install firebase` to enable production auth.
        // console.warn('Firebase adapter not available', e)
      }
    })()
  }, [])

  return <>{children}</>
}
