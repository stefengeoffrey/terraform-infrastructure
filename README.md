# terraform-infrastructure

1) Download terragrunt binary
2) Add role to .account.hcl to run terragrunt
3) Download devops-terraform-infrastructure repo
4) Run terragrunt init/plan/apply in demo/use1/network/vpc directory
5) Run terragrunt init/plan/apply in demo/use1/services/eks directory
6) Run terragrunt init/plan/apply in demo/use1/services/argocd directory
7) Run kubectl port-forward svc/argo-cd-argocd-server 8080:443
8) user is admin
9) run to obtain password: kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
10) Download repo argocd-k8-applications repo and run github action pipeline
11) run following: kubectl apply -f argocd-helloworld.yaml -n argocd
