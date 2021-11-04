package XML::MyXML::Util;

use strict;
use warnings;

require Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw/ trim strip_ns debug /;

sub trim {
    my $string = shift;

    if (defined $string) {
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
    }

    return $string;
}

sub strip_ns {
    my $string = shift;

    defined $string or return undef;

    my $num_colons = () = $string =~ /\:/g;
    if ($num_colons == 1 and $string =~ /.\:./) {
        $string =~ s/^.+\://;
    }

    return $string;
}

sub debug {
    my $thing = shift;
    require Data::Dumper;
    warn Data::Dumper::Dumper($thing) if $ENV{DEBUG};
}

1;
