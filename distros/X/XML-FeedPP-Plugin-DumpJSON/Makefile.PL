use ExtUtils::MakeMaker;
use strict;
require 5.008001;

my $opt = {
    NAME                => 'XML-FeedPP-Plugin-DumpJSON',
    VERSION_FROM        => 'lib/XML/FeedPP/Plugin/DumpJSON.pm',
    PREREQ_PM           => {
        'Test::More'        => '0',
        'XML::TreePP'       => '0.33',
        'XML::FeedPP'       => '0.33',
#       'JSON'              => '2.0',
        'JSON::Syck'        => '0',
    },
};

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'perl' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
