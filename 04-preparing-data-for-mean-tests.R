library(readr)
library(stringr)
library(dplyr)

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

rdat <- select(rdat, -starts_with('Item'))

## Writing data to perform hypotheses with means
ngroups <- setdiff(colnames(rdat), c('ID','pedagogica','cidadania','desenvolvimento'))
for (n in 1:length(ngroups)) {
  comb_groups <- combn(ngroups, n)
  for (j in 1:ncol(comb_groups)) {
    cnames <- comb_groups[,j]
    sdat <- rdat[,c('ID', cnames, 'pedagogica','cidadania','desenvolvimento')]
    filename <- paste0('data/comp-digital-by-',paste0(cnames, collapse = '-'),'.csv')
    write_csv(sdat[complete.cases(sdat),], filename)
  }
}

