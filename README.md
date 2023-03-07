# terraform-infrastructure
1) Download and install terraform and terragrunt
2) Go to the demo->use1->network->vpc directory and run 'terragrunt apply' to deploy vpc
3) Go to the demo->use1->services->eks directory and run 'terragrunt apply' to deploy eks
4) Go the the demo->use1->services->argocd directory and run 'terragrunt apply' to install argocd
5) Bring up Lens and go to the argocd service and ckick on port forward to bring up the Argocd console
  There would be an ingress for this but this is a demo
6) Go to demo->globals and deploy IAM across all folders  
6) Go to Lens and get the Argocd password in secrets
7) Go to the Argocd repo and deploy the Argocd helloworld application yaml file, this would be done in terraform for a production setup but for
   demo's its good to have it seperated so it can be discussed



