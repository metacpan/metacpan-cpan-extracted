package WebService::Hexonet::Connector::Response;

use strict;
use warnings;
use WebService::Hexonet::Connector::Util;
use overload
  '%{}' => \&_as_hash_op,
  '@{}' => \&as_list,
  ;

our $VERSION = '1.05';

sub new {
    my $class    = shift;
    my $response = shift;
    my $self     = {};

    if ( ( ref $response ) eq "HASH" ) {
        $self->{_response_hash} = $response;
    }
    elsif ( !ref $response ) {
        $self->{_response_string} = $response;
    }
    else {
        die "Unsupported Class: " . ( ref $response );
    }

    bless $self, $class;
    $self->{test} = 1;

    return bless $self, $class;
}

sub as_string {
    my $self = shift;

    return $self->{_response_string};
}

sub _as_hash_op {
    my $self = shift;

    # Don't hide the $self hash if called from within class
    my ($pkg) = caller 0;
    return $self if $pkg->isa('WebService::Hexonet::Connector::Response');
    return $self->as_hash();
}

sub as_hash {
    my $self = shift;

    return $self->{_response_hash} if defined $self->{_response_hash};
    $self->{_response_hash} =
      WebService::Hexonet::Connector::Util::response_to_hash(
        $self->{_response_string} );
    return $self->{_response_hash};
}

sub as_list_hash {
    my $self = shift;

    return $self->{_response_list_hash} if defined $self->{_response_list_hash};
    $self->{_response_list_hash} =
      WebService::Hexonet::Connector::Util::response_to_list_hash(
        $self->as_hash() );
    return $self->{_response_list_hash};
}

sub as_list {
    my $self      = shift;
    my $list_hash = $self->as_list_hash();
    if (wantarray) {
        return @{ $list_hash->{ITEMS} };
    }
    return $list_hash->{ITEMS};
}

sub code {
    my $self = shift;
    return $self->as_hash()->{CODE};
}

sub description {
    my $self = shift;
    return $self->as_hash()->{DESCRIPTION};
}

sub properties {
    my $self = shift;
    return $self->as_hash()->{PROPERTY};
}

sub runtime {
    my $self = shift;
    return $self->as_hash()->{RUNTIME};
}

sub queuetime {
    my $self = shift;
    return $self->as_hash()->{QUEUETIME};
}

sub property {
    my $self     = shift;
    my $property = shift;
    my $index    = shift;
    my $p        = $self->as_hash()->{PROPERTY};
    if ( defined $index ) {
        return undef
          unless exists $p->{$property};
        return $p->{$property}[$index];
    }
    if (wantarray) {
        return () unless exists $p->{$property};
        return @{ $p->{$property} };
    }
    return undef unless exists $p->{$property};

    #TODO: we mixup here wantarray and LIST/SCALAR which does basically the same
    return $p->{$property};
}

sub is_success {
    my $self = shift;
    return $self->as_hash()->{CODE} =~ /^2/;
}

sub is_tmp_error {
    my $self = shift;
    return $self->as_hash()->{CODE} =~ /^4/;
}

sub columns  { my $self = shift; return $self->as_list_hash()->{COLUMNS}; }
sub first    { my $self = shift; return $self->as_list_hash()->{FIRST}; }
sub last     { my $self = shift; return $self->as_list_hash()->{LAST}; }
sub count    { my $self = shift; return $self->as_list_hash()->{COUNT}; }
sub limit    { my $self = shift; return $self->as_list_hash()->{LIMIT}; }
sub total    { my $self = shift; return $self->as_list_hash()->{TOTAL}; }
sub pages    { my $self = shift; return $self->as_list_hash()->{PAGES}; }
sub page     { my $self = shift; return $self->as_list_hash()->{PAGE}; }
sub prevpage { my $self = shift; return $self->as_list_hash()->{PREVPAGE}; }

sub prevpagefirst {
    my $self = shift;
    return $self->as_list_hash()->{PREVPAGEFIRST};
}
sub nextpage { my $self = shift; return $self->as_list_hash()->{NEXTPAGE}; }

sub nextpagefirst {
    my $self = shift;
    return $self->as_list_hash()->{NEXTPAGEFIRST};
}

sub lastpagefirst {
    my $self = shift;
    return $self->as_list_hash()->{LASTPAGEFIRST};
}

1;

__END__

=head1 NAME

WebService::Hexonet::Connector::Response - package to provide functionality to deal with Backend
API reponses.

=head1 DESCRIPTION

This package provides any functionality that you need to deal with Backend API responses.

The Response object itself can be instantiated by bytes array (basically the plaintext
response from the Backend API), or by a hash format (an already parsed response).
But the latter case is more for internal use.

=head1 METHODS WebService::Hexonet::Connector::Response

=over 4

=item C<new(response)>

Create an new Response object using the given Backend API response data.
This can be a bytes array (basically the plaintext response from the Backend API),
or by a hash format (an already parsed response returned by method as_list_hash).
The latter case is more for internal use.

=item C<as_string()>

Returns the response as a string

=item C<as_hash()>

Returns the response as a hash

=item C<as_list_hash()>

Returns the response as a list hash

=item C<as_list()>

Returns the response as a list

=item C<code()>

Returns the response code

=item C<description()>

Returns the response description

=item C<properties()>

Returns the response properties

=item C<runtime()>

Returns the response runtime

=item C<queuetime()>

Returns the response queutime

=item C<property(index)>

Returns the property for a given index If no index given, the complete property list is returned

=item C<is_success()>

Returns true if the results is a success Success = response code starting with 2

=item C<is_tmp_error()>

Returns true if the results is a tmp error tmp error = response code starting with 4

=item C<columns()>

Returns the columns

=item C<first()>

Returns the index of the first element

=item C<last()>

Returns the index of the last element

=item C<count()>

Returns the number of list elements returned (= last - first + 1)

=item C<limit()>

Returns the limit of the response

=item C<total()>

Returns the total number of elements found (!= count)

=item C<pages()>

Returns the number of pages

=item C<page()>

Returns the number of the current page (starts with 1)

=item C<prevpage()>

Returns the number of the previous page

=item C<prevpagefirst()>

Returns the first index for the previous page

=item C<nextpage()>

Returns the number of the next page

=item C<nextpagefirst()>

Returns the first index for the next page

=item C<lastpagefirst()>

Returns the first index for the last page

=back

=head1 AUTHOR

Hexonet GmbH

L<https://www.hexonet.net>

=head1 LICENSE

MIT

=cut
