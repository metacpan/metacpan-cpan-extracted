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

package Text::Query::BuildAdvancedString;

use strict;

use vars qw(@ISA $VERSION);

use Text::Query::Build;

@ISA = qw(Text::Query::Build);

sub build_init {
    my($self) = @_;
}

sub build_final_expression {
    my($self, $t1) = @_;
    my($t);
    $t = ($self->{parseopts}{-case}) ? '' : '(?i)';

    $self->{matchstring} = "$t$t1";

    return eval("sub { \$_[0] =~ /$t$t1/s; }")
}

sub build_expression {
    my($self, $l, $r) = @_;
    #factor any common "^" out of the disjunction
    #This really speeds up matching
    if(substr($l,0,1) eq '^' and substr($r,0,1) eq '^') {
	return '^(?:'.substr($l,1).'|'.substr($r,1).')';
    } else {
	return "$l|$r";
    }
}

sub build_expression_finish {
    my($self, $l) = @_;
    return "(?:$l)";
}

sub build_conj {
    my($self, $l, $r, $first) = @_;
    $l = "^(?=.*$l)" if($first);
    return "$l(?=.*$r)";
}

sub build_near {
    my($self, $l, $r)=@_;
    my($t1) = $self->{parseopts}{-near} || '';
    return "(?:$l\\s*(?:\\S+\\s+){0,$t1}$r)|(?:$r\\s*(?:\\S+\\s+){0,$t1}$l)";
}

sub build_concat {
    my($self, $l, $r) = @_;
    return "(?:$l\\s*$r)";
}

sub build_negation {
    my($self, $t) = @_;
    return "(?:^(?:(?!$t).)*\$)";
}

sub build_literal {
    my($self, $t) = @_;

    if(!$self->{parseopts}{-regexp}) {
	$t = quotemeta($t);
	$t =~ s/\\\*/\\w*/g;
    }

    $t =~ s/\\? +/\\s+/g if(!$self->{parseopts}{-litspace});
    $t = "\\b$t\\b" if($self->{parseopts}{-whole});
    $t = "(?:$t)" if($self->{parseopts}{-regexp});

    warn("build_literal 1 = $t") if($self->{-verbose} > 1);

    return $t;
}

sub build_scope_start {
    my ($self)=@_;
}

sub build_scope_end {
    my ($self, $scope, $t)=@_;

    return $t;
}

1;

__END__

=head1 NAME

Text::Query::BuildAdvancedString - Builder for Text::Query::ParseAdvanced to build regexps

=head1 SYNOPSIS

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveAdvancedString',
                        -build => 'Text::Query::BuildAdvancedString');


=head1 DESCRIPTION

Build a regexp to match the advanced query parsed by Text::Query::ParseAdvanced.
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
