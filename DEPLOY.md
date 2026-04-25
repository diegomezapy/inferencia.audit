# Despliegue de la app Shiny en shinyapps.io

## 1. Pre-requisitos

* Cuenta gratuita en <https://www.shinyapps.io>
* API key de Google AI Studio (<https://aistudio.google.com/app/apikey>)
* R con `rsconnect`, `remotes`, y el paquete `inferencia.audit` instalado.

## 2. Configurar `rsconnect`

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(
  name   = "TU_USUARIO",
  token  = "TU_TOKEN",
  secret = "TU_SECRET"
)
```

(Datos disponibles en el panel de shinyapps.io > Account > Tokens.)

## 3. Configurar el secret de la API key

shinyapps.io expone variables de entorno definidas en el panel:

> Applications > tu-app > Settings > Variables

Definir:

* `GOOGLE_API_KEY` = tu clave (NO commitearla al repo nunca).

La aplicacion la lee con `Sys.getenv("GOOGLE_API_KEY")`.

## 4. Configurar billing alert en Google Cloud

> Console > Billing > Budgets & alerts > Create budget

Recomendado: alerta a 50 % y 100 % de **10 USD/mes**.

## 5. Desplegar

Desde la raiz del paquete:

```r
rsconnect::deployApp(
  appDir   = "inst/shiny",
  appName  = "inferencia-audit",
  appTitle = "inferencia.audit"
)
```

`rsconnect` detecta automaticamente las dependencias del `app.R`. Como el
paquete `inferencia.audit` se instala desde GitHub, agregar antes:

```r
rsconnect::writeManifest(
  appDir   = "inst/shiny",
  appPrimaryDoc = "app.R",
  contentCategory = "application"
)
```

Si el package server no encuentra `inferencia.audit`, agregar al inicio de
`app.R`:

```r
if (!requireNamespace("inferencia.audit", quietly = TRUE)) {
  remotes::install_github("diegomezapy/inferencia.audit")
}
```

## 6. Topes de cuota incorporados (defensa de costos)

Estan en `inst/shiny/rate_limit.R`:

| Tope | Valor por defecto |
|---|---:|
| Por IP por dia | `3` |
| Global por dia | `200` |
| Global por mes | `3.000` |

Para ajustar, editar las constantes `LIMITE_POR_IP_DIA`, `LIMITE_GLOBAL_DIA`,
`LIMITE_GLOBAL_MES` en ese archivo y redeployar.

## 7. Privacidad / borrado de PDFs

El archivo subido se procesa via `pdftools::pdf_text()` desde la ruta temporal
que Shiny administra. Tras la llamada a la API, `app.R` invoca
`unlink(input$pdf$datapath, force = TRUE)` para borrar el temporal. Ningun
PDF se persiste.

## 8. Verificacion post-deploy

* Sin PDF -> deberia mostrar la UI sin errores.
* PDF chico -> respuesta en ~10 s con badge de clasificacion.
* Reintento desde misma IP > 3 veces -> mensaje de cupo agotado.
* Revisar logs en `Applications > tu-app > Logs` ante cualquier error.
