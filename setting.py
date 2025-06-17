import os
from dotenv import load_dotenv
load_dotenv(override=True)

SERVER_PORT = os.getenv("SERVER_PORT",  "52000")
SERVER_HOST = os.getenv("SERVER_HOST", "0.0.0.0")



# 确保存储目录存在
UPLOAD_DIR = os.path.join(os.getcwd(), 'difypkg')
OUTPUT_DIR = os.path.join(os.getcwd(), 'difypkg-offline')