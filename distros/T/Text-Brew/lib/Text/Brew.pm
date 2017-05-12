package Text::Brew;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.02';
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&distance);
%EXPORT_TAGS = ();

use constant INITIAL	=> 'INITIAL';
use constant DEL	=> 'DEL';
use constant INS	=> 'INS';
use constant SUBST	=> 'SUBST';
use constant MATCH	=> 'MATCH';
use constant None	=> [];

sub _best {

	my ($sub_move,$ins_move,$del_move)=@_;

	my ($increment,$move1,$move2,$move3,$tb1,$tb2,$tb3);

	($increment,$move1,$tb1)=@$sub_move;
	my $cost_with_sub=$increment+$tb1->[0];

	($increment,$move2,$tb2)=@$ins_move;
	my $cost_with_ins=$increment+$tb2->[0];

	($increment,$move3,$tb3)=@$del_move;
	my $cost_with_del=$increment+$tb3->[0];

	my $best_cost=$cost_with_sub;
	my $move=$move1;
	my $tb=$tb1;

	if ($cost_with_ins < $best_cost) {

		$best_cost=$cost_with_ins;
		$move=$move2;
		$tb=$tb2;
	}

	if ($cost_with_del < $best_cost) {

		$best_cost=$cost_with_del;
		$move=$move3;
		$tb=$tb3;
	}

	if ($best_cost == $tb->[0]) {$move=MATCH}
	return [$best_cost,$move,$tb];
}

sub _edit_path {

	my ($string1,$string2,$refc)=@_;

	my $m=length($string1);
	my $n=length($string2);

	my ($matchCost,$insCost,$delCost,$substCost)=@$refc;
	my @d;

	$d[0][0]=[0,INITIAL,None];

	foreach my $i (0 .. $m-1) {

		my $sofar= $d[$i][0][0];

		#		cost		move	tb
		$d[$i+1][0]=[$sofar+$delCost, 	DEL , 	$d[$i][0]];
	}

	foreach my $j (0 .. $n-1) {

		my $sofar= $d[0][$j][0];

		#		cost		move	tb
		$d[0][$j+1]=[$sofar+$insCost, 	INS ,	$d[0][$j]];
	}

	foreach my $i (0 .. $m-1) {

		my $string1_i=substr($string1,$i,1);

		foreach my $j (0 .. $n-1) {

			my $string2_i=substr($string2,$j,1);
			my $subst;

			if ($string1_i eq $string2_i) {

				$subst=$matchCost;

			} else {

				$subst=$substCost;
			}

			#			cost	move	tb
			$d[$i+1][$j+1]=_best([$subst,	SUBST ,	$d[$i][$j]],
					     [$insCost,	INS ,	$d[$i+1][$j]],
					     [$delCost, DEL ,	$d[$i][$j+1]]);
		}
	}

	return $d[$m][$n];
}

sub distance {

	my ($string1,$string2,$optional_ref)=@_;
	my $output;
	my $cost;

	if ($optional_ref) {

		if (ref($optional_ref) ne "HASH") {

			warn "Text::Brew: options not well formed, using default";

		} else {

			foreach my $key (keys %$optional_ref) {

				if ($key eq "-cost") {

					$cost=$$optional_ref{'-cost'};
					if (ref($cost) ne "ARRAY") {

           					require Carp;
				      		Carp::croak("Text::Brew: -cost option requires an array");

					} else {

						if (@$cost < 4) {

							warn "Text::Brew: array cost not well formed, using default";
							$cost=undef;
						}
					}

				} elsif ($key eq "-output") {

					$output=$$optional_ref{'-output'};

				} else {

					require Carp;
					Carp::croak("Text::Brew: $key is not a valid option");
				}
			}
		}
	}

	$cost ||= [0,1,1,1];
	$output='both' if (!defined $output);

	if ($output eq 'both') {

		my $tb=_edit_path($string1,$string2,$cost);
		my $distance=$tb->[0];
		my $arrayref_edits;

		while (defined $tb->[0]) {

			unshift @$arrayref_edits,$tb->[1];
			$tb=$tb->[2];	
		}

		return $distance,$arrayref_edits;

	} elsif ($output eq 'distance') {

		my $tb=_edit_path($string1,$string2,$cost);
		my $distance=$tb->[0];

		return $distance;

	} elsif ($output eq 'edits') {

		my $tb=_edit_path($string1,$string2,$cost);
		my $arrayref_edits;

		while (defined $tb->[0]) {

			unshift @$arrayref_edits,$tb->[1];
			$tb=$tb->[2];	
		}

		return $arrayref_edits;

	} else {

		require Carp;
		Carp::croak("Text::Brew: -output option must be 'distance' or 'both' or 'edits', not $output");
	}
}

1;

__END__

=head1 NAME

Text::Brew - An implementation of the Brew edit distance

=head1 SYNOPSIS


 use Text::Brew qw(distance);

 my ($distance,$arrayref_edits)=distance("four","foo");
 my $sequence=join",",@$arrayref_edits;
 print "The Brew distance for (four,foo) is $distance\n";
 print "obtained with the edits: $sequence\n\n";


=head1 DESCRIPTION

This module implements the Brew edit distance that is very close to the
dynamic programming technique used for the Wagner-Fischer (and so for the
Levenshtein) edit distance. Please look at the module references below.
For more information about the Brew edit distance see:
<http://ling.ohio-state.edu/~cbrew/795M/string-distance.html>

The difference here is that you have separated costs for the DELetion and
INSertion operations (but with the default to 1 for both, you obtain the
Levenshtein edit distance). But the most interesting feature is that you
can obtain the description of the edits needed to transform the first string 
into the second one (not vice versa: here DELetions are separated from INSertions).
The difference from the original algorithm by Chris Brew is that I have
added the SUBST operation, making it different from MATCH operation.

The symbols used here are:

 INITIAL that is the INITIAL operation (i.e. NO operation)
 MATCH	 that is the MATCH operation (0 is the default cost)
 SUBST	 that is the SUBSTitution operation (1 is the default cost)
 DEL	 that is the DELetion operation (1 is the default cost)
 INS	 that is the INSertion operation (1 is the default cost)

and you can change the default costs (see below).

You can make INS and DEL the same operation in a simple way:

 1) give both the same cost
 2) change the output string DEL to INS/DEL (o whatever)
 3) change the output string INS to INS/DEL (o whatever)


=head2 USAGE

 use strict;
 use Text::Brew qw(distance);

 my ($distance,$arrayref_edits)=distance("four","foo");
 my $sequence=join",",@$arrayref_edits;
 print "The Brew distance for (four,foo) is $distance\n";
 print "obtained with the edits: $sequence\n\n";

 my $string1="foo";
 my @strings=("four","foo","bar");
 my (@dist,@edits);
 foreach my $string2 (@strings) {
	my ($dist,$edits)=distance($string1,$string2);
	push @dist,$dist;
	push @edits,(join ",",@$edits);
 }
 foreach my $i (0 .. $#strings) {

	print "The Brew distance for ($string1,$strings[$i]) is $dist[$i]\n";
	print "obtained with the edits: $edits[$i]\n\n";
 }


=head2 OPTIONAL PARAMETERS

 distance($string1,$string2,{-cost=>[0,2,1,1],-output=>'edits'});

 -output
 accepted values are: 	
	distance	means that the distance returns 
			only the numeric distance
					
	both	the distance returns both the 
		numeric distance and the array of the edits

	edits	means that the distance returns only the 
		array of the edits

 Default output is 'both'.

 -cost
 accepted value is an array with 4 elements: 
 1st is the cost for the MATCH
 2nd is the cost for the INS (INSertion)
 3rd is the cost for the DEL (DELetion)
 4th is the cost for the SUBST (SUBSTitution)

 Default array is [0,1,1,1] .

 Examples are:

 my $distance=distance("four","foo",{-output=>'distance'});
 print "The Brew distance for (four,foo) is $distance\n\n";


 my $arrayref_edits=distance("four","foo",{-output=>'edits'});
 my $sequence=join",",@$arrayref_edits;
 print "The Brew sequence for (four,foo) is $sequence\n\n";


 my ($distance,$arrayref_edits)=distance("four","foo",{-cost=>[0,2,1,1]});
 my $sequence=join",",@$arrayref_edits;
 print "The Brew distance for (four,foo) is $distance\n";
 print "obtained with the edits: $sequence\n\n";

 ($distance,$arrayref_edits)=distance("foo","four",{-cost=>[0,2,1,1]});
 $sequence=join",",@$arrayref_edits;
 print "The Brew distance for (foo,four) is $distance\n";
 print "obtained with the edits: $sequence\n\n";


=head1 CREDITS

All the credits goes to Chris Brew the author of the algorithm.


=head1 THANKS

Many thanks to Stefano L. Rodighiero <F<larsen at perlmonk.org>> for the
suggestions.


=head1 AUTHOR

Copyright 2003 Dree Mistrut <F<dree@friuli.to>>

This package is free software and is provided "as is" without express
or implied warranty. You can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 SEE ALSO

C<Text::Levenshtein>, C<Text::WagnerFischer>


=cut

