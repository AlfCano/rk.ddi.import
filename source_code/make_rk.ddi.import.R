local({
  # =========================================================================================
  # 1. Setup and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  plugin_name <- "rk.ddi.import"

  about_info <- rk.XML.about(
    name = plugin_name,
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "Applies variable labels and factor levels (responses) to an existing data.frame by reading a DDI/XML file. Highly optimized for massive datasets.",
      version = "0.0.5",
      date = format(Sys.Date(), "%Y-%m-%d"),
      url = "https://github.com/AlfCano/rk.ddi.import",
      license = "GPL (>= 3)"
    )
  )

  dependencies_node <- rk.XML.dependencies(
    dependencies = list(R.min = "3.5.0"),
    package = list(
      c(name = "xml2"),
      c(name = "dplyr"),
      c(name = "purrr"),
      c(name = "tibble")
    )
  )

  # =========================================================================================
  # 2. R Helper Functions (¡CORREGIDO EL ORDEN PARA PRESERVAR ETIQUETAS!)
  # =========================================================================================
  r_helpers_code <- '
    trim_ws <- function(x) { gsub("^\\\\s+|\\\\s+$", "", gsub("\\\\s+", " ", x)) }

    resolver_var_key <- function(col_name, x, vars_tbl, val_labs = NULL) {
      cand_name <- vars_tbl$var[vars_tbl$var == col_name]
      cand_label <- vars_tbl$var[vars_tbl$var_label == col_name]
      orig <- attr(x, "original_name")
      cand_attr <- if (!is.null(orig) && orig %in% vars_tbl$var) orig else character(0)

      candidatos <- unique(c(cand_name, cand_label, cand_attr))
      if (length(candidatos) == 0) return(NA_character_)
      if (length(candidatos) == 1) return(candidatos)

      if (is.null(val_labs)) {
        if (col_name %in% candidatos) return(col_name)
        return(candidatos[1])
      }

      # OPTIMIZACIÓN 1: Solo analizamos los valores únicos, evitando evaluar miles de filas
      vals_chr <- as.character(unique(x[!is.na(x)]))

      puntajes <- vapply(candidatos, function(vk) {
        vl <- dplyr::filter(val_labs, var == vk)
        cod_chr <- as.character(suppressWarnings(as.numeric(vl$code)))
        if (all(is.na(cod_chr))) cod_chr <- as.character(vl$code)
        length(intersect(vals_chr, cod_chr))
      }, FUN.VALUE = numeric(1))
      candidatos[which.max(puntajes)]
    }

    # OPTIMIZACIÓN 2: Una sola función maestra
    apply_ddi_metadata <- function(df, xml_path, mode = c("character", "factor")) {
      mode <- match.arg(mode)
      doc <- xml2::read_xml(sub("^file:/+","", xml_path))

      # OPTIMIZACIÓN 3: XPath de dos pasos (Corregido el error de comillas)
      dscr_node <- xml2::xml_find_first(doc, "//*[local-name()=\'dataDscr\']")
      if (!is.na(dscr_node)) {
          var_nodes <- xml2::xml_find_all(dscr_node, "./*[local-name()=\'var\']")
      } else {
          var_nodes <- xml2::xml_find_all(doc, "//*[local-name()=\'var\']")
      }

      vars_tbl <- purrr::map_df(var_nodes, function(vnode) {
        vname <- xml2::xml_attr(vnode, "name")
        if (is.na(vname) || vname == "") vname <- xml2::xml_text(xml2::xml_find_first(vnode, ".//*[local-name()=\'name\' or local-name()=\'Name\']"))
        vlabel <- xml2::xml_text(xml2::xml_find_first(vnode, ".//*[local-name()=\'labl\' or local-name()=\'Labl\' or local-name()=\'label\' or local-name()=\'Label\']"))
        tibble::tibble(var = trim_ws(vname), var_label = trim_ws(vlabel))
      }) %>% dplyr::filter(var != "") %>% dplyr::distinct(var, .keep_all = TRUE)

      val_labs <- purrr::map_df(var_nodes, function(vnode) {
        vname <- xml2::xml_attr(vnode, "name")
        if (is.na(vname) || vname == "") vname <- xml2::xml_text(xml2::xml_find_first(vnode, ".//*[local-name()=\'name\' or local-name()=\'Name\']"))
        vname <- trim_ws(vname)
        cats <- xml2::xml_find_all(vnode, ".//*[local-name()=\'catgry\' or local-name()=\'Catgry\']")
        if (length(cats) == 0) return(tibble::tibble(var = character(), code = character(), label = character(), ord = integer()))
        purrr::map_df(seq_along(cats), function(i) {
          code <- xml2::xml_text(xml2::xml_find_first(cats[[i]], ".//*[local-name()=\'catValu\' or local-name()=\'CatValu\']"))
          lab  <- xml2::xml_text(xml2::xml_find_first(cats[[i]], ".//*[local-name()=\'labl\' or local-name()=\'Labl\' or local-name()=\'label\' or local-name()=\'Label\']"))
          tibble::tibble(var = vname, code = trim_ws(code), label = trim_ws(lab), ord = i)
        })
      }) %>% dplyr::filter(var != "", code != "", label != "") %>% dplyr::arrange(var, ord) %>% dplyr::distinct(var, code, .keep_all = TRUE)

      for (col in names(df)) {
        var_key <- resolver_var_key(col, df[[col]], vars_tbl, val_labs)
        if (is.na(var_key)) next

        # PASO 1: APLICAR NIVELES DE FACTOR O TEXTO PRIMERO (para no destruir las etiquetas)
        vl <- dplyr::filter(val_labs, var == var_key)
        if (nrow(vl) > 0) {
            codes_chr <- if (is.numeric(df[[col]]) || is.integer(df[[col]])) as.character(suppressWarnings(as.numeric(vl$code))) else as.character(vl$code)
            lab_map <- vl$label
            names(lab_map) <- codes_chr
            mapped <- lab_map[as.character(df[[col]])]

            if (mode == "character") {
              df[[col]] <- as.character(mapped)
            } else {
              levels_vec <- vl %>% dplyr::arrange(ord) %>% dplyr::pull(label) %>% trim_ws() %>% unique()
              df[[col]] <- factor(mapped, levels = levels_vec, ordered = FALSE)
            }
        }

        # PASO 2: APLICAR ETIQUETA DE VARIABLE AL FINAL (ahora sí se conservará)
        desc <- vars_tbl$var_label[vars_tbl$var == var_key]
        if (length(desc) > 0 && !is.na(desc) && desc != "") {
          try(attr(df[[col]], "label") <- desc, silent=TRUE)
          if (exists("rk.set.label", mode = "function")) rk.set.label(df[[col]], desc)
        }

      }
      return(df)
    }
  '

  # =========================================================================================
  # 3. UI Components
  # =========================================================================================
  var_sel <- rk.XML.varselector(id.name = "var_sel_source")

  inp_df <- rk.XML.varslot("Data Frame to process (Raw Data)", source = var_sel, classes = c("data.frame", "tibble", "tbl_df"), required = TRUE, id.name = "inp_dataframe")
  inp_xml <- rk.XML.browser("Metadata File (XML / DDI)", type = "file", filter = c("*.xml", "*.ddi"), required = TRUE, id.name = "inp_xml_file")

  rad_mode <- rk.XML.radio("Value conversion mode", options = list("Factors (Recommended)" = c(val = "factor", chk = TRUE), "Text (Character)" = c(val = "character")), id.name = "rad_mode")
  save_res <- rk.XML.saveobj("Save result as", initial = "tagged_data", chk = TRUE, id.name = "save_result")

  full_dialog <- rk.XML.dialog(label = "Import DDI Metadata", rk.XML.row(var_sel, rk.XML.col(inp_df, inp_xml, rad_mode, rk.XML.stretch(), save_res)))

  # =========================================================================================
  # 4. JavaScript Generation
  # =========================================================================================
  js_calc <- rk.paste.JS(
    rk.JS.vars(inp_df, inp_xml, rad_mode, save_res),

    echo("# --- Helper Functions Definition ---\n"),
    echo(r_helpers_code),
    echo("\n# ----------------------------------\n\n"),

    echo("# Apply responses and labels simultaneously (Optimized)\n"),
    echo("tagged_data <- apply_ddi_metadata(\n"),
    echo("  df = ", inp_df, ",\n"),
    echo("  xml_path = \"", inp_xml, "\",\n"),
    echo("  mode = \"", rad_mode, "\"\n"),
    echo(")\n\n")
  )

  js_print <- rk.paste.JS(
    rk.JS.vars(save_res),
    echo("rk.header(\"DDI Import Results\")\n"),
    echo("rk.print(paste(\"Created object:\", \"", save_res, "\"))\n"),
    # FIXED: Hardcoded 'tagged_data' based on user fix
    echo("rk.results(head(tagged_data))\n")
  )

  # =========================================================================================
  # 5. Final Skeleton
  # =========================================================================================
  rk.plugin.skeleton(
    about = about_info,
    path = ".",
    xml = list(dialog = full_dialog),
    js = list(require = c("xml2", "dplyr", "purrr", "tibble"), calculate = js_calc, printout = js_print),
    pluginmap = list(name = "Import DDI Metadata", hierarchy = list("data", "Names and Labels")),
    dependencies = dependencies_node,
    create = c("pmap", "xml", "js", "desc", "rkh"),
    overwrite = TRUE,
    load = TRUE
  )
})
