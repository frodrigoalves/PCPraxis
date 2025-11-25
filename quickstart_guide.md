# 🚀 PC Praxis - Guia Rápido de Setup

## ⚡ Setup Completo em 5 Minutos

### Pré-requisitos
- Node.js 20+ instalado
- Docker e Docker Compose instalados
- Git instalado

### 1️⃣ Clone e Configure

```bash
# Criar diretório do projeto
mkdir pc-praxis-platform
cd pc-praxis-platform

# Executar setup base
bash 01-setup-projeto-base.sh

# Editar .env com suas credenciais
nano .env
```

### 2️⃣ Setup Backend

```bash
bash 02-setup-backend.sh

# Criar primeira migration
cd backend
npx prisma migrate dev --name init
cd ..
```

### 3️⃣ Setup Frontend

```bash
bash 03-setup-frontend.sh
```

### 4️⃣ Subir Stack Completo

```bash
bash 04-deploy-stack.sh
# Escolha opção 1 (Desenvolvimento)
```

### 5️⃣ Acessar

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:4000/api
- **API Docs:** http://localhost:4000/api/docs
- **Plausible:** http://localhost:8000
- **Database:** localhost:5432

---

## 📦 Comandos Essenciais

### Desenvolvimento Diário

```bash
# Subir tudo
make dev

# Ver logs
make logs

# Parar tudo
make down

# Limpar e reiniciar
make clean
make dev
```

### Backend

```bash
cd backend

# Desenvolvimento (hot reload)
npm run start:dev

# Build produção
npm run build

# Testes
npm run test

# Nova migration
npx prisma migrate dev --name nome_da_migration

# Ver banco (Prisma Studio)
npx prisma studio
```

### Frontend

```bash
cd frontend

# Desenvolvimento (hot reload)
npm run dev

# Build produção
npm run build

# Testes
npm run test

# Lint
npm run lint
```

---

## 🏗️ Estrutura do Projeto

```
pc-praxis-platform/
├── backend/              # API NestJS
│   ├── src/
│   │   ├── auth/         # Autenticação
│   │   ├── users/        # Usuários
│   │   ├── catalog/      # Produtos e Serviços
│   │   ├── orders/       # Pedidos
│   │   ├── service-tickets/  # Tickets manutenção
│   │   ├── tracking/     # Analytics e eventos
│   │   └── common/       # Utilitários
│   ├── prisma/
│   │   └── schema.prisma # Schema do banco
│   └── Dockerfile
│
├── frontend/             # Website Next.js
│   ├── src/
│   │   ├── app/          # Páginas (App Router)
│   │   ├── components/   # Componentes React
│   │   ├── lib/          # Utilitários
│   │   └── types/        # TypeScript types
│   └── Dockerfile
│
├── infra/                # Infraestrutura
│   ├── nginx.conf        # Nginx config
│   └── ssl/              # Certificados
│
├── .github/
│   └── workflows/        # CI/CD
│
├── docs/                 # Documentação
├── docker-compose.yml    # Dev
├── docker-compose.prod.yml  # Produção
├── Makefile              # Comandos úteis
└── README.md
```

---

## 🔄 Workflow de Desenvolvimento

### 1. Criar Feature

```bash
git checkout -b feature/nova-funcionalidade
# Desenvolver...
git add .
git commit -m "feat: descrição da feature"
git push origin feature/nova-funcionalidade
```

### 2. Pull Request

1. Abrir PR no GitHub
2. CI/CD roda testes automaticamente
3. Review do código
4. Merge para `main`

### 3. Deploy Automático

- **Staging:** Push para branch `staging`
- **Produção:** Push para branch `main`

---

## 🗄️ Banco de Dados

### Acessar PostgreSQL

```bash
# Via Docker
docker compose exec db psql -U pcpraxis pcpraxis

# Via localhost
psql -h localhost -U pcpraxis -d pcpraxis
```

### Backup Manual

```bash
# Criar backup
docker compose exec db pg_dump -U pcpraxis pcpraxis > backup_$(date +%Y%m%d).sql

# Restaurar backup
docker compose exec -T db psql -U pcpraxis pcpraxis < backup_YYYYMMDD.sql
```

### Migrations

```bash
cd backend

# Criar nova migration
npx prisma migrate dev --name descricao

# Aplicar migrations em prod
npx prisma migrate deploy

# Resetar banco (DEV APENAS!)
npx prisma migrate reset
```

---

## 🔐 Segurança

### Variáveis Sensíveis

**Nunca commitar:**
- `.env`
- Chaves privadas
- Senhas
- Tokens de API

**Sempre usar:**
- `.env.example` para documentar
- GitHub Secrets para CI/CD
- Senhas fortes (32+ caracteres)

### Checklist de Produção

- [ ] Trocar todas as senhas padrão
- [ ] Configurar SSL/TLS
- [ ] Ativar firewall (portas 80, 443, 22 apenas)
- [ ] Configurar backup automático
- [ ] Ativar monitoramento
- [ ] Revisar permissões do banco
- [ ] Configurar rate limiting
- [ ] Ativar logs de auditoria

---

## 🐛 Troubleshooting

### Containers não sobem

```bash
# Ver logs detalhados
docker compose logs backend
docker compose logs frontend
docker compose logs db

# Recriar containers
docker compose down -v
docker compose up -d --build
```

### Erro de conexão com banco

```bash
# Verificar se DB está rodando
docker compose ps db

# Testar conexão
docker compose exec db pg_isready -U pcpraxis

# Ver logs do DB
docker compose logs db
```

### Frontend não conecta no backend

1. Verificar `NEXT_PUBLIC_API_URL` no `.env.local`
2. Verificar se backend está rodando: `curl http://localhost:4000/api/health`
3. Ver console do navegador (F12)

### Prisma não gera types

```bash
cd backend
npx prisma generate
npm run build
```

### Erro de migração

```bash
# Ver status
npx prisma migrate status

# Resolver manualmente
npx prisma migrate resolve --applied "nome_da_migration"

# Reset completo (DEV)
npx prisma migrate reset
```

---

## 📊 Monitoramento

### Health Checks

```bash
# Backend
curl http://localhost:4000/api/health

# Frontend
curl http://localhost:3000

# Plausible
curl http://localhost:8000
```

### Logs em Tempo Real

```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f backend
docker compose logs -f frontend

# Últimas 100 linhas
docker compose logs --tail=100 backend
```

### Métricas do Container

```bash
# Stats em tempo real
docker stats

# Uso de disco
docker system df

# Limpar recursos não usados
docker system prune -a
```

---

## 🚀 Deploy para Produção

### Checklist Pré-Deploy

- [ ] Testes passando localmente
- [ ] Migrations testadas
- [ ] Variáveis de ambiente configuradas
- [ ] Backup do banco atual
- [ ] SSL configurado
- [ ] Domínio apontando para VPS

### Deploy VPS

```bash
# 1. Conectar no VPS
ssh user@seu-servidor.com

# 2. Clonar projeto
git clone https://github.com/seu-user/pc-praxis.git
cd pc-praxis

# 3. Configurar .env
nano .env
# Preencher com valores de produção

# 4. Subir stack
docker compose -f docker-compose.prod.yml up -d

# 5. Rodar migrations
docker compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy

# 6. Verificar
docker compose ps
curl https://seu-dominio.com/api/health
```

### Deploy via CI/CD

```bash
# Push para produção
git push origin main

# Acompanhar
gh run watch

# Ver logs do deploy
gh run view
```

---

## 📚 Recursos Adicionais

### Documentação

- **NestJS:** https://docs.nestjs.com
- **Next.js:** https://nextjs.org/docs
- **Prisma:** https://www.prisma.io/docs
- **Docker:** https://docs.docker.com

### Ferramentas Úteis

- **Prisma Studio:** Interface visual do banco
- **Postman/Insomnia:** Testar API
- **pgAdmin:** Cliente PostgreSQL
- **Docker Desktop:** Interface Docker

### Suporte

- Issues: https://github.com/seu-user/pc-praxis/issues
- Docs: `docs/` no repositório
- Email: office@pcprxs.at

---

## 🏷️ Pontos de Restauração

Se algo der errado, volte para uma versão estável:

```bash
# Ver tags disponíveis
git tag -l

# Voltar para uma tag
git checkout v0.2-backend-core
git checkout v0.5-frontend-admin
git checkout v1.0-production-ready

# Ou criar nova branch a partir de uma tag
git checkout -b fix-branch v0.5-frontend-admin
```

### Tags Principais

- `v0.1-planning` - Setup inicial
- `v0.2-backend-core` - Backend funcionando
- `v0.3-catalog-orders` - Catálogo completo
- `v0.5-frontend-admin` - Interface pronta
- `v1.0-production-ready` - Pronto para produção

---

## ✅ Checklist de Projeto Completo

### Backend
- [ ] Auth funcionando (login, registro, JWT)
- [ ] CRUD de produtos
- [ ] CRUD de serviços
- [ ] Sistema de pedidos com protocolo
- [ ] Tickets de manutenção
- [ ] Tracking de eventos
- [ ] Configurador de PC
- [ ] Cálculo de frete e taxas
- [ ] Migrations rodando
- [ ] Testes básicos

### Frontend
- [ ] Home page
- [ ] Página de serviços
- [ ] Loja (catálogo)
- [ ] PC Konfigurator
- [ ] Formulário de contato
- [ ] Dashboard admin
- [ ] Responsivo
- [ ] Dark mode
- [ ] Integração com backend
- [ ] Consent banner

### Infra
- [ ] Docker configurado
- [ ] CI/CD funcionando
- [ ] SSL ativo
- [ ] Backup automático
- [ ] Monitoramento
- [ ] Analytics (Plausible)
- [ ] Logs estruturados

### Docs
- [ ] README completo
- [ ] API documentada (Swagger)
- [ ] Guia de desenvolvimento
- [ ] Guia de deploy
- [ ] Variáveis de ambiente documentadas

---

**🎉 Parabéns! Seu projeto PC Praxis está pronto para rodar!**

Para dúvidas ou melhorias, abra uma issue no GitHub.
