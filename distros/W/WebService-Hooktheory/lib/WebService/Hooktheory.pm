package WebService::Hooktheory;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Access to the Hooktheory API

our $VERSION = '0.0601';

use strictures 2;
use Carp qw(croak);
use Mojo::UserAgent ();
use Mojo::JSON qw(decode_json);
use Mojo::URL ();
use Moo;
use Try::Tiny;
use namespace::clean;


has username => (
    is => 'ro',
);


has password => (
    is => 'ro',
);


has activkey => (
    is => 'ro',
);


has base => (
    is      => 'rw',
    default => sub { 'https://api.hooktheory.com' },
);


has ua => (
    is      => 'rw',
    default => sub { Mojo::UserAgent->new() },
);


sub BUILD {
    my ( $self, $args ) = @_;

    if ( !$args->{activkey} && $args->{username} && $args->{password} ) {
        my $tx = $self->ua->post(
            $self->base . 'users/auth',
            { 'Content-Type' => 'application/json' },
            json => { username => $args->{username}, password => $args->{password} },
        );

        my $data = _handle_response($tx);

        $self->{activkey} = $data->{activkey}
            if $data && $data->{activkey};
    }
}


sub fetch {
    my ( $self, %args ) = @_;

    croak 'No activkey provided' unless $self->activkey;
    croak 'No endpoint provided' unless $args{endpoint};
    croak 'No query provided' unless $args{query};

    my $url = Mojo::URL->new($self->base)
        ->path('v1' . $args{endpoint})
        ->query(%{ $args{query} });

    my $tx = $self->ua->get( $url, { Authorization => 'Bearer ' . $self->activkey } );

    my $data = _handle_response($tx);

    return $data;
}

sub _handle_response {
    my ($tx) = @_;

    my $data;

    my $res = $tx->result;

    if ( $res->is_success ) {
        my $body = $res->body;
        try {
            $data = decode_json($body);
        }
        catch {
            croak $body, "\n";
        };
    }
    else {
        croak "Connection error: ", $res->message;
    }

    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Hooktheory - Access to the Hooktheory API

=head1 VERSION

version 0.0601

=head1 SYNOPSIS

  use WebService::Hooktheory;

  my $w = WebService::Hooktheory->new( username => 'foo', password => 'bar' );
  print $w->activkey, "\n";

  # Or:
  $w = WebService::Hooktheory->new( activkey => '1234567890abcdefghij' );

  my $r = $w->fetch( endpoint => '/trends/nodes', query => { cp => '4,1' } );
  print Dumper $r;

=head1 DESCRIPTION

C<WebService::Hooktheory> provides access to the L<https://www.hooktheory.com> API.

=head1 ATTRIBUTES

=head2 username

=head2 password

=head2 activkey

Your authorized access key.

=head2 base

The base URL.  Default: https://api.hooktheory.com

=head2 ua

The user agent.

=head1 METHODS

=head2 new()

  $w = WebService::Hooktheory->new(%arguments);

Create a new C<WebService::Hooktheory> object.

=for Pod::Coverage BUILD

=head2 fetch()

  $r = $w->fetch(%arguments);

Fetch the results given the B<endpoint> and optional B<query> arguments.

=head1 THANK YOU

Dan Book (DBOOK)

=head1 SEE ALSO

The examples in the F<eg/> directory.

The tests in F<t/01-methods.t>

L<https://www.hooktheory.com/api/trends/docs>

L<Moo>

L<Mojo::JSON>

L<Mojo::UserAgent>

L<Mojo::URL>

L<Try::Tiny>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
