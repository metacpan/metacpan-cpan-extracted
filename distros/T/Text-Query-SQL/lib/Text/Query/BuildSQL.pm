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
# $Header: /cvsroot/TextQuery/Text-Query-SQL/lib/Text/Query/BuildSQL.pm,v 1.9 2000/12/27 13:14:11 loic Exp $
#
package Text::Query::BuildSQL;

use strict;

use vars qw(@ISA $VERSION);

use Text::Query::Build;
use Carp;

$VERSION = "0.09";

@ISA = qw(Text::Query::Build);

sub build_final_expression {
  my ($self,$t1)=@_;

  my($opts) = $self->{parseopts};

  $t1 = $self->sortplusminus($t1);

#  show($t1); print "\n";

  if($$t1[1] eq '') {
      my($opts) = $self->{parseopts};
      if(!exists($opts->{'-fields_searched'})) {
	  croak("must specify -fields_searched");
      }
      $t1 = $self->build_scope_end([ $opts->{'-fields_searched'} ], $t1);
  }

#  show($t1); print "\n";

  $t1 = $self->resolve([], $t1);
  my($where);
  if($t1 =~ /__FIELD__/s) {
      #
      # Distribute the expression over all searched fields
      #
      if(!exists($opts->{'-fields_searched'})) {
	  croak("must specify -fields_searched");
      }
      $where = $self->fill_fields($t1, $opts->{'-fields_searched'});
  } else {
      $where = $t1;
  }

#  print "where = $where\n";

  my($select);
  if($opts->{'-select'}) {
      $select = $opts->{'-select'};
      $select =~ s/__WHERE__/ ( $where ) /s;
  } else {
      $select = " ( $where ) ";
  }

  $t1 = $self->SUPER::build_final_expression($select);
  
  $self->relevance_reset();

  return $t1;
}

#
# Print the query tree
#
sub show {
    my($t) = @_;

    print " [ $$t[0] '$$t[1]' ";
    if(!ref($$t[2])) {
	print $$t[2];
    } else {
	foreach (@{$t}[2..$#{$t}]) {
	    show($_);
	}
    }
    print " ] ";
}

sub build_expression {
  my($self, $l, $r) = @_;

  return $self->build_or_and($l, $r, 'or');
}

sub build_expression_finish {
  my($self, $l) = @_;

  return $l;
}

sub build_conj {
  my($self, $l, $r, $first) = @_;

  return $self->build_or_and($l, $r, 'and');
}

sub build_or_and {
  my($self, $l, $r, $op) = @_;

  my($same_scope) = $$l[1] eq $$r[1];
  my($scope) =  $same_scope ? $$l[1] : '';
  my(@operands);
  if($same_scope) {
      foreach ($l, $r) {
	  if($$_[0] eq $op) {
	      push(@operands, @{$_}[2..$#{$_}]);
	  } else {
	      push(@operands, $_);
	  }
      }
  } else {
      push(@operands, $l, $r);
  }
  return [ $op , $scope, @operands ];
}

sub build_near {
  my($self, $l, $r) = @_;

  if($$l[0] ne 'literal' || $$r[0] ne 'literal') {
      croak("cannot use near on non literal");
  } elsif($$l[1] ne $$r[1]) {
      croak("cannot use near with literals that does not belong to the same scope");
  } else {
      return [ 'near', '', $l, $r ];
  }
}

sub build_concat {
  my($self, $l, $r) = @_;

  #
  # If both literals are in the same scope, concat
  #
  if($$l[0] eq 'literal' &&
     $$l[0] eq $$r[0] &&
     $$l[1] eq $$r[1]) {
      return [ 'literal', $$l[1], "$$l[2] $$r[2]" ];
  } elsif($$l[0] eq 'not' &&
     $$l[0] eq $$r[0] &&
     $$l[1] eq $$r[1]) {
      return [ 'not', $$l[1], $self->build_concat($$l[2], $$r[2]) ];
  } else {
      croak("cannot concat two non literal or not");
  }
}

sub build_negation {
  my($self, $t) = @_;
  return [ 'not', $$t[1], $t ];
}

sub build_literal {
  my($self, $t) = @_;

  $t = [ 'literal', '', $t ];

  return $t;
}

sub build_mandatory {
    my($self, $t) = @_;

    return [ 'mandatory', '',  $t ];
}

sub build_forbiden {
    my($self, $t) = @_;

    return [ 'forbiden', '', $t ];
}


sub build_scope_start {
    my($self) = @_;
}

sub build_scope_end {
    my($self, $scope, $t) = @_;

    my($s);
    if($$t[0] ne 'literal') {
	$s = $self->scope_set($scope->[0], @{$t}[2..$#{$t}]) ? $scope->[0] : '';
    } else {
	$s = $scope->[0];
    }

    $$t[1] = $s;

    return $t;
}

#
# Distribute $scope to @ts elements that do not already have
# a scope.
# Return 1 if all elements in @ts have the same scope.
# Return 1 if at least one element in @ts has a scope different from $scope
#
sub scope_set {
    my($self, $scope, @ts) = @_;

    my($homogenous) = 1;
    foreach (@ts) {
	next if($$_[1] eq $scope);
	if($$_[1] ne '') {
	    $homogenous = 0;
	} else {
	    if($$_[0] eq 'literal') {
		$$_[1] = $scope;
	    } else {
		if($self->scope_set($scope, @{$_}[2..$#{$_}])) {
		    #
		    # Even if scope is homogenous, near requires scope
		    # specification in Fulcrum.
		    #
		    if($$_[0] eq 'near') {
			$homogenous = 0;
		    }
		    $$_[1] = $scope;
		} else {
		    $homogenous = 0;
		}
	    }
	}
    }

    return $homogenous;
}

sub relevance_needed {
    return exists(shift->{'need_relevance'});
}

sub relevance_reset {
    delete(shift->{'need_relevance'});
}

sub has_relevance {
    shift->{'need_relevance'} = 1;
    return undef;
}

sub sortplusminus {
    my($self, $t) = @_;

    $self->{'mandatory'} = [];
    $self->{'forbiden'} = [];
    $self->{'optional'} = [];

    $self->sortplusminus_1($t);

    if(@{$self->{'mandatory'}} > 0 ||
       @{$self->{'forbiden'}} > 0) {
	my($scope) = $$t[1];
	my(@tmp);
	if(@{$self->{'mandatory'}} > 0) {
	    push(@tmp, @{$self->{'mandatory'}});
	}
	if(@{$self->{'forbiden'}} > 0) {
	    push(@tmp, [ 'not', $scope, [ 'or', $scope, @{$self->{'forbiden'}} ] ]);
	}
	if(@{$self->{'optional'}} > 0) {
	    my(@true) = $self->has_relevance() && @{$self->{'mandatory'}} > 0 ? [ 'true', $scope, $self->{'mandatory'}->[0] ] : ();
	    push(@tmp, [ 'or', $scope, @{$self->{'optional'}}, @true ]);
	}
	$t = [ 'and', $scope, @tmp ];
    }

    delete($self->{'mandatory'});
    delete($self->{'forbiden'});
    delete($self->{'optional'});

    return $t;
}

sub sortplusminus_1 {
    my($self, $t) = @_;

    if(!ref($$t[2])) {
	push(@{$self->{'optional'}}, $t);
    } else {
	if($$t[0] eq 'mandatory') {
	    push(@{$self->{'mandatory'}}, $$t[2]);
	} elsif($$t[0] eq 'forbiden') {
	    push(@{$self->{'forbiden'}}, $$t[2]);
	} else {
	    foreach (@{$t}[2..$#{$t}]) {
		$self->sortplusminus_1($_);
	    }
	}
    }
}

#
# Utility functions
#
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
    return @t == 1 ? $t[0] : "( " . join(" ) or ( ", @t) . " )";
}

sub quote {
    my($self, $value) = @_;

    $value =~ s/\'/\'\'/g;

    return $value;
}

1;

__END__

=head1 NAME

Text::Query::BuildSQL - Base class for SQL query builders

=head1 SYNOPSIS

    package Text::Query::BuildSQLsqldb;

    use Text::Query::BuildSQL;
    
    use vars qw(@ISA);

    @ISA = qw(Text::Query::BuildSQL);

=head1 DESCRIPTION

Defines all the C<build_*> functions to build a syntax tree. The tree nodes
are [ operator scope operand operand... ]. The C<build_final_expression> function
translate the syntax tree in a C<where> clause using the C<resolve> method.
If the scope of the search is not specified (simple query or advanced query without
scope operator), the scope is set to the list of comma separated fields provided
by the C<-fields_searched> option.
The resulting C<where> clause is placed in the C<select> order provided with
the C<-select> option, if any.

=head1 SYNTAX TREE

The string enclosed in single quotes must match exactly. The <string> 
token stands for an arbitrary string. A description enclosed in [something ...]
means repeated 0 or N times.

 expr: 'or' scope expr [expr ...]
       'and' scope expr [expr ...]
       'not' scope expr
       'near' scope expr_literal expr_literal
       'forbiden' scope expr_literal [expr_literal ...]
       'mandatory' scope expr_literal [expr_literal ...]
       'optional' scope expr_literal [expr_literal ...]
       'literal' scope <string>

 expr_literal: literal scope <string>

 scope: <string>

=head1 METHODS

=over 4

=item resolve([], Q1)

Returns a C<where> clause string corresponding to the C<Q1> syntax tree.

=item sortplusminus([], Q1)

Translate the C<mandatory> and C<forbiden> syntactic nodes to their boolean 
equivalents. If it C<has_relevance> returns false and
there is at least one C<mandatory> word, the first C<mandatory> word
is added to the list of C<optional> words. 

=item has_relevance()

Returns true if relevance ranking is possible, false if not. It
is used by the C<sortplusminus> function. Returns false by default.

If relevance ranking is not possible, the semantic of the simple
search is slighthly modified. When asking for C<+a b c> it shows
all the documents containing C<a> and (C<b> or C<c>). 

The normal behaviour is to return all the documents containing C<a>
and to sort them to show first those containing (C<b> or C<c>). When
relevance ranking is not available the C<b>, C<c> search terms are
therefore useless. That is why we decided to change the semantic
of the query if no relevance ranking is available.

=back

=head1 OPTIONS

=over 4

=item -select STRING

If provided the string returned by C<build_final_expression> substitutes the
C<__WHERE__> tag with the C<where> string generated by the C<resolve> function.
The substituted string is the return value of the C<build_final_expression>.

If not set the return value of the C<build_final_expression> is the result
of the C<resolve> function.

=item -fields_searched FIELDS_LIST

C<FIELDS_LIST> is a list of comma separated field names. It is used as the
default scope if no scope is provided in the query string. The C<build_final_expression>
function will C<croak> if this option is not provided and no scope operator 
were used.

=back

=head1 SEE ALSO

Text::Query(3)
Text::Query::Build(3)

=head1 AUTHORS

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
