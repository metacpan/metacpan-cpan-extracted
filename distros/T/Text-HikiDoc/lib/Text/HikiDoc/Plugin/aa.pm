package Text::HikiDoc::Plugin::aa;

use strict;
use warnings;
use base 'Text::HikiDoc::Plugin';

sub to_html {
    my $self = shift;
    my $str = @_ ? join("\n",@_) : '';

#    $str =~ s/\n/<br$self->{empty_element_suffix}\n/g;
#    return '<div class="ascii-art">'.$str.'</div>';
    return '<pre class="ascii-art">'.$str.'</pre>';
}

1;
