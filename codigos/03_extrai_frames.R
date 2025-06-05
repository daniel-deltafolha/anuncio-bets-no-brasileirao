# Sorteia um frame para cada minuto de jogo e salva esse frame em 
# dados/interim/frames

# pacotes -----------------------------------------------------------------
library(dplyr)
library(glue)
library(stringr)
library(magrittr)
library(av)


# variáveis ---------------------------------------------------------------

# Diretório com os jogos
dir_jogos_trim <- "dados/interim/jogos_trim/"

# Onde vamos salvar os frames
dir_frames <- "dados/interim/frames/"


# pega só a parte dos jogos -----------------------------------------------
jogos <- path_urls %>% 
  readLines() 

# Quantidade de jogos e indexes deles
#    cada jogo tem duas linhas no arquivo. Uma com as informações dele e outra
#    com o URL
indexes_urls <- seq(1, length(jogos), 2)
count <- 1
total <- length(jogos)/2
for(i_jogo in indexes_urls){
  
  cat(count, "/", total, "\n", sep = "")
  count <- count  + 1
  
  # ID do jogo
  descricao_jogo <- jogos[[i_jogo]] %>% 
    str_remove("^#\\s+") %>%
    str_remove("\\s+\\|.*") %>% 
    str_trim() %>% 
    tolower() %>% 
    iconv(to="ASCII//TRANSLIT") %>% 
    str_replace_all("\\s+", "-")
  
  # Arquivo do vídeo do jogo. Esse arquivo tem só o jogo, sem o intervalo, pré
  # e pós jogo
  path_jogo_trim <- glue("{dir_jogos_trim}/{descricao_jogo}.mp4")
  
  ##
  ## Sorteia um frame para cada segundo do jogo
  ##
  
  # Duração do arquivo
  movie_duration_seconds <- av_media_info(path_jogo_trim) %>% 
    extract2("duration")
  
  # Quantidade de intervalos de onde vamos sortear um frame
  num_intervals <- ceiling(movie_duration_seconds / 60)
  
  # Para cada intervalo sorteia um número entre o início e o fim dele
  random_timestamps_df <- tibble(minute_interval_num = 1:num_intervals) %>%
    mutate(interval_start_s = (minute_interval_num - 1) * 60,
           interval_end_s = pmin(minute_interval_num * 60, 
                                 movie_duration_seconds)) %>% 
    rowwise() %>%
    mutate(sampled_timestamp_s = runif(1, interval_start_s, interval_end_s)) %>%
    ungroup()
  
  
  # Usa o ffmpeg para extrair o frame sorteado
  for (i in 1:nrow(random_timestamps_df)) {
    timestamp_seconds <- random_timestamps_df$sampled_timestamp_s[i]
    minute_id <- random_timestamps_df$minute_interval_num[i] %>% 
      subtract(1) %>% 
      str_pad(width = 3, pad = 0)
    path_frame <- glue(dir_frames, "/", descricao_jogo, "_", minute_id, ".jpg")
    if(file.exists(path_frame)) next
    ffmpeg_command <- paste0(
      "ffmpeg -y -ss ", shQuote(as.character(timestamp_seconds)),
      " -i ", shQuote(path_jogo_trim),
      " -vframes 1 -q:v 2 ", shQuote(path_frame)
    )
    system(ffmpeg_command)  
  }
}