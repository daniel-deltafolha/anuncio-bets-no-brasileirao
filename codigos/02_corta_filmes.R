# Corta os filmes para só termos o período do jogo, sem o pŕe ou pós jogo e
# intervalo. Salva os filmes cortados no diretório dados/interim/jogos_trim

# pacotes -----------------------------------------------------------------
library(dplyr)
library(glue)
library(stringr)


# variáveis ---------------------------------------------------------------

# Arquivo com informação sobre os jogos
path_urls <- "dados/brutos/urls_jogos.txt"

# Arquivo bruto dos jogos
dir_jogos <- "dados/brutos//video_jogos/"

# Onde vamos salvar os arquivos cortados
dir_jogos_trim <- "dados/interim/jogos_trim/"


# pega só a parte dos jogos -----------------------------------------------

# Arquivo com informação sobre os jogos, incluíndo quando começa e termina cada
# tempo do jogo
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
  
  # Arquivo do jogo bruto
  path_jogo_raw <- glue("{dir_jogos}/{descricao_jogo}.mp4")
  
  # Se o arquivo ainda não foi baixado passa para o próximo
  if(!file.exists(path_jogo_raw)) next
  
  # Onde vamos salvar o arquivo cortado
  path_jogo_trim <- glue("{dir_jogos_trim}/{descricao_jogo}.mp4")
  
  # Se já existe o arquivo cortado passa para o próximo
  if(file.exists(path_jogo_trim)) next
  
  # Tempos que os tempos começam e terminam
  timestamp <- jogos[[i_jogo]] %>% 
    str_remove(".*?\\|\\s+") %>% 
    str_split("\\s+\\|") %>% 
    unlist %>% 
    str_trim()
  
  # Onde vamos salvar temporariamente os arquivos do primeiro e segundo tempo
  path_primeiro_tempo <- tempfile(fileext = ".mp4")
  path_segundo_tempo <- tempfile(fileext = ".mp4")
  
  # Comand para cortar o primeiro tempo
  # (no caso de só ter um tempo no arquivo, esse comando corta esse tempo)
  cmd_primeiro_tempo <- glue("ffmpeg -i {path_jogo_raw} ", 
                             "-ss {timestamp[1]} -to {timestamp[2]} ", 
                             "-c copy -avoid_negative_ts ", 
                             "make_zero -y {path_primeiro_tempo}")
  system(cmd_primeiro_tempo)
  
  # Casos que tem mais de um tempo no mesmo arquivo
  if(length(timestamp) == 4){
    
    # Comand para cortar o segundo tempo tempo
    cmd_segundo_tempo <- glue("ffmpeg -i {path_jogo_raw} ", 
                              "-ss {timestamp[3]} -to {timestamp[4]} ", 
                              "-c copy -avoid_negative_ts ", 
                              "make_zero -y {path_segundo_tempo}")
    
    system(cmd_segundo_tempo)
    
    # Arquivo que vai ser usado pelo ffmpeg para juntar os tempos.
    # Constroi ele e o salva
    list_file_path <- tempfile(fileext = ".txt")
    segment_paths <- c(path_primeiro_tempo, path_segundo_tempo)
    lines_for_ffmpeg <- sprintf("file '%s'", segment_paths)
    writeLines(lines_for_ffmpeg, con = list_file_path)
    
    # Comando para juntar os tempos
    cmd_concatenate <- glue("ffmpeg -f concat -safe 0 -i {list_file_path} ", 
                            "-c copy -y {path_jogo_trim}")
    system(cmd_concatenate)
    
  } else{
    # Se só tiver um tempo esse vai ser o próprio arquivo - Aqui copia ele do 
    # temporário para o final
    file.copy(path_primeiro_tempo, path_jogo_trim)
  }
  
  # Remove os arquivos temporários
  file.remove(path_primeiro_tempo)
  if(file.exists(path_segundo_tempo)){
    file.remove(path_segundo_tempo)  
  }
  file.remove(list_file_path)
}