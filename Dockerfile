# Estágio de build
FROM node:20-alpine AS builder

# Instala dependências do sistema
RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash tzdata dos2unix

# Define variáveis de ambiente
ENV TZ=America/Sao_Paulo

# Define metadados da imagem
LABEL version="2.2.0" description="Api to control whatsapp features through http requests."
LABEL maintainer="Davidson Gomes" git="https://github.com/DavidsonGomes"
LABEL contact="contato@atendai.com"

# Define o diretório de trabalho
WORKDIR /evolution

# Copia arquivos de configuração e dependências
COPY package.json tsconfig.json ./

# Instala as dependências do projeto com flags para resolver conflitos
RUN npm install --legacy-peer-deps

# Copia o código fonte e outros arquivos necessários
COPY ./src ./src
COPY ./public ./public
COPY ./prisma ./prisma
COPY ./manager ./manager
COPY ./.env.example ./.env
COPY ./runWithProvider.js ./
COPY ./tsup.config.ts ./
COPY ./Docker ./Docker

# Configura scripts e permissões
RUN chmod +x ./Docker/scripts/* && \
    dos2unix ./Docker/scripts/*

# Executa o script de geração do banco de dados
RUN ./Docker/scripts/generate_database.sh

# Compila o projeto
RUN npm run build

# Estágio final (imagem leve)
FROM node:20-alpine AS final

# Instala dependências do sistema
RUN apk update && \
    apk add --no-cache tzdata ffmpeg bash dos2unix

# Define variáveis de ambiente
ENV TZ=America/Sao_Paulo
ENV DOCKER_ENV=true

# Define o diretório de trabalho
WORKDIR /evolution

# Copia apenas os arquivos necessários do estágio de build
COPY --from=builder /evolution/package.json ./package.json
COPY --from=builder /evolution/package-lock.json ./package-lock.json
COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/prisma ./prisma
COPY --from=builder /evolution/manager ./manager
COPY --from=builder /evolution/public ./public
COPY --from=builder /evolution/.env ./.env
COPY --from=builder /evolution/Docker ./Docker
COPY --from=builder /evolution/runWithProvider.js ./runWithProvider.js
COPY --from=builder /evolution/tsup.config.ts ./tsup.config.ts

# Expõe a porta da aplicação
EXPOSE 8080

# Define o comando de entrada
ENTRYPOINT ["/bin/bash", "-c", ". ./Docker/scripts/deploy_database.sh && npm run start:prod"]
