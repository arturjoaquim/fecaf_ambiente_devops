# fecaf_ambiente_devops

Este é o repositório base para a infraestrutura e esteira DevOps da NexaDesk, englobando a aplicação, pipeline de CI/CD e configuração do cluster Kubernetes local.

## Tecnologias Utilizadas

- **Aplicação:** Node.js, Express, Swagger (OpenAPI)
- **Containerização:** Docker
- **Orquestração:** Kubernetes (KinD - Kubernetes in Docker)
- **CI (Integração Contínua):** GitHub Actions
- **CD (Entrega Contínua):** Argo CD (Abordagem GitOps)
- **Gerenciamento de Manifestos:** Kustomize
- **Registry de Imagens:** GitHub Container Registry (GHCR)

## Aplicação e Endpoints

A aplicação é uma API REST simples construída em Node.js com Express.

### Endpoints Disponíveis

- `GET /` : Retorna a mensagem de *Hello World* junto com a versão atual da API (baseada no `package.json`).
- `GET /api-docs` : Acesso à interface interativa do Swagger contendo a documentação completa da API.

### Acessando a Aplicação Localmente

Após o deploy realizado com sucesso via Argo CD, você pode expor o serviço do ambiente de produção localmente rodando:

````Bash
kubectl port-forward svc/prod-api-express-service -n default 4200:80
````
A API estará acessível no navegador através de `http://localhost:4200`.

---

## Esteira de CI/CD

A esteira DevOps do projeto foi desenhada utilizando os princípios de GitOps:

### Continuous Integration (CI) - GitHub Actions
A pipeline de CI (`.github/workflows/ci-pipeline.yml`) é acionada a cada push nas branches `main` e `staging`.
1. **Build & Push:** Faz o build da imagem Docker utilizando a pasta `src/` como contexto.
2. **Tagging Seguro:** A imagem recebe como *tag* o **SHA curto do commit**, garantindo uma identificação única e imutável.
3. **Registry:** A imagem é enviada (push) automaticamente para o GitHub Container Registry (GHCR).
4. **GitOps Auto-Update:** O Kustomize é acionado pela pipeline para atualizar dinamicamente o arquivo `kustomization.yaml` (do ambiente dev/staging ou prod, dependendo da branch) com a nova tag da imagem.
5. **Pull Request Automático:** Por fim, a pipeline cria um Pull Request automático apontando para a branch original contendo a alteração dos manifestos do Kubernetes.

### Continuous Deployment (CD) - Argo CD
O Argo CD fica em constante execução dentro do cluster Kubernetes, monitorando o diretório `k8s/` da branch `main`.
Quando o Pull Request gerado pela CI é mesclado (merged), o Argo CD detecta a mudança na *tag* da imagem no manifesto e realiza a sincronização automática (`SelfHeal` e `Prune` ativados), aplicando o *Rolling Update* sem tempo de inatividade (*downtime*).

---

## Cluster Kubernetes

### Pré-requisitos
Instalação do Kubernetes (`kubectl`):
````Bash
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
````

Instalação do KinD (Kubernetes in Docker):
````Bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
sudo mv kind /usr/local/bin/
````

### Criação do Cluster Kubernetes

1. Crie o cluster Kubernetes (KinD)
   Abra o seu terminal (precisa ter o Docker rodando na máquina) e digite:

````Bash
kind create cluster --name nexadesk-lab --config ./infra/kind-config.yaml 
````

O KinD vai baixar a imagem do "nó" do Kubernetes e iniciar o seu cluster local.

### Setup Rápido do Cluster

Para facilitar, você pode criar o cluster e instalar o ArgoCD de forma automática rodando o script de setup. Certifique-se de que o Docker está rodando na sua máquina antes de executar.

A partir da raiz do repositório, execute:

````Bash
chmod +x infra/bootstrap-cluster/setup-cluster.sh
./infra/bootstrap-cluster/setup-cluster.sh
````
O script se encarregará de criar o cluster, aplicar as configurações do ArgoCD via Kustomize, exibir a senha inicial de administrador e abrir o port-forward no final!

### Passo a Passo Manual (Setup do Cluster)

2. Instale o Argo CD e as Configurações via Kustomize
   A partir dos arquivos presentes na infra, aplique o manifesto base que criará o namespace, instalará o ArgoCD (versão stable) e as secrets necessárias:
````Bash
kubectl apply -k ./infra/bootstrap-cluster/
````
Dê um minuto ou dois para que todos os containers do Argo CD sejam baixados e iniciados.

3. Descubra a senha de administrador
   Por segurança, o Argo CD gera uma senha inicial aleatória. Para visualizá-la no terminal, rode:
```Bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Copie essa senha, pois o usuário padrão é admin.

4. Acesse o painel pelo seu navegador
   Como o Argo CD está rodando escondido dentro do cluster, você precisa abrir uma "ponte" entre a sua máquina e ele:
````Bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
````
Pronto! Agora é só abrir o seu navegador, acessar https://localhost:8080 (ignore o aviso de certificado SSL, pois é um ambiente local), fazer login com o usuário `admin` e a senha que você copiou no passo 3. O Argo CD estará rodando limpo e pronto para observar o seu repositório.

---

## Observabilidade

Em nossa stack técnica, utilizamos o próprio **Argo CD** como a primeira camada fundamental de observabilidade e saúde do deploy. 

Através da interface interativa do Argo CD, conseguimos monitorar em tempo real:
- **Status da Aplicação:** Visão clara sobre a integridade da aplicação (`Healthy` / `Degraded`), permitindo identificar se os Pods estão de pé e respondendo corretamente.
- **Sincronização:** Indicativo de paridade entre o estado desejado (declarado no GitHub) e o estado real atual dentro do cluster (`Synced` / `Out of Sync`).
- **Rastreabilidade da Imagem:** É possível inspecionar visualmente os manifestos gerados para descobrir com exatidão **qual versão/tag da imagem Docker** está sendo executada atualmente em produção nos Pods.
- **Árvore de Recursos Kubernetes:** Um mapa visual da topologia de todos os componentes que formam nossa API (Deployments, ReplicaSets, Pods, Services), facilitando o troubleshooting e possibilitando acesso fácil aos logs dos containers.