package Text::Keywords::Container;
BEGIN {
  $Text::Keywords::Container::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Text::Keywords::Container::VERSION = '0.900';
}
# ABSTRACT: Class for a container of serveral Text::Keywords::List

use 5.010;
use Moo;
use Text::Keywords::Found;

has lists => (
	is => 'ro',
	required => 1,
);

has shuffle => (
	is => 'ro',
	default => sub { 1 },
);

has use_secondary => (
	is => 'ro',
	default => sub { 1 },
);

has params => (
	is => 'ro',
	default => sub {{}},
);

sub find_keywords {
	my ( $self, $primary, $secondary ) = @_;
	$primary = $secondary if !$primary;
	return () if !$primary;
	my @founds;
	my @keywordlists;
	my $klpos = 0;
	for (@{$self->lists}) {
		push @keywordlists, [ $_, $_->count ];
	}
	while (@keywordlists) {
		my $klcount = scalar @keywordlists;
		my $idx = $klpos % $klcount;
		my $kl = $keywordlists[$idx];
		$klpos++;
		for my $keyword (@{$kl->[0]->keywords}[$kl->[0]->count - $kl->[1],$kl->[0]->count - 1]) {
			$kl->[1]--;
			my $found;
			splice(@keywordlists, $idx, 1) if (!$kl->[1]);
			my $rx = qr/(?:^|[^\w]|_)($keyword)(?:$|[^\w]|_)/i;
			my @text_found;
			my $primary_str = $primary;
			push (@text_found, [$primary_str =~ $rx]), $primary_str =~ s{$rx}{} while $primary_str =~ $rx;
			my @secondary_found;
			if ($secondary && $self->use_secondary) {
				my $con_str = $secondary;
				push (@secondary_found, [$con_str =~ $rx]), $con_str =~ s{$rx}{} while $con_str =~ $rx;
			}
			for (@text_found) {
				$found = 1;
				my @matches = @{$_};
				my $found_string = shift @matches;
				my $already_found = 0;
				for my $cur_found (@founds) {
					if ($cur_found->found eq $found_string and @{$cur_found->matches} ~~ @matches) {
						$already_found = 1; last;
					}
				}
				next if $already_found;
				my $found_in_secondary = 0;
				my $cidx = 0;
				for (@secondary_found) {
					my @cmatches = @{$_};
					my $found_cstring = shift @cmatches;
					if ($found_string eq $found_cstring and @matches ~~ @cmatches) {
						delete $secondary_found[$cidx];
					}
					$cidx++;
				}
				push @founds, $self->_new_found($found_string,1,$found_in_secondary,$kl->[0],$keyword,\@matches);
			}
			my @still_secondary_found;
			if (@text_found) {
				for (@secondary_found) {
					push @still_secondary_found, $_ if ($_);
				}
			} else {
				@still_secondary_found = @secondary_found;
			}
			for (@still_secondary_found) {
				$found = 1;
				my @matches = @{$_};
				my $found_string = shift @matches;
				my $already_found = 0;
				for my $cur_found (@founds) {
					if ($cur_found->found eq $found_string and @{$cur_found->matches} ~~ @matches) {
						$already_found = 1; last;
					}
				}
				next if $already_found;
				push @founds, $self->_new_found($found_string,0,1,$kl->[0],$keyword,\@matches);
			}
			last if $self->shuffle and $found;
		}
	}
	return @founds;
}

sub _new_found {
	my ( $self, $found, $in_primary, $in_secondary, $keywordlist, $keyword, $matches ) = @_;
	return Text::Keywords::Found->new({
		keyword => $keyword,
		found => $found,
		list => $keywordlist,
		matches => $matches,
		in_primary => $in_primary ? 1 : 0,
		in_secondary => $in_secondary ? 1 : 0,
		container => $self
	});
}

1;
__END__
=pod

=head1 NAME

Text::Keywords::Container - Class for a container of serveral Text::Keywords::List

=head1 VERSION

version 0.900

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

