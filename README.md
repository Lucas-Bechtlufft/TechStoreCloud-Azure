# TechStore Cloud (Azure) - MVP Cadastro de Produtos

MVP do sistema de cadastro de produtos em microsservicos, feito pra disciplina de
Cloud Computing, rodando na Microsoft Azure. API em .NET 6, banco PostgreSQL gerenciado,
frontend estatico e monitoramento com Azure Monitor.

- Frontend: https://techstorelucas2026.z9.web.core.windows.net/
- API (documentação): https://techstore-lucas.canadacentral.cloudapp.azure.com/swagger

## Estrutura

```
src/ProductApi/        -> API REST (.NET 6, EF Core, Npgsql)
frontend/              -> site estatico (vai pro Blob Storage)
database/schema.sql    -> criacao da tabela e dados de teste
deploy/                -> arquivo de servico (systemd) usado na VM
docs/                  -> documento de arquitetura e diagrama
```

## Como montei na Azure

Tudo no mesmo grupo de recursos (`rg-techstore`), regiao Canada Central.

1. **Banco**: Azure Database for PostgreSQL (servidor flexivel), camada Burstable B1ms,
   32 GiB, acesso publico com firewall. Criei o banco `techstoredb` e rodei o
   `database/schema.sql` nele usando o `psql` de dentro da VM (a conexao exige SSL).

2. **VM**: Ubuntu Server 22.04 (ARM64), tamanho Standard B2pts_v2, login por chave SSH.
   No grupo de seguranca de rede deixei SSH (22) restrito ao meu IP e as portas 80 e 443
   pro HTTPS. Criei um arquivo de swap de 2 GB porque a VM tem 1 GiB de RAM.

3. **API na VM**: instalei o `dotnet-sdk-6.0`, clonei o repositorio, publiquei com
   `dotnet publish -c Release -o ~/publish` e configurei como servico do systemd
   (`deploy/techstore-api.service`), com reinicio automatico.

   A connection string real **nao fica no repositorio**. Ela fica num arquivo so na VM
   (`/etc/techstore-api.env`), lido pelo systemd:

   ```
   ConnectionStrings__DefaultConnection=Host=<servidor>.postgres.database.azure.com;Port=5432;Database=techstoredb;Username=pgadmin;Password=<senha>;SSL Mode=Require;Trust Server Certificate=true
   ```

   O ASP.NET Core ja sobrescreve o valor do `appsettings.json` com essa variavel, entao
   o codigo nao muda. O `appsettings.json` do repo tem so um placeholder de `localhost`.

4. **HTTPS**: coloquei o Caddy na frente da API. Ele recebe 80/443, emite o certificado
   sozinho pro nome DNS da VM e repassa pra `localhost:5000`. Depois disso fechei a porta
   5000 no grupo de seguranca de rede.

5. **Frontend**: o `frontend/index.html` e um site estatico simples que chama a API.
   Fica no contêiner `$web` de uma conta de armazenamento com o recurso de site estatico
   habilitado.

6. **Monitoramento**: criei um workspace do Log Analytics (`log-techstore`) e uma regra de
   coleta de dados (`dcr-techstore-syslog`) associada a VM, que instala o Azure Monitor
   Agent. A regra coleta o syslog (LOG_DAEMON, nivel Info). Pra ver os logs da API:

   ```
   Syslog | where ProcessName == "techstore-api" | order by TimeGenerated desc | take 50
   ```

## Rodando localmente

```
cd src/ProductApi
dotnet restore
dotnet run
```

(precisa de um PostgreSQL local com o banco `techstoredb`; a connection string de exemplo
esta no `appsettings.json`)

## Endpoints

- `GET /health`
- `GET /api/products`
- `GET /api/products/{id}`
- `POST /api/products`
- `PUT /api/products/{id}`
- `DELETE /api/products/{id}`
- `GET /swagger` (documentacao interativa)
