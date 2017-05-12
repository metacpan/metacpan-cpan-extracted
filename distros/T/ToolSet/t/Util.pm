package t::Util;
use strict;
use warnings;

use Test::More;
use base 'Exporter';

our @EXPORT = qw( cant_ok );

sub cant_ok ($@) {
    my ( $proto, @methods ) = @_;
    my $class = ref $proto || $proto;
    my $tb = Test::More->builder;

    unless (@methods) {
        my $ok = $tb->ok( 0, "$class->can(...)" );
        $tb->diag('    cant_ok() called with no methods');
        return $ok;
    }

    my @ok = ();
    foreach my $method (@methods) {
        local ( $!, $@ ); # don't interfere with caller's $@
        # eval sometimes resets $!
        eval { $proto->can($method) } && push @ok, $method;
    }

    my $name;
    $name =
      @methods == 1
      ? "$class->cant('$methods[0]')"
      : "$class->cant(...)";

    my $ok = $tb->ok( !@ok, $name );

    $tb->diag( map "    $class->cant('$_') failed\n", @ok );

    return $ok;
}

1;
