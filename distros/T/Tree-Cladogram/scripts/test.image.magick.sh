#!/bin/bash

rm data/test.image.magick.png

perl scripts/test.image.magick.pl data/test.image.magick.png

echo -n 'Calling identify ... '

identify data/test.image.magick.png

# Output to my web server's doc root, which is in Debian's RAM disk.

cp data/test.image.magick.png $DR/misc
