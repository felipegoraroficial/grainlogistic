# Projeto Grain Logistic

Objetivo do projeto é realizar a captura de dados brutos e armazena-los no datalakehouse da Databricks,
Realizando tratativas de dados no modelo de arquitetura medalhão
É necessário a realização de teste e garantir a qualidade dos dados durante a aplicação

Diferenciais serão a construção de um Dashboard simples com Power BI e demonstração de uso de governança de dados com Unity Catalog

## Desenho Técnico

<div align="center">
  <img src="https://github.com/user-attachments/assets/03c4a975-4cfc-4f81-86b4-692572626943" alt="Desenho Técnico">
  <p><b>Desenho Técnico</b></p>
</div>

<p align="left">
</p>

1 - Referenciando diversos modelos de Source conectados a um Event Hub que envia os dados em uma camada denominada Inbound no Data Lake
obs: não precisa necessáriamente ser um recurso Event Hub para essa movimentação de dados

2- Arquitetura medalhão dos dados da camada Inbound para a camada Gold, utilizando Pyspark para essas tratativas nas camadas:
- Bronze: Dados incremental armazenados pela partição da data referencia que o dado é armazenado na camada Inboun. Na camada bronze os dados estão estruturados no formato de tabela mas sem a definição de schemas
- Silver: Se lê a ultima partição da camada Bronze para realizar a tratativa de dados no formatos decimais, inteiros e datas, além da correção de valores anomaliticos na tabela. Não é necessário a realização de retirar duplicatas poís na camada Bronze já realizamos ID unicos no modelo incremental
- Gold: A etapa final da arquitetura medalhão, nessa camada incluímos regras de négocios para facilitar a construçãod e views e tabelas normalizadas para a equipe de dataviz além de melhorar a eficiencia de uma equipe com foco em modleos de machine learning e utilização de IA para diminuir a utilização de Tokens.

3- Modelagem e normalização de dados, onde criamos a partir de dados da camada  gold a construção de tabelas fatos e dimensão com uso do Spark SQL

4- Conexão do Databricks com Power BI para desenvolvimento de Insights e metricas.

## Construção do Ambiente

Foi utilziado Terraform para construir o ambiente cloud sendo os recursos:
- Storage Account
- Access Conector
- Databricks

O Access conector é uma forma simplificada e mais recente para fazer a conexão do Storage Account com a Worksapce da Databricks.
Sendoa ssim nãos endo mais necessárioa  configuraçãod e DBFS ou Service Principal com Key Vaulst e Segredos de Usuários.

## Como Funciona o Pipeline de Dados

1 - Na pasta grainlogistic\src\inbound existe um arquivo .py que faz a leitura dos dados CSV na pasta grainlogistic\files e envia ID por ID para a camada Inbound da StorageAccount
Simulando o envio de dados pelo Event Hub

<div align="center">
  <img src="https://github.com/user-attachments/assets/6beeaa22-08c5-4b65-b86e-bfc29520cd14" alt="Inbound">
  <p><b>Simulando Event Hub</b></p>
</div>

<p align="left">
</p>

2- Assim que um arquivo é armazenado na camada Inbound, o pipeline referente a arquitetura medalhão é acionada no Databricks

<div align="center">
  <img src="https://github.com/user-attachments/assets/afe562af-32af-43e8-bb22-975beb3f308d" alt="Medalion">
  <p><b>Pipeline Medalhão</b></p>
</div>

<p align="left">
</p>

3- Um cluster de Job vai ser iniciado e dar inicio a tratativas de dados

<div align="center">
  <img src="https://github.com/user-attachments/assets/e01791be-05e9-49f6-8251-f16bbbeec7d2" alt="cluster">
  <p><b>Job Cluster</b></p>
</div>

<p align="left">
</p>

Ao terminar a execução o Job Cluster é imediatamente desligado e por isso devemos utiliza-lo em pipelines no Databricks

4- Quando é finalizado , uma adição ou alteração é feita na camada Gold, que também dá inicio ao pipeline de modelagem de dados

<div align="center">
  <img src="https://github.com/user-attachments/assets/5474e7e7-c153-4a88-b85e-4078e56cfae1" alt="modelagem">
  <p><b>Pipeline Modelagem</b></p>
</div>

<p align="left">
</p>

5- Diferente do pipeline medalhão, o cluster utilizado para modelagem e normalização de dados é o Serveless ideal para utilização de SQL com menor custo

<div align="center">
  <img src="https://github.com/user-attachments/assets/30e2fefb-1033-4627-84c0-c3d8200f2deb" alt="cluster Serveless">
  <p><b>Cluster Serveless</b></p>
</div>

<p align="left">
</p>

6- Para integrar os dados do Storage Account com Access Conector , foram criados Volumes no Catalog

<div align="center">
  <img src="https://github.com/user-attachments/assets/cdf9e8a4-f6ff-40f1-94e8-5c0f0b4b8a37" alt="cluster Serveless">
  <p><b>Catalogo Volumes</b></p>
</div>

<p align="left">
</p>

7- Conectamos o Databricks ao Power BI utilizando o Cluster Serveless WareHouse

<div align="center">
  <img src="https://github.com/user-attachments/assets/d00e0935-8037-4d49-b093-e285bc4a9f6c" alt="cluster Power BI">
  <p><b>Cluster Power BI</b></p>
</div>

<p align="left">
</p>

Para gerar um relátorio simples como :

<div align="center">
  <img src="https://github.com/user-attachments/assets/9df4bb17-3175-43ca-9a54-36153cad2b94" alt="Power BI">
  <p><b>Dashboard Power BI</b></p>
</div>

<p align="left">
</p>

8- Para Controlar os Acessos do Unity Catalo podemos utilizar ferramentas como System Tables e controles de accessos por Grupos de Usuários:

<div align="center">
  <img src="https://github.com/user-attachments/assets/03a1f6ef-2673-47db-a1d9-13975e8b2d79" alt="Controle de Acesso">
  <p><b>Controle de Acesso</b></p>
</div>

<p align="left">
</p>

Para system tables temos algumas tabelas bem interessantes como as que estão na imagem abaixo:

<div align="center">
  <img src="https://github.com/user-attachments/assets/34364135-3712-40b7-a616-e00bb906ba94" alt="system">
  <p><b>System Tables</b></p>
</div>

<p align="left">
</p>

Na pasta grainlogistic\src\monitoring foi criado 3 tipos de dashboards no próprio databricks utilizando as system tables para monitorar:
- Consumo de cluster
- Linhagem de dados nas tabelas do Unity Catalog
- Monitoramento de Workflows
