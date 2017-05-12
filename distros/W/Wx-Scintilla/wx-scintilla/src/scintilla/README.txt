This folder contains copies of the scintilla/src, scintilla/lexers and 
scintilla/include folders from the Scintilla source distribution. 

The source distribution is located in 
http://prdownloads.sourceforge.net/scintilla/scite304.zip?download

Please note that 'scintilla/lexers' is currently copied into the
scintilla/src folder.

Unneeded *.py was removed. Why? We love Python :) Unneeded *.properties 
files are also removed.

We also have the experimental LexPerl6.cxx and a modified
scintilla/src/SciLexer.h to include the Perl 6 syntax highlighter
(i.e. lexer). Once it is stable, we will push it upstream again. 

wxWidgets-specific code to embed Scintilla as a wxWidgets editor component
is located in the parent folder.

The current version of the Scintilla code is 3.0.2.