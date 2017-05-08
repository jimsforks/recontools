#' Performes various checks
#'
#' @param path the path to the package
#' @param run_gp run goodpractice tests
#' @export
check_package <- function(path = ".", run_gp = FALSE) {
  stopifnot(length(path) == 1, is.character(path))
  if (run_gp) {
    if ("goodpractice" %in% utils::installed.packages()) {
      message("Running goodpractice::gp")
      message("--------------------------")
      print(goodpractice::gp(path = path))
      message("--------------------------")
      if(!ask_to_continue()) {
        return()
      }
    } else {
      message("Please consider installing `goodpractice`")
      message("devtools::install_github('MangoTheCat/goodpractice')")
    }
    message("")
  }
  message("Running RECON specific tests:")
  ok <- check_at_least_one_markdown_vignette(path)

  ok <- ok & check_no_imports(path)

  ok <- ok & check_news_file(path)

  ok <- ok & check_tests(path)

  message("")
  if (!ok) {
    message("Consider fixing the issues identified above.")
    tpl <- "However, your package is already ${adjective}!"
    message(praise::praise(template = tpl))
  } else {
    message("All good. ",
            praise::praise(template = "Your package is ${adjective}!"))
  }
}

ask_to_continue <- function() {
  if (!interactive()) {
    return(TRUE)
  }
  res <- readline("Press enter to continue or type :q to quit")
  res != ":q"
}

check_at_least_one_markdown_vignette <- function(path) {
  vignette_path <- file.path(path, "vignettes")
  vignettes <- list.files(vignette_path, pattern = "\\.Rmd$")
  ok <- length(vignettes) > 0
  message_test(ok, "Packages should have at least one rmarkdown vignette")
  ok
}

check_no_imports <- function(path) {
  if (file.exists(file.path(path, "NAMESPACE"))) {
    res <- base::parseNamespaceFile(path, ".")
    ok <- length(res$imports) == 0
    message_test(ok, paste0("Packages should not import ",
                            "functions in NAMESPACE but use :: instead"))
    ok
  } else {
    TRUE
  }
}

check_news_file <- function(path) {
  ok <- file.exists(file.path(path, "NEWS.md"))
  message_test(ok, paste0("Packages should have a NEWS.md file"))
  ok
}

check_tests <- function(path) {
  ok <- dir.exists(file.path(path, "tests"))
  message_test(ok, paste0("Packages should have tests"))
  ok
}

check_conduct <- function(path) {
  ok <- file.exists(file.path(path, "CONDUCT.md"))
  message_test(ok, paste0("Packages should have a CONDUCT.md file"))
  ok
}

message_test <- function(result, text) {
  if (!result) {
    result <- crayon::red("x")
  } else {
    result <- crayon::green("\u2713")
  }
  message("   ", result, " ", text)
}
