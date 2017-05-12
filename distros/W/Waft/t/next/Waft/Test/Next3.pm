package Waft::Test::Next3;

use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

$VERSION = '1.0';

sub html_escape {
    my ($self, @values) = @_;

    for my $value ( @values ) {
        $value = $self->next($value);
        $value =~ s/ \x0A /&#10;/gxms;
        $value =~ s/ \x0D /&#13;/gxms;
    }

    return wantarray ? @values : $values[0];
}

1;
