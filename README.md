
<!-- README.md is generated from README.Rmd. Please edit that file -->

# withdots

<!-- badges: start -->
<!-- badges: end -->

The `withdots()` function adds `...` to the argument list of a function
if it does not already have it. This lets the function tolerate
extraneous arguments that are passed to it.

## Installation

You can install the development version of withdots like so:

``` r
remotes::install_github("NikKrieger/withdots")
```

## Demo

The base R function `match()` has no `...` in its argument list:

``` r
match
#> function (x, table, nomatch = NA_integer_, incomparables = NULL) 
#> .Internal(match(x, table, nomatch, incomparables))
#> <bytecode: 0x3413c38>
#> <environment: namespace:base>
```

Therefore, it can’t handle extraneous arguments:

``` r
match("z", letters, bad_arg = "error!")
#> Error in match("z", letters, bad_arg = "error!"): unused argument (bad_arg = "error!")
```

But if we give it dots, then it can:

``` r
library(withdots)

match_with_dots <- withdots(match)

match_with_dots("z", letters, can_now_handle = "junk arguments")
#> [1] 26
```

Functions that already have `...` in their argument list are returned as
is:

``` r
lapply
#> function (X, FUN, ...) 
#> {
#>     FUN <- match.fun(FUN)
#>     if (!is.vector(X) || is.object(X)) 
#>         X <- as.list(X)
#>     .Internal(lapply(X, FUN))
#> }
#> <bytecode: 0x189ecb8>
#> <environment: namespace:base>
withdots(lapply)
#> function (X, FUN, ...) 
#> {
#>     FUN <- match.fun(FUN)
#>     if (!is.vector(X) || is.object(X)) 
#>         X <- as.list(X)
#>     .Internal(lapply(X, FUN))
#> }
#> <bytecode: 0x189ecb8>
#> <environment: namespace:base>
```

``` r
c
#> function (...)  .Primitive("c")
withdots(c)
#> function (...)  .Primitive("c")
```

## Notes

### A note about `primitive` functions

If a function is primitive (see `?primitive`) and it has `...` in its
argument list (e.g., `c()`, `sum()`, `as.character()`), it is returned
as is. If the primitive function does not have `...` in its argument
list, an error is thrown.

The user can bypass this by pre-processing the function with
`rlang::as_closure()`. Observe:

``` r
# Observe that round() is a primitive function with no ... in its arg list:
round
#> function (x, digits = 0)  .Primitive("round")
```

``` r
# So, we can't pass it to withdots() as is:
withdots(round)
#> Error: f cannot be a primitive function with no dots in its args().
#> Consider passing to rlang::as_closure() first
```

``` r
# But if we turn it into a closure, we can give it dots:
library(rlang)

round <- withdots(as_closure(round))

round
#> function (x, digits = 0, ...) 
#> .Primitive("round")(x, digits)
```

``` r
# And now it can handle extraneous arguments:
round(45.78, digits = 1, junk, arguments)
#> [1] 45.8
```

**However**, keep in mind that the argument matching behavior of the
result ***may*** be different from what is expected, since each
primitive is special and ***may*** use nonstandard argument matching.

### The `srcref` `attribute`.

Many functions—including those created with `function()`—have a `srcref`
`attribute`. When a function is `print`ed, `print.function()` relies on
this `attribute` by default to depict the function’s `formals` and
`body`.

`withdots()` adds `...` via `formals<-`, which expressly drops
`attributes` (see `` ?`formals<-` ``. To prevent this loss, `withdots()`
sets the function’s `attributes` aside at the beginning and re-attaches
them to at the end. Normally, this would re-attach the original
function’s `srcref` `attribute` to the new function, making it so that
the newly added `...` would not be depicted when the new function is
`print`ed. For this reason, the old `srcref` `attribute` is dropped, and
only the remaining `attributes` are re-attached to the new function.

Observe what would happen during `print`ing if **all** original
`attributes` were naively added to the modified function:

``` r
# Create a function with no dots:
foo <- function(a = 1) {
  # Helpful comment
  a
}

# Give it important attributes that we can't afford to lose:
attr(foo, "important_attribute") <- "crucial information"
class(foo) <- "very_special_function"

# Print foo, which also prints its important attributes:
foo
#> function(a = 1) {
#>   # Helpful comment
#>   a
#> }
#> attr(,"important_attribute")
#> [1] "crucial information"
#> attr(,"class")
#> [1] "very_special_function"
```

``` r
# Save its attributes:
old_attributes <- attributes(foo)

# Add dots:
formals(foo)[["..."]] <- quote(expr = )

# See that the important attributes have been dropped:
foo
#> function (a = 1, ...) 
#> {
#>     a
#> }
```

``` r
# Add the attributes back:
attributes(foo) <- old_attributes

# Print it again, and we see that the attributes have returned.
# However, the ... disappears from the argument list.
foo
#> function(a = 1) {
#>   # Helpful comment
#>   a
#> }
#> attr(,"important_attribute")
#> [1] "crucial information"
#> attr(,"class")
#> [1] "very_special_function"
```

``` r
# We know the actual function definitely has dots, since it can handle
# extraneous arguments:
foo(1, 2, junk, "arguments", NULL)
#> [1] 1
```

``` r
# Remove the "srcref" attribute, and the function is printed accurately.
# Furthermore, its important attributes are intact:
attr(foo, "srcref") <- NULL
foo
#> function (a = 1, ...) 
#> {
#>     a
#> }
#> attr(,"important_attribute")
#> [1] "crucial information"
#> attr(,"class")
#> [1] "very_special_function"
```

Success! However, the comments in the `body()` of the function are lost.
Even so, this is better than inaccurate `print`ing.
