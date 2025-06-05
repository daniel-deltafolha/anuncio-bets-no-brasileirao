# Análise de Anúncios de Bets em Transmissões do Campeonato Brasileiro 2025

Este projeto consiste em uma série de scripts em R para baixar vídeos de jogos, processá-los para extrair frames, detectar texto de anúncios de apostas e, por fim, realizar análises e visualizações dos dados coletados.

## Visão Geral dos Scripts

O fluxo de trabalho é dividido nos seguintes scripts, que devem ser executados em ordem:
  
1.  **`01_baixa_jogos.R`**:
* Lê URLs de um arquivo de texto (`dados/brutos/urls_jogos.txt`).
* Baixa os vídeos correspondentes utilizando `yt-dlp`.
* Salva os vídeos em `dados/brutos/video_jogos/`.

2.  **`02_corta_filmes.R`**:
* Processa os vídeos baixados.
* Utiliza timestamps (definidos no mesmo arquivo `urls_jogos.txt`) para cortar os vídeos entre o começo e fim dos tempos.
* Salva os vídeos cortados em `dados/interim/jogos_trim/`.

3.  **`03_extrai_frames.R`**:
* Extrai frames dos vídeos cortados.
* Seleciona um frame aleatório por minuto de vídeo.
* Salva os frames em `dados/interim/frames/`.

4.  **`04_extrai_info_frame.R`**:
* Utiliza a API Google Cloud Vision para detectar texto em cada frame extraído.
* Identifica a presença de palavras-chave relacionadas a apostas (ex: "bet", "aposta", "cassino").
* Salva os resultados da detecção e a anotação sobre anúncios de apostas em arquivos CSV em `dados/interim/info_frames/` e `dados/interim/info_frames_anotado/`.

5.  **`05_analise.R`**:
* Agrega os dados de todos os frames analisados.
* Calcula estatísticas, como a porcentagem de frames com anúncios de apostas e a média de anúncios por frame/jogo.
* Mapeia os jogos para as respectivas transmissões.
* Salva os dados processados em csvs em `dados/processados/tabelas/`.

6.  **`06_representacoes.R`**:
* Cria visualizações a partir dos dados e frames.
* Gera imagens em preto e branco com os anúncios de apostas destacados em cores.
* Produz um GIF com exemplos de frames com e sem o destaque dos anúncios.
* Cria um heatmap para mostrar as regiões da tela onde os anúncios de apostas mais aparecem.
* Gera uma imagem consolidada com todos os anúncios detectados sobrepostos.
* Salva as saídas em `dados/processados/representacaoes/`.

## Estrutura de Diretórios Esperada
```
.
├── dados/
│   ├── brutos/
│   │   ├── video_jogos/     # Vídeos baixados
│   │   ├── urls_jogos.txt   # Lista de URLs e timestamps
│   │   └── chave-google.json # Chave da API Google Cloud Vision
│   ├── interim/
│   │   ├── frames/          # Frames sorteados serão colocados aqui
│   │   ├── frames_bw/       # Frames com anúncios destacados
│   │   ├── info_frames/     # Resultados brutos da detecção de texto
│   │   ├── info_frames_anotado/ # Resultados anotados com identificação de bets
│   │   └── jogos_trim/      # Vídeos após o corte
│   ├── processados/
│   │   ├── tabelas/         # Tabelas com o resultado da análise
│   └   └── representacaoes  # Representação gráfica dos resultados
├── codigos/
│   ├── 01_baixa_jogos.R
│   ├── 02_corta_filmes.R
│   ├── 03_extrai_frames.R
│   ├── 04_extrai_info_frame.R
│   ├── 05_analise.R
│   ├── 06_representacoes.R
└── README.md
```


## Requisitos

* R
* Pacotes R: `magrittr`, `stringr`, `purrr`, `glue`, `jsonlite`, `dplyr`, `av`, `googleCloudVisionR`, `googleAuthR`, `magick`, `tidyr`, `exifr`, `sf`, `ggplot2`.
* `yt-dlp` (para o script `01_baixa_jogos.R`)
* `ffmpeg` (para os scripts `02_corta_filmes.R` e `03_extrai_frames.R`)
* Uma chave de API do Google Cloud Vision em formato JSON (nomeada `chave-google.json` e localizada em `dados/brutos/`).

## Como Usar

1.  Configure o ambiente com todos os requisitos.
2.  Crie a estrutura de diretórios conforme descrito acima.
3.  Adicione o arquivo `urls_jogos.txt` em `dados/brutos/` com as URLs dos vídeos e os respectivos timestamps para corte. O formato esperado no `urls_jogos.txt` é:
    ```
    # NOME DO JOGO 1 | HH:MM:SS (QDO COMEÇA O 1ºT) | HH:MM:SS (QDO TERMINA O 1ºT) | HH:MM:SS (QDO COMEÇA O 2ºT) | HH:MM:SS (QDO TERMINA O 2ºT)
    URL_DO_VIDEO_1
    # NOME DO JOGO 2 (QUE SÓ TEM UM TEMPO) | HH:MM:SS (QDO COMEÇA O TEMPO) | HH:MM:SS (QDO TERMINA O TEMPO)
    URL_DO_VIDEO_2
    ```
4.  Coloque sua chave da API Google Cloud Vision (`chave-google.json`) em `dados/brutos/`.
5.  Execute os scripts R na ordem numérica (01 a 06).