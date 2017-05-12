package WWW::Search::AntikvariatJudaicaCZ;

# Pragmas.
use base qw(WWW::Search);
use strict;
use warnings;

# Modules.
use LWP::UserAgent;
use Readonly;
use Web::Scraper;

# Constants.
Readonly::Scalar our $MAINTAINER => 'Michal Spacek <skim@cpan.org>';
Readonly::Scalar my $BASE_URL => 'http://antikvariat-judaica.cz/';
Readonly::Scalar my $ACTION1 => 'search/node/';

# Version.
our $VERSION = 0.02;

# Setup.
sub _native_setup_search {
	my ($self, $query) = @_;
	$self->{'_def'} = scraper {
		process '//div[@class="content"]/dl/div', 'books[]' => scraper {
			process '//h2/a', 'title' => 'TEXT';
			process '//h2/a', 'url' => '@href';
			process '//img[@class="imagecache '.
				'imagecache-product_list"]',
				'cover_url' => '@src';
			process '//div[@class="field sell-price"]',
				'price' => 'TEXT';
			process '//div[@class="field '.
				'field-type-content-taxonomy '.
				'field-field-author"]',
				'author' => 'TEXT';
			return;
		};
		return;
	};
	$self->{'_query'} = $query;
	return 1;
}

# Get data.
sub _native_retrieve_some {
	my $self = shift;

	# Get content.
	my $ua = LWP::UserAgent->new(
		'agent' => "WWW::Search::AntikvariatJudaicaCZ/$VERSION",
	);
	my $response = $ua->get($BASE_URL.$ACTION1.$self->{'_query'});

	# Process.
	if ($response->is_success) {
		my $content = $response->content;

		# Get books structure.
		my $books_hr = $self->{'_def'}->scrape($content);

		# Process each book.
		foreach my $book_hr (@{$books_hr->{'books'}}) {
			_fix_url($book_hr, 'url');
			$book_hr->{'price'} =~ s/\N{U+00A0}/ /ms;
			$book_hr->{'price'} =~ s/^\s*Cena:\s*//ms;
			$book_hr->{'author'} =~ s/^\s*Autor:\s*//ms;
			push @{$self->{'cache'}}, $book_hr;
		}
	}

	return;
}

# Fix URL to absolute path.
sub _fix_url {
	my ($book_hr, $url) = @_;
	if (exists $book_hr->{$url}) {
		$book_hr->{$url} = $BASE_URL.$book_hr->{$url};
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::Search::AntikvariatJudaicaCZ - Class for searching http://antikvariat-judaica.cz .

=head1 SYNOPSIS

 use WWW::Search::AntikvariatJudaicaCZ;
 my $obj = WWW::Search->new('AntikvariatJudaicaCZ');
 $obj->native_query($query);
 my $maintainer = $obj->maintainer; 
 my $res_hr = $obj->next_result;
 my $version = $obj->version;

=head1 METHODS

=over 8

=item C<native_setup_search($query)>

 Setup.

=item C<native_retrieve_some()>

 Get data.

=back

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Data::Printer;
 use WWW::Search::AntikvariatJudaicaCZ;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 match\n";
         exit 1;
 }
 my $match = $ARGV[0];

 # Object.
 my $obj = WWW::Search->new('AntikvariatJudaicaCZ');
 $obj->maximum_to_retrieve(1);

 # Search.
 $obj->native_query($match);
 while (my $result_hr = $obj->next_result) {
        p $result_hr;
 }

 # Output:
 # Usage: /tmp/1Ytv23doz5 match

 # Output with 'Čapek' argument like:
 # \ {
 #     author      "Kolektiv autorů",
 #     cover_url   "http://www.antikvariat-judaica.cz/sites/default/files/imagecache/product_list/2012-10/121003_29660_scan10055.jpg",
 #     price       "100,00 Kč",
 #     title       "J. B. Čapek. Jubilejní sborník 1903 - 2003.",
 #     url         "http://antikvariat-judaica.cz//kniha/j-b-capek-jubilejni-sbornik-1903-2003"
 # }

=head1 DEPENDENCIES

L<LWP::UserAgent>,
L<Readonly>,
L<Web::Scraper>,
L<WWW::Search>.

=head1 SEE ALSO

L<WWW::Search>.

=head1 REPOSITORY

L<https://github.com/tupinek/WWW-Search-AntikvariatJudaicaCZ>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.02

=cut
