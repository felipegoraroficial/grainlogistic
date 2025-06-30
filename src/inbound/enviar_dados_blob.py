import pandas as pd
import locale
from azure.storage.blob import BlobServiceClient
import json
from azure.core.exceptions import AzureError
from dotenv import load_dotenv
import os

env_path = os.path.join(os.getcwd(), '.env')
load_dotenv(dotenv_path=env_path)

CONNECTION_STRING = os.getenv('CONNECTION_STRING')
CONTAINER_NAME = os.getenv('CONTAINER_NAME')

# Configuração do locale
try:
    locale.setlocale(locale.LC_ALL, 'pt_BR.UTF-8')
except locale.Error:
    try:
        locale.setlocale(locale.LC_ALL, 'pt_BR')
    except locale.Error:
        try:
            locale.setlocale(locale.LC_ALL, 'Portuguese_Brazil')
        except locale.Error:
            print("Aviso: Não foi possível definir o locale.")

# Leitura e processamento dos dados
df = pd.read_csv('files\\grain_logistic_shipping.csv', encoding='utf-8', sep=';')
df['send_api'] = pd.to_datetime(df['DataEnvio'], format="%A, %d de %B de %Y", errors='coerce')
df_ordenado = df.sort_values(by='send_api', ascending=True)
df_ordenado.drop('send_api', axis='columns', inplace=True)
dados = df_ordenado.to_dict(orient='records')

try:
    # Criar clientes do Blob Storage
    blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
    container_client = blob_service_client.get_container_client(CONTAINER_NAME)
    
    # Verificar se o container existe
    if not container_client.exists():
        container_client.create_container()
        print(f"Container '{CONTAINER_NAME}' criado com sucesso.")
    
    # Enviar dados
    for i, registro in enumerate(dados):
        try:
            id_envio = registro['id_envio']
            blob_name = f"inbound/{id_envio}.json"
            blob_client = container_client.get_blob_client(blob_name)
            
            # Converter para JSON
            json_data = json.dumps(registro, ensure_ascii=False)
            
            # Fazer upload
            blob_client.upload_blob(json_data, overwrite=True)
            print(f"[{i+1}/{len(dados)}] Arquivo {blob_name} enviado com sucesso!")
            
        except AzureError as e:
            print(f"Erro no envio do registro {id_envio}: {str(e)}")
        except Exception as e:
            print(f"Erro inesperado no registro {id_envio}: {str(e)}")

except AzureError as e:
    print(f"Erro de conexão com o Azure Storage: {str(e)}")
except Exception as e:
    print(f"Erro inesperado: {str(e)}")
