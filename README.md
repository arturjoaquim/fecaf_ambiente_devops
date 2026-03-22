# fecaf_ambiente_devops

## Aplicação

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

### Setup do Cluster

1. Crie o cluster Kubernetes (Kind)
   Abra o seu terminal (precisa ter o Docker rodando na máquina) e digite:

````Bash
kind create cluster --name nexadesk-lab --config ./infra/kind-config.yaml 
````

O Kind vai baixar a imagem do "nó" do Kubernetes e iniciar o seu cluster local.

2. Crie o espaço para o Argo CD
   No Kubernetes, separamos as coisas em "Namespaces" (como se fossem pastas virtuais). Vamos criar uma para o Argo CD:
```Bash
kubectl create namespace argocd
```
3. Instale o Argo CD
   Agora, você passa para o Kubernetes (usando o kubectl) o link oficial dos manifestos do Argo CD. O "Maestro" vai ler o arquivo lá do GitHub deles e instalar todos os componentes:
````Bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
````
Dê um minuto ou dois para que todos os containers do Argo CD sejam baixados e iniciados.

4. Descubra a senha de administrador
   Por segurança, o Argo CD gera uma senha inicial aleatória. Para visualizá-la no terminal, rode:
```Bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Copie essa senha, pois o usuário padrão é admin.

5. Acesse o painel pelo seu navegador
   Como o Argo CD está rodando escondido dentro do cluster, você precisa abrir uma "ponte" entre a sua máquina e ele:
````Bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
````
Pronto! Agora é só abrir o seu navegador, acessar https://localhost:8080 (ignore o aviso de certificado SSL, pois é um ambiente local), fazer login com o usuário admin e a senha que você copiou no passo 4. O Argo CD estará rodando limpo e pronto para observar o seu repositório.

## Observabilidade