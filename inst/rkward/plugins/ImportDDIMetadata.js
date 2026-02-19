// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(xml2)\n");	echo("require(dplyr)\n");	echo("require(purrr)\n");	echo("require(tibble)\n");
}

function calculate(is_preview){
	// read in variables from dialog
	var inpDataframe = getValue("inp_dataframe");
	var inpXmlFile = getValue("inp_xml_file");
	var radMode = getValue("rad_mode");
	var saveResult = getValue("save_result");

	// the R code to be evaluated
	var inpDataframe = getValue("inp_dataframe");
	var inpXmlFile = getValue("inp_xml_file");
	var radMode = getValue("rad_mode");
	var saveResult = getValue("save_result");
	echo("# --- Helper Functions Definition ---\n");
	echo("\n    trim_ws <- function(x) { gsub(\"^\\\\s+|\\\\s+$\", \"\", gsub(\"\\\\s+\", \" \", x)) }\n\n    resolver_var_key <- function(col_name, x, vars_tbl, val_labs = NULL) {\n      cand_name <- vars_tbl$var[vars_tbl$var == col_name]\n      cand_label <- vars_tbl$var[vars_tbl$var_label == col_name]\n      orig <- attr(x, \"original_name\")\n      cand_attr <- if (!is.null(orig) && orig %in% vars_tbl$var) orig else character(0)\n\n      candidatos <- unique(c(cand_name, cand_label, cand_attr))\n      if (length(candidatos) == 0) return(NA_character_)\n      if (length(candidatos) == 1) return(candidatos)\n\n      if (is.null(val_labs)) {\n        if (col_name %in% candidatos) return(col_name)\n        return(candidatos[1])\n      }\n\n      vals_chr <- as.character(x)\n      puntajes <- vapply(candidatos, function(vk) {\n        vl <- dplyr::filter(val_labs, var == vk)\n        cod_chr <- as.character(suppressWarnings(as.numeric(vl$code)))\n        if (all(is.na(cod_chr))) cod_chr <- as.character(vl$code)\n        length(intersect(vals_chr, cod_chr))\n      }, FUN.VALUE = numeric(1))\n      candidatos[which.max(puntajes)]\n    }\n\n    apply_ddi_responses <- function(df, xml_path, mode = c(\"character\", \"factor\")) {\n      mode <- match.arg(mode)\n      doc <- xml2::read_xml(sub(\"^file:/+\",\"\", xml_path))\n\n      var_nodes <- xml2::xml_find_all(doc, \"//*[local-name()='dataDscr']/*[local-name()='var']\")\n      if (length(var_nodes) == 0) var_nodes <- xml2::xml_find_all(doc, \"//*[local-name()='var']\")\n\n      vars_tbl <- purrr::map_df(var_nodes, function(vnode) {\n        vname <- xml2::xml_attr(vnode, \"name\")\n        if (is.na(vname) || vname == \"\") vname <- xml2::xml_text(xml2::xml_find_first(vnode, \".//*[local-name()='name' or local-name()='Name']\"))\n        vlabel <- xml2::xml_text(xml2::xml_find_first(vnode, \".//*[local-name()='labl' or local-name()='Labl' or local-name()='label' or local-name()='Label']\"))\n        tibble::tibble(var = trim_ws(vname), var_label = trim_ws(vlabel))\n      }) %>% dplyr::filter(var != \"\") %>% dplyr::distinct(var, .keep_all = TRUE)\n\n      val_labs <- purrr::map_df(var_nodes, function(vnode) {\n        vname <- xml2::xml_attr(vnode, \"name\")\n        if (is.na(vname) || vname == \"\") vname <- xml2::xml_text(xml2::xml_find_first(vnode, \".//*[local-name()='name' or local-name()='Name']\"))\n        vname <- trim_ws(vname)\n        cats <- xml2::xml_find_all(vnode, \".//*[local-name()='catgry' or local-name()='Catgry']\")\n        if (length(cats) == 0) return(tibble::tibble(var = character(), code = character(), label = character(), ord = integer()))\n        purrr::map_df(seq_along(cats), function(i) {\n          code <- xml2::xml_text(xml2::xml_find_first(cats[[i]], \".//*[local-name()='catValu' or local-name()='CatValu']\"))\n          lab  <- xml2::xml_text(xml2::xml_find_first(cats[[i]], \".//*[local-name()='labl' or local-name()='Labl' or local-name()='label' or local-name()='Label']\"))\n          tibble::tibble(var = vname, code = trim_ws(code), label = trim_ws(lab), ord = i)\n        })\n      }) %>% dplyr::filter(var != \"\", code != \"\", label != \"\") %>% dplyr::arrange(var, ord) %>% dplyr::distinct(var, code, .keep_all = TRUE)\n\n      for (col in names(df)) {\n        var_key <- resolver_var_key(col, df[[col]], vars_tbl, val_labs)\n        if (is.na(var_key)) next\n        vl <- dplyr::filter(val_labs, var == var_key)\n        if (nrow(vl) == 0) next\n\n        codes_chr <- if (is.numeric(df[[col]]) || is.integer(df[[col]])) as.character(suppressWarnings(as.numeric(vl$code))) else as.character(vl$code)\n        lab_map <- vl$label\n        names(lab_map) <- codes_chr\n        mapped <- lab_map[as.character(df[[col]])]\n\n        if (mode == \"character\") {\n          df[[col]] <- as.character(mapped)\n        } else {\n          levels_vec <- vl %>% dplyr::arrange(ord) %>% dplyr::pull(label) %>% trim_ws() %>% unique()\n          df[[col]] <- factor(mapped, levels = levels_vec, ordered = FALSE)\n        }\n      }\n      df\n    }\n\n    apply_ddi_labels <- function(df, xml_path) {\n      doc <- xml2::read_xml(sub(\"^file:/+\",\"\", xml_path))\n      var_nodes <- xml2::xml_find_all(doc, \"//*[local-name()='dataDscr']/*[local-name()='var']\")\n      if (length(var_nodes) == 0) var_nodes <- xml2::xml_find_all(doc, \"//*[local-name()='var']\")\n\n      vars_tbl <- purrr::map_df(var_nodes, function(vnode) {\n        vname <- xml2::xml_attr(vnode, \"name\")\n        if (is.na(vname) || vname == \"\") vname <- xml2::xml_text(xml2::xml_find_first(vnode, \".//*[local-name()='name' or local-name()='Name']\"))\n        vlabel <- xml2::xml_text(xml2::xml_find_first(vnode, \".//*[local-name()='labl' or local-name()='Labl' or local-name()='label' or local-name()='Label']\"))\n        tibble::tibble(var = trim_ws(vname), var_label = trim_ws(vlabel))\n      }) %>% dplyr::filter(var != \"\") %>% dplyr::distinct(var, .keep_all = TRUE)\n\n      for (col in names(df)) {\n        var_key <- resolver_var_key(col, df[[col]], vars_tbl, val_labs = NULL)\n        if (!is.na(var_key)) {\n          desc <- vars_tbl$var_label[vars_tbl$var == var_key]\n          if (length(desc) > 0 && !is.na(desc) && desc != \"\") {\n            try(attr(df[[col]], \"label\") <- desc, silent=TRUE)\n            if (exists(\"rk.set.label\", mode = \"function\")) rk.set.label(df[[col]], desc)\n          }\n        }\n      }\n      return(df)\n    }\n  ");
	echo("\n# ----------------------------------\n\n");
	echo("# 1. Apply response mapping (Values)\n");
	echo("data_tmp <- apply_ddi_responses(\n");
	echo("  df = " + inpDataframe + ",\n");
	echo("  xml_path = \"" + inpXmlFile + "\",\n");
	echo("  mode = \"" + radMode + "\"\n");
	echo(")\n\n");
	echo("# 2. Apply variable labels (Metadata)\n");
	echo("tagged_data <- apply_ddi_labels(\n");
	echo("  df = data_tmp,\n");
	echo("  xml_path = \"" + inpXmlFile + "\"\n");
	echo(")\n\n");
	echo("# Cleanup\n");
	echo("rm(data_tmp)\n");
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Import DDI Metadata results")).print();
	var saveResult = getValue("save_result");
	echo("rk.header(\"DDI Import Results\")\n");
	echo("rk.print(paste(\"Created object:\", \"" + saveResult + "\"))\n");
	echo("rk.results(head(" + saveResult + "))\n");
	//// save result object
	// read in saveobject variables
	var saveResult = getValue("save_result");
	var saveResultActive = getValue("save_result.active");
	var saveResultParent = getValue("save_result.parent");
	// assign object to chosen environment
	if(saveResultActive) {
		echo(".GlobalEnv$" + saveResult + " <- tagged_data\n");
	}

}

