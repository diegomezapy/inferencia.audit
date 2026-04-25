#' Normalizar Si/No de los campos auxiliares devueltos por Gemini
#'
#' La API a veces responde "Sí", "Si", "SI", "yes", "Sí.", etc. Esta funcion
#' canonicaliza a `TRUE` cuando el valor representa una afirmacion clara, a
#' `FALSE` cuando representa negacion clara, y a `NA` en otro caso.
#'
#' @param x cadena de caracteres (puede ser NULL o vacia).
#' @return logical de longitud 1.
#' @keywords internal
es_si <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA)
  s <- toupper(trimws(as.character(x)[[1]]))
  s <- iconv(s, to = "ASCII//TRANSLIT", sub = "")
  if (s %in% c("SI", "S", "YES", "Y", "TRUE", "VERDADERO")) return(TRUE)
  if (s %in% c("NO", "N", "FALSE", "FALSO")) return(FALSE)
  NA
}


#' Aplicar la regla operacional de agregacion (Falla fuerte = A & C)
#'
#' Toma los binarios devueltos por Gemini (`muestreo_no_probabilistico`,
#' `extrapola_a_poblacion`, `advierte_limites_muestreo`,
#' `aplica_muestreo_inferencial`) y devuelve una lista con:
#'   - `clasificacion_final`: "Falla fuerte", "Debilidad importante",
#'     "Sin falla relevante", "No aplica".
#'   - `subtipo`: para FF, indica si la advertencia esta presente
#'     ("FF clasica" o "FF con reconocimiento") o NA.
#'   - `etiqueta_modelo`: la clasificacion textual original devuelta por la IA
#'     (puede diferir de `clasificacion_final` por matices que el modelo
#'     considero relevantes).
#'
#' Esta funcion implementa la decision metodologica del Paso 21 (BITACORA):
#' la cifra titular de la tesis se construye desde los binarios A y C, no
#' desde la etiqueta textual. La condicion B (advertencia) se conserva como
#' descomposicion del subtipo.
#'
#' @param respuesta lista nombrada (resultado de `llamar_gemini`).
#' @return lista con `clasificacion_final`, `subtipo`, `etiqueta_modelo`.
#' @keywords internal
aplicar_regla_AC <- function(respuesta) {
  aplica <- es_si(respuesta$aplica_muestreo_inferencial)
  A      <- es_si(respuesta$muestreo_no_probabilistico)
  B      <- es_si(respuesta$advierte_limites_muestreo)
  C      <- es_si(respuesta$extrapola_a_poblacion)
  etiqueta <- as.character(respuesta$clasificacion_inferencial %||% "")

  if (isFALSE(aplica) || identical(toupper(etiqueta), "NO APLICA")) {
    return(list(
      clasificacion_final = "No aplica",
      subtipo             = NA_character_,
      etiqueta_modelo     = etiqueta
    ))
  }
  if (isTRUE(A) && isTRUE(C)) {
    sub <- if (isTRUE(B)) "FF con reconocimiento (advierten pero generalizan igual)"
           else if (isFALSE(B)) "FF clasica (no advierten + generalizan)"
           else NA_character_
    return(list(
      clasificacion_final = "Falla fuerte",
      subtipo             = sub,
      etiqueta_modelo     = etiqueta
    ))
  }
  # No es FF: usar la etiqueta textual del modelo para distinguir DI vs SFR
  if (grepl("debilidad", etiqueta, ignore.case = TRUE)) {
    return(list(clasificacion_final = "Debilidad importante",
                subtipo = NA_character_, etiqueta_modelo = etiqueta))
  }
  if (grepl("sin falla", etiqueta, ignore.case = TRUE)) {
    return(list(clasificacion_final = "Sin falla relevante",
                subtipo = NA_character_, etiqueta_modelo = etiqueta))
  }
  list(clasificacion_final = "Debilidad importante",
       subtipo = NA_character_,
       etiqueta_modelo = etiqueta)
}


# Operador NULL-coalescente local (R no lo trae nativo).
`%||%` <- function(a, b) if (is.null(a)) b else a
