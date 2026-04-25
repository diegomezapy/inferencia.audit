# Shiny app de inferencia.audit
# Despliegue: shinyapps.io con secret GOOGLE_API_KEY configurado en el panel.

library(shiny)
library(inferencia.audit)

source("i18n.R", local = TRUE)
source("rate_limit.R", local = TRUE)

CSS <- "
.badge-clase { display:inline-block; padding:.5rem 1rem; border-radius:.5rem;
               font-weight:700; font-size:1.1rem; color:#fff; }
.badge-FF  { background:#c0392b; }
.badge-DI  { background:#e67e22; }
.badge-SFR { background:#27ae60; }
.badge-NA  { background:#7f8c8d; }
.aviso { color:#7f8c8d; font-size:.85rem; margin-top:.5rem; }
.subtipo { color:#34495e; font-style:italic; margin-top:.25rem; }
.contenedor { max-width: 880px; margin: 1rem auto; }
"

ui <- fluidPage(
  tags$head(tags$style(HTML(CSS))),
  div(class = "contenedor",
    fluidRow(
      column(8, h2(textOutput("titulo")),
                p(textOutput("subtitulo"))),
      column(4, align = "right",
                selectInput("lang", label = NULL,
                            choices = c("Espanol" = "es",
                                        "English" = "en",
                                        "Portugues" = "pt"),
                            selected = "es", width = "150px"))
    ),
    hr(),
    fileInput("pdf", label = textOutput("upload_label"),
              accept = ".pdf", buttonLabel = "...",
              placeholder = ""),
    div(class = "aviso", textOutput("upload_hint")),
    div(class = "aviso", textOutput("aviso_privacidad")),
    br(),
    actionButton("analizar", label = NULL,
                 class = "btn-primary",
                 icon = icon("magnifying-glass")),
    br(), br(),
    uiOutput("estado"),
    uiOutput("resultado"),
    hr(),
    div(class = "aviso", textOutput("pie"))
  )
)

server <- function(input, output, session) {

  lang <- reactive(input$lang %||% "es")
  tt   <- function(k, ...) t_(lang(), k, ...)

  output$titulo            <- renderText({ tt("titulo") })
  output$subtitulo         <- renderText({ tt("subtitulo") })
  output$upload_label      <- renderText({ tt("upload_label") })
  output$upload_hint       <- renderText({ tt("upload_hint") })
  output$aviso_privacidad  <- renderText({ tt("aviso_privacidad") })
  output$pie               <- renderText({ tt("pie") })

  observe({
    updateActionButton(session, "analizar", label = tt("boton_analizar"))
  })

  resultado <- reactiveVal(NULL)
  estado    <- reactiveVal(NULL)

  observeEvent(input$analizar, {
    estado(NULL); resultado(NULL)
    req(input$pdf)

    ip <- obtener_ip(session)
    chk <- tryCatch(verificar_y_registrar_consulta(ip),
                    error = function(e) list(ok = FALSE, motivo = "error"))
    if (!isTRUE(chk$ok)) {
      msg <- switch(chk$motivo,
        ip  = tt("error_quota_ip", LIMITE_POR_IP_DIA),
        dia = tt("error_quota_global"),
        mes = tt("error_quota_mensual"),
        "Error")
      estado(div(class = "alert alert-warning", msg))
      return()
    }

    estado(div(class = "alert alert-info", tt("estado_analizando")))

    res <- tryCatch({
      r <- inferencia.audit::evaluar_articulo(
             ruta_pdf = input$pdf$datapath,
             api_key  = Sys.getenv("GOOGLE_API_KEY"))
      try(unlink(input$pdf$datapath, force = TRUE), silent = TRUE)
      r
    }, error = function(e) {
      try(unlink(input$pdf$datapath, force = TRUE), silent = TRUE)
      structure(conditionMessage(e), class = "error_eval")
    })

    if (inherits(res, "error_eval")) {
      estado(div(class = "alert alert-danger", tt("error_api", as.character(res))))
      return()
    }
    estado(NULL)
    resultado(res)
  })

  output$resultado <- renderUI({
    r <- resultado()
    if (is.null(r)) return(NULL)
    clase_key <- switch(r$clasificacion_final,
      "Falla fuerte"          = "FF",
      "Debilidad importante"  = "DI",
      "Sin falla relevante"   = "SFR",
      "No aplica"             = "NA",
      "NA")
    etiqueta <- switch(clase_key,
      FF  = tt("clase_FF"),
      DI  = tt("clase_DI"),
      SFR = tt("clase_SFR"),
      tt("clase_NA"))

    json_str <- jsonlite::toJSON(r$respuesta_completa, auto_unbox = TRUE, pretty = TRUE)

    div(
      h3(tt("titulo_resultado")),
      div(class = paste0("badge-clase badge-", clase_key), etiqueta),
      if (!is.na(r$subtipo)) div(class = "subtipo", r$subtipo) else NULL,
      br(), br(),
      strong(paste0(tt("label_confianza"), ":")), r$nivel_confianza, br(),
      strong(paste0(tt("label_motivo"), ":")), br(),
      tags$blockquote(r$motivo_principal),
      tags$details(
        tags$summary(tt("label_campos")),
        tags$ul(
          tags$li(sprintf("muestreo_no_probabilistico (A) = %s",
                          ifelse(is.na(r$campos_binarios$A_muestreo_no_probabilistico), "?",
                                 ifelse(r$campos_binarios$A_muestreo_no_probabilistico, "Si", "No")))),
          tags$li(sprintf("advierte_limites_muestreo (B) = %s",
                          ifelse(is.na(r$campos_binarios$B_advierte_limites), "?",
                                 ifelse(r$campos_binarios$B_advierte_limites, "Si", "No")))),
          tags$li(sprintf("extrapola_a_poblacion (C) = %s",
                          ifelse(is.na(r$campos_binarios$C_extrapola_a_poblacion), "?",
                                 ifelse(r$campos_binarios$C_extrapola_a_poblacion, "Si", "No")))),
          tags$li(sprintf("aplica_muestreo_inferencial = %s",
                          ifelse(is.na(r$campos_binarios$aplica_muestreo_inferencial), "?",
                                 ifelse(r$campos_binarios$aplica_muestreo_inferencial, "Si", "No"))))
        )
      ),
      br(),
      downloadLink("descargar_json", tt("label_descargar_json")),
      br(), br(),
      tags$details(
        tags$summary(tt("label_metodologia")),
        tags$pre(prompt_v41())
      )
    )
  })

  output$descargar_json <- downloadHandler(
    filename = function() "inferencia_audit_resultado.json",
    content = function(file) {
      r <- resultado()
      if (is.null(r)) return()
      jsonlite::write_json(r$respuesta_completa, file, auto_unbox = TRUE, pretty = TRUE)
    }
  )

  output$estado <- renderUI({ estado() })
}

shinyApp(ui, server)
