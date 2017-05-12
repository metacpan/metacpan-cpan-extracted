
# Saving images from OpenOffice Draw is a pain, it can't save a decent
# scalable .svg and screws up the resolution in .png. So save as .eps
# and use convert:

SRC_EPS := $(wildcard *.eps)
LOWRES_PNGS =  $(SRC_EPS:.eps=.lowres.png)

all: $(LOWRES_PNGS)

clean:
	rm -f .depends .depends.tmp *.png *.gif *.tiff *.svg

%.png: %.eps
	convert -depth 1 -density 1200 $< $@

# For HTML version generate a low-resolution but high-depth picture
%.lowres.png: %.eps
	convert -density 100 $< $@

# For the already-png files, just copy them
%.lowres.png: %.png_orig
	 convert -geometry 450x550 $< $@

# .tiff gives the real depth 1 images, much smaller than png
%.tiff: %.eps
	convert -depth 1 -compress Group4 -density 1200 $< $@

# the correct way to produce svg from eps
%.svg: %.eps
	./eps2svg $< $@

# just rename from the suffix that makes sure that the file won't be deleted
%.png: %.png_orig
	cp $< $@
