
use Test;
BEGIN { plan tests => 2 * 2 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use lib 't/next';
use Waft with => qw( ::Test::Next1 ::Test::Next2 ::Test::Next3 );

sub html_escape {
    my ($self, @values) = @_;

    return $self->next(@values);
}

for my $obj ( __PACKAGE__, __PACKAGE__->new ) {
    my ($value1, $value2) = $obj->html_escape(q{"&'<>}, "\x0D\x0A");
    ok( $value1 eq '&#34;&amp;&#39;&lt;&gt;' );
    ok( $value2 eq '&#13;&#10;' );
}
