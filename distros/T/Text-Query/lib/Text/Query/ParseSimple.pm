#
#   Copyright (C) 1999 Eric Bohlman, Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.  You may also use, redistribute and/or modify it
#   under the terms of the Artistic License supplied with your Perl
#   distribution
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 

package Text::Query::ParseSimple;

use strict;
use re qw/eval/;

use Text::Query::Parse;

use vars qw(@ISA);

@ISA = qw(Text::Query::Parse);

sub expression {
    my($self) = shift;

    my($t, $expr);
    foreach $t (@{$self->{'tokens'}}) {
	warn("t 0 = $t") if($self->{-verbose} > 1);

	my($type) = ($t =~ s/([-+\e])//) ? $1 : '';

	$t = $self->build_literal($t);
	
	if ($type eq '-') {
	    $t = $self->build_forbiden($t);
	} elsif($type eq '+') {
	    $t = $self->build_mandatory($t);
	}

	warn("t 1 = $t") if($self->{-verbose} > 1);
	
	$t = $self->build_expression_finish($t);

	warn("t 2 = $t") if($self->{-verbose} > 1);

	$expr = $expr ? $self->build_expression($expr, $t) : $t;
    }    

    return $expr;
}

sub parse_tokens {
    local($^W) = 0;
    my($self) = shift;
    my($line) = @_;
    my($quote, $quoted, $unquoted, $delim, $word);
    my($quotes) = $self->{parseopts}{-quotes};

    my(@tokens) = ();
    while (length($line)) {
	($quote, $quoted, undef, $unquoted, $delim, undef) =
	    $line =~ m/^([$quotes])                 # a $quote
                ((?:\\.|(?!\1)[^\\])*)    # and $quoted text
                \1 		       # followed by the same quote
                ([\000-\377]*)	       # and the rest
	       |                       # --OR--
                ^((?:\\.|[^\\$quotes])*?)    # an $unquoted text
	        (\Z(?!\n)|\s+|(?!^)(?=[$quotes])) # plus EOL, delimiter, or quote
                ([\000-\377]*)	       # the rest
	       /ix;		       # extended layout

	last unless($quote || length($unquoted) || length($delim));
	$line = $+;
	$unquoted=~s/^\s+//;
	$unquoted=~s/\s+$//;
	$word .= defined($quote) ? (length($word) ? $quoted : "\e$quoted" ) : $unquoted;
	push(@tokens,$word) if(length($word) and (length($delim) or !length($line)));
	undef $word if(length($delim));
    }

    warn("parsed tokens @tokens") if($self->{-verbose} > 1);

    $self->{'tokens'} = \@tokens;
}

1;

__END__

=head1 NAME

Text::Query::ParseSimple - Parse AltaVista simple query syntax

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseSimple',
                        -solve => 'Text::Query::SolveSimpleString',
                        -build => 'Text::Query::BuildSimpleString');


=head1 DESCRIPTION

This module provides an object that parses a string  
containing a Boolean query expression similar to an AltaVista "simple 
query". Elements of the query expression may be assigned weights.

It's base class is Text::Query::Parse;

Query expressions are compiled into an internal form when a new object is 
created or the C<prepare> method is called; they are not recompiled on each 
match.

Query expressions consist of words (sequences of non-whitespace)  
or phrases (quoted strings) separated by whitespace.  Words or phrases 
prefixed with a C<+> must be present for the expression to match; words or 
phrases prefixed with a C<-> must be absent for the expression to match.

Words or phrases may optionally be followed by a number in parentheses (no 
whitespace is allowed between the word or phrase and the parenthesized 
number).  This number specifies the weight given to the word or phrase.
If a weight is not given, a weight of 1 is assumed.

=head1 EXAMPLES

  use Text::Query;
  my $q=new Text::Query('+hello world',
                        -solve => 'Text::Query::SolveSimpleString',
                        -build => 'Text::Query::BuildSimpleString');
  die "bad query expression" if not defined $q;
  $count=$q->match;
  ...
  $q->prepare('goodbye adios -"ta ta"', -litspace=>1);
  #requires single space between the two ta's
  if ($q->match($line, -case=>1)) {
  #doesn't match "Goodbye"
  ...
  $q->prepare('\\bintegrate\\b', -regexp=>1);
  #won't match "disintegrated"
  ...
  $q->prepare('information(2) retrieval');
  #information has twice the weight of retrieval

=head1 SEE ALSO

Text::Query(3)
Text::Query::Parse(3)

=head1 AUTHORS

Eric Bohlman (ebohlman@netcom.com)

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
