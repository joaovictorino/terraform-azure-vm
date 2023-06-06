# Terraform criando VM (IaaS) na Azure

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

Acessar a máquina com o comando abaixo, alterando o IP e depois informar a senha Teste@admin123!

```sh
ssh azureuser@[ip criado]
```