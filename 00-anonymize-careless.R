wants <- c('digest', 'readxl', 'dplyr','careless','car')
has <- wants %in% rownames(installed.packages())
if (any(!has)) install.packages(wants[!has])

library(readxl)
library(readr)
library(digest)     # biblioteca para anonimizar dados
library(dplyr)      # biblioteca para manipular data.frames
library(careless)   # biblioteca para tratamento de respostas descuidadas
library(car)        # biblioteca para graficar Boxplots com identificação de pontos

## Anonimizando dados dos participantes

raw_data <- read_excel("raw-data/DadosBrutos-AvaliacaoDocente-UFAL.xlsx")

data <- select(raw_data, -starts_with("nome"), -starts_with("data de nascimento"),
               -starts_with("respondido em"), -starts_with("pedagógica"),
               -starts_with("cidadania "), -starts_with("desenvolvimento"))
colnames(data) <- c("ID", "etapa.de.ensino","area.de.conhecimento","formacao.continuada","unidade",
                    "Item1","Item2","Item3","Item4","Item5","Item6","Item7","Item8",
                    "Item9","Item10","Item11","Item12","Item13","Item14","Item15",
                    "Item16","Item17","Item18","Item19","Item20","Item21","Item22","Item23")

write_csv(data, 'data/anonymized-responses.csv')


## identificando careless - como são paginados a cada dois respostas não aplicamos IRV
dataItem <- select(data, starts_with("Item"))
outliers <- Boxplot(longstring(dataItem), main = "Boxplot do Longstring") 

careless <- cbind(resp=outliers, longstring=longstring(dataItem)[outliers], data[outliers,])
data.table::setorder(careless, -longstring)
head(careless)


# .. posições 37 e 59 são considerados careless
# .. salvar respostas descuidadas no arquivo <../data/careless.csv>
# .. salvar respostas sem respostas descuidadas no arquivo <../data/responses.csv>
careless <- careless[c(1,2),]
write_csv(careless, 'data/careless.csv')

responses <- data[!data$ID %in% careless$ID,]
write_csv(responses, 'data/responses.csv')

