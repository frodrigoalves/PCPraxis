#!/bin/bash
# ============================================================================
# PC PRAXIS - Deploy Stack Completo
# Fase 6: Subir ambiente completo (dev, staging ou prod)
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 PC Praxis - Deploy Stack${NC}"
echo ""

# Verificar se .env existe
if [ ! -f .env ]; then
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    echo "Copie .env.example para .env e configure as variáveis"
    exit 1
fi

# Perguntar ambiente
echo "Selecione o ambiente:"
echo "1) Desenvolvimento (local)"
echo "2) Staging (VPS)"
echo "3) Produção (VPS)"
read -p "Opção [1-3]: " ENV_CHOICE

case $ENV_CHOICE in
    1)
        ENV="development"
        ;;
    2)
        ENV="staging"
        ;;
    3)
        ENV="production"
        echo -e "${YELLOW}⚠️  ATENÇÃO: Deploy em PRODUÇÃO!${NC}"
        read -p "Tem certeza? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
            echo "Deploy cancelado."
            exit 0
        fi
        ;;
    *)
        echo -e "${RED}Opção inválida${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}📦 Ambiente: $ENV${NC}"
echo ""

# Função para verificar saúde dos serviços
check_health() {
    local service=$1
    local url=$2
    local max_attempts=30
    local attempt=0

    echo -n "Verificando $service"
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e " ${RED}✗${NC}"
    return 1
}

# Se desenvolvimento local
if [ "$ENV" = "development" ]; then
    echo "🔨 Preparando ambiente de desenvolvimento..."
    
    # Parar containers existentes
    docker compose down
    
    # Build das imagens
    echo "📦 Construindo imagens Docker..."
    docker compose build
    
    # Subir banco primeiro
    echo "🗄️  Iniciando banco de dados..."
    docker compose up -d db plausible_db plausible_events_db
    sleep 5
    
    # Rodar migrations
    echo "🔄 Executando migrations..."
    cd backend
    npx prisma migrate deploy
    npx prisma generate
    cd ..
    
    # Subir todos os serviços
    echo "🚀 Iniciando todos os serviços..."
    docker compose up -d
    
    echo ""
    echo -e "${GREEN}✅ Stack iniciado!${NC}"
    echo ""
    echo "📍 Serviços disponíveis:"
    echo "   Frontend:  http://localhost:3000"
    echo "   Backend:   http://localhost:4000"
    echo "   API Docs:  http://localhost:4000/api/docs"
    echo "   Plausible: http://localhost:8000"
    echo "   Database:  localhost:5432"
    echo ""
    echo "📊 Verificando saúde dos serviços..."
    
    check_health "Backend" "http://localhost:4000/api/health" || true
    check_health "Frontend" "http://localhost:3000" || true
    
    echo ""
    echo "💡 Comandos úteis:"
    echo "   make logs          - Ver logs de todos os serviços"
    echo "   make down          - Parar todos os containers"
    echo "   docker compose ps  - Status dos containers"
    
fi

# Se staging ou produção (VPS)
if [ "$ENV" = "staging" ] || [ "$ENV" = "production" ]; then
    
    # Verificar se temos SSH configurado
    if [ -z "$VPS_HOST" ]; then
        echo -e "${YELLOW}Configure VPS_HOST no .env${NC}"
        read -p "Host do VPS (ex: user@ip): " VPS_HOST
    fi
    
    echo "🌐 Preparando deploy para VPS..."
    
    # Criar arquivo docker-compose de produção
    cat > docker-compose.prod.yml << 'PRODEOF'
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: pcpraxis-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./infra/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./infra/ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
      - backend
    networks:
      - pcpraxis-net
    restart: always

  db:
    image: postgres:16-alpine
    container_name: pcpraxis-db
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - pcpraxis-net
    restart: always

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: pcpraxis-backend
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      JWT_SECRET: ${JWT_SECRET}
      PORT: 4000
    depends_on:
      - db
    networks:
      - pcpraxis-net
    restart: always

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: pcpraxis-frontend
    environment:
      NODE_ENV: production
      NEXT_PUBLIC_API_URL: https://${DOMAIN}/api
    depends_on:
      - backend
    networks:
      - pcpraxis-net
    restart: always

  plausible:
    image: plausible/analytics:latest
    container_name: plausible-analytics
    command: sh -c "sleep 10 && /entrypoint.sh db createdb && /entrypoint.sh db migrate && /entrypoint.sh run"
    depends_on:
      - plausible_db
      - plausible_events_db
    environment:
      BASE_URL: https://${PLAUSIBLE_DOMAIN}
      SECRET_KEY_BASE: ${PLAUSIBLE_SECRET}
      DATABASE_URL: postgresql://${PLAUSIBLE_DB_USER}:${PLAUSIBLE_DB_PASSWORD}@plausible_db:5432/plausible
      CLICKHOUSE_DATABASE_URL: http://plausible_events_db:8123/plausible
    networks:
      - pcpraxis-net
    restart: always

  plausible_db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: plausible
      POSTGRES_USER: ${PLAUSIBLE_DB_USER}
      POSTGRES_PASSWORD: ${PLAUSIBLE_DB_PASSWORD}
    volumes:
      - plausible_db_data:/var/lib/postgresql/data
    networks:
      - pcpraxis-net
    restart: always

  plausible_events_db:
    image: clickhouse/clickhouse-server:latest
    volumes:
      - plausible_events_data:/var/lib/clickhouse
    networks:
      - pcpraxis-net
    restart: always

volumes:
  postgres_data:
  plausible_db_data:
  plausible_events_data:

networks:
  pcpraxis-net:
    driver: bridge
PRODEOF

    # Criar configuração nginx
    mkdir -p infra
    cat > infra/nginx.conf << 'NGINXEOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:4000;
    }

    upstream frontend {
        server frontend:3000;
    }

    server {
        listen 80;
        server_name _;

        # Redirect to HTTPS
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name _;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        # API
        location /api/ {
            proxy_pass http://backend/api/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        # Frontend
        location / {
            proxy_pass http://frontend/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
NGINXEOF

    echo ""
    echo "📝 Instruções para deploy no VPS:"
    echo ""
    echo "1. No VPS, instale Docker e Docker Compose:"
    echo "   curl -fsSL https://get.docker.com | sh"
    echo "   sudo usermod -aG docker \$USER"
    echo ""
    echo "2. Clone o repositório:"
    echo "   git clone <seu-repo> pc-praxis"
    echo "   cd pc-praxis"
    echo ""
    echo "3. Configure o .env com valores de produção"
    echo ""
    echo "4. Execute:"
    echo "   docker compose -f docker-compose.prod.yml up -d"
    echo ""
    echo "5. Configure SSL (Let's Encrypt):"
    echo "   sudo apt install certbot"
    echo "   sudo certbot certonly --standalone -d seu-dominio.com"
    echo "   sudo cp /etc/letsencrypt/live/seu-dominio.com/fullchain.pem infra/ssl/cert.pem"
    echo "   sudo cp /etc/letsencrypt/live/seu-dominio.com/privkey.pem infra/ssl/key.pem"
    echo ""
    
    # Se tiver SSH configurado, pode fazer deploy automático
    if [ ! -z "$VPS_HOST" ]; then
        echo "🔄 Quer fazer deploy automático via SSH? (yes/no)"
        read -p "> " AUTO_DEPLOY
        
        if [ "$AUTO_DEPLOY" = "yes" ]; then
            echo "📤 Fazendo deploy..."
            
            # Fazer backup do .env
            ssh $VPS_HOST "cd ~/pc-praxis && cp .env .env.backup"
            
            # Sync arquivos
            rsync -avz --exclude 'node_modules' --exclude '.git' \
                . $VPS_HOST:~/pc-praxis/
            
            # Deploy no VPS
            ssh $VPS_HOST << 'SSHEOF'
cd ~/pc-praxis
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml exec backend npx prisma migrate deploy
echo "✅ Deploy concluído!"
SSHEOF
        fi
    fi
fi

echo ""
echo -e "${GREEN}✨ Deploy finalizado!${NC}"
echo ""
echo "🏷️  Tag de restauração: v1.0-production-ready"

# Criar tag se for produção
if [ "$ENV" = "production" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    git tag -a "v1.0-prod-$TIMESTAMP" -m "Production release $TIMESTAMP"
    echo "Tag criada: v1.0-prod-$TIMESTAMP"
fi
