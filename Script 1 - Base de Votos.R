#######################################
#### Criação da base de voto-lv ####
#######################################

library(cepespR)
library(tidyr)
library(dplyr)
library(readr)

#Abrir tabela de correposndência entre Seção e Local de Votação (CepespData):

tab_locvot <- read_csv("C:/Users/gcase/OneDrive/CEPESP/LOCVOT_11_MUN/lat_lon/tab_LV_sp.csv", 
                       col_types = cols(NR_LOCVOT = col_character()),locale = locale(encoding = "ISO-8859-1"))

  tab_locvot<-tab_locvot[tab_locvot$CD_LOCALIDADE_TSE==71072,c(1,4:7,8,9,13,14)]
  
  tab_locvot_lv<-tab_locvot[!duplicated(tab_locvot[,c(1,2,3,5)]),]
  tab_locvot_lv$NR_SECAO<-NULL

#Baixar tabela de votos válidos (CepespData):

#data <- get_votes(year = 2008, position="Prefeito", 
#                  regional_aggregation="Electoral Section", state="SP",blank_votes = T,null_votes = T,dev=T)

  #saveRDS(data,"votos_sp_pref.rds")
  data<-readRDS("votos_sp_pref.rds")

  data<-data[data$COD_MUN_TSE==71072,]

  data<-data[,c("ANO_ELEICAO","NUM_TURNO","NUM_ZONA","NUM_SECAO","NUMERO_CANDIDATO","QTDE_VOTOS")]

  colnames(data)<-c("NR_ANO","NR_TURNO","NR_ZONA","NR_SECAO","NR_CANDIDATO","QTD_VOTOS")

data2<-left_join(data,tab_locvot) #Juntar com informações dos locais de votação e agregar total de votos no Local de Votação:

  data2<-aggregate(data2$QTD_VOTOS,by=list(data2$NR_ANO,data2$NR_ZONA,data2$NR_LOCVOT,data$NR_TURNO),FUN=function(x){sum(x,na.rm = T)})  

  colnames(data2)<-c("NR_ANO","NR_ZONA","NR_LOCVOT","NR_TURNO","QTD_VOTOS_LV")

  
data<-left_join(data,tab_locvot)
    
data<-data[!data$NR_CANDIDATO%in%c(95,96),] #Retirar votos nulos e brancos da base de candidatos para calcular total de votos válidos por seção:

  data1<-aggregate(data$QTD_VOTOS,by=list(data$NR_ANO,data$NR_ZONA,data$NR_LOCVOT,data$NR_TURNO),FUN=function(x){sum(x,na.rm = T)})  

  colnames(data1)<-c("NR_ANO","NR_ZONA","NR_LOCVOT","NR_TURNO","QTD_VOTOS_T")

  data<- aggregate(data$QTD_VOTOS,by=list(data$NR_ANO,data$NR_ZONA,data$NR_LOCVOT,data$NR_TURNO,data$NR_CANDIDATO),FUN=function(x){sum(x,na.rm = T)})  
 
  colnames(data)<-c("NR_ANO","NR_ZONA","NR_LOCVOT","NR_TURNO","NR_CANDIDATO","QTD_VOTOS")
  
data<-left_join(data,data2)
data<-left_join(data,data1)


#Definir candidatos incumbentes nas eleições de 2000 a 2016:

incumb<-as.data.frame(cbind(seq(2000,2016,4),c(11,13,25,45,13)))
  colnames(incumb)<-c("NR_ANO","NR_INCUMB")

data<-left_join(data,incumb,by="NR_ANO")
  data$QTD_VOTOS_P<-data$QTD_VOTOS/data$QTD_VOTOS_T #Percentual de votos válidos de cada candidato por seção eleitoral

temp<-unique(data[,c(1:4,8,7)])
  
data_t1<-data[data$NR_TURNO==1&(data$NR_INCUMB==data$NR_CANDIDATO),c(1:6,10) ] #Selecionar apenas resultados do incumbente no 1º Turno
  data_t1$NR_INCUMB<-NULL


data_t2<-data[data$NR_TURNO==2&(data$NR_INCUMB==data$NR_CANDIDATO), c(1:6,10) ] #Selecionar apenas resultados do incumbente no 2º Turno
  data_t2$NR_INCUMB<-NULL


#Criar bases com a votação dos incumbentes no 1º e no 2º turnos:  
  
res_lv_sec_t1<-left_join(temp[temp$NR_TURNO==1,], data_t1)
  res_lv_sec_t1[is.na(res_lv_sec_t1)]<-0 #LVs em que o incumbente não recebeu votos no 1º Turno

res_lv_sec_t2<-left_join(temp[temp$NR_TURNO==2,], data_t2)
  res_lv_sec_t2[is.na(res_lv_sec_t2)]<-0 #LVs em que o incumbente não recebeu votos no 2º Turno
  

#Definir partido do incumbente em t na eleição de t-1:

incumb_1<-as.data.frame(cbind(c(2000,2004,2008,2012),c(13,45,25,13),rep(1,4),rep(1,4)))
  incumb_1<-rbind(incumb_1,as.data.frame(cbind(c(2000,2004,2008,2012),c(13,45,25,13),rep(1,4),rep(2,4))))   

colnames(incumb_1)<-c("NR_ANO","NR_CANDIDATO","I_1","NR_TURNO")

data_lag<-left_join(data,incumb_1)
  data_lag<-data_lag[!is.na(data_lag$I_1),]
  data_lag$I_1<-NULL
  data_lag$NR_ANO<-data_lag$NR_ANO+4
  data_lag$NR_INCUMB<-NULL

data_t1_lag<-data_lag[data_lag$NR_TURNO==1, ]
  data_t1_lag$NR_TURNO<-NULL
  colnames(data_t1_lag)[4:8]<-c("NR_CANDIDATO_lag","QTD_VOTOS_lag","QTD_VOTOS_LV_lag","QTD_VOTOS_T_lag","QTD_VOTOS_P_lag")

data_t2_lag<-data_lag[data_lag$NR_TURNO==2, ]
  data_t2_lag$NR_TURNO<-NULL
  colnames(data_t2_lag)[4:8]<-c("NR_CANDIDATO_lag","QTD_VOTOS_lag","QTD_VOTOS_LV_lag","QTD_VOTOS_T_lag","QTD_VOTOS_P_lag")

#Unir dados defasados às bases finais:  
  
  
res_lv_sec_t1<-left_join(res_lv_sec_t1,data_t1_lag)
res_lv_sec_t1<-left_join(res_lv_sec_t1,tab_locvot_lv)
  res_lv_sec_t1<-res_lv_sec_t1[!is.na(res_lv_sec_t1$QTD_VOTOS_LV),]
  res_lv_sec_t1<-res_lv_sec_t1[!res_lv_sec_t1$NR_ANO==2000,]

res_lv_sec_t2<-left_join(res_lv_sec_t2,data_t2_lag)
res_lv_sec_t2<-left_join(res_lv_sec_t2,tab_locvot_lv)
  res_lv_sec_t2<-res_lv_sec_t2[!is.na(res_lv_sec_t2$QTD_VOTOS_LV),]
  res_lv_sec_t2<-res_lv_sec_t2[!res_lv_sec_t2$NR_ANO==2000,]

  
#Salvar bases:

saveRDS(res_lv_sec_t1,file="res_lv_sec_t1.rds")
saveRDS(res_lv_sec_t2,file="res_lv_sec_t2.rds")

rm(list = ls())

