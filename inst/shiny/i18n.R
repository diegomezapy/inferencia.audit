# Diccionarios de traduccion para la UI (no para el prompt enviado a la IA).
# El prompt se mantiene siempre en espanol calibrado v4.1 para paridad
# metodologica con la tesis.

I18N <- list(

  es = list(
    titulo                = "inferencia.audit",
    subtitulo             = "Auditoria automatizada de fallas en muestreo e inferencia estadistica",
    selector_idioma       = "Idioma",
    upload_label          = "Subir articulo en PDF",
    upload_button         = "Examinar...",
    upload_hint           = "Maximo 20 MB. Solo se enviara el texto a la API; el archivo no se guarda.",
    aviso_privacidad      = paste0(
      "Aviso: el texto extraido del PDF se envia al modelo Gemini para analisis. ",
      "Ningun archivo se almacena en el servidor."),
    boton_analizar        = "Analizar articulo",
    estado_analizando     = "Analizando con el modelo (~10 segundos)...",
    titulo_resultado      = "Resultado",
    label_clasificacion   = "Clasificacion",
    label_subtipo         = "Subtipo",
    label_confianza       = "Confianza",
    label_motivo          = "Motivo principal",
    label_campos          = "Campos auxiliares",
    label_descargar_json  = "Descargar resultado (JSON)",
    label_metodologia     = "Ver protocolo metodologico (v4.1)",
    error_quota_ip        = "Has alcanzado el limite de %d analisis por dia desde tu IP. Intenta manana.",
    error_quota_global    = "El servicio alcanzo el cupo diario gratuito. Intenta manana.",
    error_quota_mensual   = "El servicio alcanzo el cupo mensual. Intenta el primer dia del mes proximo.",
    error_pdf             = "No se pudo procesar el PDF: %s",
    error_api             = "Error en la llamada al modelo: %s",
    pie                   = "Paquete R inferencia.audit. Tesis Doctoral en Ciencias, FACEN-UNA.",
    clase_FF              = "Falla fuerte",
    clase_DI              = "Debilidad importante",
    clase_SFR             = "Sin falla relevante",
    clase_NA              = "No aplica"
  ),

  en = list(
    titulo                = "inferencia.audit",
    subtitulo             = "Automated audit of sampling and inference flaws",
    selector_idioma       = "Language",
    upload_label          = "Upload article (PDF)",
    upload_button         = "Browse...",
    upload_hint           = "Max 20 MB. Only the extracted text is sent to the API; the file is not stored.",
    aviso_privacidad      = paste0(
      "Notice: the text extracted from your PDF is sent to the Gemini model for analysis. ",
      "No file is kept on the server."),
    boton_analizar        = "Analyze article",
    estado_analizando     = "Analyzing with the model (~10 seconds)...",
    titulo_resultado      = "Result",
    label_clasificacion   = "Classification",
    label_subtipo         = "Subtype",
    label_confianza       = "Confidence",
    label_motivo          = "Main reason",
    label_campos          = "Auxiliary fields",
    label_descargar_json  = "Download result (JSON)",
    label_metodologia     = "See methodological protocol (v4.1)",
    error_quota_ip        = "You have reached the limit of %d analyses per day from your IP. Try again tomorrow.",
    error_quota_global    = "The service has reached its free daily quota. Try again tomorrow.",
    error_quota_mensual   = "The service has reached its monthly quota. Try again on the first day of next month.",
    error_pdf             = "PDF could not be processed: %s",
    error_api             = "Error calling the model: %s",
    pie                   = "R package inferencia.audit. Doctoral Dissertation, FACEN-UNA.",
    clase_FF              = "Strong flaw (Falla fuerte)",
    clase_DI              = "Important weakness (Debilidad importante)",
    clase_SFR             = "No relevant flaw (Sin falla relevante)",
    clase_NA              = "Not applicable (No aplica)"
  ),

  pt = list(
    titulo                = "inferencia.audit",
    subtitulo             = "Auditoria automatizada de falhas em amostragem e inferencia estatistica",
    selector_idioma       = "Idioma",
    upload_label          = "Enviar artigo em PDF",
    upload_button         = "Procurar...",
    upload_hint           = "Maximo 20 MB. Apenas o texto extraido e enviado a API; o arquivo nao e armazenado.",
    aviso_privacidad      = paste0(
      "Aviso: o texto extraido do PDF e enviado ao modelo Gemini para analise. ",
      "Nenhum arquivo e mantido no servidor."),
    boton_analizar        = "Analisar artigo",
    estado_analizando     = "Analisando com o modelo (~10 segundos)...",
    titulo_resultado      = "Resultado",
    label_clasificacion   = "Classificacao",
    label_subtipo         = "Subtipo",
    label_confianza       = "Confianca",
    label_motivo          = "Motivo principal",
    label_campos          = "Campos auxiliares",
    label_descargar_json  = "Baixar resultado (JSON)",
    label_metodologia     = "Ver protocolo metodologico (v4.1)",
    error_quota_ip        = "Voce atingiu o limite de %d analises por dia a partir do seu IP. Tente amanha.",
    error_quota_global    = "O servico atingiu a cota diaria gratuita. Tente amanha.",
    error_quota_mensual   = "O servico atingiu a cota mensal. Tente no primeiro dia do mes seguinte.",
    error_pdf             = "Nao foi possivel processar o PDF: %s",
    error_api             = "Erro ao chamar o modelo: %s",
    pie                   = "Pacote R inferencia.audit. Tese de Doutorado, FACEN-UNA.",
    clase_FF              = "Falha forte (Falla fuerte)",
    clase_DI              = "Fraqueza importante (Debilidad importante)",
    clase_SFR             = "Sem falha relevante (Sin falla relevante)",
    clase_NA              = "Nao aplica (No aplica)"
  )
)

t_ <- function(lang, key, ...) {
  dic <- I18N[[lang]] %||% I18N$es
  msg <- dic[[key]] %||% I18N$es[[key]] %||% key
  if (length(list(...))) sprintf(msg, ...) else msg
}

`%||%` <- function(a, b) if (is.null(a)) b else a
