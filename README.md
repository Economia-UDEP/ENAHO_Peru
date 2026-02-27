# Encuesta Nacional de Hogares (ENAHO, Peru)

**Languages:** [English](#english) | [Español](#espanol)
----

<a id="english"></a>

# English Description

----

This repository contains Python code that downloads and cleans ENAHO datasets according to the users custom requirements.

The pipeline is designed to be **user-customizable**: you edit a small set of options in `0_master.do` and can adapt `1_clean_enaho.do`, then run one command to build your dataset end-to-end.

## Requirements 
---- 

- Stata (16+ due to Python integration) 


## How it works
---- 

1. Stata runs a Python script `master_enaho.py` that loads the necessary packages from `requirements.txt`.
2. The Python script:
   - Downloads ENAHO module archives (INEI),
   - Unzips them into a standardized folder structure.
3. `0_master.do`:
   - performs within-year merges across modules,
   - appends data across years,
   - calls a **user-adaptable cleaning do-file** `1_clean_enaho.do` for final harmonization.
4. Output: a **consolidated Stata dataset** with multiple cross-sections (one per year), containing the **variables you requested**.


## Credits
----

If you benefit form code in this repository, please cite it in your work as:
- Universidad de Piura (2026), *Cleaning Encuesta Nacional de Hogares (ENAHO, Peru) dataset*. Github repository - https://github.com/Economia-UDEP/ENAHO_Peru

This code is the result of excellent research assistance by Vladimir Baños Calle (@Vladimir1804).


## Disclaimer & feedback
----

This repository is provided as is, without warranty of any kind. While we aim for correctness and reproducibility, the pipeline may contain bugs or require adaptation to changes in ENAHO/INEI file structures.

If you find an issue or have suggestions, please open a GitHub issue in this repository (bug reports, feature requests, and improvements are welcome).


<br><br>

---

<br><br>


<a id="espanol"></a>

# Descripción en Español
----

Este repositorio contiene código en Python que descarga y limpia las bases de datos de ENAHO de acuerdo con los requerimientos del usuario.

El flujo está diseñado para ser **personalizable**: usted edita un conjunto pequeño de opciones en `0_master.do` y puede adaptar `1_clean_enaho.do`; luego ejecuta un solo comando para construir su base final de inicio a fin.

## Requisitos
----

- Stata (16+ por la integración con Python)

## ¿Cómo funciona?
----

1. Stata ejecuta el script de Python `master_enaho.py`, que carga los paquetes necesarios desde `requirements.txt`.
2. El script de Python:
   - Descarga los archivos de módulos de ENAHO (INEI),
   - Los descomprime en una estructura de carpetas estandarizada.
3. `0_master.do`:
   - realiza los merges dentro de cada año entre módulos,
   - hace append entre años,
   - llama al do-file de limpieza **adaptable por el usuario** `1_clean_enaho.do` para la armonización final.
4. Salida: un **dataset consolidado en Stata** con múltiples cortes transversales (uno por año), que contiene las **variables solicitadas**.

## Créditos
----

Si este repositorio le resulta útil, por favor cítelo como:
- Universidad de Piura (2026), *Cleaning Encuesta Nacional de Hogares (ENAHO, Peru) dataset*. Github repository - https://github.com/Economia-UDEP/ENAHO_Peru

Este código es resultado de una excelente asistencia de investigación por Vladimir Baños Calle (@Vladimir1804).


## Disclaimer y Feedback
----

Este repositorio se proporciona tal cual, sin garantía de ningún tipo. Aunque buscamos corrección y reproducibilidad, el flujo puede contener errores o requerir ajustes si cambian las estructuras de archivos de ENAHO/INEI.

Si encuentra un problema o tiene sugerencias, por favor abra un issue en este repositorio (son bienvenidos reportes de errores, solicitudes de mejoras y nuevas funcionalidades).