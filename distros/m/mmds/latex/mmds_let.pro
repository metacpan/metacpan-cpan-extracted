% sqd_let.pro -- 
% RCS Status      : $Id: sq_let.pro,v 1.4 1999-10-27 13:35:53+02 jv Exp $
% Author          : Johan Vromans
% Created On      : Fri Mar 18 13:05:36 1994
% Last Modified By: Johan Vromans
% Last Modified On: Wed Jan 21 12:15:34 1998
% Update Count    : 22
% Status          : Unknown, Use with caution!

%%BeginProcSet: Squirrel 0 0
/Squirrel 20 dict def
Squirrel begin
/MakeOutlineFont
  {	/uniqueid exch def
	/strokewidth exch def
	/newfontname exch def
	/basefontname exch def

	/basefontdict basefontname findfont def
	
	/numentries basefontdict maxlength 1 add def
	
	basefontdict /UniqueID known not
	  { /numentries numentries 1 add def } if
	  
	/outfontdict numentries dict def

	basefontdict
	  { exch dup /FID ne
		  { exch outfontdict 3 1 roll put }
		  { pop pop }
		  ifelse
		} forall
		
	outfontdict /FontName newfontname put
	outfontdict /PaintType 2 put
	outfontdict /StrokeWidth strokewidth put
	outfontdict /UniqueID uniqueid put
	
	newfontname outfontdict definefont pop
  } def

/Garamond-LightItalic /Garamond-LightItalicOutline 1000 80 div 

  /Garamond-LightItalic findfont dup /UniqueID known
    { /UniqueID get 1 add }
    { pop 1 }
    ifelse
  MakeOutlineFont

/m { moveto } def
/c { curveto } def
/s { stroke } def
/g { setgray } def
/f { fill } def

/Logo {
gsave
0 setgray
1.5 setlinewidth
0.025 1 0.8 sethsbcolor
DoLogo } def
/LogoBW {
gsave
0 setgray
1 setlinewidth
DoLogo } def
/DoLogo {
/Garamond-LightItalicOutline findfont 36 scalefont setfont 
  93 503 moveto (Squirrel Consultancy) show
%  93 503 moveto (Squirrel Design) show
%  213 470 moveto (& Consultancy) show
40 504 translate
0.5 0.5 scale
% back
37 19.5 m
34 39.5 34 36 36 51.5 c
37.4077 62.4095 42.85 68.818 45 70.5 c
51.375 75.487 67 85 79.5 92 c
93.235 99.691 90.033 100.001 93.5 105.5 c
97.3159 111.5524 99.3711 126.1264 98.5 134 c
s
% head
101 133.5 m
98.5 118.5 106.8905 108.9708 110.5 108.5 c
122 107 126 97.25 129 90.25 c
134.7101 76.9264 133.9855 71.9423 124.375 71 c
118 70.375 116.75 70.25 106 73.5 c
s
% arm
99 71.5 m
111 59.5 121.063 65.097 131.168 62.578 c
138.5 60.75 140 52.25 134.5 52.5 c
129 52.75 136 55 125 54.5 c
114.6964 54.0311 95.5 39 71 59 c
s
% leg
61.5 46 m
65.762 50.262 74.9 52.675 80 52.25 c
86 51.75 88.469 49.054 90.134 45.336 c
93.076 38.764 92.154 31.111 89.865 24.727 c
86.255 14.66 82.031 12.546 75 4.5 c
s
% foot, tail
59.125 80 m
62.4084 87.4283 78 103.5 70 136 c
64.1001 159.9675 48.984 164.628 33 165.5 c
19.25 166.25 -2 161.507 -2 145.5 c
-2 138 2.5 129 18 123.5 c
56.6107 109.799 19 57.5 20.5 24.5 c
20.9754 14.0406 36.11 -0.886 46.5 -2 c
53.374 -2.736 91.353 -2.595 98.5 -2 c
104.5 -1.5 103.25 6.25 96.75 8.5 c
89.255 11.094 85.387 8.567 78.5 7.5 c
s
% eye
115.1194 89.3333 m
117.1013 87.6703 119.522 87.2922 120.5261 88.4888 c
121.5302 89.6854 120.7375 92.0037 118.7556 93.6667 c
116.7737 95.3297 114.353 95.7078 113.3489 94.5112 c
112.3448 93.3146 113.1375 90.9963 115.1194 89.3333 c
f
% neck
109.125 72.625 m
107.375 68.375 106.6515 69.0762 104.875 66.8125 c
s
grestore
} def
end
%%EndProcSet

/overlay {
    userdict /overlaytext known {
	gsave
	/Times-Roman findfont 100 scalefont setfont
	0.95 setgray
	userdict /isoddpage known 
	{300 400 moveto -35 rotate} 
	{200 300 moveto 55 rotate} ifelse
	overlaytext show
	grestore
    }
    if
} def
