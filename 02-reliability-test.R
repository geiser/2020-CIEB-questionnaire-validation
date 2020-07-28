wants <- c('readr','dplyr','psych','lavaan','ggraph','semPlot','robustHD','GPArotation')
has <- wants %in% rownames(installed.packages())
if (any(!has)) install.packages(wants[!has])
options(stringsAsFactors = FALSE)

library(readr)
library(dplyr)
library(psych)
library(lavaan)
library(ggraph)
library(semPlot)
library(data.table)

library(xlsx)
library(r2excel)

source('common/excel/write_alpha_in_workbook.R')

library(MVN)
library(daff)
library(robustHD)
library(stringr)

dat <- read_csv('data/responses-cfa.csv')
dat$area.de.conhecimento <- as.vector(sapply(dat$area.de.conhecimento, FUN = function(x) {
  stringr::str_replace_all(x, "/", ".")
})) 

groups <- unique(expand.grid(unidade=c(NA,unique(dat$unidade))
                             , etapa.de.ensino=c(NA,unique(dat$etapa.de.ensino))
                             , area.de.conhecimento=c(NA,unique(dat$area.de.conhecimento))
                             , formacao.continuada=c(NA,unique(dat$formacao.continuada))
                             , stringsAsFactors = F))

reliability_df <- do.call(rbind, lapply(seq(1,nrow(groups)), FUN = function(i) {
  sdat <- dat; group <- groups[i,]
  if (!is.na(group$unidade)) sdat <- sdat[sdat$unidade == group$unidade,]
  if (!is.na(group$etapa.de.ensino)) sdat <- sdat[sdat$etapa.de.ensino == group$etapa.de.ensino,]
  if (!is.na(group$area.de.conhecimento)) sdat <- sdat[sdat$area.de.conhecimento == group$area.de.conhecimento,]
  if (!is.na(group$formacao.continuada)) sdat <- sdat[sdat$formacao.continuada == group$formacao.continuada,]
  sdat <- select(sdat, starts_with('Item'))
  sdat <- sdat[complete.cases(sdat),]
  
  if (nrow(sdat) > 30) {
    alpha_mods <- list(
      'all'=list(factor='all', mod=psych::alpha(sdat))
      , 'ML1'=list(factor='ML1', mod=psych::alpha(sdat[,c('Item4','Item5','Item3','Item6')]))
      , 'ML2'=list(factor='ML2', mod=psych::alpha(sdat[,c('Item15','Item13','Item17','Item18','Item14','Item12')]))
      , 'ML3'=list(factor='ML3', mod=psych::alpha(sdat[,c('Item19','Item2','Item11','Item16','Item9','Item23','Item21')]))
    )
    
    # write reliability analysis
    filename <- "report/reliability/"
    if (is.na(group$unidade) & is.na(group$etapa.de.ensino) & is.na(group$area.de.conhecimento) & is.na(group$formacao.continuada)) {
      filename <- paste0(filename, "full-all.xlsx")
    } else if (!is.na(group$unidade) & is.na(group$etapa.de.ensino) & is.na(group$area.de.conhecimento) & is.na(group$formacao.continuada)) {
      filename <- paste0(filename, "by-unidade/", group$unidade,".xlsx")
    } else if (is.na(group$unidade) & !is.na(group$etapa.de.ensino) & is.na(group$area.de.conhecimento) & is.na(group$formacao.continuada)) {
      filename <- paste0(filename, "by-etapa-ensino/", group$etapa.de.ensino,".xlsx")
    } else if (is.na(group$unidade) & is.na(group$etapa.de.ensino) & !is.na(group$area.de.conhecimento) & is.na(group$formacao.continuada)) {
      filename <- paste0(filename, "by-area-conhecimento/", group$area.de.conhecimento,".xlsx")
    } else if (is.na(group$unidade) & is.na(group$etapa.de.ensino) & is.na(group$area.de.conhecimento) & !is.na(group$formacao.continuada)) {
      filename <- paste0(filename, "by-formacao-continuada/", group$formacao.continuada,".xlsx")
    } else {
      filename <- paste0(filename, "by-comb/", paste0(group[!is.na(group)], collapse = '-'),".xlsx")
    }
    wb <- createWorkbook(type="xlsx")
    lapply(alpha_mods, FUN = function(mod) {
      write_alpha_in_workbook(mod$mod, wb, mod$factor, mod$factor)
    })
    xlsx::saveWorkbook(wb, filename)
    
    
    cbind(
      'unidade'=group$unidade
      ,'etapa.de.ensino'=group$etapa.de.ensino
      , 'area.de.conhecimento'=group$area.de.conhecimento
      , 'formacao.continuada'=group$formacao.continuada
      , 'n'=nrow(sdat)
      , do.call(cbind, lapply(alpha_mods, FUN = function(alpha_mod) {
        cbind('factor'=alpha_mod$factor
              , round(alpha_mod$mod$total,2))
      })))
  }
}))

# write summaries of reliability tests
write_csv(reliability_df, 'report/reliability/summary-all.csv')
alpha.df <- reliability_df[which(is.na(reliability_df$unidade) & is.na(reliability_df$etapa.de.ensino) & is.na(reliability_df$area.de.conhecimento) & is.na(reliability_df$formacao.continuada)),]
summary.df <- cbind(val = 'Todos', select(alpha.df, starts_with("n"), ends_with(".std.alpha"))) 

idx <- !is.na(reliability_df$unidade) & is.na(reliability_df$etapa.de.ensino) & is.na(reliability_df$area.de.conhecimento) & is.na(reliability_df$formacao.continuada) 
alpha.df <- select(reliability_df[idx,], -starts_with('etapa.de.ensino'), -starts_with('area.de.conhecimento'), -starts_with('formacao.continuada'))
write_csv(alpha.df, 'report/reliability/summary-by-unidade.csv')
summary.df <- rbind(summary.df, cbind(val = paste('Unidade:', alpha.df$unidade), select(alpha.df, starts_with("n"), ends_with(".std.alpha"))))

idx <- is.na(reliability_df$unidade) & !is.na(reliability_df$etapa.de.ensino) & is.na(reliability_df$area.de.conhecimento) & is.na(reliability_df$formacao.continuada)
alpha.df <- select(reliability_df[idx,], -starts_with('unidade'), -starts_with('area.de.conhecimento'), -starts_with('formacao.continuada'))
write_csv(alpha.df, 'report/reliability/summary-by-etapa.csv')
summary.df <- rbind(summary.df, cbind(val = paste('Etapa:', alpha.df$etapa.de.ensino), select(alpha.df, starts_with("n"), ends_with(".std.alpha"))))

idx <- is.na(reliability_df$unidade) & is.na(reliability_df$etapa.de.ensino) & !is.na(reliability_df$area.de.conhecimento) & is.na(reliability_df$formacao.continuada)
alpha.df <- select(reliability_df[idx,], -starts_with('unidade'), -starts_with('etapa.de.ensino'), -starts_with('formacao.continuada'))
write_csv(alpha.df, 'report/reliability/summary-by-area.csv')
summary.df <- rbind(summary.df, cbind(val = paste('Area:', alpha.df$area.de.conhecimento), select(alpha.df, starts_with("n"), ends_with(".std.alpha"))))

idx <- is.na(reliability_df$unidade) & is.na(reliability_df$etapa.de.ensino) & is.na(reliability_df$area.de.conhecimento) & !is.na(reliability_df$formacao.continuada)
alpha.df <- select(reliability_df[idx,], -starts_with('unidade'), -starts_with('etapa.de.ensino'), -starts_with('area.de.conhecimento'))
write_csv(alpha.df, 'report/reliability/summary-by-formacao.csv')
summary.df <- rbind(summary.df, cbind(val = paste('Formação:', alpha.df$formacao.continuada), select(alpha.df, starts_with("n"), ends_with(".std.alpha"))))

colnames(summary.df) <- c("val", "n", "DTL", "ML1", "ML2", "ML3")
(summary.df)

