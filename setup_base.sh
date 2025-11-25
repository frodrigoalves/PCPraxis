#!/bin/bash
# ============================================================================
# PC PRAXIS - Setup Base do Projeto
# Fase 0: Estrutura de diretórios e configuração inicial
# ============================================================================

set -e

echo "🚀 Iniciando setup do projeto PC Praxis..."

# Criar estrutura de diretórios
mkdir -p pc-praxis-platform/{backend,frontend,infra,docs}
cd pc-praxis-platform

# Inicializar Git
git init
git branch -M main

# Criar .gitignore raiz
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnp/
.pnp.js

# Testing
coverage/
*.log

# Production
dist/
build/
.next/

# Environment
.env
.env.local
.env.*.local

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Docker
*.pid
*.seed
*.log
EOF

# Criar README principal
cat > README.md << 'EOF'
# PC Praxis Platform

Plataforma completa para venda de PCs personalizados, serviços de manutenção e gestão de tickets.

## Stack

- Frontend: Next.js 14 + React + TypeScript + TailwindCSS
- Backend: NestJS + TypeScript + Prisma
- Database: PostgreSQL 16
- Analytics: Plausible CE (self-hosted)
- Infra: Docker + Docker Compose

## Quick Start

```bash
# Desenvolvimento
docker compose up -d

# Acesso
- Frontend: http://localhost:3000
- Backend: http://localhost:4000
- Plausible: http://localhost:8000
```

## Estrutura

```
├── backend/          # API NestJS
├── frontend/         # Website Next.js
├── infra/            # Docker, CI/CD
└── docs/             # Documentação
```

Consulte `docs/DESENVOLVIMENTO.md` para guia completo.
EOF

# Criar estrutura de docs
cat > docs/DESENVOLVIMENTO.md << 'EOF'
# Guia de Desenvolvimento

## Pontos de Restauração

- `v0.1-planning` - Setup inicial
- `v0.2-backend-core` - Auth e base
- `v0.3-catalog-orders` - Catálogo e pedidos
- `v0.4-logistics` - Frete e taxas
- `v0.5-frontend` - Interface completa
- `v0.6-tracking` - Analytics
- `v1.0-production` - Deploy produção

## Comandos Úteis

### Backend
```bash
cd backend
npm run start:dev     # Desenvolvimento
npm run build         # Build produção
npm run test          # Testes
npm run migration:run # Rodar migrations
```

### Frontend
```bash
cd frontend
npm run dev          # Desenvolvimento
npm run build        # Build produção
npm run lint         # Lint
```

### Docker
```bash
docker compose up -d              # Subir stack
docker compose logs -f backend    # Ver logs
docker compose down              # Derrubar stack
docker compose restart backend   # Restart serviço
```
EOF

# Criar docker-compose inicial
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    container_name: pcpraxis-db
    environment:
      POSTGRES_DB: pcpraxis
      POSTGRES_USER: pcpraxis
      POSTGRES_PASSWORD: ${DB_PASSWORD:-dev_password_change_in_prod}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - pcpraxis-net
    restart: unless-stopped

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: pcpraxis-backend
    environment:
      NODE_ENV: ${NODE_ENV:-development}
      DATABASE_URL: postgresql://pcpraxis:${DB_PASSWORD:-dev_password_change_in_prod}@db:5432/pcpraxis
      JWT_SECRET: ${JWT_SECRET:-change_this_in_production}
      PORT: 4000
    ports:
      - "4000:4000"
    depends_on:
      - db
    volumes:
      - ./backend:/app
      - /app/node_modules
    networks:
      - pcpraxis-net
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: pcpraxis-frontend
    environment:
      NODE_ENV: ${NODE_ENV:-development}
      NEXT_PUBLIC_API_URL: ${NEXT_PUBLIC_API_URL:-http://localhost:4000}
    ports:
      - "3000:3000"
    depends_on:
      - backend
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next
    networks:
      - pcpraxis-net
    restart: unless-stopped

  plausible_db:
    image: postgres:16-alpine
    container_name: plausible-db
    environment:
      POSTGRES_DB: plausible
      POSTGRES_USER: plausible
      POSTGRES_PASSWORD: ${PLAUSIBLE_DB_PASSWORD:-plausible_dev}
    volumes:
      - plausible_db_data:/var/lib/postgresql/data
    networks:
      - pcpraxis-net
    restart: unless-stopped

  plausible_events_db:
    image: clickhouse/clickhouse-server:latest
    container_name: plausible-events
    volumes:
      - plausible_events_data:/var/lib/clickhouse
    networks:
      - pcpraxis-net
    restart: unless-stopped

  plausible:
    image: plausible/analytics:latest
    container_name: plausible-analytics
    command: sh -c "sleep 10 && /entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"
    depends_on:
      - plausible_db
      - plausible_events_db
    ports:
      - "8000:8000"
    environment:
      BASE_URL: ${PLAUSIBLE_BASE_URL:-http://localhost:8000}
      SECRET_KEY_BASE: ${PLAUSIBLE_SECRET:-change_this_in_production_min_64_chars_long}
      DATABASE_URL: postgresql://plausible:${PLAUSIBLE_DB_PASSWORD:-plausible_dev}@plausible_db:5432/plausible
      CLICKHOUSE_DATABASE_URL: http://plausible_events_db:8123/plausible
    networks:
      - pcpraxis-net
    restart: unless-stopped

volumes:
  postgres_data:
  plausible_db_data:
  plausible_events_data:

networks:
  pcpraxis-net:
    driver: bridge
EOF

# Criar .env de exemplo
cat > .env.example << 'EOF'
# Database
DB_PASSWORD=your_secure_password

# Backend
NODE_ENV=development
JWT_SECRET=your_jwt_secret_min_32_chars
HASH_SALT_ROTATION=daily

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXT_PUBLIC_ANALYTICS_ENABLED=true

# Plausible
PLAUSIBLE_BASE_URL=http://localhost:8000
PLAUSIBLE_DB_PASSWORD=your_plausible_db_password
PLAUSIBLE_SECRET=your_plausible_secret_min_64_chars
EOF

cp .env.example .env

# Criar Makefile para comandos comuns
cat > Makefile << 'EOF'
.PHONY: help setup dev up down logs clean test build deploy

help: ## Mostra ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Setup inicial do projeto
	@echo "🔧 Instalando dependências..."
	cd backend && npm install
	cd frontend && npm install

dev: ## Inicia ambiente de desenvolvimento
	docker compose up -d

up: dev ## Alias para dev

down: ## Para todos os containers
	docker compose down

logs: ## Mostra logs de todos os serviços
	docker compose logs -f

clean: ## Remove volumes e limpa ambiente
	docker compose down -v
	rm -rf backend/node_modules frontend/node_modules
	rm -rf backend/dist frontend/.next

test: ## Roda testes
	cd backend && npm test
	cd frontend && npm test

build: ## Build para produção
	cd backend && npm run build
	cd frontend && npm run build

deploy-staging: ## Deploy para staging
	@echo "🚀 Deploy para staging..."
	git push staging main

deploy-prod: ## Deploy para produção
	@echo "🚀 Deploy para produção..."
	git tag -a v$$(date +%Y%m%d-%H%M%S) -m "Production release"
	git push origin --tags
	git push production main
EOF

echo "✅ Estrutura base criada!"
echo ""
echo "📋 Próximos passos:"
echo "1. Edite o arquivo .env com suas credenciais"
echo "2. Execute: bash 02-setup-backend.sh"
echo ""
echo "🏷️  Tag de restauração: v0.1-planning"
git add .
git commit -m "feat: setup inicial do projeto - v0.1-planning"
git tag v0.1-planning

echo "✨ Setup concluído!"
