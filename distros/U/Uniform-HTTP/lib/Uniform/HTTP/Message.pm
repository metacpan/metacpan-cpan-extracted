package Uniform::HTTP::Message;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.06';

my $TOKEN_RE = qr/\A[!\#\$%&'*+\-.\^_`|~0-9A-Za-z]+\z/;

sub new {
    my ($class, @args) = @_;
    my $args = _named_args('new', @args);

    for my $name (keys %$args) {
        croak "unknown constructor option '$name'"
            unless $name eq 'version'
                || $name eq 'headers'
                || $name eq 'trailers'
                || $name eq 'body';
    }

    my $self = bless {
        version           => undef,
        headers           => [],
        trailers          => [],
        initial_frozen    => 0,
        trailers_frozen   => 0,
        body              => undef,
        has_buffered_body => 0,
        complete          => 1,
        mutable           => 1,
    }, $class;

    $self->version($args->{version}) if exists $args->{version};
    $self->_set_initial_headers($args->{headers}) if exists $args->{headers};
    $self->_set_initial_trailers($args->{trailers}) if exists $args->{trailers};
    $self->body($args->{body}) if exists $args->{body};

    return $self;
}

sub version {
    my ($self, @args) = @_;
    return $self->{version} unless @args;
    croak 'version() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    if (!defined $args[0]) {
        $self->{version} = undef;
        return $self;
    }

    my $version = _byte_string('version', $args[0]);
    croak 'version must contain digits with an optional decimal part'
        unless $version =~ /\A[0-9]+(?:\.[0-9]+)?\z/;
    $self->{version} = $version;
    return $self;
}

sub header {
    my ($self, @args) = @_;
    croak 'header() requires a field name' unless @args;
    croak 'header() accepts a field name and optional value' unless @args <= 2;

    my $name = _field_name('header', $args[0]);
    my $key = _ascii_lc($name);

    if (@args == 1) {
        for my $field (@{ $self->{headers} }) {
            return $field->[1] if _ascii_lc($field->[0]) eq $key;
        }
        return;
    }

    $self->_assert_initial_mutable;
    my $value = _field_value('header', $args[1]);
    my @headers;
    my $inserted;

    for my $field (@{ $self->{headers} }) {
        if (_ascii_lc($field->[0]) eq $key) {
            if (!$inserted) {
                push @headers, [ $name, $value ];
                $inserted = 1;
            }
            next;
        }
        push @headers, [ @$field ];
    }

    push @headers, [ $name, $value ] unless $inserted;
    $self->{headers} = \@headers;
    return $self;
}

sub header_values {
    my ($self, @args) = @_;
    croak 'header_values() requires exactly one field name' unless @args == 1;

    my $key = _ascii_lc(_field_name('header', $args[0]));
    return [
        map { $_->[1] }
        grep { _ascii_lc($_->[0]) eq $key }
        @{ $self->{headers} }
    ];
}

sub add_header {
    my ($self, @args) = @_;
    croak 'add_header() requires exactly a field name and value'
        unless @args == 2;

    $self->_assert_initial_mutable;
    push @{ $self->{headers} }, [
        _field_name('header', $args[0]),
        _field_value('header', $args[1]),
    ];
    return $self;
}

sub remove_header {
    my ($self, @args) = @_;
    croak 'remove_header() requires exactly one field name' unless @args == 1;

    $self->_assert_initial_mutable;
    my $key = _ascii_lc(_field_name('header', $args[0]));
    $self->{headers} = [
        map { [ @$_ ] }
        grep { _ascii_lc($_->[0]) ne $key }
        @{ $self->{headers} }
    ];
    return $self;
}

sub header_count {
    my ($self, @args) = @_;
    croak 'header_count() does not accept arguments' if @args;
    return scalar @{ $self->{headers} };
}

sub header_name {
    my ($self, @args) = @_;
    croak 'header_name() requires exactly one index' unless @args == 1;
    my $index = _field_index('header', $args[0]);
    return if $index >= @{ $self->{headers} };
    return $self->{headers}[$index][0];
}

sub header_value {
    my ($self, @args) = @_;
    croak 'header_value() requires exactly one index' unless @args == 1;
    my $index = _field_index('header', $args[0]);
    return if $index >= @{ $self->{headers} };
    return $self->{headers}[$index][1];
}

sub trailer {
    my ($self, @args) = @_;
    croak 'trailer() requires a field name' unless @args;
    croak 'trailer() accepts a field name and optional value' unless @args <= 2;

    my $name = _field_name('trailer', $args[0]);
    my $key = _ascii_lc($name);

    if (@args == 1) {
        for my $field (@{ $self->{trailers} }) {
            return $field->[1] if _ascii_lc($field->[0]) eq $key;
        }
        return;
    }

    $self->_assert_trailers_mutable;
    my $value = _field_value('trailer', $args[1]);
    my @trailers;
    my $inserted;

    for my $field (@{ $self->{trailers} }) {
        if (_ascii_lc($field->[0]) eq $key) {
            if (!$inserted) {
                push @trailers, [ $name, $value ];
                $inserted = 1;
            }
            next;
        }
        push @trailers, [ @$field ];
    }

    push @trailers, [ $name, $value ] unless $inserted;
    $self->{trailers} = \@trailers;
    return $self;
}

sub trailer_values {
    my ($self, @args) = @_;
    croak 'trailer_values() requires exactly one field name' unless @args == 1;

    my $key = _ascii_lc(_field_name('trailer', $args[0]));
    return [
        map { $_->[1] }
        grep { _ascii_lc($_->[0]) eq $key }
        @{ $self->{trailers} }
    ];
}

sub add_trailer {
    my ($self, @args) = @_;
    croak 'add_trailer() requires exactly a field name and value'
        unless @args == 2;

    $self->_assert_trailers_mutable;
    push @{ $self->{trailers} }, [
        _field_name('trailer', $args[0]),
        _field_value('trailer', $args[1]),
    ];
    return $self;
}

sub remove_trailer {
    my ($self, @args) = @_;
    croak 'remove_trailer() requires exactly one field name' unless @args == 1;

    $self->_assert_trailers_mutable;
    my $key = _ascii_lc(_field_name('trailer', $args[0]));
    $self->{trailers} = [
        map { [ @$_ ] }
        grep { _ascii_lc($_->[0]) ne $key }
        @{ $self->{trailers} }
    ];
    return $self;
}

sub trailer_count {
    my ($self, @args) = @_;
    croak 'trailer_count() does not accept arguments' if @args;
    return scalar @{ $self->{trailers} };
}

sub trailer_name {
    my ($self, @args) = @_;
    croak 'trailer_name() requires exactly one index' unless @args == 1;
    my $index = _field_index('trailer', $args[0]);
    return if $index >= @{ $self->{trailers} };
    return $self->{trailers}[$index][0];
}

sub trailer_value {
    my ($self, @args) = @_;
    croak 'trailer_value() requires exactly one index' unless @args == 1;
    my $index = _field_index('trailer', $args[0]);
    return if $index >= @{ $self->{trailers} };
    return $self->{trailers}[$index][1];
}

sub body {
    my ($self, @args) = @_;
    return $self->{body} unless @args;
    croak 'body() accepts at most one value' unless @args == 1;

    $self->_assert_mutable;
    croak 'buffered body is immutable' unless $self->body_is_mutable;
    $self->{body} = _byte_string('body', $args[0]);
    $self->{has_buffered_body} = 1;
    return $self;
}

sub has_buffered_body {
    my ($self, @args) = @_;
    croak 'has_buffered_body() does not accept arguments' if @args;
    return $self->{has_buffered_body} ? 1 : 0;
}

sub is_complete {
    my ($self, @args) = @_;
    croak 'is_complete() does not accept arguments' if @args;
    return $self->{complete} ? 1 : 0;
}

sub is_mutable {
    my ($self, @args) = @_;
    croak 'is_mutable() does not accept arguments' if @args;
    return $self->{mutable} ? 1 : 0;
}

sub initial_is_mutable {
    my ($self, @args) = @_;
    croak 'initial_is_mutable() does not accept arguments' if @args;
    return $self->is_mutable && !$self->{initial_frozen} ? 1 : 0;
}

sub body_is_mutable {
    my ($self, @args) = @_;
    croak 'body_is_mutable() does not accept arguments' if @args;
    return $self->is_mutable ? 1 : 0;
}

sub trailers_are_mutable {
    my ($self, @args) = @_;
    croak 'trailers_are_mutable() does not accept arguments' if @args;
    return $self->is_mutable && !$self->{trailers_frozen} ? 1 : 0;
}

sub freeze_initial {
    my ($self, @args) = @_;
    croak 'freeze_initial() does not accept arguments' if @args;
    $self->{initial_frozen} = 1;
    return $self;
}

sub freeze_trailers {
    my ($self, @args) = @_;
    croak 'freeze_trailers() does not accept arguments' if @args;
    $self->{trailers_frozen} = 1;
    return $self;
}

sub freeze {
    my ($self, @args) = @_;
    croak 'freeze() does not accept arguments' if @args;
    $self->{mutable} = 0;
    return $self;
}

sub mark_incomplete {
    my ($self, @args) = @_;
    croak 'mark_incomplete() does not accept arguments' if @args;
    $self->{complete} = 0;
    return $self;
}

sub mark_complete {
    my ($self, @args) = @_;
    croak 'mark_complete() does not accept arguments' if @args;
    $self->{complete} = 1;
    return $self;
}

sub headers_are_lossless {
    my ($self, @args) = @_;
    croak 'headers_are_lossless() does not accept arguments' if @args;
    return 1;
}

sub has_trailers {
    my ($self, @args) = @_;
    croak 'has_trailers() does not accept arguments' if @args;
    my $count = $self->trailer_count;
    return unless defined $count;
    return $count ? 1 : 0;
}

sub trailers_are_lossless {
    my ($self, @args) = @_;
    croak 'trailers_are_lossless() does not accept arguments' if @args;
    return 1;
}

sub _set_initial_headers {
    my ($self, $headers) = @_;
    croak 'headers must be an array reference of field-name/value pairs'
        unless ref($headers) eq 'ARRAY';

    my @copy;
    for my $field (@$headers) {
        croak 'each header must be a two-element array reference'
            unless ref($field) eq 'ARRAY' && @$field == 2;
        push @copy, [
            _field_name('header', $field->[0]),
            _field_value('header', $field->[1]),
        ];
    }
    $self->{headers} = \@copy;
    return;
}

sub _set_initial_trailers {
    my ($self, $trailers) = @_;
    croak 'trailers must be an array reference of field-name/value pairs'
        unless ref($trailers) eq 'ARRAY';

    my @copy;
    for my $field (@$trailers) {
        croak 'each trailer must be a two-element array reference'
            unless ref($field) eq 'ARRAY' && @$field == 2;
        push @copy, [
            _field_name('trailer', $field->[0]),
            _field_value('trailer', $field->[1]),
        ];
    }
    $self->{trailers} = \@copy;
    return;
}

sub _assert_mutable {
    my ($self) = @_;
    croak 'message is immutable' unless $self->is_mutable;
    return;
}

sub _assert_initial_mutable {
    my ($self) = @_;
    $self->_assert_mutable;
    croak 'initial message data is immutable' unless $self->initial_is_mutable;
    return;
}

sub _assert_trailers_mutable {
    my ($self) = @_;
    $self->_assert_mutable;
    croak 'trailers are immutable' unless $self->trailers_are_mutable;
    return;
}

sub _named_args {
    my ($method, @args) = @_;
    croak "$method() requires named arguments" if @args % 2;
    return { @args };
}

sub _byte_string {
    my ($name, $value) = @_;
    croak "$name must be a defined plain scalar"
        unless defined($value) && !ref($value);

    my $copy = "$value";
    croak "$name must be a byte string"
        unless utf8::downgrade($copy, 1);
    return $copy;
}

sub _field_name {
    my ($section, $value) = @_;
    my $name = _byte_string("$section name", $value);
    croak "$section name must be an HTTP token" unless $name =~ $TOKEN_RE;
    return $name;
}

sub _field_value {
    my ($section, $value) = @_;
    my $field_value = _byte_string("$section value", $value);
    croak "$section value contains a prohibited control byte"
        if $field_value =~ /[\x00-\x08\x0a-\x1f\x7f]/;
    return $field_value;
}

sub _field_index {
    my ($section, $value) = @_;
    croak "$section index must be a non-negative integer"
        unless defined($value) && !ref($value) && $value =~ /\A[0-9]+\z/;
    return 0 + $value;
}

sub _ascii_lc {
    my ($value) = @_;
    $value =~ tr/A-Z/a-z/;
    return $value;
}

1;

__END__

=head1 NAME

Uniform::HTTP::Message - Common HTTP message behavior

=head1 SYNOPSIS

    use Uniform::HTTP::Message;

    my $message = Uniform::HTTP::Message->new(
        version => '1.1',
        headers => [
            [ 'Content-Type', 'text/plain' ],
            [ 'Set-Cookie',   'a=1' ],
            [ 'Set-Cookie',   'b=2' ],
        ],
        body => "hello\n",
    );

=head1 DESCRIPTION

Uniform::HTTP::Message is the common base for
L<Uniform::HTTP::Request> and L<Uniform::HTTP::Response>.

It stores HTTP version, headers, trailers, and an optional buffered body. It
does not parse HTTP, send data, read streams, or perform network I/O.

Headers and trailers are separate lists preserving duplicate fields, order,
original field-name spelling, and value bytes.

Most applications will create Request or Response objects rather than using
Message directly.

=head1 CONSTRUCTOR

=head2 new

    my $message = Uniform::HTTP::Message->new(
        version => '1.1',
        headers => [
            [ 'Content-Type', 'text/plain' ],
        ],
        body => 'hello',
    );

All arguments are optional.

C<headers> and C<trailers> must be array references containing
C<[ name, value ]> pairs. Both default to empty lists.

=head1 HEADERS

=head2 header

    my $value = $message->header('Content-Type');

Returns the first matching value. Header names are matched
case-insensitively.

Set or replace a header with:

    $message->header('Content-Type', 'application/json');

When duplicate fields already exist, the setter replaces them with one field.

=head2 header_values

    my $values = $message->header_values('Set-Cookie');

Returns an array reference containing every matching value in order.

=head2 add_header

    $message->add_header('Set-Cookie', 'c=3');

Appends one new field without replacing existing fields.

=head2 remove_header

    $message->remove_header('X-Debug');

Removes every matching field.

=head2 header_count

Returns the number of header field occurrences.

=head2 header_name

    my $name = $message->header_name($index);

Returns the original field name at a zero-based index.

=head2 header_value

    my $value = $message->header_value($index);

Returns the field value at a zero-based index.

=head2 headers_are_lossless

Returns true for canonical Uniform messages because duplicate fields, order,
and original field-name spelling are preserved.

Adapters may return false when their native framework cannot preserve all of
those details.

=head1 TRAILERS

Trailers use the same field rules as headers, but never appear in header
lookups. They may be supplied to the constructor:

    trailers => [ [ 'Content-Digest', $digest_field_value ] ],

=head2 trailer

    my $first = $message->trailer('Content-Digest');
    $message->trailer('Content-Digest', $digest_field_value);

The getter returns the first matching value or C<undef>. The setter replaces
all matches at the first matching position, or appends when absent.

=head2 trailer_values

Returns an array reference of all matching values in order, or an empty array
when none are present. Values are never comma-joined.

=head2 add_trailer

    $message->add_trailer('X-Metric', '42');

Appends one field without replacing earlier occurrences.

=head2 remove_trailer

Removes every occurrence of the named field.

=head2 trailer_count

Returns the number of currently represented trailer field occurrences.

=head2 trailer_name

Returns the original field name at the supplied zero-based index, or C<undef>
when out of range.

=head2 trailer_value

Returns the value at the supplied zero-based index, or C<undef> when out of
range. Negative or noninteger indexes throw.

=head2 has_trailers

Returns true when at least one trailer field is represented. Omitted trailers
and an explicit empty list both return false. On an incomplete message, false
does not mean no fields can arrive later.

=head2 trailers_are_lossless

Returns true for canonical objects. Adapters report false when trailer fields,
order, spelling, or value bytes were lost. This is independent of header
fidelity.

Adapters with unavailable trailers return C<undef> from all trailer getters,
including C<trailer_count>, C<has_trailers>, and C<trailer_values>; they return
false from C<trailers_are_lossless> and C<trailers_are_mutable>. This differs
from a known empty section.

The HTTP sender is responsible for checking which fields may be trailers and
whether its selected framing supports them. Uniform checks generic field
syntax without interpreting field-specific rules.

=head1 BODY

=head2 body

    my $bytes = $message->body;

Returns the buffered body, or C<undef> when no buffered body is present.

Set a buffered body with:

    $message->body($bytes);

Calling C<body()> never reads a socket, filehandle, callback, or streaming
source.

=head2 has_buffered_body

Returns true when C<body()> contains a buffered body. An empty string still
counts as a buffered body.

=head1 VERSION

=head2 version

    my $version = $message->version;

Returns values such as C<1.1>, C<2>, or C<3>, without an C<HTTP/> prefix.
C<undef> is suitable for an application-created neutral message. A sender can
choose a version separately without changing or unfreezing that object.
Received messages should report their actual version when known.

Set or clear it with:

    $message->version('2');
    $message->version(undef);

=head1 MESSAGE STATE

=head2 is_mutable

Returns true when at least one section can be changed; false means all data
mutations are forbidden. Canonical objects begin fully mutable. After a
section freeze, use the specific capability before changing that section.

=head2 initial_is_mutable

Reports whether initial headers, version, and Request/Response metadata can
be changed. False after C<freeze_initial()> or C<freeze()>.

=head2 body_is_mutable

Reports whether a complete buffered body can be supplied or replaced. False
after C<freeze()>. Adapters may report false for a streaming-only body.

=head2 trailers_are_mutable

Reports whether trailer fields can be changed. False after
C<freeze_trailers()> or C<freeze()>.

=head2 freeze_initial

    $message->mark_incomplete->freeze_initial;
    # External receipt continues; Uniform itself performs no I/O.
    $message->add_trailer('Content-Digest', $digest_field_value);
    $message->mark_complete->freeze;

Locks only initial headers, version, and Request/Response metadata. Body and
trailers remain editable. It is idempotent and never thaws a fully frozen
object.

=head2 freeze_trailers

Locks just the trailer fields, including an empty section. It is idempotent.

=head2 freeze

    $message->freeze;

Freezes all data in a canonical Uniform object, including body and trailers.
After this, all data setters throw an exception.

C<freeze()> only changes the local object. It does not send headers, commit a
framework response, or perform I/O.

=head2 is_complete

Returns true when the whole message is known to be complete, including any
trailers. A buffered body alone does not establish completeness.

Canonical objects begin complete. An adapter may return C<undef> when its
framework cannot determine completeness yet.

=head2 mark_incomplete

Marks a canonical message incomplete.

=head2 mark_complete

Marks a canonical message complete.

These two helpers are useful when a detached Uniform object is following
externally managed streaming progress. They change only completeness, even
after full freeze. Neither helper freezes nor thaws any section. Complete
objects remain editable unless explicitly frozen.

Freeze and completeness helpers belong to canonical objects. Adapters need
only report native state; they are not required to provide these helpers.

=head1 BYTE STRINGS

Message values are byte strings. Uniform::HTTP does not guess a character
encoding.

Header and trailer names must be valid HTTP tokens. Field values reject
prohibited control bytes. Body bytes remain opaque.

=head1 SEE ALSO

L<Uniform::HTTP>, L<Uniform::HTTP::Request>, L<Uniform::HTTP::Response>.

The full adapter contract is documented in F<docs/MESSAGE-SPEC.md>.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
