package Text::HikiDoc::Plugin::ins;

use strict;
use warnings;
use base 'Text::HikiDoc::Plugin';

sub to_html {
    my $self = shift;
    my $str = @_ ? join("\n",@_) : '';

    $str =~ s/\n/<br$self->{empty_element_suffix}\n/g if ($self->{br_mode} eq 'true');

    return '<ins>'.$str.'</ins>';
}

1;
