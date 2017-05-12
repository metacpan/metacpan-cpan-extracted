package WWW::Search::Torrentz;

use 5.014000;
use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';
use parent qw/WWW::Search/;
use re '/s';

our $VERSION = '0.002';
our $MAINTAINER = 'Marius Gavrilescu <marius@ieval.ro>';

use WWW::Search::Torrentz::Result;

sub debug { say STDERR @_ } ## no critic (RequireCheckedSyscalls)

sub gui_query{ shift->native_query(@_) }

sub _native_setup_search{ ## no critic (ProhibitUnusedPrivateSubroutines)
	my ($self, $native_query, $options) = @_;
	$self->agent_email('marius@ieval.ro');
	$options //= {};
	my $base_url = $options->{search_url} // 'https://torrentz.eu/search';
	$self->{search_debug} = $options->{search_debug};
	$self->{_next_url} = "$base_url?f=$native_query";
	$self->user_agent->delay(2/60);
}

sub fullint ($) { int (shift =~ y/0-9//cdr) } ## no critic (ProhibitSubroutinePrototypes)

sub _parse_tree{ ## no critic (ProhibitUnusedPrivateSubroutines)
	my ($self, $tree) = @_;
	my $found = 0;

	my @potential_results = $tree->find('dl');
	my $result_count = $tree->find('h2')->as_text;
	if (defined $result_count && $result_count ne 'No Torrents Found') {
		$result_count =~ s/orrents.*//;
		$self->approximate_result_count(fullint $result_count);
	}

	for my $node (@potential_results) {
		my $a = $node->find('a');
		next unless defined $a;

		my $infohash = substr $a->attr('href'), 1;
		next unless $infohash =~ /^[a-f0-9]{40}$/;
		my $title = $a->as_text;
		my ($verified, $age, $size, $seeders, $leechers);
		$verified = 0;
		for my $span ($node->find('span')) {
			given($span->attr('class')){
				$verified = int ($span->as_text =~ /^\d+/) when 'v';
				$age = $span->as_text when 'a';
				$size = $span->as_text when 's';
				$seeders = fullint $span->as_text when 'u';
				$leechers = fullint $span->as_text when 'd';
			}
		}

		push @{$self->{cache}}, WWW::Search::Torrentz::Result->new(infohash => $infohash, title => $title, verified => $verified, age => $age, size => $size, seeders => $seeders, leechers => $leechers, ua => $self->user_agent);
		debug "infohash => $infohash, title => $title, verified => $verified, age => $age, size => $size, seeders => $seeders, leechers => $leechers" if $self->{search_debug};
		$found++;
	}

	my $url = $tree->look_down(rel => 'next');
	if (defined $url) {
		my $prev = $self->{_prev_url} =~ s{/[^/]+$}{}r;
		$self->{_next_url} = $prev . $url->attr('href')
	}
	debug "Found: $found" if $self->{search_debug};
	return $found;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Search::Torrentz - [DEPRECATED] search torrentz.eu with WWW::Search

=head1 SYNOPSIS

  use WWW::Search;
  my $search = WWW::Search->new('Torrentz');
  $search->gui_query('query');
  say $_->title while $_ = $search->next_result;

=head1 DESCRIPTION

This module is deprecated since L<https://torrentz.eu> was shut down
in August 2016.

WWW::Search::Torrentz is a subclass of WWW::Search that searches the
L<https://torrentz.eu> search aggregator.

To use this module, read the L<WWW::Search> documentation.

Search results are instances of the L<WWW::Search::Torrentz::Result> class.

Available optional L<WWW::Search> methods:

=over

=item B<gui_query>

Identical to B<native_query>.

=item B<approximate_result_count>

Returns the exact result count, as indicated by Torrentz.

=back

=head1 SEE ALSO

L<https://torrentz.eu/help>, L<WWW::Search>, L<WWW::Search::Torrentz::Result>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
