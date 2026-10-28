import { defineShikiSetup } from '@slidev/types'

const ink = {
  name: 'bento-ink',
  type: 'dark',
  colors: {
    'editor.background': '#2a2723',
    'editor.foreground': '#e6e0d8',
  },
  tokenColors: [
    { scope: ['support.type.property-name', 'support.type.property-name.json'], settings: { foreground: '#ff8199' } },
    { scope: ['string', 'string.quoted.double.json'], settings: { foreground: '#e6e0d8' } },
    { scope: ['constant.numeric', 'constant.language'], settings: { foreground: '#f3c77a' } },
    { scope: ['punctuation', 'meta.structure'], settings: { foreground: '#8f877d' } },
  ],
}

export default defineShikiSetup(() => ({
  themes: { light: ink, dark: ink },
}))
