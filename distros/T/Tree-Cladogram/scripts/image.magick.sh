#!/bin/bash

# Great.

LEAF_FONT_FILE=Courier
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSans-ExtraLight.ttf
LEAF_FONT_FILE=DejaVu-Sans-ExtraLight

# shell> fc-list | grep n022003l
# /usr/share/fonts/type1/gsfonts/n022003l.pfb: Nimbus Mono L:style=Regular

LEAF_FONT_FILE=/usr/share/fonts/type1/gsfonts/n022003l.pfb
# Aka
LEAF_FONT_FILE=Nimbus-Mono-L

# Good.

LEAF_FONT_FILE=Courier-10-Pitch-Italic

# OK.

LEAF_FONT_FILE=Liberation-Mono

# Just OK.

# These 2 are the same.

LEAF_FONT_FILE=Gentium
LEAF_FONT_FILE=Gentium-Basic

# Not OK.

LEAF_FONT_FILE=/usr/share/fonts/type1/gsfonts/p052003l.pfb
LEAF_FONT_FILE=Helvetica-Narrow-Oblique
LEAF_FONT_FILE=Palatino-Italic
LEAF_FONT_FILE=Century-Gothic
LEAF_FONT_FILE=Cantarell-Regular
LEAF_FONT_FILE=Free-Mono
LEAF_FONT_FILE=AvantGarde-Book

# Try.

LEAF_FONT_FILE=FreeMono

TITLE_FONT_FILE=FreeMono

echo Font: $LEAF_FONT_FILE

for i in nationalgeographic wikipedia; do

	echo Processing data/$i.01.png

	rm -rf data/$i.02.png $DR/misc/$i.02.png

	if [ "$i" == "wikipedia" ]; then
		FRAME=1
		TITLE='A horizontal cladogram, with the root to the left'
	else
		FRAME=0
		TITLE='The diversity of hesperornithiforms. From Bell and Chiappe, 2015'
	fi

	perl -Ilib scripts/image.magick.pl \
		-debug 0 \
		-draw_frame $FRAME \
		-input_file data/$i.01.clad \
		-leaf_font_file $LEAF_FONT_FILE \
		-output_file data/$i.02.png \
		-title "$TITLE" \
		-title_font_file $TITLE_FONT_FILE

	echo -n 'Calling identify ... '

	identify data/$i.02.png

	cp data/$i.02.png $DR/misc

	echo
done
