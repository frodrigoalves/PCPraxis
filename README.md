✅ Resumo Final
Criei 5 módulos executáveis completos para seu projeto PC Praxis:
📦 Módulos Criados

01-setup-projeto-base.sh

Estrutura de diretórios
Docker Compose
Makefile com comandos úteis
Git inicializado
Tag: v0.1-planning


02-setup-backend.sh

NestJS + TypeScript
Prisma ORM com schema completo
Módulos: Auth, Users, Catalog, Orders, Tickets, Tracking
Dockerfile multi-stage
Tag: v0.2-backend-core


03-setup-frontend.sh

Next.js 14 + React + TypeScript
TailwindCSS com paleta escura
API client configurado
Estrutura de componentes
Tag: v0.5-frontend-admin


04-deploy-stack.sh

Deploy automático (dev/staging/prod)
Health checks
Nginx configurado
SSL ready
Tag: v1.0-production-ready


05-github-actions-setup.sh

CI/CD completo
Testes automáticos
Deploy automático
Backup diário
Security scans



🎯 Características
✅ Alemão/Áustria: Preparado para de-AT, EUR
✅ GDPR Compliant: IP pseudonimizado, consent tracking
✅ Protocolo de Pedidos: Formato PCP-AAAAMMDD-0001
✅ Tickets de Manutenção: Formato SRV-AAAAMMDD-0001
✅ PC Konfigurator: Sistema de componentes com compatibilidade
✅ Frete & Taxas: Cálculo integrado aos pedidos
✅ Analytics: Plausible self-hosted, privacy-first
✅ Ferramentas Gratuitas: Stack 100% open-source
✅ Pontos de Restauração: Tags Git em cada fase
🚀 Como Usar
bash# 1. Setup base
bash 01-setup-projeto-base.sh

# 2. Backend
bash 02-setup-backend.sh
cd backend && npx prisma migrate dev --name init && cd ..

# 3. Frontend
bash 03-setup-frontend.sh

# 4. Subir tudo
bash 04-deploy-stack.sh
# Escolha: 1) Desenvolvimento

# 5. CI/CD (opcional)
bash 05-github-actions-setup.sh
📍 Acessos Locais

Frontend: http://localhost:3000
Backend: http://localhost:4000
API Docs: http://localhost:4000/api/docs
Plausible: http://localhost:8000
Database: localhost:5432

🏷️ Tags de Restauração
Cada fase tem uma tag Git para você poder voltar:
bashgit checkout v0.2-backend-core    # Backend pronto
git checkout v0.5-frontend-admin  # Interface completa
git checkout v1.0-production-ready # Prod ready

# PCPraxis

# PC Praxis Platform

Plataforma full stack para a empresa **PC Praxis (Pedro Hauser)**, com foco em:

- Website institucional e comercial;
- Loja + PC Konfigurator (configurador de PCs);
- Catálogo de serviços e produtos;
- Tickets com número de protocolo para:
  - compras/pedidos;
  - serviços de manutenção;
  - frete, entregas e taxas associadas;
- Backend para autenticação, leads e rastreamento de eventos;
- Stack baseada em ferramentas gratuitas / open-source.

---

## 1. Stack Tecnológica (gratuita / open-source)

### 1.1. Frontend

- **Next.js + React + TypeScript** – framework full stack gratuito, focado em performance e SEO.
- **TailwindCSS** – utilitário CSS open-source, leve e flexível.
- **Radix / Headless UI (opcional)** – componentes acessíveis.

### 1.2. Backend

- **Node.js + NestJS ou Express** – runtime e framework gratuitos e amplamente usados.
- **TypeScript** – tipagem estática para maior segurança.
- **Prisma ou TypeORM** – ORM gratuito para Postgres.

### 1.3. Banco de Dados

- **PostgreSQL** – banco relacional open-source, robusto e padrão de mercado.   

### 1.4. Observabilidade, Logs e Analytics

- Logs tratados como **streams de eventos**, conforme 12-Factor App.   
- Web analytics:
  - **Plausible CE** (self-hosted) – open-source, leve, focado em privacidade, compatível com GDPR, sem cookies.   
  - Alternativa: **Matomo** self-hosted (também open-source e GDPR-compliant).   

### 1.5. Infraestrutura & Deploy

- **Docker + Docker Compose** – empacotamento de frontend, backend e banco.
- **Nginx ou Traefik** – reverse proxy e TLS.
- **GitHub + GitHub Actions** – CI/CD gratuito, com build, testes e deploy automatizado.   

---

## 2. Domínios de Negócio

### 2.1. Catálogo

- **Serviços** (manutenção, montagem, consultoria).
- **Produtos** (PCs completos, componentes, acessórios).
- Ligação com:
  - PC Konfigurator (componentes configuráveis);
  - Tickets de manutenção (serviços contratados);
  - Pedidos de compra (produtos vendidos).

### 2.2. Pedidos e Protocolo de Compra

Cada compra gera um **Ticket de Pedido** com número de protocolo único (`order_protocol`), usado para:

- rastrear status do pedido;
- referenciar em e-mails, notas fiscais e atendimento.

Campos principais do pedido:

- `order_id` (UUID);
- `order_protocol` (ex.: `PCP-AAAAMMDD-0001`);
- `customer_id` / `visitor_id`;
- itens (produtos/serviços);
- valores de frete, taxas, descontos;
- status (`pending`, `paid`, `in_preparation`, `shipped`, `delivered`, `cancelled`);
- timestamps de cada etapa.

### 2.3. Tickets de Manutenção / Serviços

Cada serviço de manutenção abre um **Ticket de Serviço** com protocolo próprio:

- `service_ticket_id` (UUID);
- `service_protocol` (ex.: `SRV-AAAAMMDD-0001`);
- cliente, equipamento, sintomas, prioridade;
- vínculo com produtos/serviços do catálogo;
- status (`opened`, `diagnosing`, `waiting_customer`, `in_repair`, `ready`, `closed`).

### 2.4. Frete, Entrega e Taxas

Tratados como entidades de primeira classe:

- **Frete**:
  - tabela de faixas de CEP/país, peso, transportadora;
  - regras de cálculo (fixo, por peso, por distância, grátis acima de X).
- **Entrega**:
  - tracking de envio (transportadora, código de rastreio, janelas de entrega);
  - eventos de status (`shipment_created`, `in_transit`, `delivered`).
- **Taxas**:
  - impostos (VAT), taxas de serviço, meios de pagamento;
  - configuráveis via painel admin.

---

## 3. Arquitetura de Módulos

### 3.1. Backend (módulos)

- `auth` – registro, login, recuperação de senha.
- `users` – perfis, dados de contato.
- `catalog` – produtos, serviços, categorias e componentes de configurador.
- `orders` – pedidos, protocolos de compra, pagamentos.
- `service-tickets` – manutenção, protocolos de serviço.
- `shipping` – fretes, transportadoras, entregas.
- `fees` – impostos e taxas.
- `tracking` – visitantes, eventos e consentimentos.
- `leads` – captação e qualificação de oportunidades.

### 3.2. Frontend (áreas)

- Website público: Home, Sobre, Serviços, Loja, PC Konfigurator, Blog, Contato.
- Área do cliente (opcional): histórico de pedidos, tickets, dados de entrega.
- Dashboard admin:
  - gestão de catálogo;
  - gestão de pedidos e tickets;
  - configuração de fretes e taxas;
  - visão de funil (visitas → configurador → pedido → entrega).

---

## 4. Princípios de Projeto (12-Factor App)

O projeto segue os princípios da **12-Factor App**:   

1. **Codebase único**, vários deploys (dev, staging, prod).  
2. **Dependências declaradas** (package.json) e isoladas.  
3. **Configuração no ambiente** (`.env`), nunca hardcoded.  
4. **Backing services** (Postgres, Redis, Plausible) tratados como recursos anexos, acessados por URL.  
5. **Build / Release / Run separados**, com versões imutáveis e rollback simples.   
6. **Processos stateless**, com estado em banco/serviços.  
7. **Port binding** – expõe HTTP diretamente.  
8. **Dev/prod parity** – dev local espelha produção o máximo possível (via Docker).  
9. **Logs como streams**, enviados para stdout e agregadores.  
10. **Admin tasks** (migrations, seeds) rodando como processos pontuais.

---

## 5. Roadmap por Fases com Pontos de Restauração

Cada fase termina com um **Ponto de Restauração Estratégico**: um tag Git (`vX.Y`) + estado mínimo do sistema que deve estar estável.

### Fase 0 – Planejamento & Setup

**Objetivo:** alinhar visão, stack e requisitos.

- Definir objetivos de negócio (venda online, serviços, leads).  
- Mapear domínios (catálogo, pedidos, tickets, frete, tracking).  
- Configurar repositório Git e convenções de branch.  
- Especificar esquema inicial de banco.

**Ponto de restauração:**  
- Tag: `v0.1-planning`  
- Estado: docs de requisitos + modelos iniciais de ERD no repo (`/docs`).

---

### Fase 1 – Base de Backend

**Objetivo:** levantar espinha dorsal da API.

- Criar projeto Node/Nest/Express com TypeScript.  
- Implementar:
  - módulos `auth`, `users`;  
  - conexão com Postgres;  
  - migrations básicas `users`, `companies`.  
- Definir infra de config (`.env`), scripts de build e start.

**Ponto de restauração:**  
- Tag: `v0.2-backend-core`  
- Estado: API com auth e health check funcionando em Docker local.

---

### Fase 2 – Catálogo + Tickets

**Objetivo:** habilitar o coração de negócio.

- Implementar módulos:
  - `catalog` (produtos, serviços, categorias);  
  - `configurator` (tipos de componentes, componentes);  
  - `orders` (pedido + protocolo de compra);  
  - `service-tickets` (ticket de manutenção com protocolo).  
- Criar endpoints CRUD protegidos para admin.

**Ponto de restauração:**  
- Tag: `v0.3-catalog-orders-tickets`  
- Estado: é possível criar produtos/serviços, abrir pedidos e tickets via API.

---

### Fase 3 – Frete, Entrega e Taxas

**Objetivo:** completar fluxo transacional.

- Módulo `shipping`:
  - tabela de faixas de frete;
  - endpoint para cálculo de frete;  
  - tracking básico de entregas.  
- Módulo `fees`:
  - configuração de VAT/taxas;
  - cálculo de totais do pedido (subtotal + frete + taxa).  
- Integração desses dados em `orders`.

**Ponto de restauração:**  
- Tag: `v0.4-logistics`  
- Estado: pedidos retornam valores completos (itens, frete, taxas, total).

---

### Fase 4 – Frontend Web & Dashboard Admin

**Objetivo:** expor tudo para usuário final e administradores.

- Website público em Next.js:
  - páginas Home, Serviços, Loja, PC Konfigurator, Contato.  
  - consumo da API para catálogo, frete e criação de pedidos.  
- Dashboard admin:
  - gestão de catálogo;  
  - visualização/edição de pedidos e tickets;  
  - configuração de fretes e taxas.

**Ponto de restauração:**  
- Tag: `v0.5-frontend-admin`  
- Estado: fluxo completo manual (admin cadastra, cliente compra, ticket abre).

---

### Fase 5 – Tracking, Analytics & Ads

**Objetivo:** dar inteligência ao sistema para follow-up e remarketing.

- Implementar módulo `tracking`:
  - registro de visitantes (`visitor_id`);  
  - pseudonimização de IP (hash + salt, sem armazenar IP cru).   
  - eventos (`page_view`, `configurator_*`, `add_to_cart`, `purchase_completed`).  
- Integrar com **Plausible** ou **Matomo** self-hosted (script + events).   
- Expor eventos relevantes via Tag Manager para Google Ads / Meta (se necessário).

**Ponto de restauração:**  
- Tag: `v0.6-tracking-analytics`  
- Estado: funil completo visível (visitas → configurador → pedido → entrega).

---

### Fase 6 – Empacotamento, Servidor & Deploy

**Objetivo:** ter ambiente de staging/produção estável com rollback simples.

- Escrever `Dockerfile` do backend e frontend (build separado de runtime).   
- Criar `docker-compose.yml` com:
  - `frontend`, `backend`, `postgres`, `reverse-proxy`, `analytics` (Plausible/Matomo).  
- Configurar CI/CD (GitHub Actions):
  - build + testes a cada push;  
  - build de imagens e deploy em VPS.  
- Configurar Nginx/Traefik com TLS e rotas `/` (frontend) e `/api` (backend).

**Ponto de restauração:**  
- Tag: `v1.0-production-ready`  
- Estado: ambiente de produção operando, com rollback por tag de imagem/versão.

---

## 6. Setup de Desenvolvimento (resumo)

### 6.1. Pré-requisitos

- Node.js LTS  
- Docker + Docker Compose  
- Git

### 6.2. Clonar e subir ambiente local

```bash
git clone https://github.com/SEU_USUARIO/pc-praxis-platform.git
cd pc-praxis-platform

# subir stack completa (dev)
docker compose up -d
