#
#   Copyright (C) 2000 Loic Dachary
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
# $Header: /cvsroot/TextQuery/Text-Query-SQL/lib/Text/Query/BuildSQLMifluz.pm,v 1.3 2000/04/12 16:35:40 loic Exp $
#
package Text::Query::BuildSQLMifluz;

use strict;

use Data::Dumper;

use vars qw(@ISA $VERSION);

use Text::Query::BuildSQL;
use Carp;

@ISA = qw(Text::Query::BuildSQL);

sub resolve {
    my($self, $scope, $t1) = @_;

    return $t1;
}

sub build_final_expression {
  my($self, $t1) = @_;

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

  $t1 = $self->Text::Query::Build::build_final_expression($t1);
  
  $self->relevance_reset();

  return $t1;
}

sub has_relevance {
    shift->SUPER::has_relevance();
    return 1;
}

sub sortplusminus {
    my($self, $t) = @_;

    return $t;
}

1;

__END__

=head1 NAME

Text::Query::BuildSQLMifluz - Builder for Mifluz

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveSQL',
                        -build => 'Text::Query::BuildSQLMifluz');


=head1 DESCRIPTION

Returns the syntax tree. Refer to the Text::Query::BuildSQL(3)
manual page for a description.

=head1 SEE ALSO

Text::Query(3)
Text::Query::BuildSQL(3)

=head1 AUTHORS

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
