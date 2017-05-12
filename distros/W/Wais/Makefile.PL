######################### -*- Mode: Perl -*- #########################
##
## File          : Makefile.PL
##
## Description   : 
##
## Author        : Ulrich Pfeifer
## Created On    : Sun Sep 10 11:00:44 1995
##
## Last Modified : Time-stamp: <1998-07-26 16:39:34 goevert>
##
## $Id: Makefile.PL 1.6 Mon, 27 Jul 1998 13:45:34 +0200 goevert $
##
## $ProjectHeader: Wais 23.11 Mon, 03 Aug 1998 18:56:40 +0200 goevert $
######################################################################


use strict;

use ExtUtils::MakeMaker;
use Config;

require 5.004;


foreach (qw(waisserver waisindex)) {
  die "Couldn't find `$_' in your PATH\n" unless findbin($_);
}

&WriteMakefile
  (
   'PREREQ_PM'    => { Curses     => 0,
                     },
   'LIBS'         => "-L$Config{ldflags} -lwais",
   'INC'          => "-DWAIS_USES_STDIO -I$Config{cppflags}",
   'NAME'         => 'Wais',
   'VERSION_FROM' => 'lib/Wais.pm',
   'DEFINE'       => '-DTRACE=0',
   'OBJECT'       => "Wais.o HTWAIS.o dictionary.o",
   'dist'         => { SUFFIX   => 'gz',
                       COMPRESS => 'gzip -9f',
                       PREOP    => 'pod2text lib/Wais.pm > README; pod2text install > INSTALL',
                     },
   'MAP_TARGET'   => 'waisperl',
   'EXE_FILES'    => [ qw(script/inspect script/makedb) ],
  );


## ###################################################################
## subs
## ###################################################################

sub MY::postamble {
  
  my $self = shift;
  
  qq[
install :: register

register ::
\t] . $self->{NOECHO} . q[$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
-e '    use Wais; ' \
-e '    use Config; ' \
-e '    eval "use Sys::Hostname; \\$$host = q[on ].hostname;";' \
-e '    $$address="waispm\@ls6.cs.uni-dortmund.de";'	\
-e '    print "Send registration mail to $$address (y/n)? ";'	\
-e '    $$answer = <STDIN>;' 	\
-e '    if ($$answer !~ /^n/i) {'	\
-e '        exec "perlbug", "-a", $$address, "-C",'	\
-e '        "-s", "Installed Wais extension $$Wais::VERSION $$host$$Config{mydomain}";'	\
-e '    } else {'	\
-e '        print "Ok ... I will keep your secret!\n";'	\
-e '    }'
]
}


sub findbin {
  
  my $prog = shift;
  
  foreach (split ':', $ENV{PATH}) {
    return "$_/$prog" if -x "$_/$prog";
  }
  
  return;
}
