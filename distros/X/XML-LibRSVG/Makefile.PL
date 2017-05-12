use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %config;

$config{INC} = '';
$config{LIBS} = '-lpng';

chomp($config{INC} .= ' ' . `gtk-config --cflags`);
chomp($config{LIBS} .= ' ' .`gtk-config --libs`);

chomp($config{INC} .= ' ' . `gdk-pixbuf-config --cflags`);
chomp($config{LIBS} .= ' ' . `gdk-pixbuf-config --libs`);

chomp($config{INC} .= ' ' . `freetype-config --cflags`);
chomp($config{LIBS} .= ' ' . `freetype-config --libs`);

chomp($config{INC} .= ' ' . `librsvg-config --cflags`);
chomp($config{LIBS} .= ' ' . `librsvg-config --libs`);

chomp($config{INC} .= ' ' . `xml2-config --cflags`);
chomp($config{LIBS} .= ' ' . `xml2-config --libs`);

WriteMakefile(
    'NAME'	=> 'XML::LibRSVG',
    'VERSION_FROM' => 'LibRSVG.pm', # finds $VERSION
    %config,
);
