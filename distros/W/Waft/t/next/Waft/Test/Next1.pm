package Waft::Test::Next1;

use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

$VERSION = '1.0';

sub html_escape {
    my ($self, @values) = @_;

    @values = $self->next(@values);

    for my $value ( @values ) {
        $value =~ s/ &quot; /&#34;/gxms;
    }

    return wantarray ? @values : $values[0];
}

1;
