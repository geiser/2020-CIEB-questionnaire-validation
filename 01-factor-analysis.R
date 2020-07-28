wants <- c('readr','dplyr','psych','lavaan','ggraph','semPlot','robustHD','GPArotation','parameters')
has <- wants %in% rownames(installed.packages())
if (any(!has)) install.packages(wants[!has])

source('common/excel/write_mvn_in_workbook.R')
source('common/excel/write_kmo_in_workbook.R')
source('common/excel/write_efa_in_workbook.R')
source('common/excel/write_cfa_in_workbook.R')

library(GPArotation)
library(readr)
library(dplyr)
library(psych)
library(lavaan)
library(ggraph)
library(semPlot)

library(xlsx)
library(r2excel)

library(MVN)
library(daff)
library(robustHD)
library(parameters)

dat <- read_csv('data/responses.csv')
datItem <- select(dat, starts_with("Item"))


#####################################
## Exploratory Factorial Analisis  ##
#####################################

## Checking assumptions 
(mvn_mod <- mvn(datItem))  # As there is not normality, use robust methods
(kmo_mod <- KMO(datItem)) 
(check_sphericity(datItem))

## Parallel factorial analysis
png(filename = "report/parallel-analysis.png", width = 800, height = 500)
parallel1 <- (fa.parallel(datItem, fm = 'ml', fa = 'fa', cor='poly'))
dev.off()
(parallel1$nfact) # nro de fatores sugeridos

## EFA with n=6 factors
(fa_mod_6 <- fa(datItem, nfactors = 6, rotate = "promax", cor = 'poly', fm='ml'))  

(fa_mod_6 <- fa(datItem[,!colnames(datItem) %in% c("Item20", "Item4", "Item7", "Item16")],
                 nfactors = 6, rotate = "promax", cor = 'poly', fm='ml'))


png(filename = "report/loading-diagram-fa6.png", width = 600, height = 600)
fa.diagram(fa_mod_6, main='',sort=T)
dev.off()

## EFA with n=5 factors
(fa_mod_5 <- fa(datItem, nfactors = 5, rotate = "promax", cor = 'poly', fm='ml'))  

(fa_mod_5 <- fa(datItem[,!colnames(datItem) %in% c("Item20","Item8",
                                                   "Item4","Item5","Item7","Item9","Item10","Item16","Item23")],
                nfactors = 5, rotate = "promax", cor = 'poly', fm='ml'))


png(filename = "report/loading-diagram-fa5.png", width = 600, height = 600)
fa.diagram(fa_mod_5, main='',sort=T)
dev.off()


## EFA with n=4 factors
(fa_mod_4 <- fa(datItem, nfactors = 4, rotate = "promax", cor = 'poly', fm='ml'))  

(fa_mod_4 <- fa(datItem[,!colnames(datItem) %in% c("Item10","Item2","Item6","Item7","Item8","Item16","Item20")],
                nfactors = 4, rotate = "promax", cor = 'poly', fm='ml'))


png(filename = "report/loading-diagram-fa4.png", width = 600, height = 600)
fa.diagram(fa_mod_4, main='',sort=T)
dev.off()


## EFA with n=3 factors
(fa_mod_3 <- fa(datItem, nfactors = 3, rotate = "promax", cor = 'poly', fm='ml'))  

(fa_mod_3 <- fa(datItem[,!colnames(datItem) %in% c("Item10","Item1","Item7","Item8","Item20","Item22")],
                nfactors = 3, rotate = "promax", cor = 'poly', fm='ml'))


png(filename = "report/loading-diagram-fa3.png", width = 600, height = 600)
fa.diagram(fa_mod_3, main='',sort=T)
dev.off()


## Write results of EFA in Excel Workbook
filename <- "report/efa.xlsx"
wb <- createWorkbook(type="xlsx")
write_mvn_in_workbook(mvn_mod, wb)
write_kmo_in_workbook(kmo_mod, wb)
write_efa_in_workbook(fa_mod_6, wb, "EFA-f6", "EFA with n=6 factors")
write_efa_in_workbook(fa_mod_5, wb, "EFA-f5", "EFA with n=5 factors")
write_efa_in_workbook(fa_mod_4, wb, "EFA-f4", "EFA with n=4 factors")
write_efa_in_workbook(fa_mod_3, wb, "EFA-final", "EFA with n=3 factors (Final)")
xlsx::saveWorkbook(wb, filename)


#####################################
## Confirmatory Factorial Analisis ##
#####################################

ritens <- c("Item10","Item1","Item7","Item8","Item20","Item22")
rdat <- as.data.frame(datItem[,!colnames(datItem) %in% ritens])

mdls <- list('multi-mdl'=list(name='multi-mdl', mdl='
ML2 =~ Item15+Item13+Item17+Item18+Item14+Item12
ML1 =~ Item4+Item5+Item3+Item6
ML3 =~ Item19+Item2+Item11+Item16+Item9+Item23+Item21

ML1 ~~ ML2
ML1 ~~ ML3

ML2 ~~ ML3
'), '2nd-order-mdl'=list(name='2nd-order-mdl', mdl='
ML2 =~ Item15+Item13+Item17+Item18+Item14+Item12
ML1 =~ Item4+Item5+Item3+Item6
ML3 =~ Item19+Item2+Item11+Item16+Item9+Item23+Item21

DTL =~ ML2+ML1+ML3
'), 'orth-mdl'=list(name='orth-mdl', mdl='
ML2 =~ Item15+Item13+Item17+Item18+Item14+Item12
ML1 =~ Item4+Item5+Item3+Item6
ML3 =~ Item19+Item2+Item11+Item16+Item9+Item23+Item21

ML1 ~~ 0*ML2
ML1 ~~ 0*ML3

ML2 ~~ 0*ML3
'))
cfa_mdls <- lapply(mdls, FUN = function(x) {
  cfa_mdl <- cfa(x$mdl, data=rdat, std.lv=T, estimator="MLR", meanstructure=T)
  print(paste('name: ', x$name))
  summary(cfa_mdl, standardized=T, fit.measures=T)
  
  
  png(filename = paste0("report/cfa-",x$name,".png"), width = 800, height = 800)
  semPaths(cfa_mdl,  "std", curvePivot = T, layout = "tree", fade = F, rotation = 2)
  dev.off()
  
  list(name = x$name, cfa = cfa_mdl, fit = fitMeasures(cfa_mdl))
})


## write summary of CFAs
(fits_df <- t(do.call(rbind, lapply(mdls, FUN = function(x) {
  fit <- cfa_mdls[[x$name]]$fit
  return(
    cbind(name=x$name, as.data.frame(t(round(as.data.frame(fit), 3)))
          , "cfi.obs" = ifelse((fit[['cfi']] < 0.85 | fit[['cfi.robust']] < 0.85), 'unacceptable fit', NA)
          , "tli.obs" = ifelse((fit[['tli']] < 0.85 | fit[['tli.robust']] < 0.85), 'unacceptable fit', NA)
          , "rmsea.obs" = ifelse((fit[['rmsea']] > 0.10 | fit[['rmsea.robust']] > 0.10), 'poor fit', NA)
          , "rmsea.pvalue.obs" = ifelse((fit[['rmsea.pvalue']] > 0.05 | fit[['rmsea.pvalue.robust']] > 0.05), "close fit", NA))
  )
}))))
write_csv(as.data.frame(rbind('model'=colnames(fits_df), fits_df)), "report/cfa-summary.csv")

# write summary of comparison for baseline-model

anova(cfa_mdls$`multi-mdl`$cfa, cfa_mdls$`2nd-order-mdl`$cfa)

## write cfa-fits details
wb <- createWorkbook(type="xlsx")
lapply(mdls, FUN = function(x) {
  write_cfa_in_workbook(cfa_mdls[[x$name]]$cfa, wb, x$name)
})
xlsx::saveWorkbook(wb, "report/cfa.xlsx")


####################################################
## Saving data for Reliability Analysis and MGCFA ##
####################################################

library(stringr)

dat <- read_csv('data/responses.csv')

etapa.de.ensino <- unique(unlist(str_split(unique(dat$etapa.de.ensino),';')))
area.de.conhecimento <- unique(unlist(str_split(unique(dat$area.de.conhecimento),';')))
formacao.continuada <- unique(unlist(str_split(unique(dat$formacao.continuada),';')))

idx <- (dat$etapa.de.ensino %in% etapa.de.ensino &
          dat$area.de.conhecimento %in% area.de.conhecimento &
          dat$formacao.continuada %in% formacao.continuada) 

rdat <- select(dat[idx,], -starts_with("Item"))
datItem <- dat[,c('ID','Item4','Item5','Item3','Item6',
                  'Item15','Item13','Item17','Item18','Item14','Item12',
                  'Item19','Item2','Item11','Item16','Item9','Item23','Item21')]
rdat <- merge(rdat, datItem)

write_csv(rdat, 'data/responses-cfa.csv')
