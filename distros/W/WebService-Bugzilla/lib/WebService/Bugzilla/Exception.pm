#!/usr/bin/false
# ABSTRACT: Exception class for WebService::Bugzilla HTTP errors
# PODNAME: WebService::Bugzilla::Exception

package WebService::Bugzilla::Exception 0.001;
use strictures 2;
use Moo;
use namespace::clean;
use overload '""' => \&as_string, fallback => 1;

has bz_code     => (is => 'ro');
has http_status => (is => 'ro');
has message     => (is => 'ro', required => 1);

sub as_string {
    my ($self) = @_;
    my $str = $self->message;
    $str .= ' [bz:' . $self->bz_code . ']'
        if defined $self->bz_code;
    $str .= ' [http:' . $self->http_status . ']'
        if defined $self->http_status;
    return $str;
}

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Exception - Exception class for WebService::Bugzilla HTTP errors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WebService::Bugzilla::Exception;

    WebService::Bugzilla::Exception->throw(
        message     => 'Bug not found',
        http_status => 404,
    );

    # or catch one thrown by the client
    eval { $bz->bug->get(999999) };
    if (my $e = $@) {
        say $e;               # stringifies via overloaded ""
        say $e->http_status;  # 404
    }

=head1 DESCRIPTION

Exception objects thrown by L<WebService::Bugzilla> for HTTP or
Bugzilla-level errors.  The class overloads stringification so exceptions
can be printed directly.  Attributes carry the HTTP status and optional
Bugzilla error code for programmatic handling.

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<bz_code>

Bugzilla-specific numeric error code, when the server provides one.

=item C<http_status>

HTTP status code returned by the server.

=item C<message>

B<Required.>  Human-readable error message.

=back

=head1 METHODS

=head2 as_string

    say $exception->as_string;
    say "$exception";          # same, via overloaded ""

Return a human-readable string combining C<message>, C<bz_code>, and
C<http_status>.

=head2 throw

    WebService::Bugzilla::Exception->throw(message => 'oops');

Class method.  Construct an exception and immediately C<die> with it.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client that throws these exceptions

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
