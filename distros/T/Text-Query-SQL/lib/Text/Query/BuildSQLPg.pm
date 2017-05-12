#
#   Copyright (C) 2000 Benjamin Drieu
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
# $Header: /cvsroot/TextQuery/Text-Query-SQL/lib/Text/Query/BuildSQLPg.pm,v 1.1 2000/03/21 14:10:48 benj2 Exp $
#
package Text::Query::BuildSQLPg;

use strict;

use vars qw(@ISA $VERSION);

use Text::Query::BuildSQL;
use Carp;

@ISA = qw(Text::Query::BuildSQL);


sub build_near {
  my($self, $l, $r) = @_;

  if($$l[0] ne 'literal' || $$r[0] ne 'literal') {
      croak("cannot use near on non literal");
  } elsif($$l[1] ne $$r[1]) {
      croak("cannot use near with literals that does not belong to the same scope");
  } else {
      my($t);
#      if(!$self->{parseopts}{-encoding} =~ /^big5$/io) {
#	  $t = "$$l[2]%$$r[2]";
#     } else {
	  my($max) = $self->{parseopts}{-near};
	  my($op) = "[^a-z0-9]{0,$max}";
	  $t = "$$l[2]$op$$r[2]";
#      }
      return [ 'literal', $$l[1], $t ];
  }
}

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
		      'and' => 'and',
		      'or' => 'or'
		      );
	my($expr);
	#
	# If there is an homogenous scope, use compact form
	#
	if($$t[1]) {
	    if($opmap{$$t[0]}) {
		$expr = " ( " . join(" $opmap{$$t[0]} ", @operands) . " ) ";
	    } elsif($$t[0] eq 'not') {
		$expr = "not (@operands)";
	    } elsif($$t[0] eq 'near') {
		my($max) = $self->{parseopts}{-near};
		$expr = "( " . join(" & ", @operands ) . " ) ";
	    }
	    #
	    # If this expression is not enclosed in an homogenous form
	    # resolve to explicit syntax
	    #
	    if($fill_fields) {
		return $self->fill_fields($expr, $$t[1]);
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
		return "not (@operands) ";
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
#	    $weight = ' weight 10';
	}
    }
    
    my($value) = "'[[:<:]]" . $self->quote($$t[2]) . "[[:>:]]'";

#    if($fill_fields) {
	return $self->fill_fields("__FIELD__ ~* $value", $$t[1]);
#    } else {
	#
	# If the enclosing expression has the same scope, the distribution
	# is delayed.
	#
#	return $value;
#    }
}



sub fill_fields {
    my($self, $t, $fields) = @_;

    return $t if($t !~ /__FIELD__/o);

    my(@t);
    my($scope);
    foreach $scope (split(',', $fields)) {
	my($tmp) = $t;
	$tmp =~ s/__FIELD__/$scope/g;
	push(@t, $tmp);
    }
    return @t == 1 ? $t[0] : "( ( " . join(" ) or ( ", @t) . " ) )";
}


1;

__END__

=head1 NAME

Text::Query::BuildSQLPg - Builder for Postgres

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveSQL',
                        -build => 'Text::Query::BuildSQLPg');


=head1 DESCRIPTION

Generates a well formed C<where> clause for Text::Query::ParseAdvanced or
Text::Query::ParseSimple suitable for query with Postgres.

Code is mainly based on Text:Query::BuildSQLMySQL.

=head1 SEE ALSO

Text::Query(3)
Text::Query::BuildSQL(3)

=head1 AUTHORS

Benjamin Drieu (bdrieu@april.org)

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
