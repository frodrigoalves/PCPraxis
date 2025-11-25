#!/bin/bash
# ============================================================================
# PC PRAXIS - Setup CI/CD com GitHub Actions
# Automação de build, testes e deploy
# ============================================================================

set -e

echo "⚙️  Configurando CI/CD com GitHub Actions..."

# Criar estrutura de workflows
mkdir -p .github/workflows

# Workflow principal - CI/CD
cat > .github/workflows/main.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [main, staging, develop]
  pull_request:
    branches: [main, staging]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test-backend:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: pcpraxis_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        working-directory: backend
        run: npm ci
      
      - name: Generate Prisma Client
        working-directory: backend
        run: npx prisma generate
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/pcpraxis_test
      
      - name: Run migrations
        working-directory: backend
        run: npx prisma migrate deploy
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/pcpraxis_test
      
      - name: Run tests
        working-directory: backend
        run: npm test
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/pcpraxis_test
          JWT_SECRET: test_secret
      
      - name: Lint
        working-directory: backend
        run: npm run lint

  test-frontend:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        working-directory: frontend
        run: npm ci
      
      - name: Lint
        working-directory: frontend
        run: npm run lint
      
      - name: Build
        working-directory: frontend
        run: npm run build
        env:
          NEXT_PUBLIC_API_URL: http://localhost:4000/api

  build-and-push:
    needs: [test-backend, test-frontend]
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/staging')
    
    permissions:
      contents: read
      packages: write
    
    strategy:
      matrix:
        service: [backend, frontend]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-${{ matrix.service }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=semver,pattern={{version}}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ./${{ matrix.service }}
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/staging'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to staging
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          script: |
            cd ~/pc-praxis
            docker compose -f docker-compose.staging.yml pull
            docker compose -f docker-compose.staging.yml up -d
            docker compose -f docker-compose.staging.yml exec -T backend npx prisma migrate deploy

  deploy-production:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://pcpraxis.com
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to production
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          script: |
            cd ~/pc-praxis
            docker compose -f docker-compose.prod.yml pull
            docker compose -f docker-compose.prod.yml up -d
            docker compose -f docker-compose.prod.yml exec -T backend npx prisma migrate deploy
      
      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ github.run_number }}
          release_name: Production Release v${{ github.run_number }}
          body: |
            Automated production deployment
            Commit: ${{ github.sha }}
          draft: false
          prerelease: false
EOF

# Workflow de backup de banco
cat > .github/workflows/backup.yml << 'EOF'
name: Database Backup

on:
  schedule:
    - cron: '0 2 * * *'  # Diário às 2h
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    
    steps:
      - name: Backup Production Database
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          script: |
            DATE=$(date +%Y%m%d_%H%M%S)
            docker compose -f ~/pc-praxis/docker-compose.prod.yml exec -T db \
              pg_dump -U pcpraxis pcpraxis | \
              gzip > ~/backups/pcpraxis_$DATE.sql.gz
            
            # Manter apenas últimos 30 dias
            find ~/backups -name "pcpraxis_*.sql.gz" -mtime +30 -delete
            
            echo "✅ Backup criado: pcpraxis_$DATE.sql.gz"
EOF

# Workflow de testes de segurança
cat > .github/workflows/security.yml << 'EOF'
name: Security Checks

on:
  push:
    branches: [main, staging, develop]
  schedule:
    - cron: '0 0 * * 1'  # Semanal

jobs:
  dependency-check:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run npm audit (backend)
        working-directory: backend
        run: npm audit --audit-level=high
        continue-on-error: true
      
      - name: Run npm audit (frontend)
        working-directory: frontend
        run: npm audit --audit-level=high
        continue-on-error: true

  code-scan:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v2
        with:
          languages: javascript, typescript
      
      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v2
EOF

# Criar arquivo de secrets de exemplo
cat > .github/SECRETS.md << 'EOF'
# GitHub Secrets Necessários

Configure os seguintes secrets no GitHub:

## Staging
- `STAGING_HOST` - IP ou domínio do servidor staging
- `STAGING_USER` - Usuário SSH
- `STAGING_SSH_KEY` - Chave privada SSH

## Production
- `PRODUCTION_HOST` - IP ou domínio do servidor produção
- `PRODUCTION_USER` - Usuário SSH
- `PRODUCTION_SSH_KEY` - Chave privada SSH

## Opcional
- `SLACK_WEBHOOK` - Para notificações
- `SENTRY_DSN` - Para monitoramento de erros

## Como configurar:
1. Vá em Settings > Secrets and variables > Actions
2. Clique em "New repository secret"
3. Adicione cada secret listado acima
EOF

# Criar script para configurar secrets localmente (desenvolvimento)
cat > .github/setup-secrets.sh << 'EOF'
#!/bin/bash
# Helper para configurar secrets no GitHub via CLI

echo "🔐 Setup GitHub Secrets"
echo ""

# Verificar se gh CLI está instalado
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI não instalado"
    echo "Instale: https://cli.github.com/"
    exit 1
fi

# Staging
echo "📝 Configurando secrets de STAGING..."
read -p "Staging Host: " STAGING_HOST
read -p "Staging User: " STAGING_USER
read -p "Caminho da chave SSH: " SSH_KEY_PATH

gh secret set STAGING_HOST --body "$STAGING_HOST"
gh secret set STAGING_USER --body "$STAGING_USER"
gh secret set STAGING_SSH_KEY < "$SSH_KEY_PATH"

# Production
echo ""
echo "📝 Configurando secrets de PRODUCTION..."
read -p "Production Host: " PRODUCTION_HOST
read -p "Production User: " PRODUCTION_USER
read -p "Caminho da chave SSH: " PROD_SSH_KEY_PATH

gh secret set PRODUCTION_HOST --body "$PRODUCTION_HOST"
gh secret set PRODUCTION_USER --body "$PRODUCTION_USER"
gh secret set PRODUCTION_SSH_KEY < "$PROD_SSH_KEY_PATH"

echo ""
echo "✅ Secrets configurados!"
echo "Verifique em: Settings > Secrets and variables > Actions"
EOF

chmod +x .github/setup-secrets.sh

# Criar documentação de CI/CD
cat > .github/CICD.md << 'EOF'
# CI/CD Pipeline - PC Praxis

## Fluxo de Trabalho

### 1. Desenvolvimento (Branch `develop`)
- Push aciona testes automáticos
- Sem deploy automático

### 2. Staging (Branch `staging`)
- Testes + Build
- Deploy automático para servidor staging
- Ambiente: https://staging.pcpraxis.com

### 3. Produção (Branch `main`)
- Testes + Build
- Deploy automático para produção
- Cria release automaticamente
- Ambiente: https://pcpraxis.com

## Comandos Úteis

### Fazer deploy manual
```bash
# Staging
git push origin staging

# Produção
git push origin main
```

### Rollback rápido
```bash
# Voltar para versão anterior
git revert HEAD
git push origin main

# Ou usar tag específica
git checkout v1.0.0
git push origin main --force
```

### Ver logs do CI/CD
```bash
gh run list
gh run view <run-id>
gh run watch
```

## Backup

Backups automáticos diários às 2h (UTC)
Localização: `~/backups/` no servidor de produção
Retenção: 30 dias

### Restaurar backup
```bash
# No servidor
cd ~/backups
gunzip pcpraxis_YYYYMMDD_HHMMSS.sql.gz
docker compose exec -T db psql -U pcpraxis pcpraxis < pcpraxis_YYYYMMDD_HHMMSS.sql
```

## Monitoramento

- GitHub Actions: status de builds
- Health checks: `/api/health`
- Logs: `docker compose logs -f`

## Segurança

- Scan semanal de dependências
- CodeQL analysis em cada push
- Secrets encriptados no GitHub
EOF

echo "✅ CI/CD configurado!"
echo ""
echo "📋 Próximos passos:"
echo "1. Configure secrets no GitHub:"
echo "   - Execute: .github/setup-secrets.sh"
echo "   - Ou configure manualmente em Settings > Secrets"
echo ""
echo "2. Faça push para testar:"
echo "   git add .github/"
echo "   git commit -m 'feat: add CI/CD workflows'"
echo "   git push origin main"
echo ""
echo "3. Acompanhe em: https://github.com/seu-user/pc-praxis/actions"

git add .github/
git commit -m "feat: add CI/CD with GitHub Actions"

echo ""
echo "✨ CI/CD pronto para uso!"
