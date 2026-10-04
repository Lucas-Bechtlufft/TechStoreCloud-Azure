-- schema do banco de produtos
-- roda no Azure Database for PostgreSQL (servidor flexivel), dentro do banco techstoredb
-- (o banco precisa ser criado antes: CREATE DATABASE techstoredb;)

CREATE TABLE IF NOT EXISTS "Products" (
    "Id" SERIAL PRIMARY KEY,
    "Name" VARCHAR(200) NOT NULL,
    "Description" VARCHAR(500),
    "Price" NUMERIC(10,2) NOT NULL DEFAULT 0,
    "StockQuantity" INTEGER NOT NULL DEFAULT 0,
    "CreatedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

-- uns produtos de teste pra demo nao subir com a tabela vazia
INSERT INTO "Products" ("Name", "Description", "Price", "StockQuantity") VALUES
('Teclado mecanico', 'Switch azul, ABNT2', 349.90, 15),
('Mouse sem fio', 'Bateria dura uns 3 meses', 89.90, 40),
('Monitor 24 polegadas', 'Full HD, 75hz', 799.00, 8);
