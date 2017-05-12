package WWW::Search::Coveralia;

use 5.014000;
use strict;
use warnings;
use parent qw/WWW::Search/;

our $VERSION = '0.001';
our $MAINTAINER = 'Marius Gavrilescu <marius@ieval.ro>';

sub DEFAULT_URL;
sub process_result;

sub _native_setup_search{
	my ($self, $native_query, $options) = @_;
	$self->agent_email('marius@ieval.ro');
	$options //= {};
	my $base_url = $options->{search_url} // $self->DEFAULT_URL;
	$self->{search_debug} = $options->{search_debug};
	$self->{_next_url} = "$base_url?bus=$native_query";
	$self->user_agent->delay(10/60); # Crawl-Delay: 10 in robots.txt
}

sub _parse_tree {
	my ($self, $tree) = @_;
	my $found = 0;

	my $result_table = $tree->look_down(class => 'mostrar');
	return unless $result_table;
	my @results = $result_table->find('tbody')->find('tr');
	for (@results) {
		my $result = $self->process_result($_);
		push @{$self->{cache}}, $result;
		say STDERR 'Title: ', $result->title, ' URL: ', $result->url if $self->{search_debug};
		$found++;
	}

	my $url = $tree->look_down(rel => 'next');
	$self->{_next_url} = $self->absurl($self->{_prev_url}, $url->attr('href')) if defined $url;

	say STDERR "Found: $found" if $self->{search_debug};
	say STDERR 'Next URL: ', $self->{_next_url} if $self->{search_debug} && $self->{_next_url};
	$found
}

1;
__END__

=head1 NAME

WWW::Search::Coveralia - search coveralia.com with WWW::Search

=head1 SYNOPSIS

  use WWW::Search;
  my $search = WWW::Search->new('Coveralia::Artists'); # or Coveralia::Albums
  $search->native_query('query');
  # see WWW::Search documentation for details

=head1 DESCRIPTION

WWW::Search::Coveralia is a subclass of WWW::Search that searches the L<http://coveralia.com> cover art website.

This module is the backend for L<WWW::Search::Coveralia::Artists> and L<WWW::Search::Coveralia::Albums> and should not be used directly. Read the documentation of those two modules for usage information.

=head1 SEE ALSO

L<http://coveralia.com>, L<WWW::Search>, L<WWW::Search::Coveralia::Artists>, L<WWW::Search::Coveralia::Albums>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
