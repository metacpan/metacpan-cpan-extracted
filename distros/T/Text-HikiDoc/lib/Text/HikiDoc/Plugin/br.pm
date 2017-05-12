package Text::HikiDoc::Plugin::br;

use strict;
use warnings;
use base 'Text::HikiDoc::Plugin';

sub to_html {
    my $self = shift;
    my $num = shift || 1;
    my $style = shift || '';

    my $ret = '<br';
    $ret .= ' style="'.$style.'"' if $style;
    $ret .= $self->{empty_element_suffix} || ' />';

    return $ret x $num;
}

1;
