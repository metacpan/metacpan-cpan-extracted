package WWW::Desk::Browser;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Moose;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Path;
use Mojo::JSON qw(decode_json encode_json);

=head1 NAME

WWW::Desk::Browser - Desk.com Browser Client

=cut

our $VERSION = '0.10';    ## VERSION

=head1 ATTRIBUTES

=head2 base_url

REQUIRED - your desk url

=cut

has 'base_url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has 'api_version' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        return "v2";
    });

has 'browser' => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $browser = Mojo::UserAgent->new;
        return $browser;
    });

=head1 SYNOPSIS

    use WWW::Desk::Browser;

    my $browser_client = WWW::Desk::Browser->new();

=head1 SUBROUTINES/METHODS

=head2 prepare_url

Utility method to build base url and path

=cut

sub prepare_url {
    my ($self, $path) = @_;
    my $api_version = $self->api_version;
    my $new_path    = Mojo::Path->new($path);
    $path = $new_path->leading_slash(0);
    my $url = Mojo::URL->new($self->base_url)->path("/api/$api_version/$path")->to_abs();
    return $url;
}

=head2 js_encode

Utility method to encode as JSON format

=cut

sub js_encode {
    my ($self, $response) = @_;
    return encode_json($response);
}

=head2 js_decode

Utility method to decode as JSON format

=cut

sub js_decode {
    my ($self, $response) = @_;
    return decode_json($response);
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

1;    # End of WWW::Desk
