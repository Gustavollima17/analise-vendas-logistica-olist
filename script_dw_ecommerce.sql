-- ============================================================================
-- PROJETO: Análise de Vendas e Performance Logística — E-commerce (Olist)
-- AUTOR: Gustavo Lima Mendes
-- FERRAMENTA: PostgreSQL 18
-- ============================================================================

-- ============================================================================
-- ETAPA 1: CRIAÇÃO DAS TABELAS DE STAGING (DADOS BRUTOS)
-- ============================================================================

CREATE TABLE stg_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE stg_order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2)
);

CREATE TABLE stg_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE stg_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

-- ============================================================================
-- ETAPA 2: MODELAGEM DIMENSIONAL (STAR SCHEMA) E TRATAMENTO DE DADOS
-- ============================================================================

-- 1. Dimensão Clientes
CREATE TABLE dim_clientes AS
SELECT DISTINCT
    customer_id,
    INITCAP(customer_city) AS cidade,
    UPPER(customer_state) AS estado
FROM stg_customers;

ALTER TABLE dim_clientes ADD PRIMARY KEY (customer_id);

-- 2. Dimensão Produtos (tratando categorias vazias e formatando texto)
CREATE TABLE dim_produtos AS
SELECT DISTINCT
    product_id,
    COALESCE(INITCAP(REPLACE(product_category_name, '_', ' ')), 'Sem Categoria') AS categoria
FROM stg_products;

ALTER TABLE dim_produtos ADD PRIMARY KEY (product_id);

-- 3. Dimensão Calendário (baseada no período dos pedidos)
CREATE TABLE dim_calendario AS
SELECT DISTINCT
    DATE(order_purchase_timestamp) AS data_pedido,
    EXTRACT(YEAR FROM order_purchase_timestamp) AS ano,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS mes_num,
    TO_CHAR(order_purchase_timestamp, 'TMMonth') AS mes_nome,
    EXTRACT(QUARTER FROM order_purchase_timestamp) AS trimestre
FROM stg_orders
WHERE order_purchase_timestamp IS NOT NULL;

ALTER TABLE dim_calendario ADD PRIMARY KEY (data_pedido);

-- 4. Tabela Fato Vendas (unindo pedidos e itens + métricas logísticas)
CREATE TABLE fato_vendas AS
SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    DATE(o.order_purchase_timestamp) AS data_pedido,
    o.order_status AS status_pedido,
    oi.price AS valor_produto,
    oi.freight_value AS valor_frete,
    (oi.price + oi.freight_value) AS valor_total,
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) AS dias_entrega_real,
    CASE 
        WHEN o.order_delivered_customer_date IS NULL THEN 'Não Entregue'
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Atrasado'
        ELSE 'No Prazo'
    END AS status_entrega
FROM stg_order_items oi
INNER JOIN stg_orders o ON oi.order_id = o.order_id;

-- ============================================================================
-- ETAPA 3: VIEWS ANALÍTICAS PARA CONSULTAS DE NEGÓCIO
-- ============================================================================

-- View 1: Resumo Mensal de Vendas e Ticket Médio
CREATE VIEW vw_resumo_mensal AS
SELECT
    c.ano,
    c.mes_num,
    c.mes_nome,
    COUNT(DISTINCT f.order_id) AS total_pedidos,
    SUM(f.valor_produto) AS faturamento_produtos,
    ROUND(SUM(f.valor_produto) / COUNT(DISTINCT f.order_id), 2) AS ticket_medio
FROM fato_vendas f
JOIN dim_calendario c ON f.data_pedido = c.data_pedido
WHERE f.status_pedido = 'delivered'
GROUP BY c.ano, c.mes_num, c.mes_nome
ORDER BY c.ano, c.mes_num;

-- View 2: Ranking Top 10 Categorias (Window Function)
CREATE VIEW vw_top_categorias AS
SELECT
    p.categoria,
    COUNT(DISTINCT f.order_id) AS qtd_pedidos,
    SUM(f.valor_produto) AS receita_total,
    RANK() OVER (ORDER BY SUM(f.valor_produto) DESC) AS ranking
FROM fato_vendas f
JOIN dim_produtos p ON f.product_id = p.product_id
WHERE f.status_pedido = 'delivered'
GROUP BY p.categoria;

-- View 3: Performance Logística por Estado
CREATE VIEW vw_logistica_estados AS
SELECT
    cli.estado,
    COUNT(DISTINCT f.order_id) AS total_entregas,
    ROUND(AVG(f.dias_entrega_real), 1) AS media_dias_entrega,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN f.status_entrega = 'Atrasado' THEN f.order_id END) 
        / COUNT(DISTINCT f.order_id), 2
    ) AS percentual_atraso
FROM fato_vendas f
JOIN dim_clientes cli ON f.customer_id = cli.customer_id
WHERE f.status_pedido = 'delivered' AND f.dias_entrega_real IS NOT NULL
GROUP BY cli.estado
ORDER BY percentual_atraso DESC;