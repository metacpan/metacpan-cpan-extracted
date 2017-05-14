
use strict;

use cmo::rpn::deco::CalcImpl;
use cmo::rpn::deco::Token;
use cmo::rpn::deco::Plus;
use cmo::rpn::deco::Minus;
use cmo::rpn::deco::Multiply;
use cmo::rpn::deco::Divide;
use cmo::rpn::deco::Mod;
use cmo::rpn::deco::Sqrt;

main();

sub main {
	my $mycalc = new cmo::rpn::deco::CalcImpl();
	$mycalc = new cmo::rpn::deco::Plus( { calc => $mycalc } );
	$mycalc = new cmo::rpn::deco::Minus( { calc => $mycalc } );
	$mycalc = new cmo::rpn::deco::Multiply( { calc => $mycalc } );
	$mycalc = new cmo::rpn::deco::Divide( { calc => $mycalc } );
	$mycalc = new cmo::rpn::deco::Mod( { calc => $mycalc } );
	$mycalc = new cmo::rpn::deco::Sqrt( { calc => $mycalc } );
	
	my $token = new cmo::rpn::deco::Token();
	my $handle;

	if (scalar(@ARGV) == 1){
		open (FILE, $ARGV[0]) or die ("couldn't open the file!");
		$handle = "FILE";
	}else{
		$handle = "STDIN";
		print "Type in 'q' to exit.\n";
	}
	
	while ( chomp( my $in = <$handle> ) ) {
		if ( $in =~ /^[Qq]/ ) {
			last;
		}
		my @tokens = split ' ', $in;
		eval {
			for (@tokens){
				if ( $_ =~ m/^[0-9]$/ ) {
					$token->push($_);
				}
				else {
					$token->opSymbol($_);
					$mycalc->evaluate($token);
				}
			}
		};
		if ($@) {
			print $@;
		}
		else {
			print "input=$in\n";
			print "ans=" . $token->getAnswer() . "\n";
		}
		$token->clear();
	}
}
