package URI::mid;

use 5.008;
use strict;
use warnings;

use base qw(URI::cid);

use Carp         ();
use Scalar::Util ();

=head1 NAME

URI::mid - RFC 2392 mid: URI implementation

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use URI;

    my $mid = URI->new('mid:');
    $mid->mid('1bb1a82c-eb3f-415d-b82f-7fa4c63d2e31@foobar.local');

    # or, pull it (them) straight from the header:

    my @mids = URI::mid->parse($email->header('References'));

    # and put it back

    $email->header(References => join(' ', map { $_->format } @mids));

=head1 METHODS

=head2 mid

Get or set the literal C<Message-ID>.

=cut

sub mid {
    my ($self, $new) = @_;
    my $o = $self->opaque;
    my ($mid, $cid) = ($o =~ m!^([^/]*)(?:/(.*))?$!);

    if ($new) {
        $new = $new->mid if ref $new and $new->isa('URI::mid');
        $self->opaque(defined $cid ? "$mid/$cid" : $mid);
        return $self;
    }

    $mid;
}

=head2 mid_uri

Get just the C<Message-ID> component as a L<URI::mid> object. Returns
itself if there is no C<Content-ID>.

=cut

sub mid_uri {
    my $self = shift;
    return $self unless $$self =~ m!/!;
    URI->new('mid:' . shift->mid);
}

=head2 cid

Get or set the C<Content-ID> as a L<URI::cid> object. Accepts a string
or a L<URI::cid> object. Which means you can do stuff like this:

    $mimepart->header('Content-ID' => $mid->cid->format);

=cut

sub cid {
    my ($self, $new) = @_;
    my $o = $self->opaque;
    my ($mid, $cid) = ($o =~ m!^([^/]*)(?:/(.*))?$!);

    if (defined $new) {
        if (ref $new) {
            Carp::croak('Must be a string or URI::cid')
                  unless Scalar::Util::blessed($new) and $new->isa('URI::cid');
            $new = $new->cid;
        }
        $self->opaque("$mid/$new");
        return $self;
    }

    return unless defined $cid and $cid ne '';

    URI->new("cid:$cid");
}

=head2 parse

Parse (i.e., remove the confining angle-brackets from) one or more
C<Message-ID> headers. Returns them all in list context, or the first
one in scalar context, like so:

    my $mid  = URI::mid->parse($email->header('Message-ID'));

    my @mids = URI::mid->parse($email->header('References'));

    # Also works as an instance method:

    my $mid = URI->new('mid:');
    $mid->parse($email->header('In-Reply-To'));

=cut

sub parse {
    my ($self, $string) = @_;
    # ha! learned this trick from DBIx::Class.
    Carp::croak('URI::mid::parse makes no sense in void context')
          unless defined wantarray;

    my @str = map { /^\s*<([^>]*)>\s*$/; $1 } split /(?<=>)\s*(?=<)/, $string;

    $self = URI->new('mid:') unless ref $self;

    unless (wantarray) {
        $self->opaque($str[0]);
        return $self;
    }

    map { URI->new("mid:$_") } @str;
}

=head1 SEE ALSO

=over 4

=item L<URI::cid>

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

    perldoc URI::mid

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

1; # End of URI::mid
