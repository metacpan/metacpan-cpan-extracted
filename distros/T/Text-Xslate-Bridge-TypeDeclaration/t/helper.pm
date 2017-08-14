package t::helper;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(cache_dir path);

use Data::Section::Simple;
use File::Temp qw(tempdir);
use Test::Name::FromLine;

sub cache_dir {
    tempdir('.xslate_cache_XXXX', CLEANUP => 1);
}

sub path {
    my $caller = caller;
    [ Data::Section::Simple->new($caller)->get_data_section ];
}

{
    package t::SomeModel;
    sub new { bless +{}, $_[0] };
}

{
    package t::OneModel;
    sub new { bless +{}, $_[0] };
}

{
    package t::AnotherModel;
    sub new { bless +{}, $_[0] };
}

1;
