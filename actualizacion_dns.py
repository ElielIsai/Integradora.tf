import os, json, requests
# Eliminamos load_dotenv porque Jenkins inyectará las variables directamente

# Jenkins pasará estas variables a través del bloque withCredentials
DOMAIN = os.getenv("DOMAIN")
API_KEY = os.getenv("TF_VAR_godaddy_key") # Nombre que usamos en el Jenkinsfile
API_SECRET = os.getenv("TF_VAR_godaddy_secret")  

# LEER LOS NAMESERVERS DE TERRAFORM
ns_list = []
try:
    # Asegúrate de que este archivo se genere en la raíz del workspace de Jenkins
    with open("nameservers_godaddy.txt", "r") as file:
        for line in file:
            line = line.strip()
            if line.startswith("ns-"):
                if line.endswith("."):
                    line = line[:-1]
                ns_list.append(line)
except FileNotFoundError:
    print("Error: Archivo nameservers_godaddy.txt no encontrado.")
    exit(1) # Código de error para que Jenkins sepa que falló

if not ns_list:
    print("Error: No se encontraron Name Servers.")
    exit(1)

# PREPARAR LA PETICIÓN A GODADDY
url = f"https://api.godaddy.com/v1/domains/{DOMAIN}"
headers = {
    "Authorization": f"sso-key {API_KEY}:{API_SECRET}",
    "Content-Type": "application/json"
}

payload = json.dumps({"nameServers": ns_list})

print(f"Enviando {len(ns_list)} Name Servers a GoDaddy para {DOMAIN}...")

response = requests.patch(url, headers=headers, data=payload)

if response.status_code == 200 or response.status_code == 204: # GoDaddy a veces devuelve 204
    print("Name Servers actualizados con éxito en GoDaddy")
else:
    print(f"Error al actualizar. Código: {response.status_code}")
    print(response.text)
    exit(1)