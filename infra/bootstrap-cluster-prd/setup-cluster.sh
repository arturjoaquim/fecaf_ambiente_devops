#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define cores para os logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Criando namespace para argocd...${NC}"

# 1. Cria o cluster Kubernetes (Kind) usando o arquivo de configuração
kubectl create namespace argocd

echo -e "${GREEN}Namespace criado com sucesso!${NC}"
echo -e "${YELLOW}Instalando argocd...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.0/manifests/install.yaml

echo -e "${YELLOW}Aguardando os pods do ArgoCD iniciarem (isso pode levar alguns minutos)...${NC}"
# Aguarda até que todos os pods do namespace argocd estejam rodando
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# 2. Aplica os manifestos do ArgoCD
kubectl apply -k "$SCRIPT_DIR"

echo -e "${GREEN}Todos os pods do ArgoCD estão rodando!${NC}"
echo -e "${YELLOW}Buscando a senha inicial de administrador...${NC}"

# 3. Descobre a senha de administrador
# Aguarda mais alguns segundos para garantir que a secret foi gerada pelo ArgoCD
sleep 5
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${GREEN}A senha do usuário 'admin' é:${NC}"
echo -e "================================================="
echo -e "${YELLOW}${ARGOCD_PASSWORD}${NC}"
echo -e "================================================="

echo -e "${YELLOW}Iniciando o port-forward para o painel do ArgoCD...${NC}"
echo -e "${GREEN}Acesse o painel em: https://localhost:8080${NC}"
echo -e "${YELLOW}(Pressione Ctrl+C para parar o port-forward e encerrar o script)${NC}"

# 4. Inicia o port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
