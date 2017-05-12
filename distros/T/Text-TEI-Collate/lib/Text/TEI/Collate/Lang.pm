package Text::TEI::Collate::Lang;

use strict;
use warnings;
use Unicode::Normalize;

=head1 NAME

Text::TEI::Collate::Lang - base class for collation language-specific extensions

=head1 DESCRIPTION

Text::TEI::Collate::Lang is the base package for any language extension (e.g.
Text::TEI::Collate::Lang::Latin) to be used by Text::TEI::Collate. The base
package provides three subroutines as default; any implementation should 
re-implement one or more of these functions, and can use the ones defined
here otherwise.  This would be a base class to subclass if we ever had a
reason to instantiate it.

=head1 SUBROUTINES

=head2 distance

This is a rudimentary, and hopefully pretty quick, word distance function. It
counts the occurrence of each letter in a word, and returns the sum of
lettercount differences between the two passed words.

=begin testing

use Test::More::UTF8;
use Text::TEI::Collate::Lang;

my $distsub = \&Text::TEI::Collate::Lang::distance;
is( $distsub->( 'bedwange', 'bedvanghe' ), 3, "Correct alpha distance bedwange" );
is( $distsub->( 'swaer', 'suaer' ), 2, "Correct alpha distance swaer" );
is( $distsub->( 'the', 'teh' ), 0, "Correct alpha distance the" );
is( $distsub->( 'αι̣τια̣ν̣', 'αιτιαν' ), 3, "correct distance one direction" );
is( $distsub->( 'αιτιαν', 'αι̣τια̣ν̣' ), 3, "correct distance other direction" );

=end testing

=cut

sub distance {
	my( $word1, $word2 ) = @_;
	my @l1 = split( '', $word1 );
	my @l2 = split( '', $word2 );
	my( %f1, %f2 );
	foreach( @l1 ) {
		$f1{$_} += 1;
	}
	foreach( @l2 ) {
		$f2{$_} += 1;
	}
	my $distance = 0;
	my %seen;
	foreach( keys %f1 ) {
		$seen{$_} = 1;
		my $val1 = $f1{$_};
		my $val2 = $f2{$_} || 0;
		$distance += abs( $val1 - $val2 );
	}
	foreach( keys %f2 ) {
		next if $seen{$_};
		my $val1 = $f1{$_} || 0;
		my $val2 = $f2{$_} || 0;
		$distance += abs( $val1 - $val2 );
	}
	return $distance;
}

=head2 canonizer

This is essentially just the lc() builtin function.

=cut

sub canonizer {
    return lc( $_[0] );
}

=head2 comparator

This is a function that replaces all characters with their base character 
after an NFKD (Normalization Form Compatibility Decomposition) operation.

=begin testing

use Test::More::UTF8;
use Text::TEI::Collate::Lang;

my $comp = \&Text::TEI::Collate::Lang::comparator;
is( $comp->( 'abcd' ), 'abcd', "Got correct no-op comparison string" );
is( $comp->( "ἔστιν" ), "εστιν", "Got correct unaccented comparison string");
is( $comp->( "զ100" ), "զ100", "Got correct comparison string with digits");

=end testing

=cut

sub comparator {
   	my $word = shift;
	my @normalized;
	my @letters = split( '', lc( $word ) );
	foreach my $l ( @letters ) {
		my $d = chr( ord( NFKD( $l ) ) );
		next unless $d =~ /[[:alnum:]]/; # toss out e.g. Greek underdots
		push( @normalized, $d );
	}
	return join( '', @normalized );
}

1;

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
