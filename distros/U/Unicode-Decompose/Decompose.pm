package Unicode::Decompose;

use lib "../../../lib";
use 5.006;
use strict;
use warnings;
use utf8;
use UnicodeCD qw(charinfo compexcl);

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( 'all' => [ qw(
	normalize normalize_d order decompose recompose
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();
our $VERSION = '0.02';

our %compat;
our %canon;

# First, load up the decomposition table
my @decomp = split /\n/, require "unicode/Decomposition.pl" or die $@;
my %decomp;
while ($_=pop @decomp) {
    chomp;
    my ($char,@line) = split;
    $decomp{$char} = [
        map { exists $decomp{$_} ? @{$decomp{$_}} : $_ } @line
    ];
}

# Then remove the recursion from it
my $changed;
do {
    $changed = 0;
    while (my($k,$v) = each %decomp) {
        $decomp{$k} = [ map { exists $decomp{$_} ? do { $changed++; @{$decomp{$_}} } : $_ } @$v ];
    }
} while $changed;

# Now split it into canon and compat
while (my($k,$v) = each %decomp) {
    $compat{pack("U*", hex $k)} = pack "U*", map { hex $_} grep !/</, @$v;
    next if "@$v" =~ /</;
    $canon{pack("U*", hex $k)} = pack "U*", map { hex $_} @$v;
}

my @ok_keys;
# Recomposition
for (keys %canon) {
    my $x = $_;
    next if (compexcl ord $x); # compexcl eats $_, bluh.
    push @ok_keys, $x;
}

my %recomp = map { $canon{$_} => $_ } @ok_keys;
my $recomppat = join "|", reverse sort keys %recomp;

bootstrap Unicode::Decompose $VERSION;

sub normalize {
    my $a = shift;
    _decompose($a, "canon");
    return recompose(order($a));
}
sub normalize_d {
    my $a = shift;
    _decompose($a, "canon");
    return order($a);
}

sub decompose {
    my $a = shift;
    decompose($a, "canon");
    return $a;
}

sub order {
    my $str = shift;
    my @chars = ($str =~ /(\X)*/);
    my $result;
    for (@chars) {
        # my ($head, @others) = /^(\PM)(\pM)*$/; Doesn't work, damn!
        s/^(\PM)// or die ;
        my $head = $1;
        my @others;
        push @others, $1 while s/^(\pM)//;
        $result .= $head;
        next unless @others;
        $result .= join '', sort { charinfo(ord $a)->{combining} <=> charinfo(ord($b))->{combining} } @others;
    }
    return $result;
}

sub recompose {
    my $a = shift;
    $a =~ s/($recomppat)/$recomp{$1}/g;
    return $a;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Unicode::Decompose - Unicode decomposition and normalization

=head1 SYNOPSIS

  use Unicode::Decompose qw(normalize order decompose recompose normalize_d);

  $norm   = normalize($string);
  
  # OR:

  $decomp  = decompose($string); 
  $ordered = order($decomp);
  $norm    = recompose($ordered);

=head1 DESCRIPTION

This module implements Unicode normalization forms D and C. 

These are important for comparing Unicode strings: consider the two 
strings C<"\N{LATIN SMALL LETTER E WITH ACUTE}">, and 
C<"\N{LATIN SMALL LETTER E}\N{COMBINING ACUTE ACCENT}">. From one point
of view, (simply looking at the characters and the bytes in the string)
they're differnet; from another, (looking at the B<meaning> of the
characters) they're the same.

Normalization is the process described in Unicode Technical Report #15
by which these two strings are made equal. There are two modes of doing
this that we particularly care about: Unicode Normalization Form D is
the "weaker" form, and C the stronger form.

Both have two stages in common: In the first stage, the data is "pulled
apart", or decomposed. That is, precomposed characters such as "LATIN
SMALL LETTER E WITH ACUTE", are split into a main character and the
combining characters that follow it. In the next stage, the combining
characters are ordered according to a list of priorities defined in the
Unicode Character Database. This will make our two example strings both
"LATIN SMALL LETTER E, COMBINING ACUTE ACCENT", and will hence compare
equal.

Unicode Normalization Form C then takes the resulting string and "pushes
together" the data, recomposing it; that is, characters may be returned
to precomposed forms - because the combining characters have been
rearranged, this might not be the same as the original precomposed
characters.

Support for compatiblity decomposition, which is considerably more
relaxed about how characters decompose, is implemented at a very rough
level but not made available to the end-user at this time. If you want
it, you should be able to figure it out from the code.

=head2 BUGS

Creating the initial data structures is B<slow>. Maybe move to Storable;
the "cooked" data could be installed with the module.

=head2 EXPORT

See list in synopsis.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<perl>.

=cut
