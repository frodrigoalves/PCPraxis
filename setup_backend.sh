#!/bin/bash
# ============================================================================
# PC PRAXIS - Setup Backend (NestJS + Prisma)
# Fase 1: Backend Core - Auth, Users, Database
# ============================================================================

set -e

echo "🔧 Configurando Backend NestJS..."

cd backend

# Criar projeto NestJS
npx @nestjs/cli new . --package-manager npm --skip-git

# Instalar dependências core
npm install --save \
  @nestjs/config \
  @nestjs/jwt \
  @nestjs/passport \
  @nestjs/swagger \
  @prisma/client \
  passport \
  passport-jwt \
  passport-local \
  bcrypt \
  class-validator \
  class-transformer \
  helmet \
  compression

npm install --save-dev \
  @types/passport-jwt \
  @types/passport-local \
  @types/bcrypt \
  prisma

# Inicializar Prisma
npx prisma init

# Criar schema Prisma
cat > prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Company {
  id        String   @id @default(uuid())
  slug      String   @unique
  name      String
  ownerName String   @map("owner_name")
  email     String
  country   String   @default("AT")
  locale    String   @default("de-AT")
  currency  String   @default("EUR")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  users            User[]
  products         Product[]
  services         Service[]
  orders           Order[]
  serviceTickets   ServiceTicket[]

  @@map("companies")
}

model User {
  id            String    @id @default(uuid())
  companyId     String?   @map("company_id")
  email         String    @unique
  password      String
  name          String
  role          UserRole  @default(CUSTOMER)
  isActive      Boolean   @default(true) @map("is_active")
  lastLoginAt   DateTime? @map("last_login_at")
  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @updatedAt @map("updated_at")

  company       Company?  @relation(fields: [companyId], references: [id])
  orders        Order[]
  serviceTickets ServiceTicket[]
  sessions      Session[]
  consents      Consent[]

  @@map("users")
}

enum UserRole {
  SUPER_ADMIN
  ADMIN
  CUSTOMER
}

model Session {
  id           String   @id @default(uuid())
  userId       String   @map("user_id")
  refreshToken String   @unique @map("refresh_token")
  expiresAt    DateTime @map("expires_at")
  createdAt    DateTime @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("sessions")
}

model Visitor {
  id          String   @id @default(uuid())
  ipHash      String   @map("ip_hash")
  userAgent   String   @map("user_agent")
  firstSeenAt DateTime @default(now()) @map("first_seen_at")
  lastSeenAt  DateTime @updatedAt @map("last_seen_at")

  events   Event[]
  consents Consent[]

  @@index([ipHash])
  @@map("visitors")
}

model Event {
  id         String   @id @default(uuid())
  visitorId  String?  @map("visitor_id")
  userId     String?  @map("user_id")
  type       String
  url        String?
  referrer   String?
  utmSource  String?  @map("utm_source")
  utmMedium  String?  @map("utm_medium")
  utmCampaign String? @map("utm_campaign")
  metadata   Json?
  createdAt  DateTime @default(now()) @map("created_at")

  visitor Visitor? @relation(fields: [visitorId], references: [id])

  @@index([type, createdAt])
  @@index([visitorId])
  @@map("events")
}

model Consent {
  id        String      @id @default(uuid())
  visitorId String?     @map("visitor_id")
  userId    String?     @map("user_id")
  category  ConsentType
  version   String
  granted   Boolean
  createdAt DateTime    @default(now()) @map("created_at")

  visitor Visitor? @relation(fields: [visitorId], references: [id])
  user    User?    @relation(fields: [userId], references: [id])

  @@map("consents")
}

enum ConsentType {
  ESSENTIAL
  ANALYTICS
  MARKETING
}

model ProductCategory {
  id        String    @id @default(uuid())
  name      String
  slug      String    @unique
  sortOrder Int       @default(0) @map("sort_order")
  isActive  Boolean   @default(true) @map("is_active")
  createdAt DateTime  @default(now()) @map("created_at")
  updatedAt DateTime  @updatedAt @map("updated_at")

  products Product[]

  @@map("product_categories")
}

model Product {
  id               String          @id @default(uuid())
  companyId        String          @map("company_id")
  categoryId       String?         @map("category_id")
  sku              String          @unique
  name             String
  shortDescription String          @map("short_description")
  fullDescription  String?         @map("full_description")
  basePrice        Decimal         @map("base_price") @db.Decimal(10, 2)
  stockQuantity    Int             @default(0) @map("stock_quantity")
  status           ProductStatus   @default(DRAFT)
  isFeatured       Boolean         @default(false) @map("is_featured")
  isConfigurable   Boolean         @default(false) @map("is_configurable")
  mainImageUrl     String?         @map("main_image_url")
  gallery          Json?
  createdAt        DateTime        @default(now()) @map("created_at")
  updatedAt        DateTime        @updatedAt @map("updated_at")

  company      Company         @relation(fields: [companyId], references: [id])
  category     ProductCategory? @relation(fields: [categoryId], references: [id])
  orderItems   OrderItem[]
  components   ConfigComponent[]

  @@map("products")
}

enum ProductStatus {
  DRAFT
  ACTIVE
  ARCHIVED
}

model ServiceCategory {
  id        String   @id @default(uuid())
  name      String
  sortOrder Int      @default(0) @map("sort_order")
  isActive  Boolean  @default(true) @map("is_active")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  services Service[]

  @@map("service_categories")
}

model Service {
  id               String          @id @default(uuid())
  companyId        String          @map("company_id")
  categoryId       String?         @map("category_id")
  slug             String          @unique
  title            String
  shortDescription String          @map("short_description")
  fullDescription  String?         @map("full_description")
  icon             String?
  startingPrice    Decimal?        @map("starting_price") @db.Decimal(10, 2)
  isHighlighted    Boolean         @default(false) @map("is_highlighted")
  isActive         Boolean         @default(true) @map("is_active")
  sortOrder        Int             @default(0) @map("sort_order")
  createdAt        DateTime        @default(now()) @map("created_at")
  updatedAt        DateTime        @updatedAt @map("updated_at")

  company        Company         @relation(fields: [companyId], references: [id])
  category       ServiceCategory? @relation(fields: [categoryId], references: [id])
  serviceTickets ServiceTicket[]

  @@map("services")
}

model Order {
  id             String      @id @default(uuid())
  protocol       String      @unique
  companyId      String      @map("company_id")
  customerId     String      @map("customer_id")
  status         OrderStatus @default(PENDING)
  subtotal       Decimal     @db.Decimal(10, 2)
  shippingCost   Decimal     @default(0) @map("shipping_cost") @db.Decimal(10, 2)
  taxAmount      Decimal     @default(0) @map("tax_amount") @db.Decimal(10, 2)
  discountAmount Decimal     @default(0) @map("discount_amount") @db.Decimal(10, 2)
  total          Decimal     @db.Decimal(10, 2)
  shippingAddress Json?      @map("shipping_address")
  trackingCode   String?     @map("tracking_code")
  createdAt      DateTime    @default(now()) @map("created_at")
  updatedAt      DateTime    @updatedAt @map("updated_at")
  paidAt         DateTime?   @map("paid_at")
  shippedAt      DateTime?   @map("shipped_at")
  deliveredAt    DateTime?   @map("delivered_at")

  company Company     @relation(fields: [companyId], references: [id])
  customer User       @relation(fields: [customerId], references: [id])
  items    OrderItem[]

  @@map("orders")
}

enum OrderStatus {
  PENDING
  PAID
  IN_PREPARATION
  SHIPPED
  DELIVERED
  CANCELLED
}

model OrderItem {
  id        String  @id @default(uuid())
  orderId   String  @map("order_id")
  productId String  @map("product_id")
  quantity  Int
  unitPrice Decimal @map("unit_price") @db.Decimal(10, 2)
  subtotal  Decimal @db.Decimal(10, 2)

  order   Order   @relation(fields: [orderId], references: [id], onDelete: Cascade)
  product Product @relation(fields: [productId], references: [id])

  @@map("order_items")
}

model ServiceTicket {
  id            String        @id @default(uuid())
  protocol      String        @unique
  companyId     String        @map("company_id")
  customerId    String        @map("customer_id")
  serviceId     String?       @map("service_id")
  status        TicketStatus  @default(OPENED)
  priority      TicketPriority @default(NORMAL)
  equipmentInfo String?       @map("equipment_info")
  symptoms      String
  diagnosis     String?
  solution      String?
  createdAt     DateTime      @default(now()) @map("created_at")
  updatedAt     DateTime      @updatedAt @map("updated_at")
  closedAt      DateTime?     @map("closed_at")

  company  Company  @relation(fields: [companyId], references: [id])
  customer User     @relation(fields: [customerId], references: [id])
  service  Service? @relation(fields: [serviceId], references: [id])

  @@map("service_tickets")
}

enum TicketStatus {
  OPENED
  DIAGNOSING
  WAITING_CUSTOMER
  IN_REPAIR
  READY
  CLOSED
  CANCELLED
}

enum TicketPriority {
  LOW
  NORMAL
  HIGH
  URGENT
}

model ConfigComponentType {
  id         String   @id @default(uuid())
  code       String   @unique
  name       String
  sortOrder  Int      @default(0) @map("sort_order")
  isRequired Boolean  @default(false) @map("is_required")
  createdAt  DateTime @default(now()) @map("created_at")
  updatedAt  DateTime @updatedAt @map("updated_at")

  components ConfigComponent[]

  @@map("config_component_types")
}

model ConfigComponent {
  id                String              @id @default(uuid())
  typeId            String              @map("type_id")
  productId         String?             @map("product_id")
  name              String
  brand             String?
  model             String?
  specs             Json?
  price             Decimal             @db.Decimal(10, 2)
  stockQuantity     Int                 @default(0) @map("stock_quantity")
  compatibilityTags Json?               @map("compatibility_tags")
  isActive          Boolean             @default(true) @map("is_active")
  createdAt         DateTime            @default(now()) @map("created_at")
  updatedAt         DateTime            @updatedAt @map("updated_at")

  type    ConfigComponentType @relation(fields: [typeId], references: [id])
  product Product?            @relation(fields: [productId], references: [id])

  @@map("config_components")
}
EOF

# Gerar client Prisma
npx prisma generate

# Criar estrutura de módulos
mkdir -p src/{auth,users,catalog,configurator,orders,service-tickets,tracking,leads,common}

# Criar módulo de configuração
cat > src/common/config.service.ts << 'EOF'
import { Injectable } from '@nestjs/common';
import { ConfigService as NestConfigService } from '@nestjs/config';

@Injectable()
export class AppConfigService {
  constructor(private configService: NestConfigService) {}

  get nodeEnv(): string {
    return this.configService.get<string>('NODE_ENV', 'development');
  }

  get port(): number {
    return this.configService.get<number>('PORT', 4000);
  }

  get databaseUrl(): string {
    return this.configService.getOrThrow<string>('DATABASE_URL');
  }

  get jwtSecret(): string {
    return this.configService.getOrThrow<string>('JWT_SECRET');
  }

  get hashSaltRotation(): string {
    return this.configService.get<string>('HASH_SALT_ROTATION', 'daily');
  }

  get isDevelopment(): boolean {
    return this.nodeEnv === 'development';
  }

  get isProduction(): boolean {
    return this.nodeEnv === 'production';
  }
}
EOF

# Criar Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

COPY . .

RUN npx prisma generate
RUN npm run build

FROM node:20-alpine AS runtime

WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/package*.json ./

EXPOSE 4000

CMD ["npm", "run", "start:prod"]
EOF

# Criar .dockerignore
cat > .dockerignore << 'EOF'
node_modules
dist
.env
.git
.gitignore
README.md
npm-debug.log
EOF

# Atualizar main.ts
cat > src/main.ts << 'EOF'
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security
  app.use(helmet());
  app.use(compression());

  // CORS
  app.enableCors({
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    credentials: true,
  });

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Swagger
  const config = new DocumentBuilder()
    .setTitle('PC Praxis API')
    .setDescription('API para plataforma PC Praxis')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // Global prefix
  app.setGlobalPrefix('api');

  const port = process.env.PORT || 4000;
  await app.listen(port);

  console.log(`🚀 Backend rodando em: http://localhost:${port}`);
  console.log(`📚 Swagger docs: http://localhost:${port}/api/docs`);
}

bootstrap();
EOF

echo "✅ Backend configurado!"
echo ""
echo "📋 Próximos passos:"
echo "1. Revise o schema Prisma em backend/prisma/schema.prisma"
echo "2. Execute: cd backend && npx prisma migrate dev --name init"
echo "3. Execute: bash ../03-setup-frontend.sh"
echo ""
echo "🏷️  Tag de restauração: v0.2-backend-core"

cd ..
git add backend/
git commit -m "feat: setup backend NestJS + Prisma - v0.2-backend-core"
git tag v0.2-backend-core

echo "✨ Backend setup concluído!"
