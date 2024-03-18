package UUID;
require 5.005;
use strict;
use warnings;
use Time::HiRes ();

require Exporter;
require DynaLoader;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK $VERSION);
@ISA = qw(DynaLoader);

$VERSION = '0.33';

%EXPORT_TAGS = (
    'all' => [qw(
        &clear &compare &copy &generate &generate_random &generate_time
        &generate_v0 &generate_v1 &generate_v4 &generate_v6 &generate_v7
        &is_null &parse &time &type &unparse &unparse_lower
        &unparse_upper &uuid &uuid0 &uuid1 &uuid4 &uuid6 &uuid7 &variant
        &version
    )],
);

@EXPORT_OK = @{$EXPORT_TAGS{'all'}};

bootstrap UUID $VERSION;

sub import {
    for (my $i=scalar(@_)-1 ; $i>0 ; --$i) {
        my $v = $_[$i];
        # :persist=FOO
        if (length($v) > 9 and substr($v,0,9) eq ':persist=') {
            _persist(substr($v, 9));
            splice @_, $i, 1;
            next;
        }
        # :mac=random
        if (length($v) == 11 and $v eq ':mac=random') {
            _hide_mac();
            splice @_, $i, 1;
            next;
        }
        # :mac=unique
        if (length($v) == 11 and $v eq ':mac=unique') {
            _hide_always();
            splice @_, $i, 1;
            next;
        }
    }
    goto &Exporter::import;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

UUID - Universally Unique Identifier library for Perl

=head1 SYNOPSIS

    use UUID qw(uuid);    # see EXPORTS

    my $str = uuid();     # generate version 4 UUID string

    $str = uuid();                    # new stringified UUID; prefer v4
    $str = uuid1();                   # new stringified UUID; always v1
    $str = uuid4();                   # new stringified UUID; always v4
    $str = uuid6();                   # new stringified UUID; always v6
    $str = uuid7();                   # new stringified UUID; always v7

    UUID::generate($bin);             # new binary UUID; prefer v4
    UUID::generate_v1($bin);          # new binary UUID; always v1
    UUID::generate_v4($bin);          # new binary UUID; always v4
    UUID::generate_v6($bin);          # new binary UUID; always v6
    UUID::generate_v7($bin);          # new binary UUID; always v7

    UUID::generate_time($bin);        # alias for generate_v1()
    UUID::generate_random($bin);      # alias for generate_v4()

    UUID::unparse($bin, $str);        # stringify $bin; prefer lowercase
    UUID::unparse_lower($bin, $str);  # force lowercase stringify
    UUID::unparse_upper($bin, $str);  # force uppercase stringify

    UUID::parse($str, $bin);          # map string to binary UUID

    UUID::compare($bin1, $bin2);      # compare binary UUIDs
    UUID::copy($dst, $src);           # copy binary UUID from $src to $dst

    UUID::clear($bin);                # set binary UUID to NULL
    UUID::is_null($bin);              # compare binary UUID to NULL

    UUID::time($bin);                 # return UUID time
    UUID::type($bin);                 # return UUID type
    UUID::variant($bin);              # return UUID variant
    UUID::version($bin);              # return UUID version


=head1 DESCRIPTION

The UUID library is used to generate unique identifiers for objects that
may be accessible beyond the local system. For instance, they could be
used to generate unique HTTP cookies across multiple web servers without
communication between the servers, and without fear of a name clash.

The generated UUIDs can be reasonably expected to be unique within a
system, and unique across all systems, and are compatible with those
created by the Open Software Foundation (OSF) Distributed Computing
Environment (DCE).

All generated UUIDs are either version 1, 4, 6, or version 7. And all
are variant 1, meaning compliant with the OSF DCE standard as described
in RFC4122.

Versions 6, 7, and 8 are not standardized. They are presented here as
proposed in RFC4122bis, version 14, and may change in the future.
RFC4122bis is noted to replace RFC4122, if approved.

=head1 FUNCTIONS

Most of the UUID functions expose the historically underlying
I<libuuid> C interface rather directly. That is, many return their
values in their parameters and nothing else.

Not very Perlish, but it's been like that for a long time so not likely
to change any time soon.

All take or return UUIDs in either binary or string format. The string
format resembles the following:

    21b081a3-de83-4480-a14f-e89a1dcf8f0f

Or, in terms of printf(3) format:

    "%08x-%04x-%04x-%04x-%012x"

The binary form is simply a packed 16 byte binary value.

=head2 B<clear(> I<$uuid> B<)>

Sets binary I<$uuid> equal to the value of the NULL UUID.

=head2 B<compare(> I<$uuid1>B<,> I<$uuid2> B<)>

Compares two binary UUIDs.

Returns an integer less than, equal to, or greater than zero if
I<$uuid1> is less than, equal to, or greater than I<$uuid2>.

If one is defined and the other not, the defined value is deemed the
larger.

If either operand is not a binary UUID, falls back to a simple string
comparison returning similar values.

=head2 B<copy(> I<$dst>B<,> I<$src> B<)>

Copies the binary I<$src> UUID to I<$dst>.

If I<$src> isn't a UUID, I<$dst> is set to the NULL UUID.

=head2 B<generate(> I<$uuid> B<)>

Alias for B<generate_v4()>.

Prior to version 0.33, this function provided either a binary version 4
UUID or fell back to version 1 in some cases. This is no longer the
case. The fallback feature was removed with the addition of an onboard
crypto-strength number generator.

=head2 B<generate_random(> I<$uuid> B<)>

Alias for B<generate_v4()>.

=head2 B<generate_time(> I<$uuid> B<)>

Alias for B<generate_v1()>.

=head2 B<generate_v1(> I<$uuid> B<)>

Generates a new version 1 binary UUID using the current time and the
local ethernet MAC address, if available.

If the MAC address is not available at startup, or a randomized address
is requested (see B<:mac> in B<EXPORTS>), a random address is used. The
multicast bit of this address is set to avoid conflict with addresses
returned from network cards.

=head2 B<generate_v4(> I<$uuid> B<)>

Generates a new version 4 binary UUID using mostly random data. There
are 6 bits used for the UUID format, leaving 122 bits for randomness.

=head2 B<generate_v6(> I<$uuid> B<)>

Generates a new version 6 binary UUID using the current time and the
local ethernet MAC address, if available.

If the MAC address is not available at startup, or a randomized address
is requested (see B<:mac> in B<EXPORTS>), a random address is used. The
multicast bit of this address is set to avoid conflict with addresses
returned from network cards.

Version 6 is the same as version 1, with reversed time fields to make it
more database friendly.

=head2 B<generate_v7(> I<$uuid> B<)>

Generates a new version 7 binary UUID using the current time and random
data. There are 6 bits used for the UUID format and 48 bits for
timestamp, leaving 74 bits for randomness.

Version 7 is the same as version 6, in that it uses reversed timestamp
fields, but also uses a Unix epoch time base instead of Gregorian.

=head2 B<is_null(> I<$uuid> B<)>

Compares the value of I<$uuid> to the NULL UUID.

Returns 1 if NULL, and 0 otherwise.

=head2 B<parse(> I<$string>B<,> I<$uuid> B<)>

Converts the string format UUID in I<$string> to binary and returns in
I<$uuid>. The previous content of I<$uuid>, if any, is lost.

Returns 0 on success and -1 on failure. Additionally on failure, the
content of I<$uuid> is unchanged.

=head2 B<time(> I<$uuid> B<)>

Returns the time element of a binary UUID in seconds since the epoch,
the same as I<Perl>'s B<time> function.

Keep in mind this only works for version 1, 6, and version 7 UUIDs.
Values returned from other versions are always 0.

=head2 B<type(> I<$uuid> B<)>

Alias for B<version()>.

=head2 B<unparse(> I<$uuid>B<,> I<$string> B<)>

Alias for B<unparse_lower()>.

Prior to version 0.32, casing of the return value was system-dependent.
Later versions are lowercase, per RFC4122.

=head2 B<unparse_lower(> I<$uuid>B<,> I<$string> B<)>

Converts the binary UUID in I<$uuid> to string format and returns in
I<$string>. The previous content of I<$string>, if any, is lost.

=head2 B<unparse_upper(> I<$uuid>B<,> I<$string> B<)>

Same as B<unparse_lower()> but I<$string> is forced to upper case.

=head2 B<uuid()>

Alias for B<uuid4()>.

=head2 B<uuid0()>

Returns a new string format NULL UUID.

=head2 B<uuid1()>

Returns a new string format version 1 UUID. Functionally the equivalent
of calling B<generate_v1()> then B<unparse()>, but throwing away the
intermediate binary UUID.

=head2 B<uuid4()>

Same as B<uuid1()> but version 4.

=head2 B<uuid6()>

Same as B<uuid1()> but version 6.

=head2 B<uuid7()>

Same as B<uuid1()> but version 7.

=head2 B<variant(> I<$uuid> B<)>

Returns the variant of binary I<$uuid>.

This module only generates variant 1 UUIDs, but others may be found in
the wild.

Known variants:

    0  NCS
    1  DCE
    2  Microsoft
    3  Other

=head2 B<version(> I<$uuid>> B<)>

Returns the version of binary I<$uuid>.

This module only generates version 1, 4, 6, and version 7 UUIDs, but
others may be found in the wild.

Known versions:
    v1  date/time and node address
    v2  date/time and node address, security version
    v3  namespace based, MD5 hash
    v4  random
    v5  namespace based, SHA-1 hash
    v6  reverse date/time and node address
    v7  reverse unix date/time and random
    v8  custom

=head1 MAINTAINING STATE

Internal state is optionally maintained for timestamped UUIDs (versions
1, 6, and 7) via a file designated by the B<:persist> export tag. See
B<EXPORTS> for details.

The file records various internal states at the time the last UUID is
generated, preventing future instances from overlapping the prior UUID
sequence. This allows the sequence to absolutely survive reboots and,
more importantly, backwards resetting of system time.

If B<:persist> is not used, time resets will still be detected while the
module is loaded and handled by incrementing the UUID clock_seq field.
The clock_seq field is randomly initialized in this case anyway, so the
chance of overlap is low but still exists since clock_seq is only 14
bits wide. Using a random MAC will help (see B<:mac> in B<EXPORTS>),
adding an additional 48 bits of randomness.

B<NOTE:> Using B<:persist> incurs a serious performance penalty, in
excess of 95% on tested platforms. You can run C<make compare> in the
distribution directory to see how this might affect your application,
but unless you need many thousands of UUIDs/sec it's probably a
non-issue.

=head1 RANDOM NUMBERS

Prior to version 0.33, UUID obtained randomness from the system's
I</dev/random> device, or similar interface. On some platforms it called
B<getrandom()> and on others it read directly from I</dev/urandom>. And
of course, Win32 did something completely different depending on the
environment.

Starting in 0.33, UUID generates random numbers itself using the
ChaCha20 algorithm which is considered crypto-strength in most circles.
This is the same algo used as the basis for many modern kernel RNGs,
albeit without the same entropy gathering ability.

To compensate, UUID mixes the output from ChaCha with output from
another RNG, Xoshiro. The idea is that by mixing the two, the true
output from either is effectively hidden, making discovery of either's
key much more unlikely than it already is. And without the keys, you
can't predict the future.

Well, that's the theory anyway.

=head1 EXPORTS

None by default. All functions may be imported in the usual manner,
either individually or all at once using the B<:all> tag.

Beware that importing B<:all> clobbers I<Perl>'s B<time()>, not to
mention a few other commonly used subs, like B<copy()> from
I<File::Copy>.

=head2 B<:mac>=I<mode>

The MAC address used for MAC-inclusive UUIDS (versions 1 and 6) is
forced to always be random in one of two modes:

=over 4

I<random> The MAC address is generated once at startup and used through
the lifetime of the process. This is the default if a real MAC cannot be
found.

I<unique> A new MAC address is generated for each new UUID. It is not
guaranteed to be unique beyond the probability of randomness.

=back

=head2 B<:persist>=F<path/to/state.txt>

Path to timestamp state maintenance file. (See B<MAINTAINING STATE>.)
The path may be either relative or absolute.

If the file does not exist, it will be created provided the path
exists and the user has permission.

If the file cannot be opened, cannot be created, or is a symlink, UUID
will ignore it. No state will be maintained.

B<WARNING>: Do not B<:persist> in a public directory. See CVE-2013-4184.
UUID attempts to avoid this, but nothing is foolproof. Only YOU can
prevent symlink attacks!

=head1 THREAD SAFETY

This module is believed to be thread safe.

=head1 UUID LIBRARY

Releases prior to UUID-0.32 required libuuid or similar be installed
first. This is no longer the case. Version 0.33 bundled the e2fsprogs
UUID code, and version 0.34 removed it altogether.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2024 by Rick Myers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

Details of this license can be found within the 'LICENSE' text file.

=head1 AUTHOR

Current maintainer:

  Rick Myers <jrm@cpan.org>.

Authors and/or previous maintainers:

  Lukas Zapletal <lzap@cpan.org>

  Joseph N. Hall <joseph.nathan.hall@gmail.com>

  Colin Faber <cfaber@clusterfs.com>

  Peter J. Braam <braam@mountainviewdata.com>

=head1 CONTRIBUTORS

David E. Wheeler

William Faulk

gregor herrmann

Slaven Rezic

twata

=head1 SEE ALSO

B<RFC4122> - L<https://www.rfc-editor.org/rfc/rfc4122>

B<RFC4122bis> - L<https://www.ietf.org/archive/id/draft-ietf-uuidrev-rfc4122bis-14.html>

B<perl(1)>.

=cut
