# Created: Tue 27 Aug 2013 04:10:03 PM IDT
# Last Changed: Sat 07 Nov 2015 10:27:08 PM IST

use 5.10.0;
use warnings;
#no warnings 'experimental';
use integer;
use strict;

package Text::Bidi::Paragraph;
# ABSTRACT: Run the bidi algorithm on one paragraph
$Text::Bidi::Paragraph::VERSION = '2.12';

use Text::Bidi;


sub new {
    my $class = shift;
    my $par = shift;
    my $self = { @_ };
    my @bd = ($self->{'bd'});
    $self->{'bd'} = Text::Bidi::S(@bd);
    $self->{'par'} = $par;
    $self->{'shape'} = 0 
      if $par =~ /[\p{bc=AL}\p{bc=AN}]/ and not exists $self->{'shape'};
    bless $self => $class;
    $self->_init
}


for my $f ( qw(par bd dir _par _mirpar _unicode _mirrored )) {
    no strict 'refs';
    *$f = sub { $_[0]->{$f} };
}

for my $f ( qw(len types levels map) ) {
    no strict 'refs';
    *$f = sub { $_[0]->{"_$f"} };
}


sub type_names {
    my $self = shift;
    my $bd = $self->bd;
    map { $bd->get_bidi_type_name($_) } @{$self->types}
}


sub is_rtl { $_[0]->dir == $Text::Bidi::private::FRIBIDI_PAR_RTL }

sub _init {
    my ($self) = (@_);
    my $par = $self->par;
    $self->{'_len'} = length($par);
    my $bd = $self->bd;
    $self->{'_unicode'} = $bd->utf8_to_internal($par);
    #$self->{'_par'} = [split '', $par];
    $self->{'_types'} = $bd->get_bidi_types($self->_unicode);
    ($self->{'dir'}, $self->{'_levels'}) =
        $bd->get_par_embedding_levels($self->types, $self->dir);
    $self->{'_map'} = [0..$#{$self->_unicode}];
    $self->{'_unicode'} = $self->shaped($self->{'shape'}) 
        if defined $self->{'shape'};
    $self->{'_mirrored'} = $bd->mirrored($self->levels, $self->_unicode);
    $self->{'_mirpar'} = $bd->internal_to_utf8($self->_mirrored);
    $self->{'_par'} = [split '', $self->_mirpar ];
    $self
}


sub ar_props {
    my ($self) = (@_);
    $self->{'_ar_props'} //= $self->bd->join_arabic($self->types, $self->levels, $self->bd->get_joining_types($self->_unicode))
}


sub shaped {
    my ($self, $flags) = (@_);
    ($self->{'_ar_props'}, $self->{'_shaped'}) = $self->bd->shaped(
        $flags, $self->levels, $self->ar_props, $self->_unicode)
        unless defined $self->{'_shaped'};
    $self->{'_shaped'}
}


sub visual {
    my ($self, $off, $len, $flags) = @_;
    $off //= 0;
    $len //= $self->len;
    my $mlen = $self->len - $off;
    $mlen = $len if $len < $mlen;
    if (defined($flags) and my $break = eval { $flags->{'break'} } ) {
        my $lb = length($break);
        my $nlen = rindex($self->par, $break, $off + $mlen - $lb) - $off + $lb;
        $mlen = $nlen if $nlen > 0;
    }
    my $bd = $self->bd;
    (my $levels, $self->{'_map'}) = 
      $bd->reorder_map($self->types, $off, $mlen, $self->dir, 
                       $self->map, $self->levels, $flags);
    my $visual = $bd->reorder($self->_par, $self->map, $off, $mlen);
    # TODO This does not currently work
    if (defined($flags) and eval { $flags->{'remove_marks'} } ) {
        ($visual, $self->{'_map'}, undef, $levels) = 
          $bd->remove_bidi_marks($visual, $self->map, undef, $levels);
    }
    $self->{'_levels'} = $bd->tie_byte($levels);
    
    $visual
}

1;

__END__

=pod

=head1 NAME

Text::Bidi::Paragraph - Run the bidi algorithm on one paragraph

=head1 VERSION

version 2.12

=head1 SYNOPSIS

    use Text::Bidi::Paragraph;

    my $par = new Text::Bidi::Paragraph $logical;
    my $offset = 0;
    my $width = 80;
    while ( $offset < $p->len ) {
        my $v = $p->visual($offset, $width);
        say $v;
        $offset += $width;
    }

=head1 DESCRIPTION

This class provides the main interface for applying the bidi algorithm in 
full generality. In the case where the paragraph can be formatted at once, 
L<Text::Bidi/log2vis> can be used as a shortcut.

A paragraph is processed by creating a L<Text::Bidi::Paragraph> object:

    $par = new Text::Bidi::Paragraph $logical;

Here C<$logical> is the text of the paragraph. This applies the first stages 
of the bidi algorithm: computation of the embedding levels. Once this is 
done, the text can be displayed using the L</visual> method, which does the 
reordering.

=head1 METHODS

=head2 new

    my $par = new Text::Bidi::Paragraph $logical, ...;

Create a new object corresponding to a text B<$logical> in logical order. The 
other arguments are key-value pairs. The only ones that have a meaning at the 
moment are I<bd>, which supplies the L<Text::Bidi> object to use, 
I<dir>, which prescribes the direction of the paragraph, and I<shape>,
which determines shaping flags. The value of I<dir> 
is a constant in C<Text::Bidi::Par::> (e.g., C<$Text::Bidi::Par::RTL>; see 
L<Text::Bidi::Constants>). The value of I<shape> is a constant from
fribidi_shape_arabic(3). If it is C<undef>, no shaping is done. If it is 
missing, default shaping will be performed if the paragraph contains Arabic 
text.

Note that the mere creation of B<$par> runs the bidi algorithm on the given 
text B<$logical> up to the point of reordering (which is dealt with in 
L</visual>).

=head2 par

    my $logical = $par->par;

Returns the logical (input) text corresponding to this paragraph.

=head2 dir

    my $dir = $par->dir;

Returns the direction of this paragraph, a constant in the 
C<$Text::Bidi::Par::> namespace.

=head2 len

    my $len = $par->len;

The length of this paragraph.

=head2 types

    my $types = $par->types;

The Bidi types of the characters in this paragraph. Each element of 
C<@$types> is a constant in the C<$Text::Bidi::Type::> namespace.

=head2 levels

    my $levels = $par->levels;

The embedding levels for this paragraph. Each element of C<@$levels> is an 
integer.

=head2 bd

    my $bd = $par->bd;

The L<Text::Bidi> object used to interface with libfribidi.

=head2 map

    my $map = $par->map;

The map from the logical text to the visual, i.e., the values in C<$map> are 
indices in the logical string, so that the C<$i>-th character of the visual 
string is the character that occurs at C<$map-E<gt>[$i]> in the logical 
string.

This is updated on each call to L</visual>, so that the map for the full 
paragraph is correct only after calling L</visual> for the whole text.

=head2 type_names

    @types = $par->type_names;

Returns the list of bidi types as strings

=head2 is_rtl

    my $rtl = $par->is_rtl;

Returns true if the direction of the paragraph is C<RTL> (right to left).

=head2 ar_props

    $props = $self->ar_props

Return the shaping properties (TODO)

=head2 shaped

    $shaped = $self->shaped(flags)

Return the shaped paragraph, and fix ar_props (TODO)

=head2 visual

    my $visual = $par->visual($offset, $length, $flags);

Return the visual representation of the part of the paragraph B<$par> 
starting at B<$offset> and of length B<$length>. B<$par> is a 
L<Text::Bidi::Paragraph> object. All arguments are optional, with B<$offset> 
defaulting to C<0> and B<$length> to the length till the end of the paragraph 
(see below from B<$flags>).

Note that this method does not take care of right-justifying the text if the 
paragraph direction is C<RTL>. Hence a typical application might look as 
follows:

    my $visual = $par->visual($offset, $width, $flags);
    my $len = length($visual);
    $visual = (' ' x ($width - $len)) . $visual if $par->is_rtl;

Note also that the length of the result might be strictly less than 
B<$length>.

The B<$flags> argument, if defined, should be either a hashref or an integer.  
If it is a number, its meaning is the same as in C<fribidi_reorder_line(3)>.  
A hashref is converted to the corresponding values for keys whose value is 
true. The keys should be the same as the constants in F<fribidi-types.h>, 
with the prefix C<FRIBIDI_FLAGS_> removed.

In addition, the B<$flags> hashref may contain lower-case keys. The only one 
recognised at the moment is I<break>. Its value, if given, should be a string 
at which the line should be broken. Hence, if this key is given, the actual 
length is potentially reduced, so that the line breaks at the given string 
(if possible). A typical value for I<break> is C<' '>.

=head1 SEE ALSO

L<Text::Bidi>

=head1 AUTHOR

Moshe Kamensky <kamensky@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Moshe Kamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
