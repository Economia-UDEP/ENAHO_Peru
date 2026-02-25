import argparse
import requests, zipfile, shutil, time, os, gc
import pandas as pd
from pathlib import Path

# Años ENAHO (código de encuesta)
YEAR_CODES = {
    2007: 283, 2008: 284, 2009: 285, 2010: 279, 2011: 291, 2012: 324,
    2013: 404, 2014: 440, 2015: 498, 2016: 546, 2017: 603, 2018: 634,
    2019: 687, 2020: 737, 2021: 759, 2022: 784, 2023: 906, 2024: 966
}

# Módulos ENAHO de interés
MODS = [
    1,2,3,4,5,7,8,9,10,11,12,13,15,16,17,18,22,23,24,25,26,27,28,34,37,
    77,78,84,85,1825
]

# extrae SOLO .dta desde el zip (plano)
def _extraer_dtas_desde_zip(zip_path: Path, out_dir: Path):
    n = 0
    with zipfile.ZipFile(zip_path, "r") as z:
        for info in z.infolist():
            name = info.filename
            if not name.lower().endswith(".dta"):
                continue

            base = Path(name).name
            out_path = out_dir / base

            # reemplazo por nombre
            if out_path.exists():
                out_path.unlink()

            with z.open(info, "r") as src, open(out_path, "wb") as dst:
                shutil.copyfileobj(src, dst)

            n += 1
    return n


def _guardar_pdfs_interes_desde_zip(zip_path: Path, year_dir: Path, year: int):
    # 1) diccionario anual (solo 1)
    out_dicc = year_dir / f"Diccionario{year}.pdf"

    dicc_guardado = out_dicc.exists()
    sumarias_guardadas = 0

    with zipfile.ZipFile(zip_path, "r") as z:
        for info in z.infolist():
            name = info.filename
            low = name.lower()

            if not low.endswith(".pdf"):
                continue

            base = Path(name).name

            # (A) guardar diccionario anual si no existe
            if (not dicc_guardado) and ("dicc" in low):
                with z.open(info, "r") as src, open(out_dicc, "wb") as dst:
                    shutil.copyfileobj(src, dst)
                dicc_guardado = True
                continue

            # (B) guardar PDFs de sumaria (si existen)
            if "sumaria" in low:
                out_sum = year_dir / base
                if not out_sum.exists():  # no sobreescribir
                    with z.open(info, "r") as src, open(out_sum, "wb") as dst:
                        shutil.copyfileobj(src, dst)
                    sumarias_guardadas += 1

    return int(dicc_guardado), sumarias_guardadas


# mueve a aux los .dta que NO son enaho* ni sumaria-*
def _filtrar_principales(year_dir: Path):
    aux_dir = year_dir / "aux"
    aux_dir.mkdir(exist_ok=True)

    moved = 0
    for p in year_dir.glob("*.dta"):
        name = p.name.lower()

        # WHITELIST REAL
        es_enaho = name.startswith("enaho") and "tabla" not in name
        es_sumaria = name.startswith("sumaria-")

        if es_enaho or es_sumaria:
            continue

        # todo lo demás -> aux
        dest = aux_dir / p.name
        if dest.exists():
            dest.unlink()

        p.replace(dest)
        moved += 1

    return moved


def descargar_y_extraer_enaho(base_path, years_dict, modules_list, reset=True):

    if reset and base_path.exists():
        shutil.rmtree(base_path)

    base_path.mkdir(parents=True, exist_ok=True)
    print("INICIO DE PROCESO MAESTRO (ENAHO - STATA)")

    for year, code in years_dict.items():

        year_dir = base_path / f"raw_{year}"
        year_dir.mkdir(exist_ok=True)

        print(f"\nAño {year}:", end=" ", flush=True)

        for mod in modules_list:

            url = f"https://proyectos.inei.gob.pe/iinei/srienaho/descarga/STATA/{code}-Modulo{mod:02d}.zip"

            tmp_dir = year_dir / f"_tmp_{mod}"
            zip_path = tmp_dir / "data.zip"

            try:
                r = requests.get(url, timeout=60)
                if r.status_code != 200:
                    continue

                tmp_dir.mkdir(exist_ok=True)
                with zip_path.open("wb") as f:
                    f.write(r.content)

                # guardar diccionario del año
                _guardar_pdfs_interes_desde_zip(zip_path, year_dir, year)

                # extraer dta
                n = _extraer_dtas_desde_zip(zip_path, year_dir)

                if n == 0:
                    print(f"[!{mod}]", end="", flush=True)
                else:
                    print(f"{mod}.", end="", flush=True)

            except:
                print(f"[!{mod}]", end="", flush=True)

            finally:
                shutil.rmtree(tmp_dir, ignore_errors=True)

        # filtro final whitelist/blacklist
        moved = _filtrar_principales(year_dir)
        if moved > 0:
            print(f" (aux:{moved})", end="", flush=True)

    print("\n\nMASTER COMPLETADO")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--out", required=True,
        help="Ruta de salida donde guardar ENAHO")

    parser.add_argument("--reset", action="store_true",
        help="Borra la carpeta de salida antes de iniciar")

    args = parser.parse_args()

    BASE = Path(args.out)
    descargar_y_extraer_enaho(BASE, YEAR_CODES, MODS, reset=args.reset)
