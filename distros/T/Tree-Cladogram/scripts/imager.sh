#!/bin/bash

# Great.

LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraBd.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMoBd.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationMono-Bold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraSeBd.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraSe.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeMono.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSansBold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/droid/DroidSans-Bold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraBI.ttf

# Good.

LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationMono-BoldItalic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMono.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMoIt.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/gentium-basic/GenBasR.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationMono-Regular.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationSans-Bold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationSans-Regular.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationSerif-Bold.ttf
LEAF_FONT_FILE=/usr/local/share/fonts/truetype/gothic.ttf

# OK.

LEAF_FONT_FILE=/usr/share/fonts/truetype/droid/DroidSansMono.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/gentium-basic/GenBkBasR.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeMonoBold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeMonoOblique.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeMonoBoldOblique.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSansBoldOblique.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/droid/DroidSerif-Bold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSansMono-BoldOblique.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Oblique.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
LEAF_FONT_FILE=/usr/local/share/fonts/truetype/gothic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraIt.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMoBI.ttf

# Just OK.

LEAF_FONT_FILE=/usr/share/fonts/truetype/gentium/GenR102.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationMono-Italic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationSansNarrow-Regular.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationSerif-BoldItalic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationSerif-Italic.ttf
LEAF_FONT_FILE=/usr/share/fonts/opentype/stix-word/STIX-Regular.otf
LEAF_FONT_FILE=/usr/local/share/fonts/truetype/monofont.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/gentium-basic/GenBkBasI.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/gentium-basic/GenBasI.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/gentium-basic/GenBasBI.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSans.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSansOblique.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSerif.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSerifBold.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSerifItalic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/droid/DroidSans.ttf

# Not OK.
# *.pfb
# *.otf
# And ...

LEAF_FONT_FILE=/usr/share/fonts/truetype/droid/DroidSans.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/ttf-liberation/LiberationSans-Italic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeSerifBoldItalic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/droid/DroidSerif-BoldItalic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/droid/DroidSerif-Regular.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSerif-BoldItalic.ttf
LEAF_FONT_FILE=/usr/share/fonts/truetype/dejavu/DejaVuSerif-Italic.ttf

# Try.

LEAF_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeMono.ttf

TITLE_FONT_FILE=/usr/share/fonts/truetype/freefont/FreeMono.ttf

echo Font: $LEAF_FONT_FILE

for i in nationalgeographic wikipedia; do

	echo Processing data/$i.01.png

	rm -rf data/$i.01.png $DR/misc/$i.01.png

	if [ "$i" == "wikipedia" ]; then
		FRAME=1
		TITLE='A horizontal cladogram, with the root to the left'
	else
		FRAME=0
		TITLE='The diversity of hesperornithiforms. From Bell and Chiappe, 2015'
	fi

	perl -Ilib scripts/imager.pl \
		-debug 0 \
		-draw_frame $FRAME \
		-input_file data/$i.01.clad \
		-leaf_font_file $LEAF_FONT_FILE \
		-output_file data/$i.01.png \
		-title "$TITLE" \
		-title_font_file $TITLE_FONT_FILE

	echo -n 'Calling identify ... '

	identify data/$i.01.png

	cp data/$i.01.png $DR/misc

	echo
done
