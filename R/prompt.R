#' System prompt v4.1-NTK (calibrado con NotebookLM)
#'
#' Devuelve el prompt de sistema usado por la auditoria de la tesis. Es el mismo
#' texto operacionalizado en `analizar_v41ntk.py` y aplicado a los `2062`
#' articulos de la corrida `rtcoh_20260423`. Se expone como funcion para que la
#' app Shiny y la API publica del paquete usen exactamente la misma fuente de
#' verdad y se mantenga la paridad metodologica con la tesis.
#'
#' @return Cadena de caracteres con el prompt completo.
#' @export
prompt_v41 <- function() {
'Eres un metodologo experto en investigacion cientifica cuantitativa.
Tu tarea es clasificar articulos cientificos segun fallas en diseno muestral e inferencia estadistica.
Debes clasificar cada articulo en dos pasos.

PASO 1. ELEGIBILIDAD
Decide si el articulo pertenece al universo analitico de una auditoria de muestreo inferencial.

Usa aplica_muestreo_inferencial = "Si" solo si:
  - el articulo usa inferencia estadistica;
  - y existe una pregunta real sobre muestreo o base inferencial de unidades observacionales
    relevantes para una poblacion objetivo humana o animal en sentido epidemiologico/social.

Usa aplica_muestreo_inferencial = "No" cuando el articulo sea:
  - Meta-analisis, revisiones sistematicas, umbrella reviews.
  - Series temporales o paneles exhaustivos sin problema muestral clasico.
  - Experimentos de laboratorio, in vitro, ex vivo o con animales de laboratorio.
  - Articulos teoricos, matematicos, simulaciones, benchmarking de modelos/algoritmos.
  - Estudios de caso historicos, arqueologicos, textuales o de cultura material.
  - Estudios ecologicos de campo, monitoreo de fauna/flora, transectos ambientales,
    analisis de biodiversidad o censos ecologicos donde el muestreo es el estandar
    del campo y no representa personas u organizaciones.
  - Estudios de validacion de instrumentos psicometricos o escalas cuyo objetivo
    principal es demostrar validez/confiabilidad, no describir una poblacion.
  - Estudios de tecnologia de alimentos, microbiologia, bromatologia, analisis sensorial
    con paneles de catadores o analisis de productos, donde la muestra es el producto.
  - Estudios traslacionales, preclinicos o mecanisticos con modelos animales, tejidos,
    organoides o muestras clinicas de laboratorio cuya conclusion principal es biologica.
  - Articulos con datos censales o registros administrativos que cubren toda la poblacion.

PASO 2. CLASIFICACION PRINCIPAL
Solo si aplica_muestreo_inferencial = "Si", clasifica usando la siguiente regla de tres condiciones.

===========================================================
FALLA FUERTE - requiere las TRES condiciones simultaneamente:
  [A] Muestreo no probabilistico (conveniencia, voluntarios, consecutivo, intencional,
      bola de nieve) SIN que los autores adviertan sobre el sesgo o limitaciones de ese
      muestreo en ninguna parte del texto (metodos, discusion o limitaciones).
  [B] Extrapolacion explicita: los autores generalizan resultados a una poblacion mas amplia
      (ciudad, pais, profesion, grupo etario) sin justificacion probabilistica.
  [C] Analisis estadistico inferencial aplicado (pruebas de hipotesis, regresion, ANOVA,
      chi-cuadrado) que asume representatividad que la muestra no tiene.

  REGLA ABSOLUTA: Si los autores reconocen EN CUALQUIER PARTE DEL TEXTO que la muestra
  es no probabilistica, tiene limitaciones de representatividad, o que los resultados no
  son generalizables -> condicion [A] NO se cumple -> NO puede ser Falla fuerte.
  En ese caso, la clasificacion maxima es Debilidad importante.
===========================================================

DEBILIDAD IMPORTANTE - cuando hay problemas metodologicos reales pero NO se cumplen
las tres condiciones de Falla fuerte simultaneamente. Incluye:
  - Muestreo no probabilistico con reconocimiento explicito de limitaciones, incluso si
    hay extrapolacion moderada o implicita en la discusion.
  - No declara tipo de muestreo o no justifica tamano muestral, pero sin extrapolacion fuerte.
  - Muestra no probabilistica en estudio preliminar, exploratorio o contextual.
  - Articulo con cautela parcial en conclusiones aunque insuficiente.
  - Estudio descriptivo con base muestral imperfecta pero lenguaje final moderado.
  - Diseno cuasi-experimental sin aleatorizacion pero conclusiones acotadas.
  - Contexto latinoamericano con recursos limitados: muestras pequenas justificadas
    por acceso/recursos, sin generalizacion fuerte -> Debilidad importante, no Falla fuerte.

SIN FALLA RELEVANTE - cuando:
  - Muestreo probabilistico (aleatorio simple, estratificado, sistematico, conglomerados).
  - Uso de bases de datos nacionales/regionales representativas o censos.
  - Diseno experimental controlado con asignacion aleatoria a grupos.
  - Estudio descriptivo que no generaliza mas alla del grupo observado.
  - Limitaciones del muestreo claramente reconocidas Y conclusiones explicitamente
    acotadas al grupo estudiado sin ninguna extrapolacion.
  - Articulo cualitativo (entrevistas, etnografia, analisis del discurso): no busca
    representatividad estadistica -> Sin falla relevante.

REGLAS DE DECISION:
  1. REGLA PRINCIPAL: advierte_limites_muestreo = "Si" -> nunca Falla fuerte -> maximo DI.
  2. Si la extrapolacion es solo implicita o moderada (lenguaje prudente) -> DI, no FF.
  3. En duda entre FF y DI -> siempre preferir DI.
  4. En duda entre DI y SFR -> usar evidencia textual y marcar confianza Media/Baja.
  5. Si aplica_muestreo_inferencial = "No" -> clasificacion_inferencial = "No aplica".
  6. No penalizar tamano muestral pequeno si el muestreo es apropiado para el campo.

INTERPRETACION DE CAMPOS AUXILIARES:
  - extrapola_a_poblacion = "Si" solo si el texto hace afirmacion poblacional EXPLICITA
    que excede la muestra (ej: "los estudiantes universitarios presentan...", "la prevalencia
    en la region es..."). NO marcar "Si" por recomendaciones de estudios futuros o
    sugerencias de politica sin afirmacion directa.
  - muestreo_no_probabilistico = "Si" si el articulo lo declara o si el texto muestra
    claramente reclutamiento por conveniencia, accesibilidad, voluntariado o seleccion
    intencional.
  - advierte_limites_muestreo = "Si" si el articulo reconoce EN CUALQUIER PARTE limitaciones
    de representatividad, generalizacion o sesgo muestral, aunque sea brevemente.

Responde SOLO con el JSON estructurado solicitado, sin texto adicional.'
}


#' Construir prompt de usuario para un articulo concreto
#'
#' @param texto_pdf Cadena con el texto extraido del PDF (truncado a 30k chars).
#' @param nombre_archivo Nombre del archivo (informativo, sin efecto en la decision).
#' @return Cadena con el prompt de usuario.
#' @keywords internal
construir_prompt_usuario <- function(texto_pdf, nombre_archivo = "articulo.pdf") {
  sprintf(
'Analiza el siguiente articulo cientifico y extrae la informacion metodologica solicitada.

Archivo: %s

--- TEXTO DEL ARTICULO ---
%s
--- FIN DEL TEXTO ---

Responde con el JSON estructurado con los campos definidos en el esquema.
Si alguna informacion no esta disponible en el texto, indica "No disponible" o "No declara".
Antes de decidir, verifica explicitamente:
1. El articulo entra al universo de auditoria? (descarta lab, ecologia, validacion, censos)
2. El muestreo es no probabilistico?
3. CRITICO: Los autores reconocen en ALGUNA PARTE limitaciones de representatividad o sesgo?
   Si la respuesta es SI -> clasificacion maxima es Debilidad importante, nunca Falla fuerte.
4. Hay extrapolacion EXPLICITA a una poblacion mas amplia (no solo recomendaciones)?
5. Se aplica inferencia estadistica que asume representatividad?
   Solo si las tres condiciones (no-probabilistico + sin advertencia + extrapolacion)
   se cumplen simultaneamente -> Falla fuerte.
6. El contexto es latinoamericano con recursos limitados? -> mayor tolerancia a DI.
7. Existe evidencia suficiente para Sin falla relevante?
Usa el criterio v4.1-NTK calibrado con NotebookLM.', nombre_archivo, texto_pdf)
}


#' Esquema JSON de respuesta esperada (response schema para Gemini)
#'
#' @keywords internal
response_schema <- function() {
  list(
    type = "object",
    properties = list(
      disciplina                       = list(type = "string"),
      objetivo_general                 = list(type = "string"),
      frase_inferencia                 = list(type = "string"),
      frase_muestreo                   = list(type = "string"),
      tipo_estudio                     = list(type = "string"),
      enfoque_metodologico             = list(type = "string"),
      diseno_estudio                   = list(type = "string"),
      tamano_muestra                   = list(type = "string"),
      es_cuantitativo_con_inferencia   = list(type = "string"),
      muestreo_probabilistico          = list(type = "string"),
      muestreo_no_probabilistico       = list(type = "string"),
      declara_tipo_muestreo            = list(type = "string"),
      declara_calculo_tamano_muestral  = list(type = "string"),
      reporta_intervalos_confianza     = list(type = "string"),
      extrapola_a_poblacion            = list(type = "string"),
      advierte_limites_muestreo        = list(type = "string"),
      aplica_muestreo_inferencial      = list(type = "string"),
      clasificacion_inferencial        = list(type = "string"),
      motivo_principal                 = list(type = "string"),
      nivel_confianza_clasificacion    = list(type = "string"),
      software_estadistico             = list(type = "string"),
      comentario_metodologico          = list(type = "string")
    ),
    required = list(
      "aplica_muestreo_inferencial",
      "clasificacion_inferencial",
      "motivo_principal",
      "nivel_confianza_clasificacion"
    )
  )
}
