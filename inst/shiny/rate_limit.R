# Rate limiting con SQLite. Aplica tres caps simultaneos:
#   - 3 consultas por IP por dia
#   - 200 consultas globales por dia
#   - 3000 consultas globales por mes
# Si shinyapps.io recicla el contenedor, los contadores se resetean (aceptable).

LIMITE_POR_IP_DIA   <- 3L
LIMITE_GLOBAL_DIA   <- 200L
LIMITE_GLOBAL_MES   <- 3000L
DB_PATH             <- file.path(tempdir(), "inferencia_audit_quota.sqlite")

quota_db <- function() {
  con <- DBI::dbConnect(RSQLite::SQLite(), DB_PATH)
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS consultas (
      ts INTEGER NOT NULL,
      ip TEXT NOT NULL,
      dia TEXT NOT NULL,
      mes TEXT NOT NULL
    )")
  DBI::dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_dia ON consultas(dia)")
  DBI::dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_ip_dia ON consultas(ip, dia)")
  DBI::dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_mes ON consultas(mes)")
  con
}

#' Verifica si la IP puede hacer una consulta y registra el evento si pasa.
#'
#' @return list(ok=lgl, motivo=chr|NA, restantes_ip=int, restantes_dia=int, restantes_mes=int)
verificar_y_registrar_consulta <- function(ip) {
  con <- quota_db()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  ahora <- Sys.time()
  dia   <- format(ahora, "%Y-%m-%d")
  mes   <- format(ahora, "%Y-%m")

  n_ip  <- DBI::dbGetQuery(con,
    "SELECT COUNT(*) AS n FROM consultas WHERE ip = ? AND dia = ?",
    params = list(ip, dia))$n
  n_dia <- DBI::dbGetQuery(con,
    "SELECT COUNT(*) AS n FROM consultas WHERE dia = ?",
    params = list(dia))$n
  n_mes <- DBI::dbGetQuery(con,
    "SELECT COUNT(*) AS n FROM consultas WHERE mes = ?",
    params = list(mes))$n

  if (n_ip   >= LIMITE_POR_IP_DIA) return(list(ok = FALSE, motivo = "ip",
    restantes_ip = 0, restantes_dia = LIMITE_GLOBAL_DIA - n_dia, restantes_mes = LIMITE_GLOBAL_MES - n_mes))
  if (n_dia  >= LIMITE_GLOBAL_DIA) return(list(ok = FALSE, motivo = "dia",
    restantes_ip = LIMITE_POR_IP_DIA - n_ip, restantes_dia = 0, restantes_mes = LIMITE_GLOBAL_MES - n_mes))
  if (n_mes  >= LIMITE_GLOBAL_MES) return(list(ok = FALSE, motivo = "mes",
    restantes_ip = LIMITE_POR_IP_DIA - n_ip, restantes_dia = LIMITE_GLOBAL_DIA - n_dia, restantes_mes = 0))

  DBI::dbExecute(con,
    "INSERT INTO consultas (ts, ip, dia, mes) VALUES (?, ?, ?, ?)",
    params = list(as.integer(ahora), ip, dia, mes))

  list(
    ok            = TRUE,
    motivo        = NA_character_,
    restantes_ip  = LIMITE_POR_IP_DIA  - n_ip  - 1L,
    restantes_dia = LIMITE_GLOBAL_DIA  - n_dia - 1L,
    restantes_mes = LIMITE_GLOBAL_MES  - n_mes - 1L
  )
}

#' Extrae IP del cliente de la sesion Shiny (compatible con shinyapps.io)
obtener_ip <- function(session) {
  req <- session$request
  if (is.null(req)) return("unknown")
  fwd <- req$HTTP_X_FORWARDED_FOR
  if (!is.null(fwd) && nzchar(fwd)) return(trimws(strsplit(fwd, ",", fixed = TRUE)[[1]][1]))
  real <- req$HTTP_X_REAL_IP
  if (!is.null(real) && nzchar(real)) return(trimws(real))
  remote <- req$REMOTE_ADDR
  if (!is.null(remote) && nzchar(remote)) return(remote)
  "unknown"
}
