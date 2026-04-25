GEMINI_ENDPOINT <- "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
DEFAULT_MODELO <- "gemini-2.5-flash"


#' Llamar a la API de Gemini con el prompt v4.1 y un texto dado
#'
#' Replica el comportamiento del script `analizar_v41ntk.py` (mismo modelo,
#' mismo prompt, mismo `temperature = 0`, mismo response schema). Es el
#' componente que garantiza paridad metodologica entre la app y la tesis.
#'
#' @param texto_pdf Texto del articulo (truncado).
#' @param nombre_archivo Nombre informativo del archivo.
#' @param api_key Clave API de Google AI Studio. Default `Sys.getenv("GOOGLE_API_KEY")`.
#' @param modelo Nombre del modelo Gemini. Default `"gemini-2.5-flash"`.
#' @param timeout_seg Timeout total de la llamada HTTP. Default `180`.
#' @return Lista nombrada con los campos del esquema (clasificacion, motivo, etc.).
#' @keywords internal
llamar_gemini <- function(texto_pdf,
                          nombre_archivo = "articulo.pdf",
                          api_key = Sys.getenv("GOOGLE_API_KEY"),
                          modelo = DEFAULT_MODELO,
                          timeout_seg = 180) {
  if (!nzchar(api_key)) {
    stop("Falta GOOGLE_API_KEY (variable de entorno o argumento api_key).", call. = FALSE)
  }
  url <- sprintf(GEMINI_ENDPOINT, modelo)
  prompt_texto <- paste0(
    prompt_v41(), "\n\n",
    construir_prompt_usuario(texto_pdf, nombre_archivo),
    "\n\nResponde exclusivamente con JSON valido."
  )
  payload <- list(
    contents = list(list(parts = list(list(text = prompt_texto)))),
    generationConfig = list(
      temperature       = 0,
      responseMimeType  = "application/json",
      responseSchema    = response_schema()
    )
  )
  resp <- httr2::request(url) |>
    httr2::req_url_query(key = api_key) |>
    httr2::req_headers("Content-Type" = "application/json") |>
    httr2::req_body_json(payload, auto_unbox = TRUE) |>
    httr2::req_timeout(timeout_seg) |>
    httr2::req_retry(max_tries = 3,
                     backoff = function(i) 5 * i,
                     is_transient = function(resp) {
                       httr2::resp_status(resp) %in% c(408, 425, 429, 500, 502, 503, 504)
                     }) |>
    httr2::req_perform()

  data <- httr2::resp_body_json(resp)
  if (!is.null(data$error)) {
    stop(jsonlite::toJSON(data$error, auto_unbox = TRUE), call. = FALSE)
  }
  parts <- data$candidates[[1]]$content$parts
  txt <- parts[[1]]$text
  parsear_json_tolerante(txt)
}


#' Parser tolerante para respuestas que vengan envueltas en bloque markdown
#' o con texto extra alrededor.
#' @keywords internal
parsear_json_tolerante <- function(txt) {
  if (is.null(txt) || !nzchar(trimws(as.character(txt)))) {
    stop("Respuesta vacia de Gemini.", call. = FALSE)
  }
  bruto <- trimws(as.character(txt))

  parsed <- try(jsonlite::fromJSON(bruto, simplifyVector = FALSE), silent = TRUE)
  if (!inherits(parsed, "try-error")) return(parsed)

  fence <- regmatches(bruto, regexpr("```(?:json)?\\s*\\{[\\s\\S]*?\\}\\s*```", bruto, perl = TRUE))
  if (length(fence)) {
    inner <- sub("^```(?:json)?\\s*", "", fence, perl = TRUE)
    inner <- sub("\\s*```$", "", inner, perl = TRUE)
    parsed <- try(jsonlite::fromJSON(inner, simplifyVector = FALSE), silent = TRUE)
    if (!inherits(parsed, "try-error")) return(parsed)
  }
  ini <- regexpr("\\{", bruto)
  fin <- max(gregexpr("\\}", bruto)[[1]])
  if (ini > 0 && fin > ini) {
    parsed <- try(jsonlite::fromJSON(substr(bruto, ini, fin), simplifyVector = FALSE),
                  silent = TRUE)
    if (!inherits(parsed, "try-error")) return(parsed)
  }
  stop("No se pudo parsear JSON de la respuesta de Gemini.", call. = FALSE)
}
