package Text::HikiDoc::Plugin::sup;

use strict;
use warnings;
use base 'Text::HikiDoc::Plugin';

sub to_html {
    my $self = shift;
    my $str = shift || '';

    return '<sup>'.$str.'</sup>';
}

1;
