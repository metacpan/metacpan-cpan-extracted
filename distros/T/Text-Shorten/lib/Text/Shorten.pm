package Text::Shorten;

use warnings;
use strict;
use Hash::SafeKeys;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(shorten_scalar shorten_array shorten_hash);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);
our $VERSION = '0.06';

our $DOTDOTDOT = '...';
our $DOTDOTDOT_LENGTH = length($DOTDOTDOT);
our $DEFAULT_ARRAY_ELEM_SEPARATOR_LENGTH = 1;
our $DEFAULT_HASH_ELEM_SEPARATOR_LENGTH = 1;
our $DEFAULT_HASH_KEYVALUE_SEPARATOR_LENGTH = 2;
our $HASHREPR_SORTKEYS;

sub shorten_scalar {
    my ($scalar, $maxlen) = @_;

    return $scalar if length($scalar) < $maxlen;

    if ($scalar =~ /^['"]./                         # "']/
	&& substr($scalar,0,1) eq substr($scalar,-1)) {

	return substr($scalar,0,$maxlen-$DOTDOTDOT_LENGTH-1)
	    . $DOTDOTDOT . substr($scalar,-1);

    }

    my ($sign,$d1,$d,$d2,$e,$exp) =
	$scalar =~ /^\s* ([+-]?)
                     (\d*)
		     (\.?)
		     (\d*)
		     ([Ee]?)
		     ([+-]?\d+)? \s*$/x;

    {
	no warnings 'uninitialized';
	if ("$d1$d2" eq "") {
	    # not a number.

	    return substr($scalar, 0, $maxlen-$DOTDOTDOT_LENGTH) . $DOTDOTDOT;
	}
    }

    # the rest of this function is strategies for making a number shorter.
    # We may lose precision but we won't need to use $DOTDOTDOT

    $sign ||= '';
    $d1 ||= '0';
    $d2 = '' if not defined $d2;
    $e ||= '';
    $exp = '' if not defined $exp;
    my $E = $e || 'e';

    $exp  =~ s/^\+//             if length("$sign$d1$d$d2$e$exp") > $maxlen;
    $d1   =~ s/^0+(.)/$1/        if length("$sign$d1$d$d2$e$exp") > $maxlen;
    $d2   =~ s/(.)0+$/$1/        if length("$sign$d1$d2$e$exp") > $maxlen;
    $exp  =~ s/^(\-?)0+(.)/$1$2/ if length("$sign$d1$d$d2$exp") > $maxlen;
    $sign =~ s/^\+//             if length("$sign$d1$d$d2$e$exp") > $maxlen;

    my $lastc = 0;
    while (length("$sign$d1$d$d2$e$exp") > $maxlen) {

	if ($d && $d2 eq '') {       # 1.E23 => 1E23
	    $d = '';
	    $d1 ||= '0';
	    next;
	}

	if ($e && ($exp eq '' || $exp==0)) {         # 4.567E0 => 4.567
	    $e = $exp = '';
	    next;
	}

	if (($d1 eq '' || $d1 == 0) && $d2 ne '') {
	    $d1=0;
	    while ($d1 == 0 && $d2 ne '') {        # 0.123 => 1.23,  
		                                   # 0.0004E-5 => 0.004E-6
		$d1 = substr($d2,0,1);
		$d2 = substr($d2,1);
		$e ||= $E;
		$exp--;
	    }
	    next;
	}

	if ($e eq '' && $d2 ne '') {
	    # start truncating digits
	    my $c = chop $d2;
	    if ($c > 5 || ($c == 5 && $lastc)) {
		my $new_d2 = $d2;
		$lastc = 0;
		if (length($new_d2) > length($d2)) {
		    $d1++;
		    $d2 = substr($new_d2,1);
		}
	    } else {
		$lastc = 1;
	    }
	    next;
	}

	if ($d eq '' && $d2 eq '') {
	    # start truncating digits and increment exp
	    my $c = chop $d1;
	    if ($c > 5 || ($c==5 && $lastc)) {
		$lastc = 0;
		$d1++;
	    } else {
		$lastc = 1;
	    }
	    $e ||= $E;
	    $exp++;
	    next;
	}

	if ($d2 ne '') {
	    # start truncating digits
	    my $c = chop $d2;
	    if ($c > 5 || ($c == 5 && $lastc)) {
		my $new_d2 = $d2;
		$lastc = 0;
		if (length($new_d2) > length($d2)) {
		    $d1++;
		    $d2 = substr($new_d2,1);
		}
	    } else {
		$lastc = 1;
	    }
	    next;
	}
    }

    $d = '' if $d2 eq '';
    while ($e && $d && $d1 ne '' && $d1 > 9) {        # 98.7E6 => 9.87E7
	$d2 = chop($d1) . $d2;
	$d = '.';
	$exp++;
    }
    $d = '' if $d2 eq '';
    return "$sign$d1$d$d2$e$exp";
}

# XXX - do we want to make it configurable whether shorten_array
#       always returns at least one full element?

sub shorten_array {
    my ($array, $maxlen, $seplen, @key) = @_;
    if (!defined($seplen)) {
	$seplen = $DEFAULT_ARRAY_ELEM_SEPARATOR_LENGTH;
    } elsif ($seplen =~ /\D/) {
	$seplen = length($seplen);
    }
    my $dotslen = $seplen + $DOTDOTDOT_LENGTH;

    my $n = $#{$array} + 1;
    @key = (0) if @key == 0;
    @key = sort {$a <=> $b} grep { $_ >= 0 && $_ < $n } @key;
    my @inc = (0) x $n;

    my $len = $n > 0 ? $dotslen - 1 : 0;
    if (@key > 1 || (@key == 1 && $key[0] != 0)) {

	my @prio = (0) x $n;
	# "prioritize" elements for display, giving preference to
	#     key items
	#     items between key items
	#     the first item
	#     <xxx>the last item</xxx>
	if ($n > 0) {
	    $prio[$_]  = 8 for @key;
	    $prio[$_] += 4 for $key[0]..$key[-1];
	}
	$prio[0] += 2;

	my $insert_fails = 0;
	for my $i ( sort { $prio[$b] <=> $prio[$a] || $a <=> $b } 0..$n-1) {
	    last if $prio[$i] < 8 && $len > $maxlen;

	    # what are the consequences of including $array->[$i] in the output?
	    #
	    # if none of $array->[$i]'s neighbors are excluded:
	    #      then we lose $dotslen and add length of $array->[$i]
	    #      [   a , ... , c ] ==> [ a , b , c ]
	    #
	    # if one of $array->[$i]'s neighbors are excluded:
	    #      then we add $array->[$i]
	    #      [   a , ... ] => [ a , b , ... ]
	    #      [   ... , c ] => [ ... , b , c ]
	    #      [  edge ... ] => [ edge a , ... ]
	    #
	    # if two of $array->[$i]'s neighbors are excluded
	    #      then we gain $dotslen + $array->[$i]
	    #      [ ... ] => [ ... , a , ... ]

	    my $excl = ($i>0 && !$inc[$i-1]) + ($i<$n-1 && !$inc[$i+1]) + 0;
	    my $dlen = defined($array->[$i])&&length($array->[$i])
		+ $seplen + $dotslen * ($excl - 1);
	    if ($prio[$i] >= 8 || $len + $dlen <= $maxlen) {
		$inc[$i] = 1;
		$len += $dlen;
		$insert_fails = 0;
	    } else {

		# for very large arrays, don't keep trying to squeeze
		# that last element in when there is a low probability
		# that it will work ...

		last if ++$insert_fails > 100;
	    }
	}

    } else {

	# don't need to sort, don't need to check $prio[$i]
	my $insert_fails = 0;
	for my $i (0 .. $n-1) {
	    last if $len > $maxlen;
	    my $excl = ($i>0 && !$inc[$i-1]) + ($i<$n-1 && !$inc[$i+1]) + 0;
	    my $dlen = defined($array->[$i])&&length($array->[$i])
		+ $seplen + $dotslen * ($excl - 1);
	    if ($len + $dlen <= $maxlen) {
		$inc[$i] = 1;
		$len += $dlen;
	    } else {
		last if ++$insert_fails > 100;
	    }
	}
    }

    # construct array, including elements in @inc
    my @result = ();
    my @explicit = grep $inc[$_], 0..$#inc;
    my $i = 0;
    while (@explicit) {
	if ($i < $explicit[0]) {
	    push @result, $DOTDOTDOT;
	}
	$i = shift @explicit;
	push @result, $array->[$i];
	$i++;
    }
    if ($i < $n) {
	push @result, $DOTDOTDOT;
    }
    return @result;
}

sub shorten_hash {
    my ($hash, $maxlen, $sep1, $sep2, @key) = @_;

    if (!defined($sep1)) {
	$sep1 = $DEFAULT_HASH_ELEM_SEPARATOR_LENGTH;
    } elsif ($sep1 =~ /\D/) {
	$sep1 = length($sep1);
    }
    if (!defined($sep2)) {
	$sep2 = $DEFAULT_HASH_KEYVALUE_SEPARATOR_LENGTH;
    } elsif ($sep2 =~ /\D/) {
	$sep2 = length($sep2);
    }

    my $total_len = -$sep1;
    my @safekeys = safekeys %$hash;
    for my $k (@safekeys) {
	$total_len += length($k) + length($hash->{$k}) + $sep1 + $sep2;
	last if $total_len > $maxlen;
    }
    if ($total_len <= $maxlen) {
	# ok to include all elements
	return map { [ $_ , $hash->{$_} ] } @safekeys;
    }

    my @r = ();
    my @hashkeys = ();
    my $hashkey = {};

    if (@key > 0) {
	my %key = map { $_ => 1 } @key;
	if (100 > @safekeys) {
	    @hashkeys = sort {
		($key{$b}||0) <=> ($key{$a}||0) 
		    || $a cmp $b
	    } @safekeys;
	} else {
	    @hashkeys = @key = grep { defined $key{$_} } @key;
	    push @hashkeys, grep { !defined $key{$_} } @safekeys;
	}
    } else {
	if (100 > @safekeys) {
	    @hashkeys = sort @safekeys;
	} else {
	    $hashkey = $hash;
	}
    }

    my $len = 3;
    my @sk = safekeys %$hashkey;
    if ($HASHREPR_SORTKEYS) {
	@sk = sort @sk;
    }

    foreach my $key (@hashkeys, @sk) {
	my $dlen = $sep1 + $sep2 + length($key) + length($hash->{$key});
	last if $len + $dlen > $maxlen
	    && @r > 0;      # always include at least one key-value pair
	push @r, [ $key, $hash->{$key} ];
	$len += $dlen;
    }
    return @r, [ $DOTDOTDOT ];
}

1;

__END__

=head1 NAME

Text::Shorten - Abbreviate long output

=head1 VERSION

0.06

=head1 SYNOPSIS

    use Text::Shorten ':all';
    $short_string = shorten_scalar($really_long_string, 40);
    @short_array = shorten_array(\@really_long_array, 80);
    @short_hash = shorten_hash(\%really_large_hash, 80);

=head1 DESCRIPTION

C<Text::Shorten> creates small strings and small arrays from
larger values for display purposes. The output will include
the string C<"..."> to indicate that the value being displayed
is abbreviated.

=head1 FUNCTIONS


=head2 shorten_scalar($SCALAR, $MAXLEN)

Returns a representation of C<$SCALAR> that is no longer than
C<$MAXLEN> characters. It usually works by chopping characters
off the end of the string and replacing them with the
abbreviation indicator C<"...">.

    $m = join('foo','A'..'Z');
    print shorten_scalar($m, 20); # => "AfooBfooCfooDfooE..."
    print shorten_scalar($m, 10); # => "AfooBfo..."

If C<$SCALAR> looks like a number,
then this method will use scientific notation and reduce the
precision of the number to fit it into the alloted space.

    $m = "123456789" x 9;
    print shorten_scalar($m, 20); # => "12345678912345679e64"
    print shorten_scalar($m, 10); # => "1234568e74"

The output of this function is not guaranteed to make sense
when C<$MAXLEN> is small, say, less than 10.


=head2 shorten_array($ARRAYREF, $MAXLEN [,$SEPARATOR=1 [,@KEY=()]])

Returns a list that is representative of the list in C<$ARRAYREF>
and which will be no longer than C<$MAXLEN> characters when it
is displayed.

  $m = [ 'aa' .. 'zz' ];
  print join',', shorten_array($m,20);    # "aa,ab,ac,ad,ae,..."

The default assumption is that displayed array elements
will be separated with a comma or other single-character delimiter.
Specify C<$SEPARATOR> as either a delimiting-string or as a number
representing the length of the delimiter to override this.

  $m = [ 'aa' .. 'zz' ];
  $s = ", ";
  print join $s, shorten_array($m,20,2);  # "aa, ab, ac, ad, ..."
  print join $s, shorten_array($m,20,$s); # "aa, ab, ac, ad, ..."

C<@KEY> is a (possibly empty) set of array indices for array
elements that must be returned in the output. All of the array
indices in C<@KEY> will be included in the output, even if that
makes the output length exceed C<$MAXLEN>,

  $m = [ 'aa' .. 'zz' ];
  $s = ',';
  print join $s, shorten_array($m,20,1,77);     # "aa,ab,ac,...,cz,..."
  print join $s, shorten_array($m,20,1,76..78); # "aa,...,cy,cz,da,..."

The output of this function is not guaranteed to make sense
when C<$MAXLEN> is small (say, less than 15).


=head2 shorten_hash($HASHREF, $MAXLEN [, $SEP1=1, $SEP2=2 [, @KEY=() ]])

Returns a list suitable for displaying representative elements
of the hashtable in C<$HASHREF> such that the displayed length
will be no longer than C<$MAXLEN> characters.

The return value is a list of list references. Each element of
the return value contains a key-value pair to be displayed,
except for the last element of the list, which may either contain
a key-value pair, or a list reference containing the single
token C<...>. This token indicates that some key-value pairs are
not to be displayed. Here is an example of how one print the output
of C<shorten_hash>, using C<":"> as a key-value pair separator,
and C<"; "> to separate different elements of the hash.

  $m = { foo => 'bar', 123 => 456 };
  @m = shorten_hash($m,20);

  # to display shortened results, do something like this
  print "{", join("; ", map { join ":", @$_ } @m), "}";
  # the above line prints "{abc:def; 123:456}"

It is assumed that each key-value pair in the output will be separated
by a single-character delimiter, and that the hash keys will be separated
from their associated hash values by a two-character delimiter.
Specify a delimiter or delimiter length to C<$SEP1> and C<$SEP2>
to override these assumptions.

C<@KEY> is a (possibly empty) set of hash keys that must be returned
in the output. The key-value pair for any valid key that is specified
in C<@KEY> will be included in the output, even if that would make
the output length exceed C<$MAXLEN>.

The output of this function is not guaranteed to make sense
when C<$MAXLEN> is small (say, less than 20).

=head1 EXPORT

Nothing by default. The three functions C<shorten_scalar>,
C<shorten_array>, and C<shorten_hash> may be exported individually,
or they may be exported as a group with the tag C<:all>.

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-text-shorten at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Shorten>.  I will be 
notified, and then you'll automatically be notified of progress on your bug
 as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Shorten


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Shorten>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Shorten>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Shorten>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Shorten/>

=back


=head1 ACKNOWLEDGEMENTS

L<Dumpvalue> / C<dumpvars.pl>.


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
