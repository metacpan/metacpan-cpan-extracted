#!/bin/false
# ABSTRACT: Base result-object class for OPNsense API responses
# PODNAME: WebService::OPNsense::Object
use strictures 2;

package WebService::OPNsense::Object;
$WebService::OPNsense::Object::VERSION = '0.001';
use Moo;
use Ref::Util qw( is_plain_hashref );
use namespace::clean;

sub BUILD {
    my ( $self, $args ) = @_;

    for my $key ( sort keys %{$args} ) {
        next if $key eq 'client';
        my $value = $args->{$key};
        if ( is_plain_hashref($value) ) {
            $value = __PACKAGE__->new($value);
        }
        $self->{$key} = $value;
    }

    return;
}

sub get {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

sub TO_JSON {
    my ($self) = @_;
    my %public = %{$self};
    if ( exists $public{client} ) {
        $public{client} = '[MASKED]';
    }
    return \%public;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Object - Base result-object class for OPNsense API responses

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $obj = WebService::OPNsense::Object->new(
        uuid        => 'abc-123',
        description => 'My Rule',
        enabled     => 1,
    );

    say $obj->get('description');

=head1 DESCRIPTION

Provides a simple hash-based result object for deserialized API responses.
Nested hashrefs are recursively converted to L<WebService::OPNsense::Object>
instances.

=head1 NAME

WebService::OPNsense::Object - Base result-object class for OPNsense API responses

=head1 METHODS

=head2 get

    my $value = $obj->get($key);

Retrieves a value by key.

=head2 TO_JSON

Returns a plain hashref suitable for JSON serialization.

=for Pod::Coverage BUILD

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
