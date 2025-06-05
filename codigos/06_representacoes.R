# Cria 3 representações do resultado:
#    1. Um gif que mostra o frame original e outro em PB com os anúncios de bets
#       em cores;
#    2. Um heatmap que mostra que local da tela mais ocorrem anúncios de bets;
#    3. Uma representação que inclui todos os anúncios extraídos.

# pacotes -----------------------------------------------------------------
library(stringr)
library(magrittr)
library(dplyr)
library(magick)
library(tidyr)
library(purrr)
library(exifr)
library(sf)
library(ggplot2)

# variáveis ---------------------------------------------------------------

# Diretório estão os frames sorteados
dir_frames <- "dados/interim/frames/"

# Diretório onde estão informações sobre os frames
dir_info_frame_anotado <- "dados/interim/info_frames_anotado/"

# Diretório onde vamos salvar os frames preto e branco com os anúncios de bets
# em cores
dir_frame_bw <- "dados/interim/frames_bw/"

# Onde iremos salvar os arquivos
gif_output <- "dados/processados/representacaoes/gif_bet.gif"
path_heatmap_pdf <- "dados/processados/representacaoes/heatmap.pdf"
path_todos_comerciais <- 
  
  # Tempo entre cada frame no gid
  frame_delay_seconds <- 2

# funções -----------------------------------------------------------------

# Função para extrair as coordenadas dos polígonos onde estão as propagadas
# no frame
parse_polygon_coords <- function(x_str, y_str) {
  xy_splited <- list(x_str, y_str) %>%
    map(strsplit, ",\\s+") %>%
    map(unlist) 
  
  check_for_NA <- xy_splited %>%
    map(equals, "NA") %>%
    unlist %>%
    any
  
  # Alguns poucos poligonos tem NA nas coordendas porque não é claro onde 
  # começam ou terminam
  if(check_for_NA) return(NULL)
  
  xy_numeric <- xy_splited %>%
    map(as.numeric) %>%
    setNames(c("x",  "y"))
  
  return(xy_numeric)
}


# cria uma image preto e branco com anúncios de bets em cor ---------------
frames_path <- list.files(dir_frames, full.names = TRUE)
n_frames <- length(frames_path)

for(i_frame in seq_len(n_frames)){  
  
  cat(i_frame, "/", n_frames, "\n")
  
  # Lê o frame original
  image_path <- frames_path[i_frame]
  info_frame_path <- image_path %>%
    str_replace(".*/", dir_info_frames_anotado) %>%
    str_replace("\\....$", ".csv")
  
  # Onde iremos salvar a versão preto e branca
  frame_bw_path <- image_path %>%
    str_replace(".*/", dir_frame_bw)
  
  # Se já criamos a nova versão, passa para o próximo frame
  if(file.exists(frame_bw_path)) next
  
  # Linhas com os anúncios de bets no frame 
  textos_bets <- info_frame_path %>%
    str_replace(".*/", dir_info_frame_anotado) %>%
    str_replace("\\....$", ".csv")  %>% 
    read.csv() %>%
    filter(anuncio_bet)
  
  # Se não tiver anúncio de bets no frame passa para o próximo
  if(nrow(textos_bets) == 0) next
  
  # Lê a imagem original
  img_original <- image_read(image_path)
  
  # transforma a imagem original em preto e branca
  img_bw <- image_convert(img_original, type = 'Grayscale') %>%
    image_modulate(brightness = 10) %>%
    image_enhance() 
  
  # Para cada anúncio de bets...
  for (i in seq_len(nrow(textos_bets))) {
    
    # Extrai a linha em questão
    row <- textos_bets[i, ]
    
    # Obtêm as coordenadas do polígono onde está a propaganda
    coords_list <- parse_polygon_coords(row$x, row$y)
    
    # Se o polígono não estiver especificado (tem NA dentro das 
    # suas coordenadas), passa para o próximo
    if(is.null(coords_list)) next
    
    
    # Cria uma imagem do mesmo tamanho da imagem original
    # Inicialmente toda preta o polígono em branco    
    mask_img <- image_blank(image_info(img_original)$width,
                            image_info(img_original)$height,
                            color = "black") %>% 
      image_draw(antialias = TRUE)
    graphics::polygon(coords_list$x, coords_list$y, col = "white", border = NA)
    dev.off()
    
    # Aplica a máscara na imagem original para manter apenas a área do anúncio
    # colorida
    color_part <- image_composite(img_original, mask_img, operator = "Multiply")
    # Cria máscara inversa (branco onde era preto, preto onde era branco)
    mask_inverse <- image_negate(mask_img)
    # Aplica a máscara inversa na imagem P&B para manter tudo exceto a área do
    # anúncio
    bw_part <- image_composite(img_bw, mask_inverse, operator = "Multiply")
    
    # Converte ambas as partes para o mesmo espaço de cores
    color_part <- image_convert(color_part, colorspace = "sRGB")
    bw_part <- image_convert(bw_part, colorspace = "sRGB") 
    # Combina as duas partes: PB + área colorida do anúncio
    img_bw <- image_composite(color_part, bw_part, operator = "Plus")
  }
  # Salva a imagem
  image_write(img_bw, frame_bw_path)
}

# # cria um gif -------------------------------------------------------------


# Aqui são os frames que selecionamos
# (como esqueci de colocar o seed no código que sorteamos os frames, o gif não 
# será o mesmo que está na reportagem, então sugiro inspecionar a pasta com os
# gis pb para selecionar)
frames_selecionados <- c("cruzeiro-x-sao-paulo_033.jpg",
                         "flamengo-x-cruzeiro_001.jpg",
                         "palmeiras-x-bahia_002.jpg",
                         "palmeiras-x-bahia_028.jpg",
                         "sport-x-palmeiras_017.jpg",
                         "botafogo-x-internacional_032.jpg",
                         "corinthinas-x-vasco_023.jpg",
                         "botafogo-x-internacional_054.jpg",
                         "corinthinas-x-vasco_101.jpg",
                         "cruzeiro-x-bragantino-2t_049.jpg",
                         "vasco-x-fortaleza_020.jpg",
                         "corinthinas-x-vasco_071.jpg",
                         "cruzeiro-x-bahia_097.jpg",
                         "cruzeiro-x-sao-paulo_085.jpg",
                         "corinthinas-x-vasco_014.jpg",
                         "fortaleza-x-palmeiras_011.jpg") %>%
  sample()


# Alterna os paths dos frames originais com suas versões PB
animation <- rbind(file.path(dir_frames, frames_selecionados),
                   file.path(dir_frame_bw, frames_selecionados)) %>%
  as.vector() %>% 
  # Lê os frames
  map(image_read) %>%
  # Junta e faz o gif
  image_join() %>% 
  image_animate(fps = 1 / frame_delay_seconds)

# Salva o gif
image_write(animation, path = output_gif_path)


# heatmap de onde aparecem os anúncios ------------------------------------


# Data frame só com as linhas de bets
df_bet <- dir_info_frame_anotado %>% 
  list.files(full.names = TRUE) %>%
  map(read.csv, colClasses = "character") %>% 
  bind_rows() %>%  
  mutate(anuncio_bet = as.logical(anuncio_bet)) %>% 
  filter(anuncio_bet) 

# Tamanho dos frames
dimensions_df <- df_bet %>%
  pull(image_path) %>% 
  unique() %>%
  read_exif(tags = c("ImageWidth", "ImageHeight"))


# Data frame com as coordenas dos poligonos em forma de vetores
df_bet2 <- df_bet %>%
  # Adiciona o tamanho dos frames no data frame
  left_join(dimensions_df, by = c("image_path" = "SourceFile")) %>%
  # Separa os números das coordenadas dos poligonos de bets
  mutate(x_coords = str_split(x, ", ")) %>%
  mutate(y_coords = str_split(y, ", ")) %>%
  # Remove poligonos que não tem todas as coordenadas
  mutate(tem_na_x = map(x_coords, equals, "NA") %>% map_lgl(any),
         tem_na_y = map(y_coords, equals, "NA") %>% map_lgl(any))   %>%
  filter(!tem_na_x)  %>%
  filter(!tem_na_y) %>%
  # Obterm as coordenadas e as normaliza para um frame de 1600 x 900
  mutate(x_coords = map(x_coords, as.numeric),
         y_coords = map(y_coords, as.numeric)) %>%
  mutate(x_coords_norm = map2(x_coords, ImageWidth, ~ (.x / .y) * 1600),
         y_coords_norm = map2(y_coords, ImageHeight, ~ (.x / .y) * 900)) 

# Transforma as coordenadas em sfc_POLYGON
df_polygons_sf <- df_bet2 %>%
  mutate(coords_matrix = map2(x_coords_norm,y_coords_norm, ~ {
    cbind(c(.x, .x[1]), c(.y, .y[1]))
  })) %>%
  mutate(geometry = map(coords_matrix, ~ st_polygon(list(.x)))) %>%
  st_as_sf()

# Grid do heatmap - Esse é um grid compostos por células de 1 x 1. Contaremos 
# a quantidade de poligonos que estão presentes em cada célula
grid <- st_make_grid(st_as_sfc(st_bbox(c(xmin = 0, xmax = 1600, 
                                         ymin = 0, ymax = 900))),
                     cellsize = c(1, 1), 
                     what = "polygons") %>% 
  st_sf() %>% 
  mutate(cell_id = row_number())

# Cria objeto com as interções de poligonos com o grid
interseccoes_grid_poli <- st_intersects(grid, df_polygons_sf)

# Conta a quantidade de poligonos em cada célula do grid
heatmap_df <- grid %>%
  # Quantidade de polígonos
  mutate(n_poligonos = lengths(interseccoes_grid_poli)) %>%
  # Quantos % dos frames tem políogno nessa célula
  mutate(porcentagem_poly = (n_poligonos / n_frames) * 100) %>%
  # Centro dos poligonos para representar o X e Y
  st_centroid() %>%
  mutate(x = st_coordinates(.)[, 1],
         y = st_coordinates(.)[, 2]) %>%
  st_drop_geometry()

# Plota
p <- ggplot(heatmap_df, aes(x = x, y = y, fill = porcentagem_poly)) +
  geom_raster(interpolate = FALSE) +
  scale_fill_gradientn(colours = c("#b4d2ee", "#4085c5", "#5b3b8c",
                                   "#420e44", "#ac362e"),
                       name = paste0("% dos Frames com propaganda de apostas", 
                                     "\n na região")) +
  scale_y_reverse() +
  coord_fixed(ratio = 1, xlim = c(0,1600), ylim = c(0,900), expand = FALSE) + 
  theme_minimal() +
  theme(plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        panel.grid = element_blank(),
        axis.text.x = element_blank(),
        panel.border = element_blank()) +
  labs(title = "", x = "", y = "")

# Salva
ggsave(path_heatmap_png, plot = p,
       width = 10, height = (900/1600)*10, dpi = 300, bg = "white")

# imagem com todos os anuncios --------------------------------------------

# Tamanho que a nossa tela terá. Tem frames com definições diferentes, logo
# vamos precisar converter para uma mesma escala
img_largura <- 1920
img_altura <- 1080


# Imagem que irá receber os anúncios. Uma imagem com fundo preto
img_mascara_all <- image_blank(img_largura, img_altura, color = "black")

for(i_frame in seq_len(n_frames)){  
  
  cat(i_frame, "/", n_frames, "\n")
  
  # Path da imagem original
  image_path <- frames_path[i_frame]
  
  # Informações das propaganfas de bets
  textos_bets <- image_path %>%
    str_replace(".*/", dir_info_frame_anotado) %>%
    str_replace("\\....$", ".csv")  %>% 
    read.csv() %>%
    filter(anuncio_bet)
  
  # Se não tiver nenhum anúncio de bet passamos para o próximo frame
  if(nrow(textos_bets) == 0) next
  
  # Lê a imagem original
  img_original <- image_read(image_path)
  
  # Tamanho da imagem do frame
  original_largura <- image_info(img_original)$width
  original_altura <- image_info(img_original)$height
  
  # Se a altura do frame for diferente da nossa base, muda a imagem
  # e quarda a escala
  if(original_largura != img_largura || original_altura != img_altura) {
    img_original <- image_resize(img_original, 
                                 paste0(img_largura, "x", img_altura, "!"))
  } 
  scale_x <- img_largura / original_largura
  scale_y <- img_altura / original_altura
  
  # Para cada anúncio no frame...
  for (i in seq_len(nrow(textos_bets))) {
    
    # Obtêm informações do anúncio
    row <- textos_bets[i, ]
    coords_list <- parse_polygon_coords(row$x, row$y)
    if(is.null(coords_list)) next
    
    # Cordenadas rescalonadas
    coords_list$x <- coords_list$x * scale_x
    coords_list$y <- coords_list$y * scale_y
    
    # Máscara do poligono
    polygon_mask <- image_blank(img_largura, img_altura, color = "black") %>% 
      image_draw(antialias = TRUE)
    graphics::polygon(coords_list$x, coords_list$y, col = "white", border = NA)
    dev.off()
    
    # Extrai a image do anúncio
    ad_content <- image_composite(img_original, polygon_mask, 
                                  operator = "Multiply")
    
    # Adiciona transparência
    ad_content_transparent <- image_modulate(ad_content, brightness = 30) 
    
    # Adiciona na imagem final
    img_mascara_all <- image_composite(img_mascara_all, ad_content_transparent, 
                                       operator = "Lighten")
  }
}