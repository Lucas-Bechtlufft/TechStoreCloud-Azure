# Arquitetura - TechStore Cloud (Azure)

## Visao geral

O fluxo e direto: o usuario abre o site estatico que fica numa conta de armazenamento
(Blob Storage), o navegador chama a API REST por HTTPS, a API roda numa maquina virtual
Linux e le/grava os produtos no Azure Database for PostgreSQL. Os logs da API vao para o
Log Analytics, onde da pra consultar sem precisar entrar na VM.

```
[Usuario / navegador]
        |  HTTPS
        v
[Conta de armazenamento - site estatico (Blob Storage)]
        |  HTTPS (fetch)
        v
[VM Ubuntu ARM64 - Caddy (TLS) -> API .NET 6 (porta 5000, so interna)]
        |                          \
        | SSL                       \ Syslog (Azure Monitor Agent)
        v                            v
[Azure Database for PostgreSQL]   [Log Analytics (log-techstore)]
```

O diagrama com os icones da Azure esta em `docs/diagrama-arquitetura.png` e tambem no PDF
da entrega.

![Diagrama de arquitetura](diagrama-arquitetura.png)

Todos os recursos ficam no grupo `rg-techstore`, na regiao Canada Central.

## Por que cada servico

**Blob Storage (site estatico)** - o frontend e so HTML e JavaScript, sem codigo de servidor,
entao nao faz sentido gastar uma VM com isso. O recurso de site estatico da conta de
armazenamento serve os arquivos direto, com HTTPS, por um custo bem baixo.

**Maquina virtual** - a API precisa do runtime do .NET rodando o tempo todo escutando
requisicao, e o enunciado pede a VM. Usei Ubuntu 22.04 ARM64 (Standard B2pts_v2), porque os
tamanhos x64 pequenos nao estavam liberados pra minha assinatura nessa regiao. A API roda
como servico do systemd, entao reinicia sozinha se cair ou se a VM reiniciar.

**Caddy** - recebe o HTTPS nas portas 80 e 443 e repassa pra API em `localhost:5000`. Ele
emite e renova o certificado sozinho, usando o nome DNS da VM
(`techstore-lucas.canadacentral.cloudapp.azure.com`). Precisei dele porque o navegador
bloqueia um site em HTTPS que chama uma API em HTTP (mixed content).

**Azure Database for PostgreSQL (servidor flexivel)** - banco gerenciado, com backup e
atualizacoes por conta da Azure. Camada Burstable B1ms, 32 GiB. Como o banco ja era
PostgreSQL, o codigo da API nao precisou mudar, so a connection string (que exige SSL).

**Azure Monitor + Log Analytics** - a API escreve no console, o systemd manda isso pro log
do sistema (syslog) e o Azure Monitor Agent leva pro workspace `log-techstore`. A regra de
coleta de dados (`dcr-techstore-syslog`) pega o syslog da VM. A consulta que uso pra ver os
logs da API:

```
Syslog | where ProcessName == "techstore-api" | order by TimeGenerated desc | take 50
```

## Seguranca

- Grupo de seguranca de rede da VM: SSH (22) liberado so pro meu IP; portas 80 e 443 pro
  HTTPS. A porta 5000 da API ficou fechada pra fora (o Caddy fala com ela por dentro da VM).
- Firewall do PostgreSQL: so o IP da VM e o meu IP. Tirei a opcao que liberava qualquer
  servico do Azure.
- Login na VM so por chave SSH, sem senha.
- A conta de armazenamento exige transferencia segura (HTTPS).
- A senha do banco nao esta no codigo nem no repositorio: fica num arquivo so na VM
  (`/etc/techstore-api.env`, permissao 600), lido pelo systemd. O `.gitignore` bloqueia
  chaves e arquivos de segredo.
- O Azure Monitor Agent usa a identidade gerenciada da VM, entao nao ha credencial de
  monitoramento guardada em lugar nenhum.

## Custos

Tudo roda na conta gratuita da Azure (credito inicial), com tamanhos pequenos: VM B2pts_v2,
PostgreSQL B1ms, armazenamento LRS. Nao atualizei a conta pra pagamento conforme o uso.

## O que ficou de fora do MVP

- Autenticacao na API (hoje o cadastro e aberto); o proximo passo seria JWT ou Entra ID.
- Banco em rede privada (VNet), sem endereco publico.
- Segredos no Azure Key Vault em vez do arquivo na VM.
- Escalabilidade: uma VM so; em producao seria VM Scale Set atras de um balanceador.
- Pipeline de deploy automatico (GitHub Actions).
