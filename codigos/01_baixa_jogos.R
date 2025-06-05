# Baixa todos os vídeos dos jogos presentes nas URLs no arquivo 
# dados/brutos/urls_jogos.txt e os salva no diretório dados/brutos/video_jogos

# pacotes -----------------------------------------------------------------
library(stringr)
library(glue)
library(dplyr)

# variáveis ---------------------------------------------------------------

# Diretório onde vamos salvar os vídeos
dir_jogos <- "dados/brutos/video_jogos"
# Arquivo com informação sobre os jogos
path_urls <- "dados/brutos/urls_jogos.txt"


# baixa -------------------------------------------------------------------

# URLs dos jogos para baixarmos
urls <- path_urls %>%
  readLines()

# Quantidade de jogos e indexes deles
#    cada jogo tem duas linhas no arquivo. Uma com as informações dele e outra
#    com o URL
indexes_urls <- seq(1, length(urls), 2)
count <- 1
total <- length(indexes_urls)

for(i_url in indexes_urls){
  cat(count, "/", total,  "\n")
  count <- count + 1

  # extrai o ID do jogo  a partida da linha com as informações
  descricao_jogo <- urls[[i_url]] %>%
    str_remove("^#\\s+") %>%
    str_remove("\\s+\\|.*") %>%
    str_trim() %>%
    tolower() %>%
    iconv(to="ASCII//TRANSLIT") %>%
    str_replace_all("\\s+", "-")

  # Verifica se já baixamos o jogo
  path_video <- glue("{dir_jogos}/{descricao_jogo}.mp4")
  if(file.exists(path_video)) next

  url_jogo <- urls[[i_url + 1]]
  cat("URL:", url_jogo, "\n")

  # Comando do yt-dlp para baixar
  cmd_baixa <- glue("yt-dlp --verbose -f 'bv+ba/b' --merge-output-format mp4 -o ",
                    "'{path_video}' {url_jogo}")
  system(cmd_baixa)
  
  # Dá um tempo porque às vezes o yt-dlp não funciona logo na seguência
  Sys.sleep(5) 
}