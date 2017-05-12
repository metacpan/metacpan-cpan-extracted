package UR::Doc::Pod2Html;

use strict;
use warnings;

our $VERSION = "0.46"; # UR $VERSION;

use Data::Dumper;

use parent 'Pod::Simple::HTML';


$Pod::Simple::HTML::Perldoc_URL_Prefix = '';
$Pod::Simple::HTML::Perldoc_URL_Postfix = '.html';


sub do_top_anchor {
    my ($self, $value) = @_;
    $self->{__do_top_anchor} = $value;
}

sub do_beginning {
    return 1;
}

sub do_end {
    return 1;
}

sub _add_top_anchor {
    my $self = shift;
    return $self->SUPER::_add_top_anchor(@_) if $self->{__do_top_anchor};
}

1;
