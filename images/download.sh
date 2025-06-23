#!/bin/bash

# Google Drive dosya ID'si
FILE_ID="1Xf_O8pprBlkvgMcjBodDnoYdFOh6JFC9"
# İndirilen dosyanın kaydedileceği yer
DESTINATION_PATH="./downloaded_file.ext"

# İlk istekte onay kodunu almak
CONFIRM=$(wget --quiet --save-cookies cookies.txt --no-check-certificate \
  "https://drive.google.com/uc?export=download&id=$FILE_ID" -O- | \
  sed -n 's/.*confirm=\([^&]*\).*/\1/p')

# Eğer onay kodu alınamamışsa
if [ -z "$CONFIRM" ]; then
    CONFIRM="NO_CONFIRM"
fi

# İkinci isteği yaparak dosyayı indirmek
if [ "$CONFIRM" != "NO_CONFIRM" ]; then
    wget --load-cookies cookies.txt \
      "https://drive.google.com/uc?export=download&confirm=$CONFIRM&id=$FILE_ID" \
      -O "$DESTINATION_PATH"
else
    wget --load-cookies cookies.txt \
      "https://drive.google.com/uc?export=download&id=$FILE_ID" \
      -O "$DESTINATION_PATH"
fi

# Çerez dosyasını temizle
rm cookies.txt

echo "İndirme tamamlandı!"
