package URI::Query::FromHash 0.006;

use strict;
use warnings;

my %escapes;
$escapes{+chr} = sprintf '%%%02X', $_ for 0..255;

sub import {
    no strict 'refs';

    *{ caller . '::hash2query' } = \&hash2query;
}

sub hash2query(+%) {
    return '' if 'HASH' ne ref( my $hash = $_[0] );

    my $q = '';

    for my $k ( sort keys %$hash ) {
        my $v = $hash->{$k};

        $k =~ s|([;/?:@&=+,\$\[\]%\\])|$escapes{$1}|g;
        $k =~ y| |+|;

        for ( ref $v ? @$v : $v ) {
            # Avoid modifying the original.
            my $v = $_ // '';

            $v =~ s|([;/?:@&=+,\$\[\]%\\])|$escapes{$1}|g;
            $v =~ y| |+|;

            $q .= "$k=$v&";
        }
    }

    # Trim off the last "&".
    substr $q, -1, 1, '';

    utf8::encode $q;

    $q =~ s|([^\Q;/?:@&=+,\$\[\]%-_.!~*'()\EA-Za-z0-9])|@escapes{ split //, $1 }|eg;

    $q;
}

sub unimport {
    no strict 'refs';

    delete ${ caller . '::' }{hash2query};
}

1;
