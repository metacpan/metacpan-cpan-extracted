package TestMethodFixtures::Dummy;

use strict;
use warnings;

use Digest::MD5 qw( md5_hex );
use Storable qw( freeze );

use base 'Test::MethodFixtures::Storage';

local $Storable::canonical = 1;

my %STORAGE;

__PACKAGE__->mk_accessors( qw/ foo / );

sub store {
    my ( $self, $args ) = @_;

    my $key = _key( $args->{key} );

    $STORAGE{ $args->{method} }->{$key} = {
        %{$args},
        input  => $args->{input},
        output => $args->{output}
    };

    return $self;
}

sub retrieve {
    my ( $self, $args ) = @_;

    my $key = _key( $args->{key} );

    return unless exists $STORAGE{ $args->{method} }->{$key};

    return $STORAGE{ $args->{method} }->{$key};
}

sub _key {
    return md5_hex freeze shift;
}

1;

