# Obtém informação dos textos contidos em cada frame atraǘes do 
# Google Cloud Vision

# pacotes -----------------------------------------------------------------
library(googleCloudVisionR)
library(googleAuthR)
library(stringr)
library(dplyr)
library(purrr)

# variáveis ---------------------------------------------------------------

# Chave do Google Cloud Vision
json_key_path <- "dados/brutos/chave-google.json"

# Diretório estão os frames sorteados
dir_frames <- "dados/interim/frames/"

# Diretório que iremos salvar o output bruto do Google Cloud Vision
dir_info_frames <- "dados/interim/info_frames/"
# Diretório que iremos salvar o output com a anotação dos comerciais de bets
dir_info_frame_anotado <- "dados/interim/info_frames_anotado/"

# autentificacao ----------------------------------------------------------
gar_auth_service(json_file = json_key_path)

# processamento -----------------------------------------------------------
frames_path <- list.files(dir_frames, full.names = TRUE)
n_frames <- length(frames_path)


# Regex que iremos usar para identificar as bets
palavras_bets <- c("bet", "aposta", "cassino", "sorte", "365", "apostou",
                   "pitaco", "alfa", "^7K$", "etano", "SUPERBE") %>%
  paste0(collapse = "|")

for(i_frame in seq_len(n_frames)){  
  
  cat(i_frame, "/", n_frames, "\n")
  
  # Input - arquivo do frame
  image_path <- frames_path[i_frame]
  # Output - arquivo csv do Google Cloud Vision
  info_frame_path <- image_path %>%
    str_replace(".*/", dir_info_frames) %>%
    str_replace("\\....$", ".csv")
  
  # Caso não tenha ainda, se obtém o resultado para Google Cloud Vision
  if(!file.exists(info_frame_path)) {
    repeat{
      textos <- gcv_get_image_annotations(imagePaths = image_path,
                                          feature = "TEXT_DETECTION")
      # Quando tem um erro se tenta de novo após 1 minuto
      # Caso contrário se salva o arquivo
      if(!"error_code" %in% colnames(textos)) {
        # Salva
        write.csv(textos, info_frame_path, row.names = FALSE)
        break
      }
      Sys.sleep(60)
    }
  } else {
    # Se já processamos o frame, se lê o arquivo salvo
    textos <- read.csv(info_frame_path)
  }
  
  # Onde se salvará o arquivo com anotações de bets
  path_info_frame_anotado <- image_path %>%
    str_replace(".*/", dir_info_frame_anotado) %>%
    str_replace("\\....$", ".csv")
  
  # Se o arquivo ainda não foi anotado, o anota e salva
  if(!file.exists(path_info_frame_anotado)){
    textos_anotado <- textos %>%
      mutate(anuncio_bet = str_detect(description, 
                                      regex(palavras_bets, 
                                            ignore_case = TRUE)))
    write.csv(textos_anotado, path_info_frame_anotado, row.names = FALSE)
  }
}