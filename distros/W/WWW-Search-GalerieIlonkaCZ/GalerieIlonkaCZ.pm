package WWW::Search::GalerieIlonkaCZ;

# Pragmas.
use base qw(WWW::Search);
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use LWP::UserAgent;
use Readonly;
use Web::Scraper;

# Constants.
Readonly::Scalar our $MAINTAINER => 'Michal Spacek <skim@cpan.org>';
Readonly::Scalar my $GILONKA_CZ => 'http://www.galerie-ilonka.cz';
Readonly::Scalar my $GILONKA_CZ_ACTION1 => '/galerie-ilonka/0/0/3/42/9/0/?hledatjak=2';

# Version.
our $VERSION = 0.01;

# Setup.
sub native_setup_search {
	my ($self, $query) = @_;
	$self->{'_def'} = scraper {
		process '//div[@id="incenterpage2"]/div'.
			'/div[@class="productBody"]', 'books[]' => scraper {
			
			process '//div[@class="productTitle"]/div/a',
				'title' => 'TEXT';
# XXX Jak vybrat podtitul, kdyz tam je. Treba pri vyhledavani exlibris
#			process '//div[@class="productTitle"]/div',
#				'subtitle' => 'RAW';
			process '//div[@class="img_box"]/a', 'url' => '@href';
			process '//div[@class="productText"]',
				'description' => 'TEXT';
# XXX Cannot parse <link>. Breaks everything after this.
			process '//div[@class="productPriceBox"]'.
				'/div[@class="productPrice"]'.
				'/span[@itemprop="price"]', 'price' => 'TEXT';
			process '//div[@class="img_box"]/a/img',
				'cover_url' => '@src';
		
			return;
		};
		return;
	};
	$self->{'_query'} = $query;
	return 1;
}

# Get data.
sub native_retrieve_some {
	my $self = shift;

	# Query.
	my $query = decode_utf8($self->{'_query'});

	# Get content.
	my $ua = LWP::UserAgent->new(
		'agent' => "WWW::Search::GalerieIlonkaCZ/$VERSION",
	);
	my $response = $ua->get($GILONKA_CZ.$GILONKA_CZ_ACTION1."&slovo=$query");

	# Process.
	if ($response->is_success) {
		my $content = $response->content;

		# Get books structure.
		my $books_hr = $self->{'_def'}->scrape($content);

		# Process each book.
		foreach my $book_hr (@{$books_hr->{'books'}}) {
			_fix_url($book_hr, 'url');
			_fix_url($book_hr, 'cover_url');
			push @{$self->{'cache'}}, $book_hr;
		}
	}

	return;
}

# Fix URL to absolute path.
sub _fix_url {
	my ($book_hr, $url) = @_;
	if (exists $book_hr->{$url}) {
		$book_hr->{$url} = $GILONKA_CZ.$book_hr->{$url};
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::Search::GalerieIlonkaCZ - Class for searching http://galerie-ilonka.cz .

=head1 SYNOPSIS

 use WWW::Search::GalerieIlonkaCZ;
 my $obj = WWW::Search->new('GalerieIlonkaCZ');
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
 use WWW::Search::GalerieIlonkaCZ;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 match\n";
         exit 1;
 }
 my $match = $ARGV[0];

 # Object.
 my $obj = WWW::Search->new('GalerieIlonkaCZ.pm');
 $obj->maximum_to_retrieve(1);

 # Search.
 $obj->native_query($match);
 while (my $result_hr = $obj->next_result) {
        p $result_hr;
 }

 # Output:
 # Usage: /tmp/1Ytv23doz5 match

 # Output with 'Čapek' argument:

=head1 DEPENDENCIES

L<HTTP::Cookies>,
L<LWP::UserAgent>,
L<Readonly>,
L<Web::Scraper>,
L<WWW::Search>.

=head1 SEE ALSO

L<WWW::Search>.

=head1 REPOSITORY

L<https://github.com/tupinek/WWW-Search-GalerieIlonkaCZ>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.01

=cut
