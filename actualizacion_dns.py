import os, json, requests
from dotenv import load_dotenv

load_dotenv() # Carga las variables del archivo .env
DOMAIN = os.getenv("DOMAIN")
API_KEY = os.getenv("GODADDY_KEY")
API_SECRET = os.getenv("GODADDY_SECRET")  

# LEER LOS NAMESERVERS DE TERRAFORM
ns_list = []
try:
    with open("nameservers_godaddy.txt", "r") as file:
        for line in file:
            line = line.strip()
            # Extraer solo las líneas que empiezan con "ns-"
            if line.startswith("ns-"):
                # Quitar el punto final si AWS lo incluyó (ej. ns-123.awsdns.com.)
                if line.endswith("."):
                    line = line[:-1]
                ns_list.append(line)
except FileNotFoundError:
    print("Archivo nameservers_godaddy.txt no encontrado. Corre terraform apply primero.")
    exit()

if not ns_list:
    print("No se pudieron extraer los Name Servers del archivo.")
    exit()

# PREPARAR LA PETICIÓN A GODADDY
url = f"https://api.godaddy.com/v1/domains/{DOMAIN}"
headers = {
    "Authorization": f"sso-key {API_KEY}:{API_SECRET}",
    "Content-Type": "application/json"
}

payload = json.dumps({"nameServers": ns_list})

print(f"Enviando Name Servers a GoDaddy para {DOMAIN}...")

# ENVIAR LA PETICIÓN
response = requests.patch(url, headers=headers, data=payload)

if response.status_code == 200:
    print("Name Servers actualizados con éxito en GoDaddy")
else:
    print(f"Error al actualizar. Código: {response.status_code}")
    print(response.text)