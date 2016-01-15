# koalamon Environment Setup

Coded in [Terraform](https://terraform.io/)

![Terraform Graph](graph.png)

## Basic Usage

To provide config variables either write them into a file `terraform.tfvars` or pass them via CLI:


    terraform plan \
        -var app_name=koalamon \
        -var app_env=stage
        
        
Use `terraform plan` to see all computed actions, `terraform apply` to change resources, and `terraform destroy` to delete everything.
Bonus: `terraform graph | dot -Tpng > graph.png`

## Environments

Most settings are hard-coded. To create several identical environments the variable `app_env` should be used in all resource ids.

To manage multiple environments it is advisable to use different terraform state files, e.g.:

    terraform plan \
        -var app_env=stage \
        -var app_name=koalamon \
        -var-file="stage.tfvars" \
        -state=stage.tfstate \
        -out=stage.plan
        
    terraform plan \
        -var app_env=prod \
        -var app_name=koalamon \
        -var-file="production.tfvars" \
        -state=prod.tfstate \
        -out=prod.plan

    terraform apply \
        -state=stage.tfstate \
        stage.plan
        
    terraform apply \
        -state=prod.tfstate \
        prod.plan

## Codeship

Codeship does not provide an API, so all projects are set up manually.
All of them use two branches: `master` to deploy on stage and
`prod` to deploy to the production environment.

### additional Heroku config

We are also using custom deployment scripts to scale Heroku dynos;
those will require the HEROKU_API_KEY environment variable.

Example for the api:

    gem install heroku
    heroku ps:scale web=1 worker=1 --app koalamon-stage

## Encryption / Decryption state files

The encryption / decryption for prod.tfstate and stage.tfstate
