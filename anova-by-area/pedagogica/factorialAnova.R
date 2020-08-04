# ANOVA `pedagogica` ~ `area.de.conhecimento`
#
# This file is automatically generate by Shiny-Statistic app (https://statistic.geiser.tech/)
#  
# Shiny-Statistic is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License.
# If not, see <https://www.gnu.org/licenses/>.
#

wants <- c('ggpubr', 'emmeans', 'rstatix', 'fBasics', 'car', 'carData','dplyr')
has <- wants %in% rownames(installed.packages())
if (any(!has)) install.packages(wants[!has])

library(dplyr)
library(carData)
library(car)
library(fBasics)
library(rstatix)
library(emmeans)

library(ggpubr)

library(stats)

normality_test <- function(x) {
  plimit <- 0.05
  n.test <- shapiro.test(x)
  cutpoints <- c(0, 1e-04, 0.001, 0.01, 0.05, 1)
  
  if (length(x) > 30) {
    plimit <- 0.01
    cutpoints <- c(0, 1e-05, 1e-04, 0.001, 0.01, 1)
  }
  if (length(x) > 50) n.test <- dagoTest(x)@test
  
  normality <- ifelse(n.test$p.value[1] < plimit, 'NO', 'YES')
  if (length(x) > 100) normality <- 'QQ'
  if (length(x) > 200) normality <- '-'
  
  return(cbind(add_significance(data.frame(
    n = length(x),
    statistic = n.test$statistic[1],
    method = strsplit(n.test$method, ' ')[[1]][1],
    p = n.test$p.value[1]
  ), p.col = "p", cutpoints = cutpoints), normality = normality))
}

normality_test_at <- function(dat, vars) {
  df <- select(group_data(dat), -starts_with(".rows"))
  do.call(rbind, lapply(vars, FUN = function(v) {
    do.call(rbind, lapply(seq(1, nrow(group_data(dat))), FUN = function(i) {
      n.test <- normality_test(dat[[v]][group_data(dat)[[".rows"]][[i]]]) 
      cbind(variable = v, df[i,] , n.test)
    }))
  }))
}

df2qqs <- function(data, group) {
  data <- as.data.frame(data)
  for (iv in group) {
    if (is.numeric(data[[iv]])) {
      quantiles <- quantile(data[[iv]])
      data[[iv]] <- sapply(data[[iv]], FUN = function(x) {
        if (x <= quantiles[[2]]) "low"
        else if (x >= quantiles[[4]]) "high"
        else "medium"
      })
      data[[iv]] <- factor(data[[iv]], levels=c("low", "medium", "high"))
    }
  }
  return(data)
}

ggPlotAoV <- function(data, x, y, color = c(), aov, pwc, linetype = color, by = c(), addParam = c() ) {
  pwc <- tryCatch(add_xy_position(pwc, x = x), error = function(e) NULL)
  if (is.null(pwc)) return(ggplot())
  if (length(color) > 0) {
    bxp <- ggboxplot(data, x = x, y = y, color = color, palette = "jco", add=addParam, facet.by = by)
    bxp <- bxp + stat_pvalue_manual(pwc, color = color, linetype = linetype, hide.ns = T
                                    , tip.length = 0, step.increase = 0.1, step.group.by = by)
  } else {
    bxp <- ggboxplot(data, x = x, y = y, color = x, palette = "jco", add=addParam, facet.by = by)
    bxp <- bxp + stat_pvalue_manual(pwc, linetype = linetype, hide.ns = T
                                    , tip.length = 0, step.increase = 0.1, step.group.by = by)
  }
  bxp <- bxp + labs(subtitle = get_test_label(aov, detailed = T), caption = get_pwc_label(pwc))
  return(bxp)
}

emm <- list()

## Initial Data and Preprocessing

dat <- read.csv("anova-by-area/pedagogica/data.csv")[,c("ID", "area.de.conhecimento", "pedagogica" )]
dat <- df2qqs(dat, c("area.de.conhecimento"))
rownames(dat) <- dat[["ID"]]

### Visualization of data distribution
ggdensity(dat, x = "pedagogica", fill = "lightgray", title= "Density of pedagogica before transformation") +
 stat_overlay_normal_density(color = "red", linetype = "dashed")
 
### Dealing with positive greater skewness in pedagogica
dat[["pedagogica"]] <- log10(dat[["pedagogica"]])
ggdensity(dat, x = "pedagogica", fill = "lightgray", title= "Density of pedagogica after transformation") +
 stat_overlay_normal_density(color = "red", linetype = "dashed")


### Summary statistics of the initial data

get_summary_stats(group_by(dat, `area.de.conhecimento`), type ="common")

## Check Assumptions

### Identifying outliers

identify_outliers(group_by(dat, `area.de.conhecimento`), `pedagogica`)
Boxplot(`pedagogica` ~ `area.de.conhecimento`, data = dat, id = list(n = Inf))

### Removing outliers from the data

outliers <- c("Obs50","Obs141","Obs286")
rdat <- dat[!dat[["ID"]] %in% outliers,]   # table without outliers

### Normality assumption

#### Checking normality assumption in the residual model

mdl <- lm(`pedagogica` ~ `area.de.conhecimento`, data = rdat)
normality_test(residuals(mdl))
qqPlot(residuals(mdl))

#### Checking normality assumption for each group

normality_test_at(group_by(rdat, `area.de.conhecimento`), "pedagogica")

qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Ciências Agrárias"),])
qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Ciências Biológicas"),])
qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Ciências da Saúde"),])
qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Ciências Exatas e da Terra"),])
qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Ciências Humanas"),])
qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Ciências Sociais Aplicadas"),])
qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Engenharias"),])
qqPlot( ~ `pedagogica`, data = rdat[which(rdat["area.de.conhecimento"] == "Linguística/Letras e Artes"),])


#### Removing non-normal data

non.normal <- c("Obs15","Obs27","Obs62","Obs110","Obs140","Obs178")
sdat <- rdat[!rdat[["ID"]] %in% non.normal,]   # table without non-normal and outliers

mdl <- lm(`pedagogica` ~ `area.de.conhecimento`, data = sdat)
normality_test(residuals(mdl))
qqPlot(residuals(mdl))

normality_test_at(group_by(sdat, `area.de.conhecimento`), "pedagogica")

qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Ciências Agrárias"),])
qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Ciências Biológicas"),])
qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Ciências da Saúde"),])
qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Ciências Exatas e da Terra"),])
qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Ciências Humanas"),])
qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Ciências Sociais Aplicadas"),])
qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Engenharias"),])
qqPlot( ~ `pedagogica`, data = sdat[which(sdat["area.de.conhecimento"] == "Linguística/Letras e Artes"),])


### Homogeneity of variance assumption

levene_test(sdat, `pedagogica` ~ `area.de.conhecimento`)

## Computation ANOVA

res.aov <- anova_test(sdat, `pedagogica` ~ `area.de.conhecimento`, type = 2, effect.size = 'ges', detailed = T)
get_anova_table(res.aov)

## Post-hoct Tests (Pairwise Comparisons)

(emm[["area.de.conhecimento"]] <- emmeans_test(sdat, `pedagogica` ~ `area.de.conhecimento`, p.adjust.method = "bonferroni", detailed = T))


## Report ANOVA with Plots and Descriptive Statistic

get_summary_stats(group_by(sdat, `area.de.conhecimento`), type ="common")

ggPlotAoV(sdat, "area.de.conhecimento", "pedagogica", aov=res.aov, pwc=emm[["area.de.conhecimento"]], addParam=c("jitter"))
