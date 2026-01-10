#!/bin/bash

input=$1
output=$2

if [ -z "$input" ]; then
    echo "Usage: $0 input-path output-path"
    exit 1
fi
if [ -z "$output" ]; then
    echo "Usage: $0 input-path output-path"
    exit 1
fi

mask="mask-${output}.png"
feathered="feathered-${output}.png"
bordered="bordered-${output}.png"


magick $input \
          \( -clone 0 -blur 0x16 +level 5%x100% \) \
          \( -clone 0 -resize 50% -bordercolor black -border 1x1 \) \
          -delete 0 -gravity center -composite -flatten $bordered 
magick $bordered -fill white -colorize 100 -virtual-pixel Black -blur 0x250 -level 50,100% $mask
magick $bordered $mask -alpha off -compose CopyOpacity -composite $feathered
magick $feathered -background black -flatten $output

rm $mask
rm $feathered
rm $bordered

