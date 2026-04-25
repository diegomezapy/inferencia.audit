#' Evaluar un articulo cientifico
#'
#' Funcion publica principal del paquete. Recibe la ruta a un PDF, extrae el
#' texto, llama al modelo Gemini con el prompt v4.1-NTK, aplica la regla de
#' agregacion A & C definida en el Paso 21 de la bitacora y devuelve el
#' veredicto junto con todos los campos auxiliares.
#'
#' @param ruta_pdf Ruta al PDF a evaluar.
#' @param api_key Clave API de Google AI Studio. Default `Sys.getenv("GOOGLE_API_KEY")`.
#' @param modelo Nombre del modelo Gemini. Default `"gemini-2.5-flash"`.
#' @param max_chars Limite de caracteres del PDF enviados a la IA.
#'   Default `30000` (idem auditoria de tesis).
#'
#' @return Lista con los siguientes campos:
#' \describe{
#'   \item{clasificacion_final}{Una de: "Falla fuerte", "Debilidad importante",
#'     "Sin falla relevante", "No aplica". Aplicando la regla A & C.}
#'   \item{subtipo}{Para Falla fuerte: "FF clasica" o "FF con reconocimiento". Si no, NA.}
#'   \item{nivel_confianza}{"Alta" / "Media" / "Baja", segun reporte del modelo.}
#'   \item{motivo_principal}{Justificacion textual breve.}
#'   \item{campos_binarios}{Lista con los 4 indicadores auxiliares clave
#'     (`A` muestreo no probabilistico, `B` advierte limites, `C` extrapola a poblacion,
#'     `aplica` muestreo inferencial).}
#'   \item{respuesta_completa}{Lista nombrada con los 22 campos del esquema v4.1.}
#'   \item{meta}{Lista con `n_paginas`, `truncado`, `advertencia` de la extraccion.}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#'   res <- evaluar_articulo("articulo.pdf",
#'                           api_key = Sys.getenv("GOOGLE_API_KEY"))
#'   res$clasificacion_final
#'   res$motivo_principal
#' }
evaluar_articulo <- function(ruta_pdf,
                             api_key   = Sys.getenv("GOOGLE_API_KEY"),
                             modelo    = "gemini-2.5-flash",
                             max_chars = 30000L) {
  extr <- extraer_texto_pdf(ruta_pdf, max_chars = max_chars)
  evaluar_texto(
    texto          = extr$texto,
    nombre_archivo = basename(ruta_pdf),
    api_key        = api_key,
    modelo         = modelo,
    .meta_extraccion = extr
  )
}


#' Evaluar a partir de texto plano (sin PDF)
#'
#' Variante de `evaluar_articulo()` para casos en que ya se dispone del texto
#' del articulo (por ejemplo, en pruebas o cuando el PDF se procesa por otra
#' via). Aplica el mismo prompt y la misma regla de agregacion.
#'
#' @param texto Texto plano del articulo.
#' @param nombre_archivo Nombre informativo. Default `"articulo.txt"`.
#' @inheritParams evaluar_articulo
#' @param .meta_extraccion uso interno (no setear manualmente).
#' @return Misma estructura que `evaluar_articulo()`.
#' @export
evaluar_texto <- function(texto,
                          nombre_archivo   = "articulo.txt",
                          api_key          = Sys.getenv("GOOGLE_API_KEY"),
                          modelo           = "gemini-2.5-flash",
                          .meta_extraccion = NULL) {
  if (!is.character(texto) || length(texto) != 1 || !nzchar(trimws(texto))) {
    stop("`texto` debe ser una cadena no vacia.", call. = FALSE)
  }
  respuesta <- llamar_gemini(
    texto_pdf      = texto,
    nombre_archivo = nombre_archivo,
    api_key        = api_key,
    modelo         = modelo
  )
  veredicto <- aplicar_regla_AC(respuesta)

  list(
    clasificacion_final = veredicto$clasificacion_final,
    subtipo             = veredicto$subtipo,
    nivel_confianza     = as.character(respuesta$nivel_confianza_clasificacion %||% ""),
    motivo_principal    = as.character(respuesta$motivo_principal %||% ""),
    campos_binarios     = list(
      A_muestreo_no_probabilistico = es_si(respuesta$muestreo_no_probabilistico),
      B_advierte_limites           = es_si(respuesta$advierte_limites_muestreo),
      C_extrapola_a_poblacion      = es_si(respuesta$extrapola_a_poblacion),
      aplica_muestreo_inferencial  = es_si(respuesta$aplica_muestreo_inferencial)
    ),
    respuesta_completa  = respuesta,
    meta                = .meta_extraccion %||% list()
  )
}


#' Lanzar la app Shiny incluida en el paquete
#'
#' Inicia la aplicacion web (`inst/shiny/app.R`) en el navegador local. Util
#' para desarrollo. Para deploy en shinyapps.io, ver `DEPLOY.md`.
#'
#' @param launch.browser logico, default TRUE.
#' @param port puerto para servir la app. Default 4321.
#' @export
lanzar_shiny <- function(launch.browser = TRUE, port = 4321L) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Instalar primero el paquete `shiny`.", call. = FALSE)
  }
  app_dir <- system.file("shiny", package = "inferencia.audit")
  if (!nzchar(app_dir) || !dir.exists(app_dir)) {
    stop("No se encontro inst/shiny/. Reinstalar el paquete.", call. = FALSE)
  }
  shiny::runApp(app_dir, launch.browser = launch.browser, port = port)
}
