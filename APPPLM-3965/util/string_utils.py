def normalize_name(name: str) -> str:
    """Normalizes a name by capitalizing the first letter of each part, except for certain exceptions.
    1. Capitalizes the first letter of each part of the name.
    2. Keeps certain parts in lowercase (e.g., "van", "de", "der", etc.).
    Args:
        name (str): The name to normalize.
    Returns:
        str: The normalized name.
    """
    if not isinstance(name, str):
        return name
    
    exceptions = {"van", "de", "der", "den", "di", "von", "du", "da"}
    
    parts = name.strip().split()
    normalized_parts = []
    
    for word in parts:
        lower = word.lower()
        if lower in exceptions:
            normalized_parts.append(lower)
        else:
            normalized_parts.append(lower.capitalize())
    
    return " ".join(normalized_parts)

def split_name(full_name: str) -> tuple[str, str]:
    """Splits a full name into first name and last name, handling special cases for Dutch names.
    Args:
        full_name (str): The full name to split.
    Returns:
        tuple[str, str]: A tuple containing the first name and last name.
    """
    if not isinstance(full_name, str) or not full_name.strip():
        return '', ''

    full_name = full_name.strip()

    #TODO: Definition of Special Cases
    special_cases = {
        "Eric van Boxel": ("Eric van", "Boxel"),
        "Ronnie van Osch": ("Ronnie van", "Osch"),
        "John de Haas": ("John de", "Haas"),
        "Frank van Berkel": ("Frank van", "Berkel"),
        "Ad van Houtum": ("Ad van", "Houtum"),
        "Pieter van Duijnhoven": ("Pieter van", "Duijnhoven"),
        "Frank van Geffen": ("Frank van", "Geffen"),
        "Paul van der Heijden": ("Paul van der", "Heijden"),
        "Stef van Diessen": ("Stef van", "Diessen"),
        "Steff van Diessen": ("Stef van", "Diessen")
    }

    # 1. Prüfung auf Spezialfälle
    if full_name in special_cases:
        return special_cases[full_name]

    # 2. Standard-Logik für alle anderen Namen
    parts = full_name.split()
    first_name = parts[0]
    last_name = " ".join(parts[1:]) if len(parts) > 1 else ""
    
    return first_name, last_name