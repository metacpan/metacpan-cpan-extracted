package WWW::Search::ValentinskaCZ;

# Pragmas.
use base qw(WWW::Search);
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use LWP::UserAgent;
use Readonly;
use URI;
use Web::Scraper;

# Constants.
Readonly::Scalar our $MAINTAINER => 'Michal Spacek <skim@cpan.org>';
Readonly::Scalar my $VALENTINSKA_CZ => 'http://www.valentinska.cz/';
Readonly::Scalar my $VALENTINSKA_CZ_ACTION1 => 'index.php?route=product/search&search=';

# Version.
our $VERSION = 0.03;

# Setup.
sub native_setup_search {
	my ($self, $query) = @_;
	$self->{'_def'} = scraper {

		# Get list of books.
		process '//div[@class="product-inner clearfix"]',
			'books[]' => scraper {

			process '//div[@class="wrap-infor"]/div[@class="name"]/a',
				'title' => 'TEXT';
			process '//div[@class="wrap-infor"]/div[@class="name"]/a',
				'url' => ['@href', sub {
					my $url = shift;
					my $uri = URI->new($url);
					my %query = $uri->query_form;
					if (exists $query{'search'}) {
						delete $query{'search'};
					}
					$uri->query_form(\%query);
					return $uri->as_string;
				}];
			process '//div[@class="image"]/a/img',
				'image' => '@src';
			process '//div[@class="wrap-infor"]/div[@class="author"]',
				'author' => 'TEXT';
			process '//div[@class="wrap-infor"]/div[@class="price"]/br/preceding-sibling::text()',
				'price' => ['TEXT', sub { s/^\s*(.*?)\s*$/$1/; }];
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
		'agent' => "WWW::Search::ValentinskaCZ/$VERSION",
	);
	my $query_url = $VALENTINSKA_CZ.$VALENTINSKA_CZ_ACTION1.$query;
	my $response = $ua->get($query_url);

	# Process.
	if ($response->is_success) {
		my $content = $response->content;

		# Get books structure.
		my $books_hr = $self->{'_def'}->scrape($content);

		# Process each book.
		foreach my $book_hr (@{$books_hr->{'books'}}) {
			push @{$self->{'cache'}}, $book_hr;
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::Search::ValentinskaCZ - Class for searching http://valentinska.cz .

=head1 SYNOPSIS

 use WWW::Search::ValentinskaCZ;
 my $obj = WWW::Search->new('ValentinskaCZ');
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
 use WWW::Search::ValentinskaCZ;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 match\n";
         exit 1;
 }
 my $match = $ARGV[0];

 # Object.
 my $obj = WWW::Search->new('ValentinskaCZ');
 $obj->maximum_to_retrieve(1);

 # Search.
 $obj->native_query($match);
 while (my $result_hr = $obj->next_result) {
        p $result_hr;
 }

 # Output like:
 # Usage: /tmp/1Ytv23doz5 match

 # Output with 'Čapek' argument like:
 # \ {
 #     author   "Larbaud, Valery; obálka: J. Čapek",
 #     image    "http://www.valentinska.cz/image/cache/data/valentinska/book_144061_1-1024x1024.jpg",
 #     price    "450Kč",
 #     title    "A. O. Barnbooth. Jeho důvěrný deník",
 #     url      "http://www.valentinska.cz/144061-a-o-barnbooth-jeho-duverny-denik"
 # }

=head1 DEPENDENCIES

L<Encode>,
L<LWP::UserAgent>,
L<Readonly>,
L<URI>,
L<Web::Scraper>,
L<WWW::Search>.

=head1 SEE ALSO

=over

=item L<WWW::Search>

Virtual base class for WWW searches

=item L<Task::WWW::Search::Antiquarian::Czech>

Install the WWW::Search modules for Czech antiquarian bookstores.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/WWW-Search-ValentinskaCZ>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2014-2015
 BSD 2-Clause License

=head1 VERSION

0.03

=cut
