
use strict;

use ExtUtils::MakeMaker 6.48;


my %WriteMakefileArgs = (
    NAME           => 'TinyDNS::Reader',
    VERSION_FROM   => 'lib/TinyDNS/Reader.pm',
    BUILD_REQUIRES => {

        # solely for the test-suite.
        'Test::More'   => 0,
        'Test::Pod'    => 0,
        'Test::Strict' => 0,
        'Test::NoTabs' => 0,

    },
    ABSTRACT         => 'Parser for TinyDNS records.',
    AUTHOR           => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.008',
    META_MERGE       => {
              resources => {
                  license    => 'http://dev.perl.org/licenses/',
                  homepage   => 'https://github.com/skx/TinyDNS--Reader/',
                  bugtracker => 'https://github.com/skx/TinyDNS--Reader/issues',
                  repository => 'https://github.com/skx/TinyDNS--Reader.git',
              },
    },
);


WriteMakefile(%WriteMakefileArgs);


package MY;

sub metafile
{
    my $self = shift;
    my $meta = $self->SUPER::metafile_target(@_);
    my ($extra) = $self->echo( 'license: perl_5', 'MYMETA.yml', 1 );
    return "$meta\t$extra\n";
}
