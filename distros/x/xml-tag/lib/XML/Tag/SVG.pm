package XML::Tag::SVG;
use Exporter 'import';
use XML::Tag;
# lynx -dump 'https://developer.mozilla.org/en-US/docs/Web/SVG/Element' |perl -0 -nE '$E{$1}++ while /<(.*?)>/g; END { say for keys  %E}'
BEGIN {
    our @EXPORT = qw<

polyline
hkern
fecolormatrix
glyphref
animatetransform
view
g
desc
clippath
textpath
line
femergenode
altglyph
symbol
fefuncb
foreignobject
femorphology
defs
fefuncg
title
font-face-src
fefunca
missing-glyph
feimage
cursor
mpath
fepointlight
color-profile
text
set
mask
fespotlight
filter
style
path
tref
image
fetile
feblend
switch
fecomposite
feconvolvematrix
glyph
font-face-format
femerge
a
font
fecomponenttransfer
fefuncr
ellipse
fespecularlighting
animate
lineargradient
metadata
feflood
animatemotion
animatecolor
fegaussianblur
circle
fedisplacementmap
altglyphitem
font-face-uri
fedistantlight
font-face
tspan
font-face-name
altglyphdef
marker
use
rect
script
stop
feoffset
feturbulence
vkern
pattern
radialgradient
fediffuselighting
polygon
svg

        >;
    ns '' => @EXPORT;
};

1;
