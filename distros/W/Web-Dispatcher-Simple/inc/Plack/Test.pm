#line 1
package Plack::Test;
use strict;
use warnings;
use parent qw(Exporter);
our @EXPORT = qw(test_psgi);

our $Impl;
$Impl ||= $ENV{PLACK_TEST_IMPL} || "MockHTTP";

sub test_psgi {
    eval "require Plack::Test::$Impl;";
    die $@ if $@;
    no strict 'refs';
    if (ref $_[0] && @_ == 2) {
        @_ = (app => $_[0], client => $_[1]);
    }
    &{"Plack::Test::$Impl\::test_psgi"}(@_);
}

1;

__END__

#line 137
