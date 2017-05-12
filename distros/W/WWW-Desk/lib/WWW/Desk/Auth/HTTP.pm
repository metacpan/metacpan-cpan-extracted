package WWW::Desk::Auth::HTTP;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Moose;
use MIME::Base64;
use Mojo::Headers;

=head1 NAME

WWW::Desk::Auth::HTTP - Desk.com HTTP Basic Authentication

=cut

our $VERSION = '0.10';    ## VERSION

=head1 ATTRIBUTES

=head2 username

REQUIRED - desk.com username

=cut

has 'username' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

=head2 password

REQUIRED - desk.com password

=cut

has 'password' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'http_header' => (
    is      => 'ro',
    isa     => 'Mojo::Headers',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $http_header = Mojo::Headers->new;
        return $http_header;
    });

=head1 SYNOPSIS

    use WWW::Desk::Auth::HTTP;

    my $auth = WWW::Desk::Auth::HTTP->new(
        'username' => 'desk username',
        'password' => 'desk password'
    );
    $auth->login_headers();

=head1 SUBROUTINES/METHODS

=head2 login_headers

Return Mojo::Headers for basic http authentication

=cut

sub login_headers {
    my ($self) = @_;
    my $http = $self->http_header;
    $http->accept('application/json');
    $http->content_type('application/json');
    $http->add('Authorization' => 'Basic ' . encode_base64($self->username . ':' . $self->password, ''));
    return $http;
}

=head1 AUTHOR

binary.com, C<< <rakesh at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-desk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Desk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Desk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Desk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Desk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Desk>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Desk/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

no Moose;
__PACKAGE__->meta->make_immutable();

1;    # End of WWW::Desk::Auth::HTTP
