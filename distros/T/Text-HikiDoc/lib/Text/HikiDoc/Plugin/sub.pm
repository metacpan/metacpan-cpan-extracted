package Text::HikiDoc::Plugin::sub;

use strict;
use warnings;
use base 'Text::HikiDoc::Plugin';

sub to_html {
    my $self = shift;
    my $str = shift || '';

    return '<sub>'.$str.'</sub>';
}

1;
