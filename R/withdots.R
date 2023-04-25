
#' Give a [function] [`...`][dots] if it does not have it
#'
#' Adds [`...`][dots] to a [closure]'s [`args`] if it does not have it already.
#'
#' If `f` already has [`...`][dots] in its [`args`], then it is returned with no
#' changes. Otherwise, [`...`][dots] is added to `f`'s [formals] and then `f` is
#' returned. See **Handling of [primitive]s** below.
#'
#' @section How [`...`][dots] is added to [closure]s:
#'
#'   1. First, [`attributes`]`(f)` are temporarily saved and set aside.
#'
#'   1. If there is a [`srcref`] [`attribute`][attr] among the set-aside
#'   [`attributes`]`(f)`, it is removed (see **Why the [`srcref`]
#'   [`attribute`][attr] is removed** below).
#'
#'   1. [`...`][dots] is added to the [formals()] of `f` using [`formals<-`].
#'
#'   1. The remaining set-aside [`attributes`] are added back to `f` with
#'   [`attributes<-`].
#'
#'   1. `f` is returned.
#'
#' @section Handling of [primitive]s: If `f` is [primitive] and already has
#'   [`...`][dots] in its [`args`] (e.g., [c()], [rep()], [max()]), then it is
#'   returned as is.
#'
#'   If `f` is [primitive] and does **not** have [`...`][dots] in its [`args`],
#'   then an error will be thrown. The user can bypass this error by processing
#'   `f` with [rlang::as_closure()] before passing it to `withdots()`.
#'   **However, keep in mind that the argument matching behavior of the
#'   resulting [closure] may be different from what is expected, since
#'   [primitive]s may use nonstandard argument matching.**
#'
#' @section Why the [`srcref`] [`attribute`][attr] is removed: Typically,
#'   [function]s created with [function()] have a [`srcref`]
#'   [`attribute`][attr]. When a [function] is [print]ed, [print.function()]
#'   relies on this [`attribute`][attr] to depict the [function]'s [formals] and
#'   [body].
#'
#'   `withdots()` adds [`...`][dots] via [`formals<-`], which expressly drops
#'   [`attributes`] (see its [documentation page][formals<-]). To prevent this
#'   loss, `withdots()` sets [`attributes`]`(f)` aside and re-attaches them to
#'   `f` at the end. Normally, this would re-attach the original `f`'s
#'   [`srcref`] [`attribute`][attr] to the new `f`, making it so that the new
#'   [`...`][dots] would not be depicted when the new `f` is [print]ed. For this
#'   reason, the old [`srcref`] [`attribute`][attr] is dropped, and only the
#'   remaining [`attributes`] are re-attached.
#'
#'   Observe what would happen during [print]ing if **all** original
#'   [`attributes`]`(f)` were naively added to the modified `f`:
#'
#'   ```{r naive_withdots}
#'   naive_withdots <- function(f) {
#'     old_attributes <- attributes(f)
#'     formals(f)[["..."]] <- quote(expr = )
#'     attributes(f) <- old_attributes
#'     f
#'   }
#'
#'   # Create a function with no dots:
#'   foo <- function(a = 1) {
#'     # Helpful comment
#'     a
#'   }
#'
#'   # Add dots:
#'   foo <- naive_withdots(foo)
#'
#'   # When printed, its dots are not depicted:
#'   foo
#'
#'   # ...but the actual function definitely has dots, since it can handle
#'   # extraneous arguments:
#'   foo(1, 2, junk, "arguments", NULL)
#'
#'   # Remove the "srcref" attribute and, the function is printed accurately:
#'   attr(foo, "srcref") <- NULL
#'   foo
#'   # Success, although the comments in the body() of the function are lost.
#'   ```
#'
#' @param f A [function]. See **Handling of [primitive]s** in case `f` is
#'   [primitive].
#'
#' @return If `f` has [`...`][dots] in it argument list, then `f`. Otherwise, a
#'   [closure]: a tweaked version of `f`, whose only difference is that
#'   [`...`][dots] has been added to the end of its [formals()], and any
#'   [`srcref`] [`attribute`][attr] has been removed (see **Why the [`srcref`]
#'   [`attribute`][attr] is removed** below).
#'
#' @examples
#' # The base::match() function has no ... and can't handle extraneous arguments
#' if (FALSE) {
#'   match("z", letters, cannot_handle_ = "junk arguments")
#' }
#'
#' # But if we give it dots...
#' match_with_dots <- withdots(match)
#'
#' # ...it can now handle extraneous arguments:
#' match_with_dots("z", letters, can_now_handle = "junk arguments")
#' @export
withdots <- function(f) {
  if (!is.function(f)) {
    stop("f must be a function.",
         "\nConsider passing to rlang::as_function() first.",
         call. = FALSE)
  }

  if (is.primitive(f)) {
    if (any(names(formals(args(f))) == "...")) {
      return(f)
    }
    stop("f cannot be a primitive function with no dots in its args().",
         "\nConsider passing to rlang::as_closure() first",
         call. = FALSE)
  }

  if (any(names(formals(f)) == "...")) {
    return(f)
  }

  a <- attributes(f)
  a[["srcref"]] <- NULL

  formals(f)[["..."]] <- quote(expr = )

  attributes(f) <- a

  f
}
