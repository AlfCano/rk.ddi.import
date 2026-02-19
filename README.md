# rk.ddi.import: DDI Metadata Importer for RKWard

![Version](https://img.shields.io/badge/Version-0.0.2-blue.svg)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.ddi.import/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.ddi.import/actions/workflows/lintr.yml)

**rk.ddi.import** is an RKWard plugin designed to streamline the workflow of processing raw survey data. It reads Data Documentation Initiative (DDI) compliant XML files—commonly distributed by statistical agencies like **INEGI (Mexico)**, **DANE (Colombia)**, and others—and automatically applies variable descriptions and value labels to your R data frames.

Stop manually recoding `1 = "Yes"`, `2 = "No"` for hundreds of variables. Let the XML do the work.

## 🚀 What's New in Version-0.0.2

This version **fixes a naming bug**.

## 🚀 What's New in Version 0.0.1

This is the **initial release** of the plugin, focusing on the core functionality of metadata mapping:

*   **XML Parsing Engine:** Robust parsing of DDI-Codebook structure (`<dataDscr>`, `<var>`, `<catgry>`) using the `xml2` package.
*   **Intelligent Matching:** Automatically matches XML definitions to Data Frame columns using variable names or internal original name attributes.
*   **Dual Mode Conversion:** Users can choose between converting coded variables into **R Factors** (with levels ordered as defined in the dictionary) or simple **Character** strings.
*   **RKWard Integration:** Applies variable labels using RKWard's native `rk.set.label()` function, ensuring descriptions appear in the workspace browser and variable view.

## ✨ Features

### 1. Automated Value Labeling (Responses)
Converts numeric codes in your raw data into meaningful text based on the XML dictionary.
*   **Factor Conversion:** Automatically creates factors with proper levels.
*   **Handling Missing Codes:** Logic to handle non-numeric codes often found in surveys (e.g., "NA", "99").
*   **Context:** `df$sex` (1, 2) becomes `df$sex` ("Male", "Female").

### 2. Variable Description Import
Imports the full question text or variable label.
*   **Metadata Injection:** Assigns the `label` attribute to every column found in the XML.
*   **Visualization:** These labels become visible immediately in RKWard's object viewer, making dataset exploration much easier.

### 3. File Support
*   Supports standard `.xml` and `.ddi` files.
*   Optimized for Latin American statistical standards (DANE, INEGI, CEPAL formats).

### 🌍 Internationalization
The interface is fully localized in:
*   🇺🇸 English (Default)
*   🇪🇸 Spanish (`es`)
*   🇫🇷 French (`fr`)
*   🇩🇪 German (`de`)
*   🇧🇷 Portuguese (Brazil) (`pt_BR`)

## 📦 Installation

This plugin is not yet on CRAN. To install it, use the `remotes` or `devtools` package in RKWard.

1.  **Open RKWard**.
2.  **Run the following command** in the R Console:

    ```R
    # If you don't have devtools installed:
    # install.packages("devtools")
    
    local({
      require(devtools)
      install_github("AlfCano/rk.ddi.import", force = TRUE)
    })
    ```
3.  **Restart RKWard** to load the new menu entries.

## 💻 Usage

Once installed, the tool is located under the **Data** menu (standard location for data manipulation tools):

**`Data` -> `Names and Labels` -> `Import DDI Metadata`**

1.  **Select Raw Data:** Choose the dataframe currently loaded in R that contains the raw numbers.
2.  **Select Metadata:** Browse for the `.xml` file provided by the statistical agency.
3.  **Choose Mode:** Select "Factors" (recommended for analysis) or "Text".
4.  **Run:** The plugin will create a new, fully labeled dataframe.

## 🛠️ Dependencies

This plugin relies on the following R packages:
*   `xml2` (Parsing XML structures)
*   `dplyr` (Data manipulation)
*   `purrr` (Functional programming/mapping)
*   `tibble` (Data frame handling)
*   `rkwarddev` (Plugin generation)

#### Troubleshooting: Errors installing `devtools` or missing binary dependencies (Windows)

If you encounter errors mentioning "non-zero exit status", "namespace is already loaded", or requirements for compilation (compiling from source) when installing packages, it is likely because the R version bundled with RKWard is older than the current CRAN standard.

**Workaround:**
Until a new, more recent version of R (current bundled version is 4.3.3) is packaged into the RKWard executable, these issues will persist. To fix this:

1.  Download and install the latest version of R (e.g., 4.5.2 or newer) from [CRAN](https://cloud.r-project.org/).
2.  Open RKWard and go to the **Settings** (or Preferences) menu.
3.  Run the **"Installation Checker"**.
4.  Point RKWard to the newly installed R version.

This "two-step" setup (similar to how RStudio operates) ensures you have access to the latest pre-compiled binaries, avoiding the need for RTools and manual compilation.

## ✍️ Author & License

*   **Author:** Alfonso Cano (<alfonso.cano@correo.buap.mx>).
*   **Co-author:** Juan Felipe Duque.
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)
