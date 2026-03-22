# Runbook Técnico - Esteira DevOps NexaDesk

## 📌 Arquitetura e Stack
* **Aplicação:** Node.js (API simples com Express)
* **Repositório de Código:** GitHub
* **Repositório de Artefatos:** GitHub Container Registry (GHCR) para armazenamento de imagens Docker
* **CI (Continuous Integration):** GitHub Actions
* **CD (Continuous Deployment):** Argo CD (GitOps, monitorando o repositório por mudanças)
* **Orquestrador de Containers:** Kubernetes Local (KinD)

---

## ✅ Checklist de Deploy

### 1. Desenvolvimento
- [ ] Criar branch a partir da `main`.
- [ ] Implementar as mudanças e testar localmente.
- [ ] Commitar as alterações e realizar PR para staging.
- [ ] Realizar testes em ambiente de homologação.
- [ ] Realizar PR de sua branch de desenvolimento para main.

### 2. Pipeline de CI (GitHub Actions)
- [ ] O push na branch principal disparou o workflow do GitHub Actions?
- [ ] A imagem Docker foi construída (build) com sucesso?
- [ ] A imagem foi assinada pelo *cosign* e enviada (push) ao GHCR?
- [ ] A pipeline atualizou o arquivo de ambiente (`kustomization.yaml`) inserindo a nova tag baseada no *Commit SHA*?
- [ ] O Pull Request (ou push direto) com a nova tag foi criado com sucesso e mesclado?

### 3. Pipeline de CD (Argo CD)
- [ ] O Argo CD detectou a alteração no repositório (arquivos na pasta `k8s`)?
- [ ] A sincronização automática do Argo CD iniciou?
- [ ] O status do app no painel do Argo CD encontra-se como `Synced` e `Healthy`?
- [ ] O Kubernetes finalizou os pods antigos e os novos pods estão em status `Running`?

---

## 🚨 Resposta a Incidentes (Troubleshooting)

### Cenário 1: Pipeline do GitHub Actions falhou
**Possíveis Causas:** Falha no build da aplicação (erro no código), erro de autenticação no GHCR, ou permissões insuficientes do token do Actions para criar PRs ou commitar.
**Ações:**
1. Acesse a aba **Actions** no repositório do GitHub.
2. Identifique e clique no step que apresentou falha (🔴) para ler o log de erros.
3. Confirme no arquivo `.github/workflows/docker-publish.yml` se as permissões (`permissions`) contemplam a falha reportada (ex: `pull-requests: write`, `contents: write`).

### Cenário 2: App fora de Sync no Argo CD / Imagem não Atualiza
**Possíveis Causas:** Argo CD com *polling* atrasado ou erro no manifesto gerado pelo Kustomize.
**Ações:**
1. Verifique se o commit de CI realmente atualizou a tag no arquivo `kustomization.yaml` correto.
2. Acesse o painel do Argo CD: `https://localhost:8080`.
3. Na aplicação alvo, clique em **Refresh** para forçar a busca no repositório e **Sync** para aplicar forçadamente no cluster.
4. Se falhar com `ImagePullBackOff` ou `ErrImagePull`, a imagem no GHCR pode estar privada e o cluster não tem credencial (`imagePullSecrets`), ou a tag da imagem fornecida não existe.

### Cenário 3: Pods quebrando em loop (`CrashLoopBackOff`)
**Possíveis Causas:** Erro fatal no código da API Node.js (ex: porta já em uso, erro de dependência, erro de sintaxe) na nova versão implantada.
**Ações:**
1. Obtenha os logs da aplicação quebrando no cluster para identificar o erro:
   ```bash
   kubectl logs deployment/api-express-deployment -n default --tail 50
   ```
2. Analise a Stack Trace (erro do Express ou NPM).
3. **Contenção Imediata (Rollback):** Acesse a interface do Argo CD, selecione a aplicação, clique na opção **History and Rollback**, selecione o deploy funcional anterior e confirme. A versão anterior da API voltará a funcionar instantaneamente até que o time de desenvolvimento aplique a correção do código.