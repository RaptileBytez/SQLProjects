import pandas as pd
import os


def compare_scm_files(base_path: str, date: str):
    """
    Vergleicht SCM-CSVs von BLD, PQE, QS und PROD.
    Erwartetes Format: {PROFILE}_SCMs_since_{date}.csv
    """

    profiles = ["BLD", "PQE", "QS", "PROD"]

    # ---- 1) CSVs einlesen ----------------------------------------------------
    dfs = []
    for profile in profiles:
        file_path = os.path.join(base_path, f"{profile}_SCMs_since_{date}.csv")

        if not os.path.exists(file_path):
            print(f"⚠ Datei fehlt: {file_path}")
            continue

        df = pd.read_csv(file_path)

        # IDX ignorieren
        df = df.drop(columns=["IDX"], errors="ignore")

        # SOURCE hinzufügen
        df["SOURCE"] = profile
        dfs.append(df)

    if len(dfs) == 0:
        raise ValueError("Keine Dateien gefunden. Script wird beendet.")

    # Gesamt-DF
    df_all = pd.concat(dfs, ignore_index=True)

    # ---- 2) Pivot-Tabelle erstellen ------------------------------------------
    pivot = df_all.pivot_table(
        index="PAT_CHG_ID",
        columns="SOURCE",
        values="MAX_EXPORT_ID",
        aggfunc="first"
    )

    # ---- 3) Fehlende IDs finden ----------------------------------------------
    missing_ids = pivot[pivot.isna().any(axis=1)]

    # ---- 4) Abweichende MAX_EXPORT_ID-Werte ----------------------------------
    differing_ids = pivot[(pivot.nunique(axis=1) > 1) & (~pivot.isna().all(axis=1))]

    # ---- 5) Alles speichern ---------------------------------------------------
    full_path = os.path.join(base_path, f"SCM_full_comparison_{date}.csv")
    missing_path = os.path.join(base_path, f"SCM_missing_PAT_CHG_IDs_{date}.csv")
    diff_path = os.path.join(base_path, f"SCM_different_MAX_EXPORT_IDs_{date}.csv")

    pivot.to_csv(full_path)
    missing_ids.to_csv(missing_path)
    differing_ids.to_csv(diff_path)

    print("\n✅ Vergleich abgeschlossen!")
    print(f"📄 Full Comparison gespeichert in:       {full_path}")
    print(f"📄 Fehlende PAT_CHG_IDs gespeichert in:   {missing_path}")
    print(f"📄 Unterschiedliche EXPORT_IDs gespeichert in: {diff_path}")

    # Optional Rückgabe für Jupyter
    return pivot, missing_ids, differing_ids



if __name__ == "__main__":
    # Ordner mit den CSVs
    base_path = "Data/SCM"

    # Datum der Dateien
    date = "01-01-2024"

    compare_scm_files(base_path, date)