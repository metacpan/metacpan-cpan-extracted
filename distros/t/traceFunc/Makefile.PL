# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.1 1996/06/02 02:53:25 jhildebr Exp $

use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);

#--- Configuration section ---

#--- End User Configuration - You should not have to change anything below this line

require 5.002;

$VERSION  = "0.1";
$NAME     = 'Devel';
$DISTNAME = 'traceFunc';

sub initialize {
 local($_);

 my $manifest = maniread();

 my %pl_files   = ();
 my @exe_files  = ();
 
 foreach (keys %$manifest) {
  $pl_files{$_} = $1 if(/(.*)\.PL\Z/ && !/^Makefile.PL$/);
  push(@exe_files,$1) if(m|\b(bin/.*)\.PL| && !m|demo|);
 }

 %hash = (
	VERSION   => $VERSION,
	NAME      => $NAME,
	DISTNAME  => $DISTNAME,
	SKIP      => [qw(static dynamic)],
	PL_FILES  => \%pl_files,
	EXE_FILES => \@exe_files,
	dist      => {COMPRESS     => 'gzip -9f',
		      SUFFIX       => 'gz',
		      DIST_DEFAULT => 'all tardist',
		      CI           => 'ci -l'
		     },
	linkext   => {LINKTYPE => ''},
	clean     => {FILES => join(' ', values %pl_files) . ' *% 851/*.851 req/*.req *.html *.bak *.old lib/*% lib/*/*%'},
 );

 \%hash;
}

sub MY::test {
    q{
TEST_VERBOSE=0

test:
	$(FULLPERL) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -e 'use Test::Harness qw(&runtests $$verbose); $$verbose=$(TEST_VERBOSE); runtests @ARGV;' t/*.t

};
}

sub MY::libscan {
    return '' if m:/(RCS|CVS)/:;
    return '' if m/[~%]$/;
    return '' if m/\.(orig|rej)$/;
    $_;
}

# -- Make the Makefile

die "You require MakeMaker v4.17 or later to install this package\n"
   unless($ExtUtils::MakeMaker::Version >= 4.17);

WriteMakefile(CONFIGURE => \&initialize);

