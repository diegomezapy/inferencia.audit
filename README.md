# inferencia.audit

Auditoria automatizada de fallas en muestreo e inferencia estadistica para
articulos cientificos cuantitativos.

Es la implementacion abierta y citable del protocolo metodologico aplicado en
la tesis doctoral *"Fallas inferenciales en revistas latinoamericanas"*
(FACEN-UNA, 2026), que audito 2.062 articulos extraidos de 277 revistas
sorteadas al azar entre las 988 revistas sudamericanas con publicacion
validada en DOAJ 2025.

## Que clasifica

Cada articulo recibe una de cuatro etiquetas:

* **Falla fuerte** — el articulo aplica inferencia estadistica y extrapola a
  una poblacion mas amplia (un pais, una profesion, un grupo etario) a partir
  de una muestra no probabilistica.
* **Debilidad importante** — hay problema metodologico real pero no se cumplen
  las dos condiciones de Falla fuerte.
* **Sin falla relevante** — muestreo apropiado o sin pretension inferencial.
* **No aplica** — el articulo no entra al universo (meta-analisis,
  experimento de laboratorio, censo, simulacion, etc.).

## Instalacion

```r
# install.packages("remotes")
remotes::install_github("diegomezapy/inferencia.audit")
```

## Uso minimo

```r
library(inferencia.audit)
Sys.setenv(GOOGLE_API_KEY = "tu_clave_de_google_ai_studio")

res <- evaluar_articulo("ruta/al/articulo.pdf")
res$clasificacion_final
res$motivo_principal
```

Para obtener una API key gratuita: <https://aistudio.google.com/app/apikey>.

## App Shiny incluida

```r
inferencia.audit::lanzar_shiny()
```

UI trilingue (es / en / pt). El prompt enviado al modelo se mantiene siempre
en espanol calibrado v4.1 para paridad con la tesis.

## Despliegue publico

Ver [DEPLOY.md](DEPLOY.md) para instrucciones de despliegue en shinyapps.io
con caps de cuota incorporados.

## Reproducibilidad

El prompt completo es publico y accesible desde R:

```r
cat(inferencia.audit::prompt_v41())
```

## Cita

> Meza Bogado, D. B. (2026). *Auditoria de fallas inferenciales en revistas
> cientificas sudamericanas (DOAJ 2025): paquete inferencia.audit*. Tesis
> Doctoral en Ciencias, FACEN-UNA.

## Licencia

MIT.
