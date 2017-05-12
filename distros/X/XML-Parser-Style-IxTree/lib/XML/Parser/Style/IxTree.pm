#
# (C) 2012 Igor Afanasyev <igor.afanasyev@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Code mostly based on original XML::Parser::Style::Tree
# v 1.2 2003/07/31 07:54:51, (C) Matt Sergeant <matt@sergeant.org>

package XML::Parser::Style::IxTree;
$XML::Parser::Built_In_Styles{IxTree} = 1;

our $VERSION = '1.0';

use Tie::IxHash;

sub Init {
  my $expat = shift;
  $expat->{Lists} = [];
  $expat->{Curlist} = $expat->{Tree} = [];
}

sub Start {
  my $expat = shift;
  my $tag = shift;

  my %h;
  tie(%h, Tie::IxHash, @_);
  my $newlist = [ \%h ];
  push @{ $expat->{Lists} }, $expat->{Curlist};
  push @{ $expat->{Curlist} }, $tag => $newlist;
  $expat->{Curlist} = $newlist;
}

sub End {
  my $expat = shift;
  my $tag = shift;
  $expat->{Curlist} = pop @{ $expat->{Lists} };
}

sub Char {
  my $expat = shift;
  my $text = shift;
  my $clist = $expat->{Curlist};
  my $pos = $#$clist;

  if ($pos > 0 and $clist->[$pos - 1] eq '0') {
    $clist->[$pos] .= $text;
  } else {
    push @$clist, 0 => $text;
  }
}

sub Final {
  my $expat = shift;
  delete $expat->{Curlist};
  delete $expat->{Lists};
  $expat->{Tree};
}

1;
__END__

=head1 NAME

XML::Parser::Style::IxTree - Maintain tag attribute ordering when parsing XML into a tree

=head1 SYNOPSIS

  use XML::Parser;
  my $p = XML::Parser->new(Style => 'IxTree');
  my $tree = $p->parsefile('foo.xml');

=head1 DESCRIPTION

This module implements XML::Parser's IxTree style parser
(same as 'XML::Parser::Style::Tree', but it keeps tag attributes
in their original order, thanks to Tie::IxHash).
This allows to parse and then reconstruct the original
document with respect to original attribute ordering).

Tree Parser on CPAN:
http://search.cpan.org/~msergeant/XML-Parser/Parser/Style/Tree.pm

Tie::IxHash on CPAN:
http://search.cpan.org/~chorny/Tie-IxHash/

=cut
