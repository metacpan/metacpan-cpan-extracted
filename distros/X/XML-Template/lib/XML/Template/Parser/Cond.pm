package XML::Template::Parser::Cond;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::namespace000002;
use strict;
use vars qw($skip $AUTOLOAD  );
$skip = '\s*';

  sub generate_varget {
    my ($text, $function) = @_;

    my $return;
    if (defined $function->[0]) {
      my ($functionname, $params) = @{$function->[0]};
      $return = "\$process->subroutine ('$functionname', $text";
      if (defined $params->[0] && scalar @{$params->[0]}) {
        $return .= ', ';
        $return .= join (', ', @{$params->[0]});
      }
      $return .= ')';
    } else {
      $return = "\$vars->get_xpath ($text)"
    }
  }
;


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::namespace000002::AUTOLOAD	= sub
{
	no strict 'refs';
	$AUTOLOAD =~ s/^Parse::RecDescent::namespace000002/Parse::RecDescent/;
	goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::namespace000002::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::paramlist
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"paramlist"};
	
	Parse::RecDescent::_trace(q{Trying rule: [paramlist]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{paramlist})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['(' ')']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{paramlist})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{paramlist});
		%item = (__RULE__ => q{paramlist});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['(']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\(//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: [')']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{')'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = [] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['(' ')']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['(' <leftop: param ',' param> ')']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{paramlist})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{paramlist});
		%item = (__RULE__ => q{paramlist});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['(']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\(//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying operator: [<leftop: param ',' param>]},
				  Parse::RecDescent::_tracefirst($text),
				  q{paramlist})
					if defined $::RD_TRACE;
		$expectation->is(q{<leftop: param ',' param>})->at($text);

		$_tok = undef;
		OPLOOP: while (1)
		{
		  $repcount = 0;
		  my  @item;
		  
		  # MATCH LEFTARG
		  
		Parse::RecDescent::_trace(q{Trying subrule: [param]},
				  Parse::RecDescent::_tracefirst($text),
				  q{paramlist})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{param})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::param($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [param]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{paramlist})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [param]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$item{q{param}} = $_tok;
		push @item, $_tok;
		
		}


		  $repcount++;

		  my $savetext = $text;
		  my $backtrack;

		  # MATCH (OP RIGHTARG)(s)
		  while ($repcount < 100000000)
		  {
			$backtrack = 0;
			
		Parse::RecDescent::_trace(q{Trying terminal: [',']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{','})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\,//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

			pop @item;
			
			
		Parse::RecDescent::_trace(q{Trying subrule: [param]},
				  Parse::RecDescent::_tracefirst($text),
				  q{paramlist})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{param})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::param($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [param]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{paramlist})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [param]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$item{q{param}} = $_tok;
		push @item, $_tok;
		
		}

			$savetext = $text;
			$repcount++;
		  }
		  $text = $savetext;
		  pop @item if $backtrack;

		  unless (@item) { undef $_tok; last }
		  $_tok = [ @item ];
		  last;
		} 

		unless ($repcount>=1)
		{
			Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: param ',' param>]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{paramlist})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: param ',' param>]<< (return value: [}
					  . qq{@{$_tok||[]}} . q{]},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;

		push @item, $item{__DIRECTIVE1__}=$_tok||[];


		Parse::RecDescent::_trace(q{Trying terminal: [')']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{')'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['(' <leftop: param ',' param> ')']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramlist})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{paramlist})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{paramlist})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{paramlist});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{paramlist})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::xpathstring
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"xpathstring"};
	
	Parse::RecDescent::_trace(q{Trying rule: [xpathstring]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{xpathstring})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' vartext '\}\\.']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{xpathstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{xpathstring});
		%item = (__RULE__ => q{xpathstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [vartext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xpathstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{vartext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::vartext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [vartext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xpathstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [vartext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$item{q{vartext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}\\.']},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}\\.'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}\\\.//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2]) . " . '.'" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' vartext '\}\\.']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' vartext '\}' function]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{xpathstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{xpathstring});
		%item = (__RULE__ => q{xpathstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [vartext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xpathstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{vartext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::vartext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [vartext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xpathstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [vartext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$item{q{vartext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [function]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xpathstring})
					if defined $::RD_TRACE;
		$expectation->is(q{function})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::function, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [function]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xpathstring})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [function]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$item{q{function}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2], $item[4]) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' vartext '\}' function]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/([\\\\][\\$\}]|[^\\$\}])+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{xpathstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{xpathstring});
		%item = (__RULE__ => q{xpathstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/([\\\\][\\$\}]|[^\\$\}])+/]}, Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:([\\][\$}]|[^\$}])+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] =~ s/\\/\\\\/g; $item[1] =~ s/'/\\'/g;
                  $return = "'$item[1]'" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/([\\\\][\\$\}]|[^\\$\}])+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{xpathstring})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{xpathstring})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{xpathstring});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{xpathstring})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::varstring
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"varstring"};
	
	Parse::RecDescent::_trace(q{Trying rule: [varstring]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{varstring})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' vartext '\}\\.']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{varstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{varstring});
		%item = (__RULE__ => q{varstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [vartext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{varstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{vartext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::vartext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [vartext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{varstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [vartext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$item{q{vartext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}\\.']},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}\\.'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}\\\.//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2]) . " . '.'" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' vartext '\}\\.']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' vartext '\}' function]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{varstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{varstring});
		%item = (__RULE__ => q{varstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [vartext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{varstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{vartext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::vartext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [vartext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{varstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [vartext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$item{q{vartext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [function]},
				  Parse::RecDescent::_tracefirst($text),
				  q{varstring})
					if defined $::RD_TRACE;
		$expectation->is(q{function})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::function, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [function]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{varstring})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [function]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$item{q{function}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2], $item[4]) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' vartext '\}' function]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/([\\\\][\\$\{\}'\\/]|[^\\$\{\}'\\/])+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{varstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{varstring});
		%item = (__RULE__ => q{varstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/([\\\\][\\$\{\}'\\/]|[^\\$\{\}'\\/])+/]}, Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:([\\][\${}'\/]|[^\${}'\/])+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] =~ s/\\/\\\\/g; $item[1] =~ s/'/\\'/g; $return = "'$item[1]'" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/([\\\\][\\$\{\}'\\/]|[^\\$\{\}'\\/])+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['\{' vartext '\}']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{varstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{varstring});
		%item = (__RULE__ => q{varstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [vartext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{varstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{vartext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::vartext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [vartext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{varstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [vartext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$item{q{vartext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = "\$vars->backslash ('\.\/', $item[2])" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['\{' vartext '\}']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['/' xpathtext]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{varstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[4];
		$text = $_[1];
		my $_savetext;
		@item = (q{varstring});
		%item = (__RULE__ => q{varstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['/']},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\///)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [xpathtext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{varstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{xpathtext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::xpathtext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [xpathtext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{varstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [xpathtext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$item{q{xpathtext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = "\$vars->backslash ('\.', $item[2])"; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['/' xpathtext]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{varstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{varstring})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{varstring})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{varstring});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{varstring})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::function
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"function"};
	
	Parse::RecDescent::_trace(q{Trying rule: [function]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{function})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		local $skip = defined($skip) ? $skip : $Parse::RecDescent::skip;
		Parse::RecDescent::_trace(q{Trying production: [<skip: '\s*'> '.' /[_a-z0-9]+/i paramlist]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{function})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{function});
		%item = (__RULE__ => q{function});
		my $repcount = 0;


		

		Parse::RecDescent::_trace(q{Trying directive: [<skip: '\s*'>]},
					Parse::RecDescent::_tracefirst($text),
					  q{function})
						if defined $::RD_TRACE; 
		$_tok = do { my $oldskip = $skip; $skip= '\s*'; $oldskip };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['.']},
					  Parse::RecDescent::_tracefirst($text),
					  q{function})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'.'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\.//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: [/[_a-z0-9]+/i]}, Parse::RecDescent::_tracefirst($text),
					  q{function})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/[_a-z0-9]+/i})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[_a-z0-9]+)//i)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [paramlist]},
				  Parse::RecDescent::_tracefirst($text),
				  q{function})
					if defined $::RD_TRACE;
		$expectation->is(q{paramlist})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::paramlist, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [paramlist]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{function})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [paramlist]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{function})
						if defined $::RD_TRACE;
		$item{q{paramlist}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{function})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = [$item[3], $item[4]] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [<skip: '\s*'> '.' /[_a-z0-9]+/i paramlist]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{function})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{function})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{function})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{function});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{function})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::paramstring
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"paramstring"};
	
	Parse::RecDescent::_trace(q{Trying rule: [paramstring]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{paramstring})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' paramtext '\}\\.']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{paramstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{paramstring});
		%item = (__RULE__ => q{paramstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [paramtext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{paramstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{paramtext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::paramtext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [paramtext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{paramstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [paramtext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$item{q{paramtext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}\\.']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}\\.'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}\\\.//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2]) . " . '.'" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' paramtext '\}\\.']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' paramtext '\}' function]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{paramstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{paramstring});
		%item = (__RULE__ => q{paramstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [paramtext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{paramstring})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{paramtext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::paramtext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [paramtext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{paramstring})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [paramtext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$item{q{paramtext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [function]},
				  Parse::RecDescent::_tracefirst($text),
				  q{paramstring})
					if defined $::RD_TRACE;
		$expectation->is(q{function})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::function, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [function]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{paramstring})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [function]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$item{q{function}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2], $item[4]) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' paramtext '\}' function]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/([\\\\][\\$\})"]|[^\\$\})"])+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{paramstring})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{paramstring});
		%item = (__RULE__ => q{paramstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/([\\\\][\\$\})"]|[^\\$\})"])+/]}, Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:([\\][\$})"]|[^\$})"])+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[1] =~ s/'/\\'/g; $return = "'$item[1]'" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/([\\\\][\\$\})"]|[^\\$\})"])+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramstring})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{paramstring})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{paramstring})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{paramstring});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{paramstring})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::string
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"string"};
	
	Parse::RecDescent::_trace(q{Trying rule: [string]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{string})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' vartext '\}\\.']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{string})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{string});
		%item = (__RULE__ => q{string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [vartext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{string})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{vartext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::vartext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [vartext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [vartext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$item{q{vartext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}\\.']},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}\\.'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}\\\.//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2]) . " . '.'" };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' vartext '\}\\.']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$\{' vartext '\}' function]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{string})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{string});
		%item = (__RULE__ => q{string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [vartext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{string})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{vartext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::vartext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [vartext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [vartext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$item{q{vartext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [function]},
				  Parse::RecDescent::_tracefirst($text),
				  q{string})
					if defined $::RD_TRACE;
		$expectation->is(q{function})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::function, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [function]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [function]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$item{q{function}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = generate_varget ($item[2], $item[4]) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$\{' vartext '\}' function]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/([\\\\]\\$|[^\\$])+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{string})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{string});
		%item = (__RULE__ => q{string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/([\\\\]\\$|[^\\$])+/]}, Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:([\\]\$|[^\$])+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/([\\\\]\\$|[^\\$])+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{string})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{string})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{string})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{string});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{string})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::paramtext
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"paramtext"};
	
	Parse::RecDescent::_trace(q{Trying rule: [paramtext]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{paramtext})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		local $skip = defined($skip) ? $skip : $Parse::RecDescent::skip;
		Parse::RecDescent::_trace(q{Trying production: [<skip: ''> paramstring]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{paramtext})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{paramtext});
		%item = (__RULE__ => q{paramtext});
		my $repcount = 0;


		

		Parse::RecDescent::_trace(q{Trying directive: [<skip: ''>]},
					Parse::RecDescent::_tracefirst($text),
					  q{paramtext})
						if defined $::RD_TRACE; 
		$_tok = do { my $oldskip = $skip; $skip= ''; $oldskip };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [paramstring]},
				  Parse::RecDescent::_tracefirst($text),
				  q{paramtext})
					if defined $::RD_TRACE;
		$expectation->is(q{paramstring})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::paramstring, 1, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [paramstring]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{paramtext})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [paramstring]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{paramtext})
						if defined $::RD_TRACE;
		$item{q{paramstring}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramtext})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = join (' . ', @{$item[2]}) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [<skip: ''> paramstring]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{paramtext})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{paramtext})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{paramtext})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{paramtext});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{paramtext})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::text
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"text"};
	
	Parse::RecDescent::_trace(q{Trying rule: [text]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{text})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		local $skip = defined($skip) ? $skip : $Parse::RecDescent::skip;
		Parse::RecDescent::_trace(q{Trying production: [<skip: ''> string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{text})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{text});
		%item = (__RULE__ => q{text});
		my $repcount = 0;


		

		Parse::RecDescent::_trace(q{Trying directive: [<skip: ''>]},
					Parse::RecDescent::_tracefirst($text),
					  q{text})
						if defined $::RD_TRACE; 
		$_tok = do { my $oldskip = $skip; $skip= ''; $oldskip };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{text})
					if defined $::RD_TRACE;
		$expectation->is(q{string})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::string, 1, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{text})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [string]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{text})
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{text})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = join ('', @{$item[2]}) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [<skip: ''> string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{text})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{text})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{text})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{text});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{text})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::vartext
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"vartext"};
	
	Parse::RecDescent::_trace(q{Trying rule: [vartext]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{vartext})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		local $skip = defined($skip) ? $skip : $Parse::RecDescent::skip;
		Parse::RecDescent::_trace(q{Trying production: [<skip: ''> varstring]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{vartext})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{vartext});
		%item = (__RULE__ => q{vartext});
		my $repcount = 0;


		

		Parse::RecDescent::_trace(q{Trying directive: [<skip: ''>]},
					Parse::RecDescent::_tracefirst($text),
					  q{vartext})
						if defined $::RD_TRACE; 
		$_tok = do { my $oldskip = $skip; $skip= ''; $oldskip };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [varstring]},
				  Parse::RecDescent::_tracefirst($text),
				  q{vartext})
					if defined $::RD_TRACE;
		$expectation->is(q{varstring})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::varstring, 1, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [varstring]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{vartext})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [varstring]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{vartext})
						if defined $::RD_TRACE;
		$item{q{varstring}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{vartext})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = join (' . ', @{$item[2]}) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [<skip: ''> varstring]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{vartext})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{vartext})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{vartext})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{vartext});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{vartext})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::xpathtext
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"xpathtext"};
	
	Parse::RecDescent::_trace(q{Trying rule: [xpathtext]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{xpathtext})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		local $skip = defined($skip) ? $skip : $Parse::RecDescent::skip;
		Parse::RecDescent::_trace(q{Trying production: [<skip: ''> xpathstring]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{xpathtext})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{xpathtext});
		%item = (__RULE__ => q{xpathtext});
		my $repcount = 0;


		

		Parse::RecDescent::_trace(q{Trying directive: [<skip: ''>]},
					Parse::RecDescent::_tracefirst($text),
					  q{xpathtext})
						if defined $::RD_TRACE; 
		$_tok = do { my $oldskip = $skip; $skip= ''; $oldskip };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [xpathstring]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xpathtext})
					if defined $::RD_TRACE;
		$expectation->is(q{xpathstring})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::namespace000002::xpathstring, 1, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [xpathstring]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xpathtext})
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [xpathstring]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathtext})
						if defined $::RD_TRACE;
		$item{q{xpathstring}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathtext})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = "'/' . " . join (' . ', @{$item[2]}) };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [<skip: ''> xpathstring]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{xpathtext})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{xpathtext})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{xpathtext})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{xpathtext});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{xpathtext})
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::namespace000002::param
{
	my $thisparser = $_[0];
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"param"};
	
	Parse::RecDescent::_trace(q{Trying rule: [param]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{param})
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['"' paramtext '"']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{param})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{param});
		%item = (__RULE__ => q{param});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['"']},
					  Parse::RecDescent::_tracefirst($text),
					  q{param})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\"//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [paramtext]},
				  Parse::RecDescent::_tracefirst($text),
				  q{param})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{paramtext})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::paramtext($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [paramtext]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{param})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [paramtext]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{param})
						if defined $::RD_TRACE;
		$item{q{paramtext}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['"']},
					  Parse::RecDescent::_tracefirst($text),
					  q{param})
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'"'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\"//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{param})
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])}, $text)
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['"' paramtext '"']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{param})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [paramstring]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{param})
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{param});
		%item = (__RULE__ => q{param});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [paramstring]},
				  Parse::RecDescent::_tracefirst($text),
				  q{param})
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::namespace000002::paramstring($thisparser,$text,$repeating,$_noactions,undef)))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [paramstring]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{param})
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [paramstring]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{param})
						if defined $::RD_TRACE;
		$item{q{paramstring}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [paramstring]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{param})
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{param})
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{param})
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{param});
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{param})
	}
	$_[1] = $text;
	return $return;
}
}
package XML::Template::Parser::Cond; sub new { my $self = bless( {
                 '_AUTOTREE' => undef,
                 'localvars' => '',
                 'startcode' => '',
                 '_check' => {
                               'thisoffset' => '',
                               'itempos' => '',
                               'prevoffset' => '',
                               'prevline' => '',
                               'prevcolumn' => '',
                               'thiscolumn' => ''
                             },
                 'namespace' => 'Parse::RecDescent::namespace000002',
                 '_AUTOACTION' => undef,
                 'rules' => {
                              'paramlist' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'param'
                                                                 ],
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 2,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '(',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'(\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 66
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'pattern' => ')',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\')\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 66
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 67,
                                                                                                  'code' => '{ $return = [] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '1',
                                                                            'strcount' => 3,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'op' => [],
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '(',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'(\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 68
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'expected' => '<leftop: param \',\' param>',
                                                                                                  'min' => 1,
                                                                                                  'max' => 100000000,
                                                                                                  'leftarg' => bless( {
                                                                                                                        'subrule' => 'param',
                                                                                                                        'matchrule' => 0,
                                                                                                                        'implicit' => undef,
                                                                                                                        'argcode' => undef,
                                                                                                                        'lookahead' => 0,
                                                                                                                        'line' => 68
                                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                                  'rightarg' => bless( {
                                                                                                                         'subrule' => 'param',
                                                                                                                         'matchrule' => 0,
                                                                                                                         'implicit' => undef,
                                                                                                                         'argcode' => undef,
                                                                                                                         'lookahead' => 0,
                                                                                                                         'line' => 68
                                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'type' => 'leftop',
                                                                                                  'op' => bless( {
                                                                                                                   'pattern' => ',',
                                                                                                                   'hashname' => '__STRING2__',
                                                                                                                   'description' => '\',\'',
                                                                                                                   'lookahead' => 0,
                                                                                                                   'line' => 68
                                                                                                                 }, 'Parse::RecDescent::Literal' )
                                                                                                }, 'Parse::RecDescent::Operator' ),
                                                                                         bless( {
                                                                                                  'pattern' => ')',
                                                                                                  'hashname' => '__STRING3__',
                                                                                                  'description' => '\')\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 68
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 69,
                                                                                                  'code' => '{ $return = $item[2] }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 68
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'paramlist',
                                                      'vars' => '',
                                                      'changed' => 0,
                                                      'line' => 66
                                                    }, 'Parse::RecDescent::Rule' ),
                              'xpathstring' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'vartext',
                                                                     'function'
                                                                   ],
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 2,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'pattern' => '${',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'$\\{\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 45
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'vartext',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 45
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '}\\.',
                                                                                                    'hashname' => '__STRING2__',
                                                                                                    'description' => '\'\\}\\\\.\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 45
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 46,
                                                                                                    'code' => '{ $return = generate_varget ($item[2]) . " . \'.\'" }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '1',
                                                                              'strcount' => 2,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'pattern' => '${',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'$\\{\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 47
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'vartext',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 47
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '}',
                                                                                                    'hashname' => '__STRING2__',
                                                                                                    'description' => '\'\\}\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 47
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'function',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 100000000,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => 's?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 47
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 48,
                                                                                                    'code' => '{ $return = generate_varget ($item[2], $item[4]) }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 47
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '2',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 1,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'description' => '/([\\\\\\\\][\\\\$\\}]|[^\\\\$\\}])+/',
                                                                                                    'rdelim' => '/',
                                                                                                    'pattern' => '([\\\\][\\$}]|[^\\$}])+',
                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'ldelim' => '/',
                                                                                                    'mod' => '',
                                                                                                    'line' => 49
                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 50,
                                                                                                    'code' => '{ $item[1] =~ s/\\\\/\\\\\\\\/g; $item[1] =~ s/\'/\\\\\'/g;
                  $return = "\'$item[1]\'" }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 49
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'xpathstring',
                                                        'vars' => '',
                                                        'changed' => 0,
                                                        'line' => 45
                                                      }, 'Parse::RecDescent::Rule' ),
                              'varstring' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'vartext',
                                                                   'function',
                                                                   'xpathtext'
                                                                 ],
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 2,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '${',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'$\\{\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 32
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'vartext',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 32
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '}\\.',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'\\}\\\\.\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 32
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 33,
                                                                                                  'code' => '{ $return = generate_varget ($item[2]) . " . \'.\'" }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '1',
                                                                            'strcount' => 2,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '${',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'$\\{\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 34
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'vartext',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 34
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '}',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'\\}\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 34
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'function',
                                                                                                  'expected' => undef,
                                                                                                  'min' => 0,
                                                                                                  'argcode' => undef,
                                                                                                  'max' => 100000000,
                                                                                                  'matchrule' => 0,
                                                                                                  'repspec' => 's?',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 34
                                                                                                }, 'Parse::RecDescent::Repetition' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 35,
                                                                                                  'code' => '{ $return = generate_varget ($item[2], $item[4]) }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 34
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '2',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 1,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'description' => '/([\\\\\\\\][\\\\$\\{\\}\'\\\\/]|[^\\\\$\\{\\}\'\\\\/])+/',
                                                                                                  'rdelim' => '/',
                                                                                                  'pattern' => '([\\\\][\\${}\'\\/]|[^\\${}\'\\/])+',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'ldelim' => '/',
                                                                                                  'mod' => '',
                                                                                                  'line' => 36
                                                                                                }, 'Parse::RecDescent::Token' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 37,
                                                                                                  'code' => '{ $item[1] =~ s/\\\\/\\\\\\\\/g; $item[1] =~ s/\'/\\\\\'/g; $return = "\'$item[1]\'" }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 36
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '3',
                                                                            'strcount' => 2,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '{',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'\\{\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 38
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'vartext',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 38
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'pattern' => '}',
                                                                                                  'hashname' => '__STRING2__',
                                                                                                  'description' => '\'\\}\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 38
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 39,
                                                                                                  'code' => '{ $return = "\\$vars->backslash (\'\\.\\/\', $item[2])" }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 38
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '4',
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '/',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'/\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 40
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'xpathtext',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 40
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 41,
                                                                                                  'code' => '{ $return = "\\$vars->backslash (\'\\.\', $item[2])"; }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 40
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'varstring',
                                                      'vars' => '',
                                                      'changed' => 0,
                                                      'line' => 32
                                                    }, 'Parse::RecDescent::Rule' ),
                              'function' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'paramlist'
                                                                ],
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 1,
                                                                           'dircount' => 1,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'hashname' => '__DIRECTIVE1__',
                                                                                                 'name' => '<skip: \'\\s*\'>',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 64,
                                                                                                 'code' => 'my $oldskip = $skip; $skip= \'\\s*\'; $oldskip'
                                                                                               }, 'Parse::RecDescent::Directive' ),
                                                                                        bless( {
                                                                                                 'pattern' => '.',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'.\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 64
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'description' => '/[_a-z0-9]+/i',
                                                                                                 'rdelim' => '/',
                                                                                                 'pattern' => '[_a-z0-9]+',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'ldelim' => '/',
                                                                                                 'mod' => 'i',
                                                                                                 'line' => 64
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'paramlist',
                                                                                                 'expected' => undef,
                                                                                                 'min' => 0,
                                                                                                 'argcode' => undef,
                                                                                                 'max' => 100000000,
                                                                                                 'matchrule' => 0,
                                                                                                 'repspec' => 's?',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 64
                                                                                               }, 'Parse::RecDescent::Repetition' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 65,
                                                                                                 'code' => '{ $return = [$item[3], $item[4]] }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'function',
                                                     'vars' => '',
                                                     'changed' => 0,
                                                     'line' => 63
                                                   }, 'Parse::RecDescent::Rule' ),
                              'paramstring' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'paramtext',
                                                                     'function'
                                                                   ],
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 2,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'pattern' => '${',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'$\\{\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 56
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'paramtext',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 56
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '}\\.',
                                                                                                    'hashname' => '__STRING2__',
                                                                                                    'description' => '\'\\}\\\\.\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 56
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 57,
                                                                                                    'code' => '{ $return = generate_varget ($item[2]) . " . \'.\'" }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '1',
                                                                              'strcount' => 2,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'pattern' => '${',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'$\\{\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 58
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'paramtext',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 58
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '}',
                                                                                                    'hashname' => '__STRING2__',
                                                                                                    'description' => '\'\\}\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 58
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'function',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 100000000,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => 's?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 58
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 59,
                                                                                                    'code' => '{ $return = generate_varget ($item[2], $item[4]) }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 58
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '2',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 1,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'description' => '/([\\\\\\\\][\\\\$\\})"]|[^\\\\$\\})"])+/',
                                                                                                    'rdelim' => '/',
                                                                                                    'pattern' => '([\\\\][\\$})"]|[^\\$})"])+',
                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'ldelim' => '/',
                                                                                                    'mod' => '',
                                                                                                    'line' => 60
                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => 61,
                                                                                                    'code' => '{ $item[1] =~ s/\'/\\\\\'/g; $return = "\'$item[1]\'" }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 60
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'paramstring',
                                                        'vars' => '',
                                                        'changed' => 0,
                                                        'line' => 56
                                                      }, 'Parse::RecDescent::Rule' ),
                              'string' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'vartext',
                                                                'function'
                                                              ],
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 2,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => '${',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\'$\\{\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 23
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'subrule' => 'vartext',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 23
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'pattern' => '}\\.',
                                                                                               'hashname' => '__STRING2__',
                                                                                               'description' => '\'\\}\\\\.\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 23
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 24,
                                                                                               'code' => '{ $return = generate_varget ($item[2]) . " . \'.\'" }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' ),
                                                                bless( {
                                                                         'number' => '1',
                                                                         'strcount' => 2,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => '${',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\'$\\{\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 25
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'subrule' => 'vartext',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 25
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'pattern' => '}',
                                                                                               'hashname' => '__STRING2__',
                                                                                               'description' => '\'\\}\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 25
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'subrule' => 'function',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 100000000,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => 's?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 25
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 26,
                                                                                               'code' => '{ $return = generate_varget ($item[2], $item[4]) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => 25
                                                                       }, 'Parse::RecDescent::Production' ),
                                                                bless( {
                                                                         'number' => '2',
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 1,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'description' => '/([\\\\\\\\]\\\\$|[^\\\\$])+/',
                                                                                               'rdelim' => '/',
                                                                                               'pattern' => '([\\\\]\\$|[^\\$])+',
                                                                                               'hashname' => '__PATTERN1__',
                                                                                               'lookahead' => 0,
                                                                                               'ldelim' => '/',
                                                                                               'mod' => '',
                                                                                               'line' => 27
                                                                                             }, 'Parse::RecDescent::Token' )
                                                                                    ],
                                                                         'line' => 27
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'string',
                                                   'vars' => '',
                                                   'changed' => 0,
                                                   'line' => 23
                                                 }, 'Parse::RecDescent::Rule' ),
                              'paramtext' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'paramstring'
                                                                 ],
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'name' => '<skip: \'\'>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 54,
                                                                                                  'code' => 'my $oldskip = $skip; $skip= \'\'; $oldskip'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'paramstring',
                                                                                                  'expected' => undef,
                                                                                                  'min' => 1,
                                                                                                  'argcode' => undef,
                                                                                                  'max' => 100000000,
                                                                                                  'matchrule' => 0,
                                                                                                  'repspec' => 's',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 54
                                                                                                }, 'Parse::RecDescent::Repetition' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 55,
                                                                                                  'code' => '{ $return = join (\' . \', @{$item[2]}) }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'paramtext',
                                                      'vars' => '',
                                                      'changed' => 0,
                                                      'line' => 53
                                                    }, 'Parse::RecDescent::Rule' ),
                              'text' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'string'
                                                            ],
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => '0',
                                                                       'strcount' => 0,
                                                                       'dircount' => 1,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'hashname' => '__DIRECTIVE1__',
                                                                                             'name' => '<skip: \'\'>',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 21,
                                                                                             'code' => 'my $oldskip = $skip; $skip= \'\'; $oldskip'
                                                                                           }, 'Parse::RecDescent::Directive' ),
                                                                                    bless( {
                                                                                             'subrule' => 'string',
                                                                                             'expected' => undef,
                                                                                             'min' => 1,
                                                                                             'argcode' => undef,
                                                                                             'max' => 100000000,
                                                                                             'matchrule' => 0,
                                                                                             'repspec' => 's',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 21
                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 22,
                                                                                             'code' => '{ $return = join (\'\', @{$item[2]}) }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'text',
                                                 'vars' => '',
                                                 'changed' => 0,
                                                 'line' => 20
                                               }, 'Parse::RecDescent::Rule' ),
                              'vartext' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'varstring'
                                                               ],
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 0,
                                                                          'dircount' => 1,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'hashname' => '__DIRECTIVE1__',
                                                                                                'name' => '<skip: \'\'>',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 30,
                                                                                                'code' => 'my $oldskip = $skip; $skip= \'\'; $oldskip'
                                                                                              }, 'Parse::RecDescent::Directive' ),
                                                                                       bless( {
                                                                                                'subrule' => 'varstring',
                                                                                                'expected' => undef,
                                                                                                'min' => 1,
                                                                                                'argcode' => undef,
                                                                                                'max' => 100000000,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => 's',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 30
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 31,
                                                                                                'code' => '{ $return = join (\' . \', @{$item[2]}) }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'vartext',
                                                    'vars' => '',
                                                    'changed' => 0,
                                                    'line' => 29
                                                  }, 'Parse::RecDescent::Rule' ),
                              'xpathtext' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'xpathstring'
                                                                 ],
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 1,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'name' => '<skip: \'\'>',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 43,
                                                                                                  'code' => 'my $oldskip = $skip; $skip= \'\'; $oldskip'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'xpathstring',
                                                                                                  'expected' => undef,
                                                                                                  'min' => 1,
                                                                                                  'argcode' => undef,
                                                                                                  'max' => 100000000,
                                                                                                  'matchrule' => 0,
                                                                                                  'repspec' => 's',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 43
                                                                                                }, 'Parse::RecDescent::Repetition' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 44,
                                                                                                  'code' => '{ $return = "\'/\' . " . join (\' . \', @{$item[2]}) }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'xpathtext',
                                                      'vars' => '',
                                                      'changed' => 0,
                                                      'line' => 43
                                                    }, 'Parse::RecDescent::Rule' ),
                              'param' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'paramtext',
                                                               'paramstring'
                                                             ],
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 2,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '"',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'"\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 70
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'paramtext',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 70
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => '"',
                                                                                              'hashname' => '__STRING2__',
                                                                                              'description' => '\'"\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 70
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => 71,
                                                                                              'code' => '{ $return = $item[2] }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => '1',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'paramstring',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => 72
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => 72
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'param',
                                                  'vars' => '',
                                                  'changed' => 0,
                                                  'line' => 70
                                                }, 'Parse::RecDescent::Rule' )
                            }
               }, 'Parse::RecDescent' );
}
