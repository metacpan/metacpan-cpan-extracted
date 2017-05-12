package WWW::Search::Coveralia::Artists;

use 5.014000;
use strict;
use warnings;
use parent qw/WWW::Search::Coveralia/;

our $VERSION = '0.001';

use WWW::Search::Coveralia::Result::Artist;
use constant DEFAULT_URL => 'http://www.coveralia.com/mostrar_artistas.php';

sub process_result{
	my ($self, $row) = @_;
	my $a = $row->find('a');
	my ($id) = $a->attr('href') =~ m,/([^/]+)\.php$,;
	WWW::Search::Coveralia::Result::Artist->new($self, $id, $a->as_text);
}

1;
__END__

=head1 NAME

WWW::Search::Coveralia::Artists - search for artists on coveralia.com with WWW::Search

=head1 SYNOPSIS

  use WWW::Search;
  my $search = WWW::Search->new('Coveralia::Artists');
  $search->native_query('query');
  # see WWW::Search documentation for details

=head1 DESCRIPTION

WWW::Search::Coveralia::Artists is a subclass of WWW::Search that searches for artists using the L<http://coveralia.com> cover art website.

To use this module, read the L<WWW::Search> documentation.

Search results are instances of the L<WWW::Search::Coveralia::Result::Album> Class.

=head1 SEE ALSO

L<http://coveralia.com>, L<WWW::Search>, L<WWW::Search::Coveralia::Albums>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
