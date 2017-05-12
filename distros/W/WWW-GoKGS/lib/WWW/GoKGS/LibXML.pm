package WWW::GoKGS::LibXML;
use strict;
use warnings;
use parent qw/WWW::GoKGS/;
use HTML::TreeBuilder::LibXML;

our $VERSION = '0.21';

sub _tree_builder_class { 'HTML::TreeBuilder::LibXML' }

1;

__END__

=head1 NAME

WWW::GoKGS::LibXML - HTML::TreeBuilder::LibXML-based WWW::GoKGS

=head1 SYNOPSIS

  use WWW::GoKGS::LibXML;
  my $gokgs = WWW::GoKGS::LibXML->new(...);

=head1 DESCRIPTION

This class inherits all methods from L<WWW::GoKGS>.
Unlike C<WWW::GoKGS>, this class uses L<HTML::TreeBuilder::LibXML>
instead of L<HTML::TreeBuilder::XPath> to parse HTML documents.
Make sure to install the alternative module in addition to this module.

=head1 SEE ALSO

L<WWW::GoKGS>, L<HTML::TreeBuilder::LibXML>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

