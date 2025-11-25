#!/bin/bash
# ============================================================================
# PC PRAXIS - Setup Frontend (Next.js 14)
# Fase 4: Frontend Web & Dashboard Admin
# ============================================================================

set -e

echo "🎨 Configurando Frontend Next.js..."

cd frontend

# Criar projeto Next.js
npx create-next-app@latest . \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-npm

# Instalar dependências adicionais
npm install --save \
  axios \
  @tanstack/react-query \
  zustand \
  react-hook-form \
  zod \
  @hookform/resolvers \
  clsx \
  tailwind-merge \
  lucide-react \
  next-themes

npm install --save-dev \
  @types/node \
  prettier \
  prettier-plugin-tailwindcss

# Criar estrutura de diretórios
mkdir -p src/{components,lib,hooks,store,types,styles}
mkdir -p src/app/{(marketing),admin,api}
mkdir -p src/components/{ui,layout,forms}

# Criar configuração do Tailwind atualizada
cat > tailwind.config.ts << 'EOF'
import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: 'class',
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          dark: '#111A19',
          darker: '#030B0D',
        },
        accent: {
          light: '#FEFEFE',
        },
        background: '#0C1416',
      },
      fontFamily: {
        sans: ['var(--font-inter)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'monospace'],
      },
    },
  },
  plugins: [],
}
export default config
EOF

# Criar lib de utilitários
cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(value: number, currency: string = 'EUR'): string {
  return new Intl.NumberFormat('de-AT', {
    style: 'currency',
    currency,
  }).format(value)
}

export function formatDate(date: Date | string): string {
  return new Intl.DateTimeFormat('de-AT', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(new Date(date))
}
EOF

# Criar API client
cat > src/lib/api-client.ts << 'EOF'
import axios from 'axios'

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api',
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
})

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// Response interceptor
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default apiClient
EOF

# Criar tipos
cat > src/types/index.ts << 'EOF'
export interface Product {
  id: string
  sku: string
  name: string
  shortDescription: string
  fullDescription?: string
  basePrice: number
  stockQuantity: number
  status: 'DRAFT' | 'ACTIVE' | 'ARCHIVED'
  isFeatured: boolean
  mainImageUrl?: string
  category?: ProductCategory
  createdAt: string
  updatedAt: string
}

export interface ProductCategory {
  id: string
  name: string
  slug: string
}

export interface Service {
  id: string
  slug: string
  title: string
  shortDescription: string
  fullDescription?: string
  icon?: string
  startingPrice?: number
  isHighlighted: boolean
  category?: ServiceCategory
}

export interface ServiceCategory {
  id: string
  name: string
}

export interface Order {
  id: string
  protocol: string
  status: 'PENDING' | 'PAID' | 'IN_PREPARATION' | 'SHIPPED' | 'DELIVERED' | 'CANCELLED'
  subtotal: number
  shippingCost: number
  taxAmount: number
  total: number
  createdAt: string
  items: OrderItem[]
}

export interface OrderItem {
  id: string
  product: Product
  quantity: number
  unitPrice: number
  subtotal: number
}

export interface ServiceTicket {
  id: string
  protocol: string
  status: 'OPENED' | 'DIAGNOSING' | 'WAITING_CUSTOMER' | 'IN_REPAIR' | 'READY' | 'CLOSED'
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT'
  symptoms: string
  createdAt: string
}

export interface ConfigComponent {
  id: string
  name: string
  brand?: string
  model?: string
  price: number
  specs?: Record<string, any>
  type: ConfigComponentType
}

export interface ConfigComponentType {
  id: string
  code: string
  name: string
  isRequired: boolean
}
EOF

# Criar layout principal
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { ThemeProvider } from '@/components/theme-provider'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'PC Praxis - Gaming PCs & Reparos',
  description: 'PCs personalizados, manutenção e suporte técnico especializado',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="de" suppressHydrationWarning>
      <body className={inter.className}>
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem
          disableTransitionOnChange
        >
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
EOF

# Criar provider de tema
cat > src/components/theme-provider.tsx << 'EOF'
'use client'

import * as React from 'react'
import { ThemeProvider as NextThemesProvider } from 'next-themes'
import { type ThemeProviderProps } from 'next-themes/dist/types'

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}
EOF

# Criar página inicial
cat > src/app/page.tsx << 'EOF'
import Link from 'next/link'

export default function Home() {
  return (
    <main className="min-h-screen bg-background text-accent-light">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center space-y-8">
          <h1 className="text-6xl font-bold">
            PC Praxis
          </h1>
          <p className="text-xl text-gray-300">
            Gaming PCs, Manutenção e Configurador Personalizado
          </p>
          
          <div className="flex gap-4 justify-center mt-12">
            <Link
              href="/configurator"
              className="px-8 py-4 bg-primary-dark hover:bg-primary-darker rounded-lg font-semibold transition"
            >
              PC Konfigurator
            </Link>
            <Link
              href="/shop"
              className="px-8 py-4 border border-primary-dark hover:bg-primary-dark rounded-lg font-semibold transition"
            >
              Zur Loja
            </Link>
          </div>
        </div>
      </div>
    </main>
  )
}
EOF

# Criar globals.css atualizado
cat > src/app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 12 16 22;
    --foreground: 254 254 254;
  }

  .dark {
    --background: 12 16 22;
    --foreground: 254 254 254;
  }
}

@layer base {
  * {
    @apply border-gray-700;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF

# Criar Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production

COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
COPY --from=build /app/public ./public

EXPOSE 3000

CMD ["node", "server.js"]
EOF

# Atualizar next.config.mjs
cat > next.config.mjs << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  images: {
    domains: ['localhost'],
  },
  experimental: {
    serverActions: {
      enabled: true,
    },
  },
}

export default nextConfig
EOF

# Criar .dockerignore
cat > .dockerignore << 'EOF'
node_modules
.next
.git
.env*.local
README.md
EOF

# Criar .env.local de exemplo
cat > .env.example << 'EOF'
NEXT_PUBLIC_API_URL=http://localhost:4000/api
NEXT_PUBLIC_ANALYTICS_ENABLED=true
NEXT_PUBLIC_PLAUSIBLE_DOMAIN=localhost
NEXT_PUBLIC_PLAUSIBLE_API_HOST=http://localhost:8000
EOF

cp .env.example .env.local

# Criar prettier config
cat > .prettierrc << 'EOF'
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
EOF

echo "✅ Frontend configurado!"
echo ""
echo "📋 Próximos passos:"
echo "1. Execute: cd frontend && npm run dev"
echo "2. Acesse: http://localhost:3000"
echo "3. Execute: bash ../04-deploy-stack.sh para subir tudo"
echo ""
echo "🏷️  Tag de restauração: v0.5-frontend-admin"

cd ..
git add frontend/
git commit -m "feat: setup frontend Next.js 14 - v0.5-frontend-admin"
git tag v0.5-frontend-admin

echo "✨ Frontend setup concluído!"
