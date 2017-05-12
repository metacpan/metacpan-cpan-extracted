#
#   Copyright (C) 1999 Eric Bohlman, Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/TextQuery/Text-Query-SQL/lib/Text/Query/BuildSQLFulcrum.pm,v 1.2 1999/07/01 11:32:11 loic Exp $
#
package Text::Query::BuildSQLFulcrum;

use strict;

use vars qw(@ISA $VERSION);

use Text::Query::BuildSQL;
use Carp;

@ISA = qw(Text::Query::BuildSQL);

sub resolve {
    my($self, $scope, $t) = @_;

    #
    # If the scope is not the scope of the enclosing
    # expression, the field must be explicitly specified.
    #
    my($fill_fields) = ( @{$scope} > 0 ) ? $$t[1] ne $scope->[0] : 1;

    if(!ref($$t[2]) || $$t[0] eq 'true') {
	return $self->resolve_literal($t, $fill_fields);
    } else {
	my(@operands);
	unshift(@{$scope}, $$t[1]);
	foreach (@{$t}[2..$#{$t}]) {
	    push(@operands, $self->resolve($scope, $_));
	}
	shift(@{$scope});

	my(%opmap) = (
		      'and' => '&',
		      'or' => '|'
		      );
	my($expr);
	#
	# If there is an homogenous scope, use compact form
	#
	if($$t[1]) {
	    if($opmap{$$t[0]}) {
		$expr = " ( " . join(" $opmap{$$t[0]} ", @operands) . " ) ";
	    } elsif($$t[0] eq 'not') {
		$expr = " ~ ( @operands ) ";
	    } elsif($$t[0] eq 'near') {
		my($max) = $self->{parseopts}{-near};
		$expr = " proximity $max characters ( " . join(" & ", @operands ) . " ) ";
	    }
	    #
	    # If this expression is not enclosed in an homogenous form
	    # resolve to explicit syntax
	    #
	    if($fill_fields) {
		return $self->fill_fields(" __FIELD__ contains $expr ", $$t[1]);
	    } else {
		#
		# Otherwise just return the compact form
		#
		return $expr;
	    }
	} else {
	    #
	    # We are not in homogenous scope, use explicit form
	    #
	    if($$t[0] eq 'or' or $$t[0] eq 'and') {
		return " ( " . join(" $$t[0] ", @operands) . " ) ";
	    } elsif($$t[0] eq 'not') {
		return " not ( @operands ) ";
	    }
	}
    }
}

sub has_relevance {
    shift->SUPER::has_relevance();
    return 1;
}

sub resolve_literal {
    my($self, $t, $fill_fields) = @_;

    my($true_value) = $$t[0] eq 'true';
    my($weight) = '';
    if($self->relevance_needed()) {
	#
	# At present relevance ranking is only needed for simple requests
	#
	if($true_value) {
	    #
	    # The 'true' value term has default weight (1)
	    #
	    $t = $$t[2];
	} else {
	    #
	    # All search terms have a 10 weight
	    #
	    $weight = ' weight 10';
	}
    }
    
    my($value) = " '" . $self->quote($$t[2]) . "'$weight ";

    if($fill_fields) {
	return $self->fill_fields(" __FIELD__ contains $value", $$t[1]);
    } else {
	#
	# If the enclosing expression has the same scope, the distribution
	# is delayed.
	#
	return $value;
    }
}

1;

__END__

=head1 NAME

Text::Query::BuildSQLFulcrum - Builder for Fulcrum SearchServer

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveSQL',
                        -build => 'Text::Query::BuildSQLFulcrum');


=head1 DESCRIPTION

Generates a well formed C<where> clause for Text::Query::ParseAdvanced or
Text::Query::ParseSimple suitable for query with Fulcrum SearchServer.

=head1 SEE ALSO

Text::Query(3)
Text::Query::BuildSQL(3)

=head1 AUTHORS

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
