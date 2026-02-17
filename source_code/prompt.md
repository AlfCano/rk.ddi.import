# The Golden Rules of RKWard Plugin Development (v2.0)

*For `rkwarddev` versions 0.08+*

## Part I: The Foundation

### 1. The R Script is the Single Source of Truth
Your output is **one single R script** wrapped in `local({})`.
*   It defines dependencies (`require(rkwarddev)`).
*   It defines metadata (`rk.XML.about`).
*   It generates all XML, JavaScript, and Help files via `rk.plugin.skeleton()`.
*   **Never** manually edit the generated `.xml` or `.js` files; always adjust the generating R script.

### 2. The Mandate of Explicit IDs
Every interactive UI element (`varslot`, `input`, `cbox`, `dropdown`, `saveobj`) **must** have a unique, hard-coded `id.name`.
*   **Why:** This prevents "Can't find ID" errors and makes your JavaScript logic readable.
*   **Do not** assign IDs to layout containers (`row`, `col`, `frame`) unless you are dynamically hiding/showing them.

### 3. The Hierarchy Case-Sensitivity Rule
RKWard's internal menu IDs are **case-sensitive** and specific.
*   **Correct:** `hierarchy = list("data", "Data Wrangling")` -> Places it in the standard "Data" menu.
*   **Incorrect:** `hierarchy = list("Data", ...)` -> Creates a *new* top-level menu called "Data" (duplicates the existing one) or falls back to "Test".
*   *Tip:* Always check the RKWard internal ID for existing menus (e.g., `"analysis"`, `"plots"`, `"data"`).

---

## Part II: The Internationalization (i18n) Protocol

This is the most critical addition for distribution. RKWard relies on **gettext**, and `rkwarddev` has specific behaviors you must follow to ensure translations load.

### 4. The `po_id` Generation Logic
By default, `rkwarddev` generates the `po_id` (the internal Translation ID) based on the **visible name** of the pluginmap, not the package name.
*   **The Formula:** `rkwarddev` strips spaces/special characters, CamelCases the name, and appends `_rkward`.
    *   Map Name: `"Batch Transform"` -> ID: `BatchTransform_rkward`
    *   Map Name: `"Summary Table (gtsummary)"` -> ID: `SummaryTablegtsummary_rkward`
*   **The Golden Rule:** To avoid guessing, **explicitly define** the `po_id` in your skeleton call:
    ```r
    pluginmap = list(
        name = "Batch Transform",
        hierarchy = list("data", "Wrangling"),
        po_id = "BatchTransform_rkward" # Explicitly set this!
    )
    ```

### 5. The `.mo` File Naming Convention
The compiled binary translation file must be named **exactly** according to this pattern:
`rkward__` + `[po_id]` + `.mo`

*   **Example:** If `po_id` is `"BatchTransform_rkward"`, the file **must** be:
    `inst/rkward/po/es/LC_MESSAGES/rkward__BatchTransform_rkward.mo`
*   If the filename does not match the `po_id` in the `.pluginmap` XML header, the translation will **never** load.

### 6. The Manual Compilation Fallback
The `rkwarddev` function `rk.updatePluginMessages()` often fails on Windows or specific setups (`sh: 1: -c: not found`) due to missing system dependencies (Python/Gettext).
*   **Golden Rule:** Keep `update.translations <- FALSE` in your script.
*   **Workflow:**
    1.  Generate the plugin.
    2.  Manually create `es.po` (text).
    3.  Compile it to `.mo` using an external tool (Poedit).
    4.  Manually place the `.mo` file in the correct folder structure.

---

## Part III: The JavaScript & R Logic Contract

### 7. The `calculate` vs. `printout` Contract
These two JS sections operate in separate scopes but share specific variables defined by `saveobj`.
*   **The Contract:** The `calculate` block **must** assign the final result to the **hard-coded name** defined in the `initial` argument of your `rk.XML.saveobj`.
    *   XML: `rk.XML.saveobj(..., initial="my_result", id.name="save_ui")`
    *   JS (`calculate`): `echo("my_result <- ...")` **(Correct)**
    *   JS (`calculate`): `var user_name = getValue("save_ui"); echo(user_name + " <- ...")` **(WRONG - Breaks RKWard internal logic)**
*   RKWard automatically handles the assignment from `my_result` to whatever name the user typed in the UI.

### 8. The Three-Level Quoting Rule
When generating R code via JavaScript inside an R script, escaping gets complex.
1.  **Level 1 (R script):** You wrap the JS string in `'...'`.
2.  **Level 2 (JS echo):** You need to print a quote to the R console: `\"`.
3.  **Level 3 (R Variable Access):** If you need to access a list item by name in R (`data[["col"]]`), the quotes inside the brackets need double escaping for the JS engine.
    *   **Target R Code:** `attr(obj[["col"]], ...)`
    *   **JS Code required:** `echo('attr(obj[["col"]], ...)')`
    *   **R Script required:** `echo('attr(obj[[\\\"col\\\"]], ...)')`
    *   **Solution:** Use **single quotes** for R indices where possible to avoid "backslash hell": `obj[['col']]`.

### 9. The Data Preview constraints
Implementing a "Preview" button requires strict constraints to avoid crashing the session or hanging RKWard.
*   **Constraint 1:** Always use `head(50)` (or similar) to limit rows.
*   **Constraint 2:** Explicitly `require()` necessary libraries (`dplyr`, `srvyr`) inside the preview block, as the preview runs in a detached environment.
*   **Constraint 3:** Convert complex objects (like `srvyr` designs) to standard `data.frame`s before printing to the preview window. The previewer often fails to render list-based S3 objects.
    *   *Code:* `echo("preview_data <- my_complex_obj %>% as.data.frame() %>% head(50)\n")`

---

## Part IV: UI Components & UX

### 10. The Matrix Widget Rule
The `rk.XML.matrix` widget is powerful but defaults to strict numeric validation.
*   **The Problem:** If a user types text into a default matrix, it turns red, marks the row invalid, and **disables the Submit button**.
*   **The Fix:** Always set `mode = "string"` if the matrix handles anything other than pure numbers.
*   **The Usability Fix:** Set `min = 0` (or remove `min`) to prevent blocking the Submit button while the user is typing empty rows.

### 11. The Tabbook Layout Strategy
If a plugin has more than 5-6 controls, do not stack them in one column.
*   **Use `rk.XML.tabbook`:**
    *   **Tab 1 (Variables):** Selectors and Slots.
    *   **Tab 2 (Settings/Rules):** Checkboxes, Dropdowns, Matrices.
    *   **Tab 3 (Output):** Save objects, Naming patterns, Previews.
*   **Structure:** Variable selectors usually go in a `row` on the left; the tabbook goes in a `col` on the right.

### 12. Robust "Else" Logic (Recoding)
When recoding variables (e.g., using `case_match`):
*   **Type Mismatch Crash:** If converting Numeric -> Character, the default "copy original value" behavior will crash R because vectors must be atomic (all one type).
*   **The Fix:** If the output type differs from input, the `.default` (Else) value **must** be explicitly cast: `.default = as.character(.)`.

### 13. Handling Spaces in Variables
Users often have messy column names (`"Variable Name"`).
*   **The Fix:** When generating R code for `select` or `across`, always **quote** the variable names in the generated string.
    *   *Bad:* `select(Variable Name)` -> Error.
    *   *Good:* `select("Variable Name")` -> Works.
    *   *Implementation:* In your JS helper, wrap the retrieved value in escaped quotes: `return "\\"" + v + "\\"";`.
