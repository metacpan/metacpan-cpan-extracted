PNG = ../htdocs/help-20px.png ../htdocs/help-16px.png

all: $(PNG)

../htdocs/%.png: help.xcf
	@echo Sorry, no can do.

# I'd like to make $(PNG) automatically from the .xcf master, but
# there doesn't seem to a be a sensible way to do this, since only
# GIMP knows about .xcf format, and driving it without the UI is
# super-painful and involves Lisp.

