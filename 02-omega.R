wants <- c('readr','psych','lavaan','dplyr','psych','GPArotation')
has <- wants %in% rownames(installed.packages())
if (any(!has)) install.packages(wants[!has])

library(psych)
library(dplyr)
library(readr)
library(lavaan)
library(GPArotation)

dat <- read_csv('data/responses.csv')
datItem <- select(dat, starts_with("Item"))

## Runing omega with all the items

png(filename = "report/omega_n3.png", width = 800, height = 800)
omega3 <- omega(datItem, nfactors = 3)
dev.off()
omega3

## Runing omega with the itens defined by the CFA model structure

items <- c("Item3","Item4","Item5","Item6",
           "Item12","Item13","Item14","Item15","Item17","Item18",
           "Item19","Item21","Item23","Item2","Item9","Item11","Item16")

png(filename = "report/omega_cfa3.png", width = 800, height = 800)
omega3cfa <- omega(datItem[,c(items)], nfactors = 3)
dev.off()
omega3cfa

## Runing omega with the itens defined by the alternative CFA model structure


items <- c("Item3","Item4","Item5","Item6",
           "Item12","Item13","Item14","Item15","Item17","Item18",
           "Item19","Item21","Item23")

png(filename = "report/omega_cfa3alt.png", width = 800, height = 800)
omega3alt <- omega(datItem[,c(items)], nfactors = 3)
dev.off()
omega3alt


## write summary fit measure in CSV-file

mdls <- list(list(name='all', mdl=omega3),
             list(name='cfa-mdl', mdl=omega3cfa),
             list(name='alt-mdl', mdl=omega3alt))

omega.fit <- do.call(rbind, lapply(mdls, FUN = function(x) {
  data.frame(
    'mdl' = x$name,
    'Omega' = x$mdl$omega.tot,
    'Omega H' = x$mdl$omega_h,
    'Omega Limit' = x$mdl$omega.lim,
    'Alpha' = x$mdl$alpha,
    'Alpha G.6' = x$mdl$G6,
    'Chisq' = x$mdl$stats$chi,
    'df' = x$mdl$stats$dof,
    'TLI' = x$mdl$stats$TLI,
    'RMSEA' = x$mdl$stats$RMSEA[['RMSEA']],
    'RMSEA.lower' = x$mdl$stats$RMSEA[['lower']],
    'RMSEA.upper' = x$mdl$stats$RMSEA[['upper']]
  )
}))
(omega.fit)
write_csv(omega.fit, 'report/omega-fit.csv')
