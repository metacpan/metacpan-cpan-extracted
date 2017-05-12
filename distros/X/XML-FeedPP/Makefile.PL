use ExtUtils::MakeMaker;
use strict;

my $opt = {
    NAME                => 'XML-FeedPP',
    VERSION_FROM        => 'lib/XML/FeedPP.pm',
    PREREQ_PM           => {
        'Test::More'        => '0',
        'XML::TreePP'       => '0.39',
    },
};

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'perl' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
