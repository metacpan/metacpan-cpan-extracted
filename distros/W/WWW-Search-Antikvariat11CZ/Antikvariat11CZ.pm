package WWW::Search::Antikvariat11CZ;

# Pragmas.
use base qw(WWW::Search);
use strict;
use warnings;

# Modules.
use HTTP::Cookies;
use LWP::UserAgent;
use Readonly;
use Web::Scraper;

# Constants.
Readonly::Scalar our $MAINTAINER => 'Michal Spacek <skim@cpan.org>';
Readonly::Scalar my $ANTIKVARIAT11_CZ => 'http://antikvariat11.cz';
Readonly::Scalar my $ANTIKVARIAT11_CZ_ACTION1 => '/hledani';

# Version.
our $VERSION = 0.01;

# Setup.
sub native_setup_search {
	my ($self, $query) = @_;
	$self->{'_cookie'} = HTTP::Cookies->new(
		'autosave' => 1,
		'file' => "$ENV{'HOME'}/.cookies.txt",
	);
	$self->{'_def'} = scraper {

		# Link to next page.
		process '//ul[@class="pager"]/li/a', 'next_page' => '@href';

		# Get list of books.
		process '//div[@id="content"]/div[@id]', 'books[]' => scraper {
			process '//div/h3', 'title' => 'TEXT';
			process '//div/h3/a', 'detailed_link' => '@href';
			process '//div[@class="para-au"]/span',
				'author' => 'TEXT';
			process '//div[@class="para-ill"]/span',
				'illustrator' => 'TEXT';
			process '//div[@class="para-pg"]/span',
				'pages' => 'RAW';
			process '//div[@class="para-issued"]/span',
				'year_issued' => 'TEXT';
			process '//div[@class="para-cat"]/span',
				'category' => 'TEXT';
			process '//div[@class="para-state"]/span',
				'stay' => 'TEXT';
			process '//div[@class="para-price"]/span',
				'price' => 'TEXT';
			process '//div/img', 'image' => '@src';
			return;
		};
		return;
	};
	$self->{'_offset'} = 0;
	$self->{'_query'} = $query;
	$self->{'ua'} = LWP::UserAgent->new(
		'agent' => "WWW::Search::Antikvariat11CZ/$VERSION",
		'cookie_jar' => $self->{'_cookie'},
	);

	# Get for root for cookie.
	$self->{'ua'}->get($ANTIKVARIAT11_CZ);
	return 1;
}

# Get data.
sub native_retrieve_some {
	my $self = shift;

	# Get content.
	my $response = $self->{'ua'}->post($ANTIKVARIAT11_CZ.
		$ANTIKVARIAT11_CZ_ACTION1,
		'Content' => {
			'q' => $self->{'_query'},
			'Submit' => 'hledat',
		},
	);

	# Process.
	if ($response->is_success) {
		my $content = $response->content;

		# Get books structure.
		my $books_hr = $self->{'_def'}->scrape($content);

		# Process each book.
		foreach my $book_hr (@{$books_hr->{'books'}}) {
			_fix_url($book_hr, 'detailed_link');
			_fix_url($book_hr, 'image');
			push @{$self->{'cache'}}, $book_hr;
		}

		# Next url.
		_fix_url($books_hr, 'next_page');
		$self->next_url($books_hr->{'next_page'});
	}

	return;
}

# Fix URL to absolute path.
sub _fix_url {
	my ($book_hr, $url) = @_;
	if (exists $book_hr->{$url}) {
		$book_hr->{$url} = $ANTIKVARIAT11_CZ.$book_hr->{$url};
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::Search::Antikvariat11CZ - Class for searching http://antikvariat11.cz .

=head1 SYNOPSIS

 use WWW::Search::Antikvariat11CZ;
 my $obj = WWW::Search->new('Antikvariat11CZ');
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
 use WWW::Search::Antikvariat11CZ;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 match\n";
         exit 1;
 }
 my $match = $ARGV[0];

 # Object.
 my $obj = WWW::Search->new('Antikvariat11CZ');
 $obj->maximum_to_retrieve(1);

 # Search.
 $obj->native_query($match);
 while (my $result_hr = $obj->next_result) {
        p $result_hr;
 }

 # Output:
 # Usage: /tmp/1Ytv23doz5 match

 # Output with 'Čapek' argument:
 # \ {
 #     author          "Karel Čapek",
 #     category        "Pohádky / Dětské",
 #     detailed_link   "http://antikvariat11.cz/kniha/capek-karel-devatero-pohadek-a-jeste-jedna-jako-privazek-od-josefa-capka-1977-319041",
 #     illustrator     "Čapek, Josef",
 #     image           "http://antikvariat11.cz/files/thumb_36885.png",
 #     pages           "242 s.",
 #     price           "55 Kč",
 #     stay            "Výborná originální vazba",
 #     title           "Devatero pohádek a ještě jedna jako přívažek od Josefa Čapka",
 #     year_issued     1977
 # }

=head1 DEPENDENCIES

L<HTTP::Cookies>,
L<LWP::UserAgent>,
L<Readonly>,
L<Web::Scraper>,
L<WWW::Search>.

=head1 SEE ALSO

L<WWW::Search>.

=head1 REPOSITORY

L<https://github.com/tupinek/WWW-Search-Antikvariat11CZ>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.01

=cut
