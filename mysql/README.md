# Terraform criando VM (IaaS) na Azure e instalando MySQL

Pré-requisitos

- az cli instalado e configurado com a conta Azure
- Terraform instalado

Logar no Azure via az cli, o navegador será aberto para que o login seja feito

```sh
az login
```

Inicializar o Terraform

```sh
terraform init
```

Executar o Terraform

```sh
terraform apply -auto-approve
```

Acessar o MySQL com o comando abaixo, informando a senha "teste"

```sh
mysql -h [ip criado] -u teste -p
```