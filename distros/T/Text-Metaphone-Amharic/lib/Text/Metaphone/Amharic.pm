package Text::Metaphone::Amharic;

# If either of these next two lines are inside
# the BEGIN block the package will break.
#
use utf8;
use Regexp::Ethiopic::Amharic qw(:forms overload setForm);

BEGIN
{
	use strict;
	use vars qw( $VERSION %IMExpected %IMError %plosives $GRANULARITY $STYLE );

	$VERSION = "0.11";

	%plosives = (
		ቅ => 'k',
		ጥ => 't',
		ጭ => 'ʧ',
		ጵ => 'p',
		ጽ => 's'
	);
	%IMExpected =(
		ስ => "s",
		ጽ => "s'",
		ቅ => "k'",
		ቕ => "q",
		ት => "t",
		ጥ => "t'",
		ች => "ʧ",
		ጭ => "ʧ",
		ን => "n",
		ኝ => "n",
		ክ => "k",
		ዝ => "z",
		ዥ => "ʒ",
		ጵ => "p'",
		ፕ => "p"
	);
	%IMError  =(
		ስ => "ጽ",
		ጽ => "ስ",
		ቅ => "ቕ",
		ቕ => "ቅ",
		ት => "ጥ",
		ጥ => "ት",
		ች => "ጭ",
		ጭ => "ች",
		ን => "ኝ",
		ኝ => "ን",
		ክ => "ኽ",
		ዝ => "ዥ",
		ዥ => "ዝ",
		ጵ => "ፕ",
		ፕ => "ጵ"
	);
	$GRANULARITY = "low";
	$STYLE       = "ethio";
}


sub import
{
my ( $pkg, %args ) = @_;

	$STYLE       = lc($args{style})        if ( $args{style}       );
	$GRANULARITY = lc($args{granularity})  if ( $args{granularity} );
}


sub new
{
my $class = shift;
my $self = { _style => $STYLE, _granularity => $GRANULARITY };

	my $blessing = bless ( $self, $class );

	%_ = @_;

	$self->{_style}        = lc($_{style})        if ( $_{style}     );
	$self->{_granularity}  = lc($_{granularity})  if ( $_{granularity} );

	$blessing;
}


sub _formatStyle
{
my ($self, $keys) = @_;

	if ( $self->{_style} eq "ipa" ) {
		foreach my $i ( 0..$#{$keys} ) {
			$keys->[$i] =~ s/([ቅጥጭጵጽ])/$plosives{$1}'/og;
			$keys->[$i] =~ tr/ህልምርስሽቕብትችንኝእክውይድዽጅዝዥግጝፍፕ/hlmrsʃqbtʧnɲakwjdɗʤzʒgɲfp/;
		}
	}
	elsif ( $self->{_style} eq "sera" ) {
		foreach my $i ( 0..$#{$keys} ) {
			$keys->[$i] =~ tr/ህልምርስሽቅቕብትችንኝእክውይድዽጅዝዥግጝጥጭጵጽፍፕ/hlmrsxqQbtcnNakwydDjzZgGTCPSfp/;
		}
	}

}


sub metaphone
{
my $self = shift;

	$_ = $self->simplify($_[0]);
	my ($re, @keys) = $self->glyphs ( $_ );
	($re, @keys)    = $self->phono  ( $re, @keys );
	($re, @keys)    = $self->im     ( $re, @keys );

	if ( @keys ) {
		push ( @keys, qr/$re/ );	
	}

	$self->_formatStyle ( \@keys ) if ( $self->{_style} ne "ethio" );

	(wantarray) ? @keys : $keys[0];
}


sub simplify
{
my $self = shift;

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[=#አ#=]/አ/o;
	s/[=#ሀ#=]/ሀ/og;

	s/(.)[=#አ#=]/$1/g;

	if ( $self->{_granularity} eq "low" ) {
		s/(.)[#ወ#]/$1/og;
		s/(.)[#የ#]/$1/og;
	}
	else {
		s/([#11#])/setForm($1,$ሳድስ)."ዋ"/eg;
	}
	s/[=#ሰ#=]/ሰ/og;
	s/[=#ጸ#=]/ጸ/og;
	s/[#ቨ#]/በ/og;

	#
	# now strip vowels, this simplies later code:
	#
	s/(\p{Ethiopic})/ ($1 eq 'ኘ') ? $1 : setForm($1,$ሳድስ)/eg;


	$_;
}


sub glyphs
{
my $self = shift;


	my @keys = ( $_[0] );
	my $re = $_[0];

	#
	#  Confusion with ዽ
	#
	if ( $keys[0] =~ /ዽ/ ) {
		$keys[2] = $keys[1] = $keys[0];
		$keys[0] =~ s/ዽ/ድ/o;    # caps problem
		                        # $keys[1] literal
		$keys[2] =~ s/ዽ/ጵ/o;    # mistaken glyph
		$re =~ s/ዽ/([ድዽጵ])/og;
	}
	#
	#  Confusion with ኘ
	#
	if ( $keys[0] =~ /ኘ/ ) {
		my (@newKeysA, @newKeysB);
		for (my $i=0; $i < @keys; $i++) {
			$newKeysA[$i] = $newKeysB[$i] = $keys[$i];  # copy old keys
			                             # $keys[$i] literal
			$newKeysA[$i] =~ s/ኘ/ን/o;    # caps problem
			$newKeysB[$i] =~ s/ኘ/ፕ/o;    # mistaken glyph
		}
		push (@keys,@newKeysA);  # add new keys to old keys
		push (@keys,@newKeysB);  # add new keys to old keys
		$re =~ s/ኘ/[ንኝፕ]/og;
	}

	($re, @keys);
}


sub phono
{
my ( $self, $re, @keys ) = @_;



	if ( $keys[0] =~ /ም[ብፍ]/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];   # copy old keys
			$newKeys[$i] =~ s/ምብ/ንብ/o;  # update old keys for primary mapping
			$newKeys[$i] =~ s/ምፍ/ንፍ/o;  # update old keys for primary mapping
		}
		push (@keys,@newKeys);  # add new keys to old keys
		$re =~ s/ምብ/[ምን]ብ/og;
		$re =~ s/ምፍ/[ምን]ፍ/og;
	}

	($re, @keys);
}


sub im
{
my ( $self, $re, @keys ) = @_;

	my $first = 1;
	#
	#  Handle IM problems
	#  try to keep least probable keys last:
	#
	$_ = $keys[0];                                       # bidi folding             # upper-to-lower
	my $keyboard = ( $self->{_granularity} eq "high" ) ? qr/([ስቅቕትችንኝክዝዥጥጭጽጵፕ])/ : qr/([ቕኝዥጥጭጽጵ])/ ; 

	while ( /$keyboard/ ) {
		my $a = $1;
		my @newKeys;
		if ( $self->{_granularity} eq "low" ) {
			s/$a/$IMExpected{$a}/g;
		}
		else {
			s/$a/$IMExpected{$a}/;
		}

		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];           # copy old keys
		}

		if ( $first ) {
			# update new keys for alternative
			$keys[0] =~ s/^$a/ሀ$a/ if ( $self->{_style} ne "ipa" );
			if ( $self->{_granularity} eq "low" ) {
				$newKeys[0] =~ s/$a/ሀ$IMError{$a}/g;
			}
			else {
				$newKeys[0] =~ s/$a/ሀ$IMError{$a}/;
			}
		}

		for (my $i=$first; $i < @newKeys; $i++) {
			# update new keys for alternative
			if ( $self->{_granularity} eq "low" ) {
				$newKeys[$i] =~ s/([^ሀ])$a/$1ሀ$IMError{$a}/g;
			}
			else {
				$newKeys[$i] =~ s/([^ሀ])$a/$1ሀ$IMError{$a}/;
			}
		}

		$first = 0;
		push (@keys,@newKeys);   # add new keys to old keys

		# 
		# this still needs work: 
		# 
		# $re =~ s/$a(?!\w+?\])/[$a$IMError{$a}]/g;
		$re =~ s/(?<!\[\w)$a(?!\w+?\])/[$a$IMError{$a}]/g;
	}

	#
	# convert symbols that were missed in low granularity mode:
	#
	foreach my $i (0..$#keys) {
		$keys[$i] =~ s/ሀ//og;
		$keys[$i] =~ s/ኘ/ኝ/og;
	}

	($re, @keys);
}


sub reverse
{
my $self = shift;

	$_ = $_[0];
	
	if ( $self->{_style} eq "ipa" ) {
		s/([stʧkp])'/$plosives{$1}/g;
		tr/hlmrsʃqbtʧnɲakwjdɗʤzʒgɲfp/ህልምርስሽቕብትችንኝእክውይድዽጅዝዥግጝፍፕ/;
	}
	elsif ( $self->{_style} eq "sera" ) {
		tr/hlmrsxqQbtcnNakwydDjzZgTCPSGfp/ህልምርስሽቅቕብትችንኝእክውይድዽጅዝዥግጝጥጭጵጽፍፕ/;
	}

	$_;
}


sub style
{
my $self = shift;

	$self->{_style} = lc($_[0]) if (@_);

	$self->{_style};
}


sub granularity
{
my $self = shift;

	$self->{_granularity} = lc($_[0]) if (@_);

	$self->{_granularity};
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Text::Metaphone::Amharic - The Metaphone Algorithm for Amharic.

=head1 SYNOPSIS

  use utf8;
  require Text::Metaphone::Amharic;

  my $mphone = new Text::Metaphone::Amharic;

  my @keys  = $mphone->metaphone ( "ሥላሴ" );

  foreach (@keys) {
      print "$_\n";
  }

  my $key = $mphone->metaphone ( "ፀሐይ" );
  print "key => $key\n";

  $mphone->style ( "ipa" );

  @keys  = $mphone->metaphone ( "ሥላሴ" );

  foreach (@keys) {
      print "$_\n";
  }

  $mphone->style ( "ethiopic" );
    :
    :

  
  The key "style" and Metaphone "granularity" can be set at import time:

    use Text::Metaphone::Amharic ( style => "ipa", granularity => "high" );

  at instantiation time:

    my $mphone = new Text::Metaphone::Amharic ( style => "ipa", granularity => "high" );

  or anytime there after:

    $mphone->style ( "ethiopic" );
    $mphone->granularity ( "low" );

=head1 DESCRIPTION

The Text::Metaphone::Amharic module is a reimplementation of the Amharic
Metaphone algorithm of the L<Text::TransMetaphone> package.  This implementation
uses an object oriented interface and will generate keys in Ethiopic script by
default (see the L<styles> section for other encoding options).

By default the keys are generated in "low" granularity mode which finds the
most matches.  The L<granularity> section discusses the effects of the
different levels.


Like L<Text::TransMetaphone::am> the terminal key returned under list context
is a regular expression.  Amharic character classes will be applied in the RE
key as per the conventions of L<Regexp::Ethiopic::Amharic>.


=head2 GRANULARITY

The granularity parameter refers to the degree of reduction that occurs
in the key generation.  The granularity modes were created for investigative
purposes.  The most effective "low" level mode is the default.

=head3 "high"

The least coarse grain.  "ወ" and "የ" are treated under consonant rules.
rules, that is stripped out of the string except as the first char.  The
default IM correction (shift-slip condition) folds keys both upward and
downward only.  The high granularity level generates the greatest number
of keys.  Each substitution causes a new key to be generated so that the
set of keys returned represent all possible permutations.  The "high"
level is the least aggressive in terms of text simplification
and leads to the fewest matches.  The "high" level is more useful for another
types of analysis, such as distance comparison to the canonical word.  Since
both the canonical and error words have keys folded downward for all
granularity levels during IM corrections, there is no particular advantage to
the "high" level for the purpose of matching.

=head3 "medium"

An in between grain.  "ወ" and "የ" are treated under consonant rules.
The default IM correction folds keys downward only.  The keys generated
represent a "lowest common denominator" that would be reducible from the
"high" mode keys.  More matches will be found at the lowest granularity
level, but the risk of false matches becomes higher.

=head3 "low"

The default and most coarse, or aggressive, grain.  "ወ" and "የ" are treated
under vowel rules, that is stripped out of the string except as the first char.
Like the medium level, the default IM correction folds keys downward only and
the keys again are lowest common denominators of "high" mode keys.
More matches will be found at the lowest granularity level, but the risk of
false matches becomes higher.

=head2 STYLES

By default keys are returned with Ethiopic characters (UTF-8 encoding).  If
this is not your text "style" of choice, IPA symbols and SERA transliteration
are also available.  The text style can be set and reset at any time:

=head3 At Import Time:

  use Text::Metaphone::Amharic qw( style => "ipa" );

=head3 At Instantiation Time:

  my $mphone = new Text::Metaphone::Amharic ( style => "sera" );

=head3 After Instantiation:

  $mphone->style ( "ethio" );

A C<reverse> method is also provided to convert an IPA or SERA symbol key into  
an equivalent Ethiopic sequence.

=head1 REQUIRES

L<Regexp::Ethiopic>.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

=item L<http://daniel.yacob.name/papers/DanielYacob-ICESXV.pdf>

=item L<Text::TransMetaphone>

=item Included with this package:

  examples/amphone.pl         examples/ipa-phone.pl
  examples/amphone-high.pl    examples/ipa-phone-high.pl
  examples/granularity.pl     examples/matchtest.pl

=cut
