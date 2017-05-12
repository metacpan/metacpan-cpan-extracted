package WWW::NHKProgram::API::Provider;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/furl api_key/],
);

sub dispatch {
    my ($self, $api_name, $arg, $raw) = @_;

    my $class = __PACKAGE__ . '::' . ucfirst($api_name);
    eval "require $class"; ## no critic

    $class->call($self, $arg, $raw);
}

1;

