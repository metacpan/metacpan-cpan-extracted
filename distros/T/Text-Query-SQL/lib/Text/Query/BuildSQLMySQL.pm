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
# $Header: /cvsroot/TextQuery/Text-Query-SQL/lib/Text/Query/BuildSQLMySQL.pm,v 1.4 2000/05/03 13:16:19 loic Exp $
#
package Text::Query::BuildSQLMySQL;

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
      if(!$self->{parseopts}{-encoding} =~ /^big5$/io) {
	  $t = "$$l[2]%$$r[2]";
      } else {
	  my($max) = $self->{parseopts}{-near};
	  my($op) = "([[:space:]]+[[:alnum:]]+){0,$max}[[:space:]]+";
	  $t = "($$l[2]$op$$r[2])|($$r[2]$op$$l[2])";
      }
      return [ 'literal', $$l[1], $t ];
  }
}

sub build_literal {
  my($self, $t) = @_;

  if(!$self->{parseopts}{-encoding} =~ /^big5$/io) {
      $t = $self->quote($t);
  } else {
      $t = $self->string2word($t);
  }

  $t = [ 'literal', '', $t ];

  return $t;
}

sub resolve {
    my($self, $scope, $t) = @_;

    my($fill_fields) = ( @{$scope} > 0 ) ? $$t[1] ne $scope->[0] : 1;

    if(!ref($$t[2])) {
	return $self->resolve_literal($t, $fill_fields);
    } else {
	my(@operands);
	unshift(@{$scope}, $$t[1]);
	foreach (@{$t}[2..$#{$t}]) {
	    push(@operands, $self->resolve($scope, $_));
	}
	shift(@{$scope});

	my($expr);
	if($$t[0] eq 'or' or $$t[0] eq 'and') {
	    $expr = " ( " . join(" $$t[0] ", @operands) . " ) ";
	} elsif($$t[0] eq 'not') {
	    $expr = " not ( @operands ) ";
	}
	croak("undefined expr for $$t[0] $$t[1] @operands") if(!defined($expr));

#	print "expr = (fill $fill_fields) $expr\n";
	return $fill_fields ? $self->fill_fields($expr, $$t[1]) : $expr;
    }
}

sub resolve_literal {
    my($self, $t, $fill_fields) = @_;

    my($value);
    if(!$self->{parseopts}{-encoding} =~ /^big5$/io) {
	$value = "__FIELD__ like '%" . $$t[2] . "%'";
    } else {
	$value = "__FIELD__ regexp '[[:<:]]" . $$t[2] . "[[:>:]]'";
    }

    return $fill_fields ? $self->fill_fields($value, $$t[1]) : $value;
}

#
# Translate a string to regexp according to case sensitivity 
#
sub string2word {
    my($self, $string) = @_;

    if(!$self->{parseopts}{-case}) {
	my($encoding) = $self->{parseopts}{-encoding};
	if(!defined($encoding) ||
	   $encoding =~ /^(iso-latin|iso-8859)/io) {
	    $string = lc($string);
	    $string =~ s/([a-z])/\[$1\u$1\]/g;
	}
    }
    return $string;
}

1;

__END__

=head1 NAME

Text::Query::BuildSQLMySQL - Builder for MySQL

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveSQL',
                        -build => 'Text::Query::BuildSQLMySQL');


=head1 DESCRIPTION

Generates a well formed C<where> clause for Text::Query::ParseAdvanced or
Text::Query::ParseSimple suitable for query with MySQL.

=head1 OPTIONS

=over 4

=item -encoding STRING

The encoding of the strings in the MySQL database. If the encoding contains
C<BIG5> the strategy used to match is slightly different.

=back

=head1 SEE ALSO

Text::Query(3)
Text::Query::BuildSQL(3)

=head1 AUTHORS

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
