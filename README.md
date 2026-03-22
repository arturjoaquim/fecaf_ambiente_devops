# fecaf_ambiente_devops

## Aplicação

````Bash
kubectl port-forward svc/prod-api-express-service -n default 4200:80
````

## Continuos Integration

## Cluster Kubernets

Instalação do kubernets
````Bash
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
````

Instalação do kind
````Bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv kind /usr/local/bin/
````

### Criação do Cluster Kubernets

1. Crie o cluster Kubernetes (Kind)
   Abra o seu terminal (precisa ter o Docker rodando na máquina) e digite:

````Bash
kind create cluster --name nexadesk-lab --config ./infra/kind-config.yaml 
````

O Kind vai baixar a imagem do "nó" do Kubernetes e iniciar o seu cluster local.

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
Pronto! Agora é só abrir o seu navegador, acessar https://localhost:8080 (ignore o aviso de certificado SSL, pois é um ambiente local), fazer login com o usuário admin e a senha que você copiou no passo 3. O Argo CD estará rodando limpo e pronto para observar o seu repositório.

## Observabilidade