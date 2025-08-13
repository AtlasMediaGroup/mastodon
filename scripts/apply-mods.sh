#!/bin/bash

set -euxo pipefail
shopt -s expand_aliases

MAX_STATUS_CHARS=500 # this is currently unchanged on stable-4.3
MAX_FEED_ITEMS=1600

# Media Attachments:
MAX_MATRIX_LIMIT=70_000_000 # 10000x7000px, default: 7680x4320px
GIF_MATRIX_LIMIT=14_822_400 # 3840x3860px, default: 1280x720px
IMAGE_LIMIT="99.megabytes" # in megabytes, default: 16mb
MAX_VIDEO_FRAMES="144_000" # # Approx. 20 minutes at 120 fps, default: 5 minutes at 120 fps

# Required because sed is different on mac..
if [[ "$OSTYPE" == "darwin"* ]]; then
  if type gsed &>/dev/null; then
    alias sed=gsed
  else
    echo "requires: brew install gnu-sed"
  fi
fi

# Ensure we're in the mastodon code directory, not the scripts directory:
currentDirectory=$(basename "$PWD")
if [ "$currentDirectory" = "scripts" ]; then
  cd ../
fi

# Change status max-length setting:
sed -i "s/^\(.*MAX_CHARS = \).*/\1$MAX_STATUS_CHARS/" app/validators/status_length_validator.rb

# Change feed settings:
sed -i "s/^\(.*MAX_ITEMS = \).*/\1$MAX_FEED_ITEMS/" app/lib/feed_manager.rb

# Change media settings:
sed -i "s/^\(.*MAX_MATRIX_LIMIT = \).*/\1$MAX_MATRIX_LIMIT/" app/models/concerns/attachmentable.rb
sed -i "s/^\(.*GIF_MATRIX_LIMIT = \).*/\1$GIF_MATRIX_LIMIT/" app/models/concerns/attachmentable.rb

sed -i "s/^\(.*IMAGE_LIMIT = \).*/\1$IMAGE_LIMIT/" app/models/media_attachment.rb
sed -i "s/^\(.*MAX_VIDEO_FRAMES.*= \).*/\1$MAX_VIDEO_FRAMES/" app/models/media_attachment.rb

sed -i "s/pixels: 8_294_400, # 3840x2160px/pixels: 9_830_400, # 3840x2560px/" app/models/media_attachment.rb

# change indexing by search engines:
sed -i "s/noindex/index/" app/views/home/index.html.haml

# increase rate limits
sed -i "s/'throttle_authenticated_api', limit: 1_500/'throttle_authenticated_api', limit: 3000/" config/initializers/rack_attack.rb
sed -i "s/'throttle_per_token_api', limit: 300/'throttle_per_token_api', limit: 1_500/" config/initializers/rack_attack.rb
sed -i "s/'throttle_unauthenticated_paging', limit: 300/'throttle_unauthenticated_paging', limit: 600/" config/initializers/rack_attack.rb
