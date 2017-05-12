package WWW::NHKProgram::API::Date;
use strict;
use warnings;
use utf8;
use Carp;

sub validate {
    my $date = shift;
    if ($date !~ /\A\d{4}-\d{2}-\d{2}\Z/) {
        croak "Date must be hyphen separated. (e.g. 2014-02-14)";
    }
    return $date;
}

1;

