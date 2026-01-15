import configparser
import os
from typing import Dict, Any

# Constant for the secrets file name
SECRETS_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.db_secrets.ini')

def load_db_credentials(profile_name: str) -> Dict[str, Any]:   
    """Loads the Oracle credentials for a specific profile.
    Args:
        profile_name (str): The profile name in the secrets file.
    Returns:
        Dict[str, Any]: A dictionary containing the database credentials.
    """
    if not os.path.exists(SECRETS_FILE):
        # Wirft einen Fehler, wenn die Datei nicht existiert (wichtig für die Sicherheit)
        raise FileNotFoundError(f"❌\t'{SECRETS_FILE}' was not found. Make sure it exists in the root directory.")
    print(f"ℹ️\tLoading Database Configuration for {profile_name}...")    
    config = configparser.ConfigParser()
    config.read(SECRETS_FILE)

    if profile_name not in config:
        raise ValueError(f"❌\tDatabase profile '{profile_name}' not found in the secrets file.")

    creds = config[profile_name]
    
    print(f"✅\tDatabase Configuration for {profile_name} loaded successfully.")
    return {
        "user": creds['user'],
        "password": creds['password'],
        "host" : creds['host'],
        'port' : creds['port'],
        'service_name' : creds['service_name']
    }