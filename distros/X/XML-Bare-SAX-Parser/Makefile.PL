#!/usr/bin/perl
use ExtUtils::MakeMaker;
require 5.006;
my @basics = ( AUTHOR       => 'David Helkowski <cpan@codechild.com>',
               ABSTRACT     => 'A minimal XML SAX parser.',
               NAME         => 'XML::Bare::SAX::Parser',
               VERSION_FROM => 'Parser.pm',
               PREREQ_PM    => { Carp => 0, Exporter => 0, DynaLoader => 0 },
               #OPTIMIZE     => '-O3 -msse2 -march=pentium4 --omit-frame-pointer',
             );
if( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
  push( @basics, LICENSE => 'perl' );
}
if( $^O eq 'MSWin32' && !has_cc() ) {
  gen_msvc(); # special case for msvc
}
elsif( $^O eq 'darwin' ) {
  gen_darwin(); # darwin
}
else {
  gen_cc(); # all others
}
sub gen_msvc {
  require Config;
  my $libpath = Config->{'archlibexp'};
  my $ver = $]*1000; # correct for possibile division problems
  my ($major,$minor,$sub) = unpack("AA3xA3","$ver");
  $major *= 1; $minor *= 1; $sub *= 1;
  WriteMakefile( @basics,
    CCFLAGS   => "/MT /DWIN32 /TP /DNOSTRING",
    LIBS      => ["$libpath\\core\\perl$major$minor.lib"],
    OBJECT    => 'Parser.o parser_engine.o',
    LDDLFLAGS => '/DLL',
  );
}
sub gen_cc {
  WriteMakefile( @basics,
    LIBS      => ['-lm'],
    OBJECT    => 'Parser.o parser_engine.o',
    LDDLFLAGS => '-shared -L/usr/local/lib',
  );
}
sub gen_darwin {
  if( substr(`which gcc`,0,2) eq 'no' ) {
    print "XCode must be installed.\n";
    exit 1;
  }
  WriteMakefile( @basics,
    LIBS      => ['-lm'],
    OBJECT    => 'Parser.o parser_engine.o',
    CCFLAGS   => "-dynamiclib -DDARWIN -fno-common",
    LDDLFLAGS => '',
  );
}
sub has_cc {
  my $div = (substr($ENV{'PATH'},0,1) eq '/') ? ':' : ';';
  my @path = split($div,$ENV{'PATH'});
  foreach my $dir ( @path ) {
    return 1 if( -e "$dir/cc" ||
                 -e "$dir/gcc" ||
                 -e "$dir/cc.exe" ||
                 -e "$dir/gcc.exe" ); }
  return 0;
}
sub MY::install {
  package MY;
  my $script = shift->SUPER::install(@_);
  if (ExtUtils::MakeMaker::prompt(
    "Do you want to modify ParserDetails.ini?", 'Y')
    =~ /^y/i) {
    $script =~ s/install :: (.*)$/install :: $1 install_sax_driver/m;
    $script .= <<"INSTALL";

install_sax_driver :
\t\@\$(PERL) -MXML::SAX -e "XML::SAX->add_parser(q(\$(NAME)))->save_parsers()"

INSTALL
  }
  return $script;
}
