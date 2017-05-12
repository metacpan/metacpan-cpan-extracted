# $Id: XSH.pm,v 1.1 2003/09/08 15:53:09 pajas Exp $

package Inline::XSH;

use vars qw($VERSION $terminator);

use strict;
use XML::XSH qw();
$VERSION = '0.1';
$terminator = undef;

use Filter::Simple;

sub filter {
  my $t=defined($terminator) ? $terminator : '__END__';
  s/$terminator\s*$// if defined($terminator);
  $_="XML::XSH::xsh(<<'$t');\n".$_."$t\n";
  $_;
};

#sub import {
#  if (@_>1) {
#    $terminator = $_[1];
#    FILTER { filter() } $terminator;
#  }
#}

FILTER(\&filter);

1;

=head1 NAME

Inline::XSH - Insert XSH commands directly into your Perl scripts

=head1 SYNOPSIS

   # perl code

   use Inline::XSH;

   # XSH Language commands (see L<XSH>)

   no Inline::XSH;

   # perl code

=head1 REQUIRES

Filter::Simple, XML::LibXML, XML::XUpdate::LibXML, XML::XSH

=head1 EXPORTS

None.

=head1 AUTHOR

Petr Pajas, pajas@matfyz.cz

=head1 SEE ALSO

L<xsh>, L<XSH>, L<XML::XSH>

=cut
