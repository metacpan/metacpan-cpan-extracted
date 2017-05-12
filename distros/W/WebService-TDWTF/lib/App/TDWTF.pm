package App::TDWTF;

use 5.014000;
use strict;
use warnings;

use Encode qw/encode/;
use HTML::FormatText;
use WebService::TDWTF;

our $VERSION = '0.003';

sub print_list {
	my $idlen = length $_[0]->Id;
	for my $art (@_) {
		my $str = sprintf "%${idlen}d %s (by %s) in %s on %s\n", $art->Id, $art->Title, $art->AuthorName, $art->SeriesTitle, $art->DisplayDate;
		print encode 'UTF-8', $str;
	}
}

sub print_article {
	my ($art) = @_;
	printf "%s (by %s) in %s on %s\n\n", $art->Title, $art->AuthorName, $art->SeriesTitle, $art->DisplayDate;
	say HTML::FormatText->format_string($art->Body)
}

sub print_series {
	for my $series (tdwtf_series) {
		$series->{$_} = encode 'UTF-8', ($series->{$_} // '') for keys %$series;
		say $series->{Slug}, ' ', $series->{Title}, "\n", $series->{Description}, "\n";
	}
}

sub run {
	my ($args, @argv) = @_;
	return print_series if $args->{show_series};
	return print_list tdwtf_list_recent @argv if $args->{recent};
	return print_list tdwtf_list_series @argv if $args->{series};
	return print_list tdwtf_list_author @argv if $args->{author};
	print_article tdwtf_article @argv
}

1;
