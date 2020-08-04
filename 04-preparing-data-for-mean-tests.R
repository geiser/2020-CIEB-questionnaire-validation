library(readr)
library(stringr)
library(dplyr)
library(xlsx)
library(r2excel)

ML1items <- c("Item3","Item4","Item5","Item6")
ML2items <- c("Item12","Item13","Item14","Item15","Item17","Item18")
ML3items <- c("Item19","Item21","Item23")

allItems <- c(ML1items, ML2items, ML3items)

## Preparing data to perform Hypothesis tests on means

dat <- read_csv('data/responses.csv')

etapa.de.ensino <- unique(unlist(str_split(unique(dat$etapa.de.ensino),';')))
area.de.conhecimento <- unique(unlist(str_split(unique(dat$area.de.conhecimento),';')))
formacao.continuada <- unique(unlist(str_split(unique(dat$formacao.continuada),';')))

idx <- (dat$etapa.de.ensino %in% etapa.de.ensino &
          dat$area.de.conhecimento %in% area.de.conhecimento &
          dat$formacao.continuada %in% formacao.continuada) 

rdat <- select(dat[idx,], -starts_with("Item"))
datItem <- dat[,c('ID',allItems)]
rdat <- merge(rdat, datItem)

rdat[['pedagogica']] <- (rdat[['Item3']]+rdat[['Item4']]+rdat[['Item5']]+rdat[['Item6']])/4
rdat[['cidadania']] <- (rdat[['Item12']]+rdat[['Item13']]+rdat[['Item14']]+rdat[['Item15']]+rdat[['Item17']]+rdat[['Item18']])/6
rdat[['desenvolvimento']] <- (rdat[['Item19']]+rdat[['Item21']]+rdat[['Item23']])/3

rdat[['ID']] <- paste0('Obs',seq(1:nrow(rdat)))

## Writing data to perform hypotheses with means
wb <- createWorkbook(type="xlsx")

items <- colnames(select(rdat, starts_with('Item')))
ngroups <- setdiff(colnames(rdat), c('ID',items,'pedagogica','cidadania','desenvolvimento'))
for (n in 1:length(ngroups)) {
  comb_groups <- combn(ngroups, n)
  for (j in 1:ncol(comb_groups)) {
    cnames <- comb_groups[,j]
    pdat <- rdat[complete.cases(rdat[,cnames]),]
      
    allgroups <- do.call(paste0, sapply(cnames, FUN = function(cname) pdat[cname]))
    validgroups <- table(allgroups)[table(allgroups) >= 15]
    if (length(validgroups) >= 2) {
      idx <- allgroups %in% names(validgroups)
      sdat <- pdat[idx, c('ID', cnames, items, 'pedagogica','cidadania','desenvolvimento')]
      
      if (all(as.vector(sapply(cnames, FUN = function(cname) length(unique(sdat[[cname]])) >= 2)))) {
        sheetName <- paste0('by-', paste0(as.vector(sapply(cnames, FUN = function(x) strsplit(x,"\\.")[[1]][1] )), collapse = '-'))
        sheet <- createSheet(wb, sheetName = sheetName)
        xlsx.addTable(wb, sheet, sdat, startCol = 1, row.names = F)
      }
    }
  }
}
saveWorkbook(wb, "report/digital-competences.xlsx")


