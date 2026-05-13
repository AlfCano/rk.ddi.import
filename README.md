# rk.ddi.import: DDI Metadata Importer for RKWard

![Version](https://img.shields.io/badge/Version-0.0.5-blue.svg)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.ddi.import/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.ddi.import/actions/workflows/lintr.yml)

**rk.ddi.import** is an RKWard plugin designed to streamline the workflow of processing raw survey data. It reads Data Documentation Initiative (DDI) compliant XML files—commonly distributed by statistical agencies like **INEGI (Mexico)**, **DANE (Colombia)**, and others—and automatically applies variable descriptions and value labels to your R data frames.

Stop manually recoding `1 = "Yes"`, `2 = "No"` for hundreds of variables. Let the XML do the work.

## 🚀 What's New in Version 0.0.5

**Crucial Bug Fixes for Metadata Preservation**
*   **Persistent Factor Labels:** Fixed a native R quirk where converting a column into a `factor` would silently strip away its variable label (`attr(..., "label")`). The internal engine now applies factor levels *before* injecting the variable description, ensuring your categorical data retains 100% of its official metadata for downstream tables and plots.
*   **Output Preview Fix:** Resolved a bug in the RKWard output window where the `head()` data preview would fail to display the newly tagged dataset if the user changed the default output name.

## 🚀 What's New in Version 0.0.4

**Extreme Performance Optimization for Massive Datasets (Big Data Ready)**
* **Lightning Fast Mapping:** Processing massive national surveys (like INEGI's ENUT with ~100,000 rows) used to crash the GUI or take forever. The internal engine was rewritten to evaluate only `unique()` values per column, dropping processing time to just a few seconds.
* **Optimized XML Parsing:** The plugin now uses a two-step XPath search (`xml_find_first` -> `xml_find_all`) and caches the giant metadata dictionaries locally, preventing R from reading the heavy XML files twice.
* **Syntax Bulletproofing:** Fixed underlying JavaScript escaping bugs (*backslash hell*) ensuring 100% stable R code generation regardless of the variable names.

## 🚀 What's New in Version-0.0.3

Fixes dependencies for r-universe construction.

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

### 4. Ecosystem Synergy
*   Works perfectly alongside the **`rk.names.labels`** plugin to fix common case-sensitivity mismatches (e.g., converting lowercase CSV headers to uppercase to match the XML definitions) before importing the metadata.

### 5. Big Data Performance
*   **Highly Optimized Engine:** Thanks to vectorized matching and `dplyr` filtering, the plugin effortlessly handles gigantic datasets (90,000+ rows and hundreds of columns) using minimal RAM, avoiding the common freezes associated with GUI data editors.

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

### Basic Workflow
1.  **Select Raw Data:** Choose the dataframe currently loaded in R that contains the raw numbers.
2.  **Select Metadata:** Browse for the `.xml` file provided by the statistical agency.
3.  **Choose Mode:** Select "Factors" (recommended for analysis) or "Text".
4.  **Run:** The plugin will create a new, fully labeled dataframe.

---

### 🇲🇽 Real-World Example: INEGI's ENOE & ENUT (Mexico)

A common issue when downloading massive open datasets from agencies like INEGI (such as the National Survey of Occupation and Employment - ENOE, or the National Time Use Survey - ENUT) is that the CSV headers are often in **lowercase**, while their DDI XML dictionaries define variables in **UPPERCASE**.

Here is the bulletproof workflow using RKWard:

**Step 1: Download the Data**
*   Download the raw CSV dataset (e.g., `SDEMT125.csv`) and the DDI XML file (e.g., `ENOE_T1_2025_V01.xml`) from the INEGI Microdata portal.
*   Import the CSV into RKWard (it will load as numeric codes).

**Step 2: Fix the Case Mismatch (The Secret Step)**
*   Open the **`rk.names.labels`** plugin (install it from GitHub if you haven't).
*   Go to **Data -> Names and Labels -> Tidy Names and Labels**.
*   Select your imported ENOE dataframe.
*   Under the **Transformations** tab, set *Case Conversion* to **Uppercase (toupper)**.
*   Click **Submit**. Your dataframe columns are now uppercase (e.g., `EST`).

**Step 3: Apply the DDI Magic**
*   Open **Data -> Names and Labels -> Import DDI Metadata**.
*   Select your new uppercase dataframe.
*   Browse and select the INEGI `.xml` file.
*   Set Mode to **Factor** and click **Submit**.

**The Result:** Go to your RKWard Workspace. Your numeric column `EST` (10, 20, 30) has magically transformed into labeled factors (`"Estrato bajo"`, `"Estrato medio bajo"`, etc.), and all columns have their official descriptions attached!

## 🛠️ Dependencies

This plugin relies on the following R packages:
*   `xml2` (Parsing XML structures)
*   `dplyr` (Data manipulation)
*   `purrr` (Functional programming/mapping)
*   `tibble` (Data frame handling)
*   `rkwarddev` (Plugin generation)

#### Troubleshooting: Errors installing `devtools` or missing binary dependencies (Windows)

If you encounter errors mentioning "non-zero exit status", "namespace is already loaded", or requirements for compilation (compiling from source) when installing packages, it is usually because the R version bundled with your current RKWard installation is older than the current CRAN standard.

**Recommended Solution: Update RKWard**
Simply update your software to **RKWard 0.8.3 or newer**. This modern release comes bundled with **R 4.5.3**, which perfectly supports the latest pre-compiled CRAN binaries out of the box. This completely eliminates the need for `RTools` and manual compilation.

**Alternative Workaround (Custom R Version):**
RKWard 0.8.3 is also fully compatible with newer releases like **R 4.6**. If you prefer to use a standalone, cutting-edge version of R instead of the bundled one:

1.  Download and install your desired R version from [CRAN](https://cloud.r-project.org/).
2.  Open RKWard and go to the **Settings** (or Preferences) menu.
3.  Run the **"Installation Checker"**.
4.  Point RKWard to the newly installed R version.

This "two-step" setup (similar to how RStudio operates) ensures you always have access to the exact R version you need for your research.

## ✍️ Author & License

*   **Author:** Alfonso Cano (<alfonso.cano@correo.buap.mx>).
*   **Co-author:** Juan Felipe Duque.
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)
