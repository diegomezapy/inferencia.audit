#' Extraer texto de un PDF, truncado al limite de caracteres usado en la auditoria
#'
#' Lee el PDF, concatena el texto de las paginas y trunca al limite (default
#' `30000` caracteres) para mantener paridad con el pipeline de la tesis. No
#' escribe nada al disco mas alla de lo que `pdftools` necesite internamente.
#'
#' @param ruta_pdf Ruta al archivo PDF en disco (Shiny pasa un fichero temporal).
#' @param max_chars Limite duro de caracteres a enviar a la IA. Default `30000`.
#' @return Lista con `texto`, `n_paginas`, `truncado` (logico) y `advertencia`.
#' @keywords internal
extraer_texto_pdf <- function(ruta_pdf, max_chars = 30000L) {
  if (!file.exists(ruta_pdf)) {
    stop(sprintf("PDF no encontrado: %s", ruta_pdf), call. = FALSE)
  }
  paginas <- tryCatch(
    pdftools::pdf_text(ruta_pdf),
    error = function(e) stop(sprintf("Error al leer PDF: %s", conditionMessage(e)), call. = FALSE)
  )
  texto_completo <- paste(paginas, collapse = "\n")
  if (!nzchar(trimws(texto_completo))) {
    stop("PDF sin texto extraible (posiblemente escaneado).", call. = FALSE)
  }
  truncado <- FALSE
  if (nchar(texto_completo) > max_chars) {
    texto_completo <- substr(texto_completo, 1L, max_chars)
    truncado <- TRUE
  }
  list(
    texto       = texto_completo,
    n_paginas   = length(paginas),
    truncado    = truncado,
    advertencia = if (truncado) sprintf("Truncado a %d chars (%d paginas).", max_chars, length(paginas)) else ""
  )
}
