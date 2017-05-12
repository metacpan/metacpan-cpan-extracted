package re2_test;
use strict;
use warnings;
use re::engine::RE2;

my $RE;

sub _gen_re {
    my ($terms,$is_cap) = @_;
    my $base = join '|', map quotemeta, @$terms;
    if($is_cap) {
        $base = qr/^($base)/;
    } else {
        $base = qr/^(?:$base)/;
    }
    return $base;
}

sub search_RE2 {
    my ($terms,$strings) = @_;
    my $re = _gen_re($terms);
    my $matches;
    
    foreach my $str (@$strings) {
        if ($str =~ /$re/) {
            $matches++;
        }
    }
    return $matches;
}

sub search_RE2_CAP {
    my ($terms,$strings) = @_;
    my $re = _gen_re($terms, 1);
    my $matches;
    foreach my $str (@$strings) {
        if(my ($match) = ($str =~ /$re/) ) {
            $matches++;
        }
    }
    return $matches;
}

1