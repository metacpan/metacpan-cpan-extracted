package Text::HikiDoc::Plugin::e;

use strict;
use warnings;
use base 'Text::HikiDoc::Plugin';

sub to_html {
    my $self = shift;
    my $str = shift || '';

    if ( $str =~ /^(\d+)$/ ) {
        $str = '&#'.$str.';';
    }
    else {
        $str = '&'.$str.';';
    }

    return $str;
}

1;
