# $Revision:   1.3  $

all: tparse

tparse: RFC822\Parser.pm

RFC822\Scanner.pm: RFC822\rfc822.l
	perl ..\lib\Scanner\plex -Ce RFC822\rfc822.l RFC822::Scanner

RFC822\Parser.pm: RFC822\rfc822.y RFC822\Scanner.pm
	perl ..\lib\Parser\ppar RFC822\rfc822.y RFC822::Parser RFC822::Scanner

test:
	@perl ..\lib\Scanner\plex RFC822\rfc822.l RFC822::Scanner
	@perl ..\lib\Parser\ppar RFC822\rfc822.y RFC822::Parser RFC822::Scanner
	@echo plain plain
	@perl tparse.pl
	@perl tparse.pl -str
	@perl ..\lib\Scanner\plex RFC822\rfc822.l RFC822::Scanner
	@perl ..\lib\Parser\ppar -dfa RFC822\rfc822.y RFC822::Parser RFC822::Scanner
	@echo plain DFA
	@perl tparse.pl
	@perl tparse.pl -str
	@perl ..\lib\Scanner\plex -Ce RFC822\rfc822.l RFC822::Scanner
	@perl ..\lib\Parser\ppar RFC822\rfc822.y RFC822::Parser RFC822::Scanner
	@echo Ce plain
	@perl tparse.pl
	@perl tparse.pl -str
	@perl ..\lib\Scanner\plex -Ce RFC822\rfc822.l RFC822::Scanner
	@perl ..\lib\Parser\ppar -dfa RFC822\rfc822.y RFC822::Parser RFC822::Scanner
	@echo Ce DFA
	@perl tparse.pl
	@perl tparse.pl -str
	@perl ..\lib\Scanner\plex -Cf RFC822\rfc822.l RFC822::Scanner
	@perl ..\lib\Parser\ppar RFC822\rfc822.y RFC822::Parser RFC822::Scanner
	@echo Cf plain
	@perl tparse.pl
	@perl tparse.pl -str
	@perl ..\lib\Scanner\plex -Cf RFC822\rfc822.l RFC822::Scanner
	@perl ..\lib\Parser\ppar -dfa RFC822\rfc822.y RFC822::Parser RFC822::Scanner
	@echo Cf DFA
	@perl tparse.pl
	@perl tparse.pl -str

clean:
	-del /s *~ RFC822\Parser.pm RFC822\Scanner.pm
