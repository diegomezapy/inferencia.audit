test_that("prompt_v41() devuelve cadena no vacia con marcadores clave", {
  p <- prompt_v41()
  expect_type(p, "character")
  expect_true(nzchar(p))
  expect_match(p, "FALLA FUERTE", fixed = TRUE)
  expect_match(p, "DEBILIDAD IMPORTANTE", fixed = TRUE)
  expect_match(p, "SIN FALLA RELEVANTE", fixed = TRUE)
  expect_match(p, "PASO 1", fixed = TRUE)
  expect_match(p, "PASO 2", fixed = TRUE)
})

test_that("es_si normaliza variantes de Si/No", {
  expect_true(inferencia.audit:::es_si("Si"))
  expect_true(inferencia.audit:::es_si("Sí"))
  expect_true(inferencia.audit:::es_si("SI"))
  expect_true(inferencia.audit:::es_si("yes"))
  expect_false(inferencia.audit:::es_si("No"))
  expect_false(inferencia.audit:::es_si("NO"))
  expect_true(is.na(inferencia.audit:::es_si("No aplica")))
  expect_true(is.na(inferencia.audit:::es_si("")))
})

test_that("aplicar_regla_AC clasifica FF cuando A & C, ignorando B", {
  base <- list(
    aplica_muestreo_inferencial   = "Si",
    muestreo_no_probabilistico    = "Si",
    extrapola_a_poblacion         = "Si",
    clasificacion_inferencial     = "Debilidad importante"  # etiqueta del modelo, deberia ser sobreescrita
  )

  r1 <- inferencia.audit:::aplicar_regla_AC(c(base, list(advierte_limites_muestreo = "No")))
  expect_equal(r1$clasificacion_final, "Falla fuerte")
  expect_match(r1$subtipo, "clasica")

  r2 <- inferencia.audit:::aplicar_regla_AC(c(base, list(advierte_limites_muestreo = "Si")))
  expect_equal(r2$clasificacion_final, "Falla fuerte")
  expect_match(r2$subtipo, "reconocimiento")
})

test_that("aplicar_regla_AC respeta No aplica", {
  r <- inferencia.audit:::aplicar_regla_AC(list(
    aplica_muestreo_inferencial   = "No",
    clasificacion_inferencial     = "No aplica"
  ))
  expect_equal(r$clasificacion_final, "No aplica")
})

test_that("parsear_json_tolerante maneja JSON envuelto en markdown", {
  inner <- '{"a": 1, "b": "hola"}'
  envuelto <- paste0("```json\n", inner, "\n```")
  res <- inferencia.audit:::parsear_json_tolerante(envuelto)
  expect_equal(res$a, 1)
  expect_equal(res$b, "hola")
})

test_that("aplicar_regla_AC cubre los 4 escenarios canonicos sin llamar a la API", {
  base <- list(
    aplica_muestreo_inferencial = "Si",
    nivel_confianza_clasificacion = "Alta",
    motivo_principal = "test"
  )

  ff_clasica <- inferencia.audit:::aplicar_regla_AC(c(base, list(
    muestreo_no_probabilistico = "Si",
    advierte_limites_muestreo  = "No",
    extrapola_a_poblacion      = "Si",
    clasificacion_inferencial  = "Falla fuerte"
  )))
  expect_equal(ff_clasica$clasificacion_final, "Falla fuerte")
  expect_match(ff_clasica$subtipo, "clasica")

  ff_hipocrita <- inferencia.audit:::aplicar_regla_AC(c(base, list(
    muestreo_no_probabilistico = "Si",
    advierte_limites_muestreo  = "Si",
    extrapola_a_poblacion      = "Si",
    clasificacion_inferencial  = "Debilidad importante"
  )))
  expect_equal(ff_hipocrita$clasificacion_final, "Falla fuerte")
  expect_match(ff_hipocrita$subtipo, "reconocimiento")

  di <- inferencia.audit:::aplicar_regla_AC(c(base, list(
    muestreo_no_probabilistico = "Si",
    advierte_limites_muestreo  = "Si",
    extrapola_a_poblacion      = "No",
    clasificacion_inferencial  = "Debilidad importante"
  )))
  expect_equal(di$clasificacion_final, "Debilidad importante")
  expect_true(is.na(di$subtipo))

  sfr <- inferencia.audit:::aplicar_regla_AC(c(base, list(
    muestreo_no_probabilistico = "No",
    advierte_limites_muestreo  = "Si",
    extrapola_a_poblacion      = "No",
    clasificacion_inferencial  = "Sin falla relevante"
  )))
  expect_equal(sfr$clasificacion_final, "Sin falla relevante")
})
