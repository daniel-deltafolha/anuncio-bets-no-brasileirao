# Faz análise dos resultados. Se calcula porcentagem de frames com anúncio de
# bets e a quantidade deles em cada frame. Isso é feito por frame, por jogo e 
# para toda a amostra.

# pacotes -----------------------------------------------------------------
library(stringr)
library(dplyr)
library(purrr)
library(googlesheets4)
library(magrittr)

# variáveis ---------------------------------------------------------------

# Arquivo com as informações extraídas dos frames
dir_info_frame_anotado <- "dados/interim/info_frames_anotado/"

# Arquivo onde vamos salvar as tabelas da análise
dir_tabelas_analises <- "dados/processados/tabelas/"



# analise -----------------------------------------------------------------

df <- dir_info_frame_anotado %>% 
  # Lista, lê e junta os arquivos
  list.files(full.names = TRUE) %>% 
  map(read.csv, colClasses = "character") %>% 
  bind_rows() %>%
  # minuto do jogo ao qual corresponde o frame
  mutate(minuto_frame = str_extract(image_path, "_(\\d+).jpg", group = 1)) %>%
  mutate(minuto_frame  = as.numeric(minuto_frame)) %>% 
  # ID do jogo
  mutate(jogo_id = str_extract(image_path, "dados/interim/frames//(.*)_", 
                               group = 1)) %>%
  # Para permitir manipular a coluna de forma booleana
  mutate(anuncio_bet = as.logical(anuncio_bet)) %>% 
  # Junta videos de tempos que vieram separados
  # |- Tem jogos que estão separados em dois vídeos separados (um para cada 
  #    tempo). Aqui a gente trata isso, de forma que o minuto_frame do segundo
  #    tempo é a continuação do minuto_frame do primeiro
  mutate(tempo = ifelse(grepl("(1|2)t", jogo_id), 
                        str_extract(jogo_id, "(1|2)t", group = 1), 
                        1)) %>% 
  mutate(jogo_id = str_remove(jogo_id, "(1|2)t")) %>% 
  arrange(jogo_id, tempo, minuto_frame) %>% 
  group_by(jogo_id) %>% 
  mutate(minuto_frame = cumsum(!duplicated(image_path))) %>%
  select(-tempo) %>% 
  ungroup() 
write.csv(df, glue("{dir_tabelas_analises}/dados_brutos.csv"))

# Para cada frame conta a quantidade de anúncio de bets presentes
por_frame <- df %>%
  group_by(jogo_id, minuto_frame) %>%
  summarise(n_bets = sum(anuncio_bet, na.rm = TRUE)) %>%
  arrange(jogo_id, minuto_frame)

write.csv(por_frame, glue("{dir_tabelas_analises}/por_frame.csv"))


# Média de frames que tem pelo menos um anúncio
por_frame  %>% 
  pull(n_bets) %>% 
  is_greater_than(0) %>%  
  mean(na.rm = TRUE) %>% 
  multiply_by(100) %>% 
  round()

# Média de anúncios por frames
total_frames <- df %>%
  pull(image_path) %>% 
  unique %>% 
  length()

# media_anuncio_por_frame
df %>%
  pull(anuncio_bet) %>% 
  as.logical %>% 
  sum(na.rm = TRUE) %>% 
  divide_by(total_frames) %>% 
  round(2)

# Faz a análise por jogos
# |- porcentagem de frames com bets e média de anúncios por frames
# |- Também adiciona quem fez a transmissão
por_jogo <- por_frame %>%
  group_by(jogo_id) %>% 
  summarise(pct_frames_bet = mean(n_bets > 0, na.rm = TRUE) * 100, 
            media_frames_bet = mean(n_bets, na.rm  = TRUE)) %>% 
  ungroup() %>%
  arrange(desc(pct_frames_bet)) %>% 
  mutate(transmissao = recode(jogo_id,
                              "corinthinas-x-vasco" = "amazon prime",
                              "sport-x-palmeiras" = "record",
                              "flamengo-x-cruzeiro-case" = "case_tv",
                              "cruzeiro-x-bragantino-" = "premier",
                              "vasco-x-fortaleza" = "case_tv",
                              "fluminense-x-vasco" = "case_tv",
                              "cruzeiro-x-sao-paulo" = "globo",
                              "cruzeiro-x-vasco" = "record",
                              "botafogo-x-internacional" = "case_tv",
                              "vitoria-x-fortaleza-" = "globo",
                              "flamengo-x-cruzeiro-record" = "record",
                              "palmeiras-x-bahia" = "premier",
                              "corinthians-x-fluminense" = "case_tv",
                              "cruzeiro-x-bahia" = "sportv",
                              "flamengo-x-cruzeiro" = "premier",
                              "internacional-x-palmeiras" = "amazon prime",
                              "fortaleza-x-cruzeiro" = "premier",
                              "vasco-x-palmeiras" = "globo",
                              "corinthians-x-palmeiras" = "premier",
                              "fortaleza-x-palmeiras" = "case_tv",
                              "palmeiras-x-botafogo" = "globo",
                              "sao-paulo-x-corinthians" = "case_tv"))

write.csv(por_frame, glue("{dir_tabelas_analises}/por_jogo.csv"))
