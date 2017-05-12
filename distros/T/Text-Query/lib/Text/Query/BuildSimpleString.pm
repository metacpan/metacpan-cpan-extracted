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

package Text::Query::BuildSimpleString;

BEGIN {
  require 5.005;
}

use strict;
use re qw/eval/;

use vars qw(@ISA);

use Text::Query::Build;

@ISA = qw(Text::Query::Build);

sub build_init {
    my($self) = @_;

    $self->{'ws'} = 0;
    $self->{'mc'} = 0;
}

sub build_literal {
    my($self, $t) = @_;

    $self->{'weight'} = ($t =~ s/\((\d+)\)$//) ? $1 : 1;
    $self->{'m'} = 0;

    warn("build_literal 0 = $t") if($self->{-verbose} > 1);

    if(!$self->{parseopts}{-regexp}) {
	$t=quotemeta($t);
	$t=~s/\\\*/\\w*/g;
    } 
    $t =~ s/\\? +/\\s+/g if(!$self->{parseopts}{-litspace});
    $t = "\\b$t\\b" if($self->{parseopts}{-whole});
    $t = "(?:$t)" if($self->{parseopts}{-regexp});

    warn("build_literal 1 = $t") if($self->{-verbose} > 1);

    return $t;
}
    
sub build_forbiden {
    my($self, $t) = @_;

    $self->{'m'} = (~0);

    return $t;
}

sub build_mandatory {
    my($self, $t) = @_;

    $self->{'m'} = 1 << $self->{'mc'};
    $self->{'mc'} += 1;
    $self->{'ws'} |= $self->{'m'};

    return $t;
}

sub build_expression_finish {
    my($self, $t) = @_;

    return sprintf("%s(?{[%d,%d]})", $t, ~($self->{'m'}), $self->{'weight'});
}

sub build_expression {
    my($self, $l, $r) = @_;

    return "$l|$r";
}

sub build_final_expression {
  my ($self,$t)=@_;

  croak("match count > 31") if($self->{'mc'} > 31);

  $t = ($self->{parseopts}{-case} ? '' : '(?i)') . $t;

  $self->{matchstring} = qr/$t/s;

  return [ $self->{matchstring}, $self->{'ws'} ];
}

1;

__END__

=head1 NAME

Text::Query::BuildSimpleString - Builder for Text::Query::ParseSimple to build regexps

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('+hello +world',
                        -parse => 'Text::Query::ParseSimple',
                        -solve => 'Text::Query::SolveSimpleString',
                        -build => 'Text::Query::BuildSimpleString');


=head1 DESCRIPTION

Build a regexp to match the simple query parsed by Text::Query::ParseSimple.
The words of the query can be regular expressions and will provide the expected
result if the C<-regexp> option is set.

=head1 SEE ALSO

Text::Query(3)
Text::Query::Build(3)

=head1 AUTHORS

Eric Bohlman (ebohlman@netcom.com)

Loic Dachary (loic@senga.org)

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
