# inferencia.audit 0.1.0 (2026-04-25)

Primera version publica del paquete.

## Funcionalidad

* `evaluar_articulo(ruta_pdf, api_key)` extrae texto de un PDF, llama a la
  API de Gemini con el prompt v4.1-NTK calibrado y devuelve un veredicto
  estructurado (clasificacion, subtipo, motivo, campos auxiliares).
* `evaluar_texto(texto, ...)` variante para entrada de texto plano.
* `prompt_v41()` expone publicamente el prompt completo para reproducibilidad.
* `lanzar_shiny()` inicia la aplicacion web local incluida en `inst/shiny/`.

## Decisiones metodologicas

* Regla operacional de Falla fuerte = `A & C` (muestreo no probabilistico
  + extrapolacion poblacional explicita), aplicada en `aplicar_regla_AC()`
  sobre los binarios devueltos por la IA.
* La condicion B (`advierte_limites_muestreo`) se conserva como
  descomposicion del subtipo dentro de FF: "FF clasica" cuando no advierten
  vs "FF con reconocimiento" cuando advierten pero generalizan igual.
* El prompt enviado al modelo se mantiene siempre en espanol calibrado
  v4.1, independientemente del idioma de la UI Shiny.

## App Shiny incluida

* UI trilingue: espanol, ingles, portugues.
* Caps de cuota integrados: 3 consultas por IP por dia, 200 globales por
  dia, 3.000 globales por mes (configurables en `inst/shiny/rate_limit.R`).
* PDF procesado en memoria; el archivo temporal se borra tras la
  respuesta (`unlink()`).
* Descarga del JSON estructurado del resultado para auditoria externa.

## Calidad y documentacion

* `R CMD check` con 0 errores; los warnings residuales son por pandoc
  faltante en local y se resuelven en CI.
* GitHub Actions corre el check en macOS y Ubuntu (R release y devel) en
  cada push y PR a `main`.
* `inst/CITATION` y `CITATION.cff` para citacion desde R y desde GitHub.
* Vignette `uso-basico.Rmd` con ejemplo reproducible.

## Trazabilidad con la tesis

Este paquete implementa el mismo protocolo metodologico aplicado en la
auditoria de la tesis doctoral asociada (universo `N = 988` revistas
DOAJ Sudamerica 2025, muestra `n = 277`, `2.062` articulos auditados,
prevalencia de Falla fuerte = `59.8%` IC95 `[52.7%, 66.9%]`). El registro
de decisiones metodologicas detalladas esta en `BITACORA.md` del proyecto
de tesis (Pasos 16, 17, 21).
