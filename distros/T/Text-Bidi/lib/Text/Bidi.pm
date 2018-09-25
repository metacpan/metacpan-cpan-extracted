use 5.10.0;
use warnings;
#no warnings 'experimental';
use strict 'vars';
#use Carp::Always;

package Text::Bidi;
# ABSTRACT: Unicode bidi algorithm using libfribidi
$Text::Bidi::VERSION = '2.15';
use Exporter;
use base qw(Exporter);
use Carp;

use Text::Bidi::private;
use Text::Bidi::Array::Byte;
use Text::Bidi::Array::Long;
use Encode qw(encode decode);


BEGIN {
    our %EXPORT_TAGS = (
        'all' => [ qw(
            log2vis
            is_bidi
            get_mirror_char
            get_bidi_type_name
            fribidi_version
            fribidi_version_num
            unicode_version
        ) ],
    );
    our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'}} );
}


# The following mechanism is used to provide both kinds of interface: Every 
# method starts with 'my $self = S(@_)' instead of 'my $self = shift'. S 
# shifts and returns the object if there is one, or returns a global object, 
# stored in $Global, if there is in @_. The first time $Global is needed, it 
# is created with type $GlobalClass.

my $Global;
our $GlobalClass = __PACKAGE__;


sub S(\@) {
    my $l = shift;
    my $s = $l->[0];
    return shift @$l if eval { $s->isa('Text::Bidi') };
    $Global = new $GlobalClass unless $Global;
    $Global
}


sub new {
    my $class = shift;
    my $self = {
        tie_byte => 'Text::Bidi::Array::Byte',
        tie_long => 'Text::Bidi::Array::Long',
        @_
    };
    bless $self => $class
}


sub tie_byte {
    my $self = shift;
    return \undef unless defined $_[0];
    $self->{'tie_byte'}->new(@_)
}

sub tie_long {
    my $self = shift;
    return \undef unless defined $_[0];
    $self->{'tie_long'}->new(@_)
}


sub utf8_to_internal {
    my $self = S(@_);
    my $str = shift;
    my ($i, $res) = 
      Text::Bidi::private::utf8_to_internal(encode('utf8', $str));
    $self->tie_long($res)
}


sub internal_to_utf8 {
    my $self = S(@_);
    my $u = shift;
    $u = $self->tie_long($u) unless eval { defined $$u };
    my $r = Text::Bidi::private::internal_to_utf8($$u);
    decode('utf8', $r)
}


sub get_bidi_types {
    my $self = S(@_);
    my $u = shift;
    my $t = Text::Bidi::private::get_bidi_types($$u);
    $self->tie_long($t)
}


sub get_bidi_type_name {
    my $self = S(@_);
    Text::Bidi::private::get_bidi_type_name(@_)
}


sub get_joining_types {
    my $self = S(@_);
    my $u = shift;
    $self->tie_byte(Text::Bidi::private::get_joining_types($$u))
}


sub get_joining_type_name {
    my $self = S(@_);
    Text::Bidi::private::get_joining_type_name(@_)
}


sub get_par_embedding_levels {
    my $self = S(@_);
    my $bt = shift;
    my $p = shift // $Text::Bidi::private::FRIBIDI_PAR_ON;
    my ($lev, $par, $out) = 
        Text::Bidi::private::get_par_embedding_levels($$bt, $p);
    my $res = $self->tie_byte($out);
    ($par, $res)
}


sub join_arabic {
    my $self = S(@_);
    my ($t, $l, $j) = @_;
    $self->tie_byte(Text::Bidi::private::join_arabic($$t, $$l, $$j));
}


sub shaped {
    my $self = S(@_);
    my ($flags, $el, $prop, $u) = @_;
    return ($prop, $u) unless defined $flags;
    $flags ||= $Text::Bidi::private::FRIBIDI_FLAGS_ARABIC;
    my ($p, $v) =Text::Bidi::private::shape_arabic($flags, $$el, $$prop, 
        $$u);
    ($self->tie_byte($p), $self->tie_long($v))
}



sub mirrored {
    my $self = S(@_);
    my ($el, $u) = @_;
    my $r =Text::Bidi::private::shape_mirroring($$el, $$u);
    my $res = $self->tie_long($r)
}


sub hash2flags {
    my ($self, $flags) = @_;
    my $res = 0;
    foreach ( keys %$flags ) {
        next unless $flags->{$_};
        next unless $_ eq uc;
        $res |= ${"Text::Bidi::private::FRIBIDI_FLAG_$_"};
    }
    $res
}


sub reorder {
    my $self = S(@_);
    my ($str, $map, $off, $len) = @_;
    $off //= 0;
    $len //= @$str - $off;
    join('', (@$str)[@$map[$off..$off+$len-1]])
}


sub reorder_map {
    my $self = S(@_);
    my ($bt, $off, $len, $par, $map, $el, $flags) = @_;
    unless ( defined $el ) {
        (my $p, $el) = $self->get_par_embedding_levels($bt, $par);
        $par //= $p;
    }
    if ( defined $flags ) {
        $flags = $self->hash2flags($flags) if ref $flags;
    } else {
        $flags = $Text::Bidi::private::FRIBIDI_FLAGS_DEFAULT;
    }
    $map //= [0..$#$bt];

    $map = $self->tie_long($map) unless eval {defined $$map};


    my ($lev, $elout, $mout) = Text::Bidi::private::reorder_map(
        $flags, $$bt, $off, $len, $par, $$el, $$map);

    ($elout, $mout)
}

# TODO this doesn't work


sub remove_bidi_marks {
    my $self = S(@_);
    my ($v, $to, $from, $levels) = @_;
    $to = $self->tie_long($to) unless eval {defined $$to};
    if ( defined($from) ) {
        $from = $self->tie_long($from) unless eval {defined $$from};
    } else {
        $from = \undef;
    }
    $levels = $self->tie_byte($levels) unless eval {defined $$levels};
    no warnings 'uninitialized';
    my ($len, $vout, $toout, $fromout, $levelsout) = 
      Text::Bidi::private::remove_bidi_marks($v, $$to, $$from, $$levels);
    ($vout, $toout, $fromout, $levelsout)
}


sub log2vis {
    require Text::Bidi::Paragraph;
    my ($log, $width, $dir, $flags) = @_;
    my $p = new Text::Bidi::Paragraph $log, dir => $dir;
    $width //= $p->len;
    my $off = 0;
    my @visual;
    while ( $off < $p->len ) {
        my $v = $p->visual($off, $width, $flags);
        my $l = length($v);
        $off += $l;
        $v = (' ' x ($width - $l)) . $v if $p->is_rtl;
        push @visual, $v;
    }
    ($p, join("\n", @visual))
}


sub is_bidi { $_[0] =~ /\p{bc=R}|\p{bc=AL}/ }


sub get_mirror_char {
    my $self = S(@_);
    my $u = shift;
    $u = $self->utf8_to_internal($u) unless ref($u);
    my $r = Text::Bidi::private::get_mirror_char($u->[0]);
    my $res = $self->tie_long([$r]);
    wantarray ? ($res) : $self->internal_to_utf8($res)
}


sub fribidi_version {
    $Text::Bidi::private::version_info
}


sub fribidi_version_num {
    fribidi_version =~ /\(GNU FriBidi\) ([0-9.]*)/ ? $1 : ()
}


sub unicode_version {
    $Text::Bidi::private::unicode_version
}


1; # End of Text::Bidi

__END__

=pod

=head1 NAME

Text::Bidi - Unicode bidi algorithm using libfribidi

=head1 VERSION

version 2.15

=head1 SYNOPSIS

    # Each displayed line is a "paragraph"
    use Text::Bidi qw(log2vis);
    ($par, $map, $visual) = log2vis($logical);
    # or just
    $visual = log2vis(...);

    # For real paragraphs, need to specify the display width
    ($par, $map, $visual) = log2vis($logical, $width);

    # object oriented approach allows one to display line by line
    $p = new Text::Bidi::Paragraph $logical;
    $visual = $p->visual($off, $len);

=head1 EXPORT

The following functions can be exported (nothing is exported by default):

=over

=item *

L</log2vis>

=item *

L</is_bidi>

=item *

L</get_mirror_char>

=item *

L</get_bidi_type_name>

=item *

L</fribidi_version>

=item *

L</unicode_version>

=item *

L</fribidi_version_num>

=back

All of them can be exported together using the C<:all> tag.

=head1 DESCRIPTION

This module provides basic support for the Unicode bidirectional (Bidi) text 
algorithm, for displaying text consisting of both left-to-right and 
right-to-left written languages (such as Hebrew and Arabic.) It does so via  
a I<swig> interface file to the I<libfribidi> library.

The fundamental purpose of the bidi algorithm is to reorder text given in 
logical order into text in visually correct order, suitable for display using 
standard printing commands. ``Logical order'' means that the characters are 
given in the order in which they would be read if printed correctly. The 
direction of the text is determined by properties of the Unicode characters, 
usually without additional hints.  See 
L<http://www.unicode.org/unicode/reports/tr9/> for more details on the 
problem and the algorithm.

=head2 Standard usage

The bidi algorithm works in two stages. The first is on the level of a 
paragraph, where the direction of each character is computed. The second is 
on the level of the lines to be displayed. The main practical difference is 
that the first stage requires only the text of the paragraph, while the 
second requires knowledge of the width of the displayed lines. The module (or 
the library) does not determine how the text is broken into paragraphs.

The full interface is provided by L<Text::Bidi::Paragraph>, see there for 
details. This module provides an abbreviation, L</log2vis>, which combines 
creating a paragraph object with calling L<Text::Bidi::Paragraph/visual> on 
it.  It is particularly useful in the case that the whole paragraph should be 
displayed at once, and the display width is known:

    $visual = log2vis($logical, $width);

There are more options (see L</log2vis>), but this is essentially it. The 
rest of this documentation will probably be useful only to people who are 
familiar with I<libfribidi> and who wish to extend or modify the module.

=head2 The object-oriented approach

All functions here can be called using either a procedural or an object 
oriented approach. For example, you may do either

        $visual = log2vis($logical);

or

        $bidi = new Text::Bidi;
        $visual = $bidi->log2vis($logical);

The advantages of the second form is that it is easier to move to a 
sub-class, and that two or more objects with different parameters can be used 
simultaneously. If you are interested in deriving from this class, please see 
L</SUBCLASSING>.

=head1 FUNCTIONS

=head2 get_bidi_type_name

    say $tb->get_bidi_type_name($Text::Bidi::Type::LTR); # says 'LTR'

Return the string representation of a Bidi character type, as in 
fribidi_get_bidi_type_name(3). Note that for the above example, one needs to 
use L<Text::Bidi::Constants>.

=head2 log2vis

    ($p, $visual) = log2vis($logical[,$width[,$dir[,$flags]]]);

Convert the input paragraph B<$logical> to visual. This constructs a 
L<Text::Bidi::Paragraph> object, and calls L<Text::Bidi::Paragraph/visual> 
several times, as required. B<$width> is the maximum width of a line, 
defaulting to the whole length of the paragraph.  B<$dir> is the base 
direction of the paragraph, determined automatically if not provided.  
B<$flags> is as in L<Text::Bidi::Paragraph/visual>. The paragraph will be 
justified to the right if it is RTL.

The output consists of the L<Text::Bidi::Paragraph> object B<$p> and the 
visual string B<$visual>.

=head2 is_bidi()

    my $bidi = is_bidi($logical);

Returns true if the input B<$logical> contains bidi characters. Otherwise, 
the output of the bidi algorithm will be identical to the input, hence this 
helps if we want to short-circuit.

=head2 get_mirror_char()

    my $mir = get_mirror_char('['); # $mir == ']'

Return the mirror character of the input, possibly itself.

=head2 fribidi_version

    say fribidi_version();

Returns the version information for the fribidi library

=head2 fribidi_version_num

    say fribidi_version_num();

Returns the version number for the fribidi library

=head2 unicode_version

    say unicode_version();

Returns the Unicode version used by the fribidi library

=head1 SUBCLASSING

The rest of the documentation is only interesting if you would like to derive 
from this class. The methods listed under L</METHODS> are wrappers around the 
similarly named functions in libfribidi, and may be useful for this purpose.

If you do sub-class this class, and would like the procedural interface to 
use your functions, put a line like

        $Text::Bidi::GlobalClass = __PACKAGE__;

in your module.

=head1 METHODS

=head2 new

    $tb = new Text::Bidi [tie_byte => ..., tie_long => ...];

Create a new L<Text::Bidi> object. If the I<tie_byte> or I<tie_long> options 
are given, they should be the names (strings) of the classes used as dual 
life arrays, most probably derived class of L<Text::Bidi::Array::Byte> and 
L<Text::Bidi::Array::Long>, respectively.

This method is probably of little interest for standard (procedural) use.

=head2 utf8_to_internal

    $la = $tb->utf8_to_internal($str);

Convert the Perl string I<$str> into the representation used by libfribidi.  
The result will be a L<Text::Bidi::Array::Long>.

=head2 internal_to_utf8

    $str = $tb->internal_to_utf8($la);

Convert the long array I<$la>, representing a string encoded in to format 
used by libfribidi, into a Perl string. The array I<$la> can be either a 
L<Text::Bidi::Array::Long>, or anything that can be used to construct it.

=head2 get_bidi_types

    $types = $tb->get_bidi_types($internal);

Returns a L<Text::Bidi::Array::Long> with the list of Bidi types of the text 
given by $internal, a representation of the paragraph text, as returned by 
utf8_to_internal(). Wraps fribidi_get_bidi_types(3).

=head2 get_joining_types

    $types = $tb->get_joining_types($internal);

Returns a L<Text::Bidi::Array::Byte> with the list of joining types of the 
text given by B<$internal>, a representation of the paragraph text, as returned 
by L</utf8_to_internal>. Wraps fribidi_get_joining_types(3).

=head2 get_joining_type_name

    say $tb->get_joining_type_name($Text::Bidi::Joining::U); # says 'U'

Return the string representation of a joining character type, as in 
fribidi_get_joining_type_name(3). Note that for the above example, one needs 
to use L<Text::Bidi::Constants>.

=head2 get_par_embedding_levels

   ($odir, $lvl) = $tb->get_par_embedding_levels($types[, $dir]);

Return the embedding levels of the characters, whose types are given by 
I<$types>. I<$types> is a L<Text::Bidi::Array::Long> of Bidi types, as 
returned by L</get_bidi_types>. I<$dir> is the base paragraph direction. If 
not given, it defaults to C<FRIBIDI_PAR_ON> (neutral).

The output is the resolved paragraph direction I<$odir>, and the 
L<Text::Bidi::Array::Byte> array I<$lvl> of embedding levels.

=head2 join_arabic

    $props = $tb->join_arabic($bidi_types, $lvl, $join_types);

Returns a L<Text::Bidi::Array::Byte> with B<$props>, as returned by 
fribidi_join_arabic(3). The inputs are B<$bidi_types>, as returned by 
L</get_bidi_types>, B<$lvl>, as returned by 
L</get_par_embedding_levels>, and B<$join_types> as returned by
L</get_joining_types>.  Wraps fribidi_join_arabic(3).

=head2 shaped

    ($newp, $shaped) = $tb->shaped($flags, $lvl, $prop, $internal);

Returns the internal representation of the paragraph, with shaping applied.  
The internal representation of the original paragraph (as returned by 
L</utf8_to_internal>) should be passed in B<$internal>, while the embedding 
levels (as returned by L</get_par_embedding_levels>) should be in B<$lvl>. 
See the documentation of F<fribidi-arabic.h> for B<$flags>, but as a special
case, a value of C<undef> here skips shaping (returning B<($prop, $internal)>),
while any other false value becomes the default. B<$prop> is as 
returned by L</join_arabic>.  This method wraps fribidi_shape_arabic(3).

=head2 mirrored

    $mirrored = $tb->mirrored($lvl, $internal);

Returns the internal representation of the paragraph, with mirroring applied.  
The internal representation of the original paragraph (as returned by 
L</utf8_to_internal>) should be passed in B<$internal>, while the embedding 
levels (as returned by L</get_par_embedding_levels>) should be in B<$lvl>.  
This method wraps fribidi_shape_mirroring(3).

=head2 reorder

    $str = $tb->reorder($in, $map[, $offset[, $len]]);
    say $tb->reorder([qw(A B C)], [2, 0, 1]); # says CAB

View the array ref B<$map> as a permutation, and permute the list (of 
characters) B<$in> according to it. The result is joined, to obtain a string. 
If B<$offset> and B<$len> are given, returns only that part of the resulting 
string.

=head2 reorder_map

    ($elout, $mout) = $tb->reorder_map($types, $offset, $len, $par,
                                       $map, $el, $flags);

Compute the reordering map for bidi types given by B<$types>, for the 
interval starting with B<$offset> of length B<$len>. Note that this part of 
the algorithm depends on the interval in an essential way. B<$types> is an 
array of types, as computed by L</get_bidi_types>. The other arguments are 
optional:

=over

=item B<$par>

The base paragraph direction. Computed via L</get_par_embedding_levels> if 
not defined.

=item B<$map>

An array ref (or a L<Text::Bidi::Array::Long>) from a previous call (with a 
different interval). The method is called repeatedly for the same paragraph, 
with different intervals, and the reordering map is updated for the given 
interval. If not defined, initialised to the identity map.

=item B<$el>

The embedding levels. If not given, computed by a call to 
L</get_par_embedding_levels>.

=item B<$flags>

A specification of flags, as described in fribidi_reorder_line(3). The flags 
can be given either as a number (using C<$Text::Bidi::Flags::..> from 
L<Text::Bidi::Constants>), or as a hashref of the form
C<{REORDER_NSM =E<gt> 1}>. Defaults to C<FRIBIDI_FLAGS_DEFAULT>.

=back

The output consists of the modified map B<$mout> (a 
L<Text::Bidi::Array::Long>), and possibly modified embedding levels 
B<$elout>.

=for Pod::Coverage S

=for Pod::Coverage tie_byte tie_long

=for Pod::Coverage hash2flags

=begin comment




=end comment

method remove_bidi_marks

    ($v, $to, $from, $levels) = 
        $tb->remove_bidi_marks($v[, $to[, $from[, $levels]]])

Remove the explicit bidi marks from C<$v>. The optional arguments, if given, 
are the map from the logical to the visual string, the inverse map, and 
embedding levels, respectively, as returned by L</reorder_map>. The inverse 
map C<$from> can be obtained from the direct one C<$to> by a command like:

    @$from[@$map] = 0..$#$map

Each of the arguments can be C<undef>, in which case it will be skipped. This 
implements step X9, see fribidi_remove_bidi_marks(3).

=head1 BUGS

There are no real tests for any of this.

Shaping is not supported (probably), since I don't know what it is. Help 
welcome!

=head1 SEE ALSO

L<Text::Bidi::Paragraph>

L<Text::Bidi::Constants>

L<Encode>

L<The fribidi library|http://fribidi.org/>

L<Swig|http://www.swig.org>

L<The unicode bidi algorithm|http://www.unicode.org/unicode/reports/tr9/>

=head1 AUTHOR

Moshe Kamensky <kamensky@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Moshe Kamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
