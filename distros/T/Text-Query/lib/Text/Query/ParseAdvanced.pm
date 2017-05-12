#
#   Copyright (C) 1999 Eric Bohlman, Loic Dachary
#   Copyright (C) 2013 Jon Jensen
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

package Text::Query::ParseAdvanced;

use strict;

use Carp;
use Text::Query::Parse;

use vars qw(@ISA);

@ISA = qw(Text::Query::Parse);

sub prepare {
    my($self) = shift;
    my($qstring) = shift;
    my(%args) = @_;

    my $default_operators = {
	'or' => 'or',
	'and' => 'and',
	'near' => 'near',
	'not' => 'not',
    };

    $self->{'scope_map'} = $args{-scope_map} || {};

    return $self->SUPER::prepare($qstring, -near=>10, -operators=>$default_operators, @_);
}

sub expression($) {
    my($self) = shift;
    my($rv, $t);
    my($or) = $self->{parseopts}{-operators}{or};
    my($tokens) = $self->{'tokens'};
    $self->{'token'} = shift(@$tokens);
    $rv = $self->conj();
    while(defined($self->{'token'}) and $self->{'token'} =~ /^($or|\|)$/i) {
	$self->{'token'} = shift(@{$self->{'tokens'}});
	$t= $self->conj();
	$rv = $self->build_expression($rv,$t);
    }
    return $self->build_expression_finish($rv); 
}

sub conj($) {
    my($self) = shift;
    my($rv);
    my($first) = 1;
    my($and) = $self->{parseopts}{-operators}{and};
    $rv = $self->concat();
    while(defined($self->{'token'}) and $self->{'token'} =~ /^($and|&)$/i) {
	$self->{'token'} = shift(@{$self->{'tokens'}});
	$rv = $self->build_conj($rv, concat($self), $first);
	$first=0;
    }
    return $rv;
}

sub concat($) {
    my($self) = shift;
    my($rv,$t,$l);
    my($not) = $self->{parseopts}{-operators}{not};
    my($near) = $self->{parseopts}{-operators}{near};
    $rv = factor($self);
    while(defined($self->{'token'}) and ($l = $self->{'token'}) =~ /^\e|([\(!\~]|$not|$near)$/i) {
	$self->{'token'} = shift(@{$self->{'tokens'}}) if($l =~ /^($near|\~)$/i);
	$t = factor($self);
	if($l =~ /^($near|\~)$/i) {
	    $rv = $self->build_near($rv, $t);
	} else {
	    $rv = $self->build_concat($rv, $t);
	}
    }
    return $rv;
}

sub factor($) {
    my($self) = shift;

    my($rv,$t);
    my($not) = $self->{parseopts}{-operators}{not};
    if(!defined($t = $self->{'token'})) {
	croak("out of token in factor");
    } elsif($t eq '(') {
	$rv = $self->expression();
	if(defined($self->{'token'}) and $self->{'token'} eq ')') {
	    $self->{'token'} = shift(@{$self->{'tokens'}});
	} else {
	    croak("missing closing parenthesis in factor");
	}
    } elsif($t =~ /^($not|!)$/i) {
	$self->{'token'} = shift(@{$self->{'tokens'}});
	$rv = $self->build_negation($self->factor());
    } elsif($t =~ s/^\e//) {
	$rv = $self->build_literal($t);
	$self->{'token'} = shift(@{$self->{'tokens'}});
    } elsif($t =~ s/:$//) {
	$self->{'token'} = shift(@{$self->{'tokens'}});
	unshift(@{$self->{'scope'}}, ($self->{'scope_map'}{$t} || $t));
	$self->build_scope_start();
	$rv = $self->build_scope_end($self->factor());
	shift(@{$self->{'scope'}});
    } else {
	croak("unexpected token $t in factor");
    }
    return $rv;
}

sub parse_tokens {
    local($^W) = 0;
    my($self) = shift;
    my($line) = @_;
    my($quote, $quoted, $unquoted, $delim, $word);
    my($quotes) = $self->{parseopts}{-quotes};
    my($operators) = join("|", values(%{$self->{parseopts}{-operators}}));
    my(@tokens) = ();

    warn("quotes = $quotes") if($self->{-verbose} > 1);
    while(length($line)) {
	($quote, $quoted, undef, $unquoted, $delim, undef) =
	    $line =~ m/^([$quotes])                 # a $quote
                ((?:\\.|(?!\1)[^\\])*)    # and $quoted text
                \1 		       # followed by the same quote
                ([\000-\377]*)	       # and the rest
	       |                       # --OR--
                ^((?:\\.|[^\\$quotes])*?)    # an $unquoted text
	        (\Z(?!\n)|(?:\s*([()|&!\~]|\b(?:$operators)\b|\b(?:[-,_\.\w]+\:))\s*)|(?!^)(?=[$quotes])) # plus EOL, delimiter, or quote
                ([\000-\377]*)	       # the rest
	       /ix;		       # extended layout

	warn("quote = $quote") if($self->{-verbose} > 1 && $quote);
	last unless($quote || length($unquoted) || length($delim));
	$line = $+;
	$unquoted =~ s/^\s+//;
	$unquoted =~ s/\s+$//;
	$word .= defined($quote) ? $quoted : $unquoted;
	warn("word = $word") if($self->{-verbose} > 1 and (length($word) and (length($delim) or !length($line))));
	push(@tokens,"\e$word") if(length($word) and (length($delim) or !length($line)));
	$delim =~ s/^\s+//;
	$delim =~ s/\s+$//;
	warn("delim = $word") if($self->{-verbose} > 1 and length($delim));
	push(@tokens, $delim) if(length($delim));
	undef $word if(length($delim));
    }

    warn("parsed tokens @tokens") if($self->{-verbose} > 1);

    $self->{'tokens'} = \@tokens;
}

1;

__END__

=head1 NAME

Text::Query::ParseAdvanced - Parse AltaVista advanced query syntax

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveAdvancedString',
                        -build => 'Text::Query::BuildAdvancedString');


=head1 DESCRIPTION

This module provides an object that parses a string  
containing a Boolean query expression similar to an AltaVista "advanced 
query".

It's base class is Text::Query::Parse;

Query expressions consist of literal strings (or regexps) joined by the 
following operators, in order of precedence from lowest to highest:

=over 4

=item OR, |

=item AND, &

=item NEAR, ~

=item NOT, !

=back

Operator names are not case-sensitive.  Note that if you want to use a C<|> 
in a regexp, you need to backwhack it to keep it from being seen as a query 
operator.  Sub-expressions may be quoted in single or double quotes to 
match "and," "or," or "not" literally and may be grouped in parentheses 
(C<(, )>) to alter the precedence of evaluation.

A parenthesized sub-expression may also be concatenated with other sub- 
expressions to match sequences: C<(Perl or Python) interpreter> would match 
either "Perl interpreter" or "Python interpreter".  Concatenation has a 
precedence higher than NOT but lower than AND.  Juxtaposition of 
simple words has the highest precedence of all.

=head1 OPTIONS

These are the additional options of the C<prepare> method and the constructor.

=over 4

=item -near defaults to 10

Sets the number of words that can occur between two expressions 
and still satisfy the NEAR operator.

=item -operators defaults to and, or, not, near

Sets the operator names. The argument of the option is a pointer to a
hash table mapping the default names to desired names. For instance:

    {
	'or' => 'ou',
	'and' => 'et',
	'near' => 'proche',
	'not' => 'non',
    }

=item -scope_map default to {}

Map the scope names to other names. If a scope is specified as C<scope:>
search the map for an entry whose key is C<scope> and replace C<scope> with
the scalar found. For instance:

     {
	 'scope' => 'otherscope'
     }

=back

=head1 SEE ALSO

Text::Query(3)
Text::Query::Parse(3)

=head1 AUTHORS

Eric Bohlman (ebohlman@netcom.com)

Loic Dachary (loic@senga.org)

Jon Jensen, jon@endpoint.com

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
