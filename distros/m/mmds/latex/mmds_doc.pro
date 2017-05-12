% sq_doc.pro -- -*-postscript-*-
% RCS Status      : $Id: mmds_doc.pro,v 1.3 2002-11-27 22:17:19+01 jv Exp $
% Author          : Johan Vromans
% Created On      : Mon Jan 27 18:23:26 1992
% Last Modified By: Johan Vromans
% Last Modified On: Wed Nov 27 22:17:11 2002
% Update Count    : 35
% Status          : Unknown, Use with caution!

/rcrnr 5 def
/rbox {
  /y1 exch def
  /x1 exch def
  /y0 exch def
  /x0 exch def
  gsave
   newpath
      y1 rcrnr sub x0 moveto
      y1 x0 y1 x1 rcrnr arcto 4 {pop} repeat
      y1 x1 y0 x1 rcrnr arcto 4 {pop} repeat
      y0 x1 y0 x0 rcrnr arcto 4 {pop} repeat
      y0 x0 y1 x0 rcrnr arcto 4 {pop} repeat
   closepath 0.75 setlinewidth stroke
  grestore } def

/border { 53 51 785 532 rbox } def

/p_border {
    % border for overhead sheets, with logo, A4 portrait
    border
    gsave
    %332 42 moveto 153 0 rlineto 0 30 rlineto -153 0 rlineto closepath
    %1 setgray fill
    %344 50 1.33 0 0 logo
    grestore
} def
/p_noborder {} def

/l_border {
    % border for overhead sheets, with logo, A4 landscape
    border
    gsave
    %535 583 moveto 0 154 rlineto -30 0 rlineto 0 -154 rlineto closepath
    %1 setgray fill
    %535 595 1.33 1 0 logo
    grestore
    840 10 translate 90 rotate
} def
/l_noborder { 840 10 translate 90 rotate } def

/lh_border {
    % border for handouts of overhead sheets, with logo, A4 portrait
    20 845 translate 0.7 0.7 scale -90 rotate
    l_border
} def
/lh_noborder { 20 845 translate 0.7 0.7 scale -90 rotate l_noborder } def

/ph_border {
    % border for handouts of overhead sheets, with logo, A4 portrait
    19 266 translate 0.7 0.7 scale
    p_border
} def
/ph_noborder { 19 266 translate 0.7 0.7 scale p_noborder } def

/Squirrel 20 dict def
Squirrel begin
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
%/Garamond-LightItalicOutline findfont 36 scalefont setfont 
%  93 503 moveto (Squirrel Consultancy) show
%  93 503 moveto (Squirrel Design) show
%  213 470 moveto (& Consultancy) show
545 767 translate
-0.25 0.25 scale
%  BoundingBox: -2 -3 140 168
%gsave
%1 setgray
%-2 -3 m 0 168 rlineto 140 0 rlineto 0 -168 rlineto closepath fill
%grestore
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

/std_logo {
    % Normal logo at the normal position on the paper.
    443 781 1 0 0 Squirrel begin LogoBW end
} def

/overlay {
    userdict /overlaytext known {
	gsave
	/Times-Roman findfont 100 scalefont setfont
	0.95 setgray
	userdict /isoddpage known 
%	{700 200 moveto 145 rotate}	% older dvips
	{300 400 moveto -35 rotate} 
	{200 300 moveto 55 rotate} ifelse
	overlaytext show
	grestore
    }
    if
} def
