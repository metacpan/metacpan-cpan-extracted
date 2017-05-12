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
# $Header: /cvsroot/TextQuery/Text-Query-SQL/lib/Text/Query/SolveSQL.pm,v 1.4 2000/02/22 18:42:23 loic Exp $
#
package Text::Query::SolveSQL;

use strict;

use Text::Query::Solve;
use Carp;

use vars qw(@ISA);

@ISA = qw(Text::Query::Solve);

sub initialize {
}

sub match {
    my($self, $expr, $db) = @_;

    croak("db undefined") if(!defined($db));

    my($stmt) = $db->prepare($expr);
    croak("cannot prepare $expr : " . $db->errstr()) if(!$stmt);
    $stmt->execute() or croak("cannot execute $expr : " . $db->errstr());

    my(@result);
    my($hash_ref);
    while($hash_ref = $stmt->fetchrow_hashref()) {
	my($key, $value);
	while(($key, $value) = each(%$hash_ref)) {
	    $hash_ref->{$key} =~ s/\s+$//;
	}
	push(@result, $hash_ref);
    }
    $stmt->finish();

    return wantarray ? @result : \@result;    
}

sub matchscalar {
    return shift->match(@_);
}

1;

__END__

=head1 NAME

Text::Query::SolveSQL - Apply query expression to an SQL database

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('field1: ( hello and world )',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveSQL',
                        -build => 'Text::Query::BuildSQLFulcrum',
			-select => 'select * from t1 where __WHERE__');

  my $db = DBI->connect(undef, undef, undef);

  my @rows = $q->match($db);

=head1 DESCRIPTION

Applies a select order computed by a C<Text::Query> object whose builder is
derived from C<Text::Query::BuildSQL> to a C<DBI> object.

=head1 METHODS

=over 4

=item match (DB)

Applies the current select order to the database provided by the C<DB> argument and
returns a table of rows that match. Each row is a C<hashref>.

=head1 SEE ALSO

Text::Query(3)
Text::Query::Solve(3)

=head1 AUTHORS

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
