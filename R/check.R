#' Performes various checks
#'
#' @param path the path to the package
#' @param run_gp run goodpractice tests
#' @export
check_package <- function(path = ".", run_gp = FALSE) {
  stopifnot(length(path) == 1, is.character(path))
  package <- devtools::as.package(path)
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
      message("remotes::install_github('MangoTheCat/goodpractice')")
    }
    message("")
  }
  message("Running RECON specific tests:")

  checks <- list(
    check_at_least_one_markdown_vignette,
    check_no_imports,
    check_news_file,
    check_tests,
    check_roxygen2,
    check_snake_case,
    check_url,
    check_bugreports,
    check_docs,
    check_travis,
    check_appveyor
  )
  ok <- Reduce("&", Map(function(f) f(package), checks))

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

check_at_least_one_markdown_vignette <- function(package) {
  path <- package$path
  vignette_path <- file.path(path, "vignettes")
  vignettes <- list.files(vignette_path, pattern = "\\.Rmd$")
  ok <- length(vignettes) > 0
  message_test(ok, "Packages should have at least one rmarkdown vignette")
}

check_no_imports <- function(package) {
  path <- package$path
  if (file.exists(file.path(path, "NAMESPACE"))) {
    ns <- parseNamespaceFile(basename(path), dirname(path), mustExist = FALSE)
    ok <- length(ns$imports) == 0
    message_test(ok, paste0("Packages should not import ",
                            "functions in NAMESPACE but use :: instead"))
    ok
  } else {
    TRUE
  }
}

check_url <- function(package) {
  ok <- !is.null(package$url) &&
    length(package$url) == 1 &&
    nchar(package$url) > 0
  message_test(ok, "Packages should have a URL in the DESCRIPTION")
}

check_bugreports <- function(package) {
  ok <- !is.null(package$bugreports) &&
    length(package$bugreports) == 1 &&
    nchar(package$bugreports) > 0
  msg <- "Packages should have a URL for bugreports in the DESCRIPTION"
  message_test(ok, msg)
}

check_news_file <- function(package) {
  path <- package$path
  ok <- file.exists(file.path(path, "NEWS.md"))
  message_test(ok, "Packages should have a NEWS.md file")
}

check_snake_case <- function(package) {
  path <- package$path
  ok <- file.exists(file.path(path, "NAMESPACE"))
  if (ok) {
    ns <- parseNamespaceFile(basename(path), dirname(path), mustExist = FALSE)
    ok <- !any(grepl(x = ns$exports, pattern = ".", fixed = TRUE))
  }
  message_test(ok, "Packages should use snake case in exported functions")
}

check_tests <- function(package) {
  path <- package$path
  ok <- dir.exists(file.path(path, "tests"))
  message_test(ok, "Packages should have tests")
}

check_conduct <- function(package) {
  path <- package$path
  ok <- file.exists(file.path(path, "CONDUCT.md"))
  message_test(ok, "Packages should have a CONDUCT.md file")
}

check_roxygen2 <- function(package) {
  ok <- !is.null(package$roxygennote)
  message_test(ok, "Packages should use roxygen2")
}

check_travis <- function(package) {
  ok <- file.exists(file.path(package$path, ".travis.yml"))
  message_test(ok, "Packages should use travis CI for Linux/Mac testing")
}

check_appveyor <- function(package) {
  ok <- file.exists(file.path(package$path, ".travis.yml"))
  message_test(ok, "Packages should use appveyor CI for Windows testing")
}

check_docs <- function(package) {
  path <- package$path
  ok <- dir.exists(file.path(path, "docs"))
  if (!ok) {
    # check if git branch exists
    if (git2r::in_repository(path)) {
      repo <- git2r::repository(path)
      branches <- git2r::branches(repo, flags = "local")
      ok <- any(vapply(branches, function(x) x@name == "gh-pages", logical(1)))
    }
  }
  message_test(ok, "Packages should have a docs folder or a gh-pages branch.")
}

message_test <- function(result, text) {
  if (!result) {
    result_icon <- crayon::red("x")
  } else {
    result_icon <- crayon::green("\u2713")
  }
  message("   ", result_icon, " ", text)
  result
}

