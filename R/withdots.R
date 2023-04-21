
#' Give a [function] `...` if it does not have it
#'
#' Puts [`...`][dots] in the [formals()] of a [closure] (i.e., a non-[primitive]
#' [function]) if it does not have it already.
#'
#' If [`formals`]`(f)` already contains [`...`][dots] then it [return]s `f` with
#' no changes.
#'
#' Otherwise:
#'
#' 1. First, [`attributes`]`(f)` are temporarily saved and set aside.
#'
#' 1. [`...`][dots] is added to the [formals()] of `f` using [`formals<-`].
#'
#' 1. The saved [attributes] are added back to `f` with [`attributes<-`].
#'
#' 1. `f` is returned.
#'
#' This does not work with [primitive] functions since they have no [formals()].
#' It only works with [closure]s. Consider pre-processing [primitive]s with
#' [rlang::as_closure()], but keep in mind that argument matching may be
#' different from what is expected since any given primitive may have its own
#' special argument matching behavior (e.g., [switch()], [call()]).
#'
#' @param f A [closure]: a [function] that is not [primitive]. Must satisfy
#'   [`is.function`]`(f)` and `!`[`is.primitive`]`(f)`. Consider pre-processing
#'   with [rlang::as_closure()].
#'
#' @return A [closure].
#'
#' @examples
#' # The base::match() function:
#' match
#'
#' # Can't handle extraneous arguments
#' if (FALSE) {
#'   match("z", letters, cannot_handle_ = "junk arguments")
#' }
#'
#' # match() with dots:
#' match_with_dots <- withdots(match)
#'
#' # Can now handle extraneous arguments:
#' match_with_dots("z", letters, can_now_handle = "junk arguments")
#' @export
withdots <- function(f) {
  if (!is.function(f)) {
    stop("f is not a function.",
         "\nConsider passing to rlang::as_function() first.",
         call. = FALSE)
  }

  if (is.primitive(f)) {
    stop("f cannot be primitive.",
         "\nConsider passing to rlang::as_closure() first",
         call. = FALSE)
  }

  if (any(names(formals(f)) == "...")) {
    return(f)
  }

  a <- attributes(f)

  formals(f)[["..."]] <- quote(expr = )

  attributes(f) <- a

  f
}
