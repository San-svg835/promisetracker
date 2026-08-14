'use client'

import { useEffect } from 'react'

export default function AdminRailToggle() {
  useEffect(() => {
    const id = 'pt-rail-toggle-button'
    function createButton() {
      if (document.getElementById(id)) return
      const btn = document.createElement('button')
      btn.id = id
      btn.className = 'pt-rail-toggle-button'
      btn.title = 'Toggle navigation'
      btn.innerText = '☰'
      btn.onclick = () => {
        const rail = document.querySelector('.admin-rail') as HTMLElement | null
        if (!rail) return
        rail.style.display = rail.style.display === 'none' ? '' : 'none'
      }
      document.body.appendChild(btn)
    }

    function updateAutoHide() {
      const profile = document.querySelector('.admin-profile-page')
      const rail = document.querySelector('.admin-rail') as HTMLElement | null
      if (!rail) return
      if (profile) rail.style.display = 'none'
      else if (rail.dataset.orig === undefined) rail.style.display = ''
    }

    createButton()
    updateAutoHide()

    const obs = new MutationObserver(() => {
      createButton()
      updateAutoHide()
    })
    obs.observe(document.body, { childList: true, subtree: true })
    return () => {
      obs.disconnect()
      const b = document.getElementById(id)
      if (b) b.remove()
    }
  }, [])
  return null
}
