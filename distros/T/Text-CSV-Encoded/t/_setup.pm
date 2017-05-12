package _setup;

use strict;

sub tests {
    package main;
    plan tests => $_[1];
}



BEGIN {
    package main;

    my $backend = $ARGV[0] || 0;

    local $ENV{PERL_TEXT_CSV} = $backend;

    require Text::CSV::Encoded;


    if ( $] < 5.008 ) {
        plan skip_all => "This test requires Perl version 5.8 or lator.";
    }
    elsif ( $backend and Text::CSV::Encoded->is_pp ) {
        plan skip_all => "Text::CSV_XS can't be loaded.";
    }
    elsif ( !$backend and Text::CSV::Encoded->is_xs ) {
        plan skip_all => "Text::CSV_PP can't be loaded.";
    }

}

1;
__END__
