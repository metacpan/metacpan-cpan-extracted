package URI::cid;

use 5.008;
use strict;
use warnings;

use base qw(URI);

use Carp ();

=head1 NAME

URI::cid - RFC 2392 cid: URI implementation

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use URI;

    my $cid = $URI->new('cid:');
    $cid->cid('c6a62d04-1037-475e-a2be-ea38f9a78b64@foobar.local')

    # or, pull it straight from the header:

    my $cid = URI::cid->parse($mimepart->header('Content-ID'));

    # and put it back:

    $mimepart->header('Content-ID' => $cid->format);

=head1 DESCRIPTION

L<RFC 2392|http://tools.ietf.org/html/rfc2392> defines a
straight-forward method of expressing the contents of email
C<Message-ID> and C<Content-ID> headers as URIs. This module provides
some utility methods for working with them.

=head1 METHODS

=head2 cid

Get or set the C<Content-ID>.

=cut

sub cid {
    my $self = shift;
    $self->opaque(@_);
}

=head2 parse

Parse (i.e., remove the confining angle-brackets from) a C<Content-ID>
header.

=cut

sub parse {
    my ($self, $string) = @_;
    $self = URI->new('cid:') unless ref $self;

    $string =~ s/^\s*<([^>]*)>\s*$/$1/;
    $self->cid($string);
    $self;
}

=head2 format

Format a C<cid:> URI as a C<Content-ID> header value.

=cut

sub format {
    sprintf '<%s>', shift->cid;
}

=head1 SEE ALSO

=over 4

=item L<http://tools.ietf.org/html/rfc2392>

=item L<Email::Simple>

=item L<Email::MIME>

=back

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-uri-mid at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-mid>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::cid

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-mid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-mid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-mid>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-mid/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.


=cut

1; # End of URI::cid
