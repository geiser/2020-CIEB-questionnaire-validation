# Kruskal–Wallis test `cidadania` ~ `formacao.continuada`
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

wants <- c('ggpubr', 'stats', 'rstatix','dplyr')
has <- wants %in% rownames(installed.packages())
if (any(!has)) install.packages(wants[!has])

library(dplyr)
library(rstatix)
library(ggpubr)
library(stats)

kruskal.plot <- function(dat, dv, iv, kwm, pwc, addParam = c(), step.increase = 0.005) {
  pwc <- tryCatch(add_xy_position(pwc, x = iv, step.increase = step.increase), error = function(e) NULL)
  bxp <- ggboxplot(dat, x = iv, y = dv, color = iv, palette = "jco", add=addParam)
  bxp <- bxp + stat_pvalue_manual(pwc, linetype = c(), hide.ns = T, tip.length = 0)
  bxp <- bxp + labs(subtitle = get_test_label(kwm, detailed = T), caption = get_pwc_label(pwc))
  return(bxp)
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

## Initial Data and Preprocessing

dat <- read.csv("kruskal-by-formacao/cidadania/data.csv")[,c("ID", "formacao.continuada", "cidadania" )]
dat <- df2qqs(dat, c("formacao.continuada"))
rownames(dat) <- dat[["ID"]]

## Computation Kruskal-Wallis test and Effect Size

(res.kruskal <- kruskal_test(dat, `cidadania` ~ `formacao.continuada`))
(ezm <- kruskal_effsize(dat, `cidadania` ~ `formacao.continuada`, ci = TRUE))

## Post-hoc Tests (Pairwise Comparisons)

pwc <- dunn_test(dat, `cidadania` ~ `formacao.continuada`, detailed=T, p.adjust.method = "bonferroni")
add_significance(pwc)

## Report Kruskal-Wallis test with Plots and Descriptive Statistic

get_summary_stats(group_by(dat, `formacao.continuada`), type ="common")

kruskal.plot(dat, "cidadania", "formacao.continuada", res.kruskal, pwc, c("jitter"))