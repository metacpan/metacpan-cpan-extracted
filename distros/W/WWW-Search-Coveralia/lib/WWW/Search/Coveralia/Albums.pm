package WWW::Search::Coveralia::Albums;

use 5.014000;
use strict;
use warnings;
use parent qw/WWW::Search::Coveralia/;

our $VERSION = '0.001';

use WWW::Search::Coveralia::Result::Album;
use constant DEFAULT_URL => 'http://www.coveralia.com/mostrar_discos.php';

sub process_result{
	my ($self, $row) = @_;
	my $a = $row->find('a');
	my ($title, $artist, $year) = map { $_->as_text } $row->find('td');
	my $url = $self->absurl('', $a->attr('href'));
	WWW::Search::Coveralia::Result::Album->new($self, $url, $title, $artist, $year);
}

1;
__END__

=head1 NAME

WWW::Search::Coveralia::Albums - search for albums on coveralia.com with WWW::Search

=head1 SYNOPSIS

  use WWW::Search;
  my $search = WWW::Search->new('Coveralia::Albums');
  $search->native_query('query');
  # see WWW::Search documentation for details

=head1 DESCRIPTION

WWW::Search::Coveralia::Albums is a subclass of WWW::Search that searches for albums using the L<http://coveralia.com> cover art website.

To use this module, read the L<WWW::Search> documentation.

Search results are instances of the L<WWW::Search::Coveralia::Result::Album> Class.

=head1 SEE ALSO

L<http://coveralia.com>, L<WWW::Search>, L<WWW::Search::Coveralia::Artists>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
