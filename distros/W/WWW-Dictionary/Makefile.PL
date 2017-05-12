use strict;
use warnings;
use ExtUtils::MakeMaker;

my @patterns = qw( t/*.t );

if ( prompt( "Do you want to run live tests?", "n" ) =~ /^y/i ) {
  print "Adding live tests.\n";
  push @patterns, 't/live/*.t';
}
else {
  print "Skipping live tests.\n";
}

WriteMakefile(
    NAME                => 'WWW::Dictionary',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Dictionary.pm',
    ABSTRACT_FROM       => 'lib/WWW/Dictionary.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'WWW::Mechanize' => 0,
        'HTML::Strip'    => 0,
    },
    'EXE_FILES'         => [ 'dictionary' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Dictionary-*' },
    test		=> { TESTS => join ' ', map { glob } @patterns },
);
