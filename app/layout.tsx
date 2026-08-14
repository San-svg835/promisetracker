import { Analytics } from '@vercel/analytics/next'
import type { Metadata, Viewport } from 'next'
import './globals.css'
import FirebaseProvider from '@/components/FirebaseProvider'
import AdminRailToggle from '@/components/AdminRailToggle'
import '@/components/admin-rail-toggle.css'

export const metadata: Metadata = {
  title: 'PromiseTrack — Track Promises. Verify Progress. Build Trust.',
  description: 'A civic accountability platform helping citizens report issues, track public projects, and make local government more transparent.',
  generator: 'PromiseTrack',
  icons: {
    icon: [
      {
        url: '/icon-light-32x32.png',
        media: '(prefers-color-scheme: light)',
      },
      {
        url: '/icon-dark-32x32.png',
        media: '(prefers-color-scheme: dark)',
      },
      {
        url: '/icon.svg',
        type: 'image/svg+xml',
      },
    ],
    apple: '/apple-icon.png',
  },
}

export const viewport: Viewport = {
  colorScheme: 'light',
  themeColor: '#fafafa',
  userScalable: false,
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        <FirebaseProvider>
          {children}
        </FirebaseProvider>
        <AdminRailToggle />
        {process.env.NODE_ENV === 'production' && <Analytics />}
      </body>
    </html>
  )
}
