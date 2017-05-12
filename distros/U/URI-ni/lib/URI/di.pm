package URI::di;

require URI;
require URI::_query;
require URI::_punycode;
require URI::QueryParam;
@ISA=qw(URI::_query URI);

$VERSION = '0.03';

# not sure why the module is laid out like this, oh well.

=head1 NAME

URI::di - URI scheme for digital signatures

=head1 SYNOPSIS

    use URI;

    $u = URI->new('di:sha-256');
    $u->compute('some data');

    my $algo = $u->algorithm;
    my $b64  = $u->b64digest;
    my $hex  = $u->hexdigest;
    my $bin  = $u->digest;

=head1 DESCRIPTION

This module implements the C<di:> URI scheme defined in
L<draft-hallambaker-digesturi|http://tools.ietf.org/html/draft-hallambaker-digesturi-02>.

=cut

use strict;
use warnings; # FATAL => 'all';
use utf8;

use MIME::Base64 ();
use URI::Escape  ();
use Digest       ();
use Carp         ();
use Scalar::Util ();

# XXX please don't go away from Digest
my %ALGOS = map { lc $_ => 1 } keys %Digest::MMAP;

=head2 compute $DATA [, $ALGO, \%QUERY]

Compute a new di: URI from some data. Since the data objects we're
typically interested in hashing tend to be bulky, this method will
optionally take GLOB or SCALAR references, even blessed ones if you
can be sure they'll behave, that is, globs treated like files and
scalars dereferenced. If not, C<$DATA> can also be a CODE reference as
well, with the L<Digest> context as its first argument, enabling you
to specify your own behaviour, like this:

    my $obj = MyObj->new;

    my $di = URI->new('di:sha-256;');
    $di->compute(sub { shift->add($obj->as_string) });

    # Alternatively:

    use URI::di;

    my $di = URI::di->compute(sub { shift->add($obj->as_string) });

It is also possible to supply your own L<Digest> instance and the URI
will be generated from its current state, like this:

    my $ctx = Digest->new('SHA-1');
    $ctx->add($some_stuff);

    # REMEMBER TO MATCH THE ALGORITHM IN THE CONSTRUCTOR!
    # I CAN'T (RELIABLY) DO IT FOR YOU!

    my $di = URI::di->compute($ctx, 'sha-1')

    # now you can use $ctx for other stuff.

    # The URI doesn't store $ctx so if you modify it, the URI won't
    # change.

The algorithms supported are the same as the ones in L<Digest>, which
will be coerced to lower-case in the URI. If omitted, the default
algorithm is SHA-256, per the draft spec.

Optionally, you can pass in a string or HASH reference which will be
appended to the URI. The keys map as they do in L<URI::QueryParam>,
and so do the values, which can be either strings or ARRAY references
containing strings, to represent multiple values.

=cut

sub compute {
    my ($self, $data, $algo, $query) = @_;
    Carp::croak('Compute constructor must have some sort of data source.')
          unless defined $data;

    # we need these right away
    my $is_blessed = Scalar::Util::blessed($data);
    my $is_digest  = $is_blessed and $data->isa('Digest::base');

    $algo = $algo ? lc $algo : 'sha-256';
    $self = ref $self ? $self->clone : URI->new("di:$algo");
    # one last time
    $algo = lc $self->algorithm;

    # easy out for exotic Digest subclasses
    Carp::croak("Algorithm $algo isn't on the menu.")
          unless $ALGOS{$algo} or $is_digest;

    # of course the chief wants it in upper case
    my $ctx = Digest->new(uc $algo);

    if (ref $data) {
        if ($is_digest) {
            $ctx = $data;
        }
        else {
            # oh man this is too damn clever. it is bound to screw up.
            my %handler = (
                GLOB   => sub { binmode $_[0]; $ctx->addfile($_[0]) },
                SCALAR => sub { $ctx->add(${shift()}) },
                CODE   => sub { shift->($ctx) },
            );

            my $ok;
            for my $type (keys %handler) {
                # XXX is there a less dumb way to do this?
                $ok = $is_blessed ? $data->isa($type) : ref $data eq $type;
                if ($ok) {
                    $handler{$type}->($data);
                    last;
                }
            }
            Carp::croak('If the data is a reference, it has to be' .
                            ' some kind of GLOB or SCALAR.') unless $ok;
        }
    }
    else {
        $ctx->add($data);
    }

    my $digest = $ctx->b64digest;
    $digest =~ tr!+/!-_!;

    $self->opaque("$algo;$digest");
    # XXX do something smarter with the query
    $self->query_form_hash($query) if $query;

    $self;
}

=head2 from_digest $DIGEST [, $ALGO, \%QUERY, $KIND ]

Returns a C<di:> URI from an already-computed digest. As with
L</compute>, you need to supply C<$ALGO> only if you have either not
supplied one in the constructor (e.g. C<URI-E<gt>new('di:')>), or you
are using this as a class method.

If C<$DIGEST> isn't a L<Digest> object, this method will try to detect
the representation of the digest that is passed in with C<$DIGEST>. By
convention, it is biased toward the hexadecimal representation, since
that is how we typically find message digests in the wild. It is
I<possible>, though not likely, that Base64 or binary representations
only contain bits that correspond to C<[0-9A-Fa-f]>, so if you're
feeling paranoid, you can supply an additional $KIND parameter with
the radix of each character (e.g. C<16>, C<64> or C<256>), or the
strings C<hex>, C<b64> or C<bin>. Base64 digests can be supplied in
either conventional or
L<base64url|http://tools.ietf.org/html/rfc4648#section-5> forms.

=over 4

(NB: The difference between standard Base64 and base64url is simply
C<tr!+/!-_!>.)

=back

=cut

my %OP = (
    16  => sub { MIME::Base64::encode_base64(pack('H*', $_[0]), '') },
    64  => sub { $_[0] },
    256 => sub { MIME::Base64::encode_base64($_[0], '') },
);

my %KINDS = (
    hex => 16,
    b64 => 64,
    bin => 256,
);

sub from_digest {
    my ($self, $digest, $algo, $query, $kind) = @_;
    Carp::croak('Compute constructor must have some sort of data source.')
          unless defined $digest;

    $algo = $algo ? lc $algo : 'sha-256';
    $self = ref $self ? $self->clone : URI->new("di:$algo");
    # one last time
    $algo = lc $self->algorithm;

    if (ref $digest) {
        Carp::croak("Digest must be a Digest::base subclass")
              unless Scalar::Util::blessed $digest
                  and $digest->isa('Digest::base');
        $digest = $digest->b64digest;
    }
    else {
        utf8::downgrade($digest);
        my $op;
        if (defined $kind) {
            $op = $OP{$kind} || $OP{$KINDS{$kind}}
                or Carp::croak("Unrecognized representation '$kind'");
        }
        else {
            my $x = $digest =~ /[\x80-\xff]/ ? 256
                : $digest =~ /[^0-9A-Fa-f]/ ? 64 : 16;
            $op = $OP{$x};
        }

        $digest = $op->($digest);
        # per Digest::base
        $digest =~ s/=+$//;
    }

    # XXX should probably compartmentalize this with the above method

    $digest =~ tr!+/!-_!;

    $self->opaque("$algo;$digest");
    # XXX do something smarter with the query
    $self->query_form_hash($query) if $query;

    $self;
}

=head2 algorithm

Retrieves the hash algorithm. This method is read-only, since it makes
no sense to change the algorithm of an already-computed hash.

=cut

sub algorithm {
    my $self = shift;
    my $o = $self->opaque;
    return unless defined $o;
    $o =~ s/^(.*?)(;.*)?$/$1/;
    $o;
}

=head2 b64digest [$RAW]

Returns the digest encoded in Base64. An optional C<$RAW> argument
will return the digest without first translating from I<base64url>
(section 5 in L<RFC 4648|http://tools.ietf.org/html/rfc4648#section-5>).

Like everything else in this module that pertains to the hash itself,
this accessor is read-only.

=cut

sub b64digest {
    my ($self, $raw) = @_;
    my $hash = $self->opaque;
    $hash =~ s/^(?:.*?;)(.*?)(?:\?.*)?$/$1/;
    $hash =~ tr!-_!+/! unless $raw;
    $hash;
}

=head2 hexdigest

Returns the hexadecimal cryptographic digest we're all familiar with.

=cut

sub hexdigest {
    unpack 'H*', shift->digest;
}

=head2 digest

Retrieves a binary digest, in keeping with the nomenclature in
L<Digest>.

=cut

sub digest {
    MIME::Base64::decode_base64(shift->b64digest);
}

=head2 locators

This is a convenience method to instantiate any locators defined in L<section
2.1.4|http://tools.ietf.org/html/draft-hallambaker-digesturi-02#section-2.1.4>
as URI objects. If you want to set these values, use L<URI::QueryParam>
with the C<http> or C<https> keys. Returns all locators in list
context, and the first one in scalar context (which of course may be
undef).

=cut

sub locators {
    my $self   = shift;
    my $algo   = $self->algorithm;
    my $digest = $self->b64digest(1);

    my @loc;
    for my $scheme (qw(http https)) {
        for my $host ($self->query_param($scheme)) {
            # RFC 5785 kinda gives me the creeps.
            push @loc, URI->new(sprintf '%s://%s/.well-known/di/%s/%s',
                                $scheme, $host, $algo, $digest);
        }
    }

    return wantarray ? @loc : $loc[0];
}

=head2 crypto

Returns the cryptography spec embedded in the C<enc> or C<menc>
parameters. A key is kind of a weird thing to embed in a URI, but
whatever floats your boat. As such, I have yet to implement this in
any sane way.

=cut

sub crypto {
    my ($self, $which, $new) = @_;
    Carp::croak("Only 'enc' and 'menc' are valid values.")
          unless $which =~ /^m?enc/i;

    my ($old) = $self->query_param($which);
    $old = URI::di::CryptoSpec->new($old) if defined $old;

    if (defined $new) {
        $new = URI::di::CryptoSpec->new($new);
        $self->query_param(lc $which => "$new");
        # i always thought this behaviour was weird.
        return $old;
    }

    $old;
}

package URI::di::CryptoSpec;

use overload '""' => \&as_string;

sub new {
    my ($class, $string) = @_;
    bless \$string, $class;
}

sub cipher {
    my $self = shift;
    my $s = $$self;
    $s =~ /^(.*?)(:.*)?$/;
    $1;
}

sub key {
    my $self = shift;
    my $s = $$self;
    $s =~ /^(?:[^:]+:)([^:]*?)(:.*)?$/;
    $1;
}

sub iv {
    my $self = shift;
    my $s = $$self;
    $s =~ /^(?:[^:]+:){2}(.*?)$/;
    $1;
}

sub as_string {
    ${$_[0]};
}

=head1 SEE ALSO

=over 4

=item L<http://tools.ietf.org/html/draft-hallambaker-digesturi-02>

=item L<URI>

=item L<Digest>

=back

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-uri-di at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-di>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::di


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-di>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-di>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-di>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-di/>

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

1; # End of URI::di
