# Terraform criando VM (IaaS) na Azure e instalando Apache

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

Acessar o Apache pelo navegador com o endereço obtido ao final da execução do Terraform