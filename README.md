# 📊 Análise de Vendas e Performance Logística — E-commerce (Olist)

Projeto de Business Intelligence e Análise de Dados desenvolvido de ponta a ponta, desde a ingestão e modelagem dimensional em *PostgreSQL* até a criação de indicadores (DAX) e visualização interativa no *Microsoft Power BI*.

## 🎯 Objetivo do Projeto
Transformar dados transacionais brutos de um e-commerce brasileiro em um modelo analítico estruturado para responder a perguntas estratégicas de negócio:
- Qual é a evolução mensal do faturamento e o ticket médio dos pedidos entregues?
- Quais categorias de produtos concentram a maior parte da receita?
- Qual é o tempo médio de entrega por estado e o percentual de atrasos logísticos?

## 🛠️ Tecnologias Utilizadas
- *Banco de Dados & SQL:* PostgreSQL 18 / pgAdmin 4 (DDL, DML, Joins, Views e Window Functions)
- *Modelagem de Dados:* Arquitetura Dimensional *Star Schema* (Tabela Fato e Dimensões)
- *Visualização de Dados & BI:* Microsoft Power BI Desktop e linguagem *DAX*

## 🗂️ Modelagem Dimensional (Star Schema)
Os dados originais foram tratados na camada de staging e estruturados em um esquema estrela otimizado para consultas analíticas:

![Modelagem Star Schema](https://githubusercontent.com)

## 📈 Dashboards e Principais Insights
- *Faturamento Total:* R$ 13,22 Milhões (considerando pedidos entregues)
- *Volume de Pedidos:* 96.478 pedidos entregues
- *Ticket Médio:* R$ 137,04 por pedido
- *Performance Logística:* Média de *12,0 dias* para entrega, com taxa global de atraso de *8,11%*.

### Visão Geral de Vendas
![Visão Geral](https://githubusercontent.com)

### Performance Logística
![Logística](https://githubusercontent.com)
