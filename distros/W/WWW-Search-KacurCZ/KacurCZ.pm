package WWW::Search::KacurCZ;

use base qw(WWW::Search);
use strict;
use warnings;

use Encode qw(decode_utf8);
use LWP::UserAgent;
use Perl6::Slurp qw(slurp);
use Readonly;
use Text::Iconv;
use Web::Scraper;

# Constants.
Readonly::Scalar our $MAINTAINER => 'Michal Josef Spacek <skim@cpan.org>';
Readonly::Scalar my $KACUR_CZ => 'http://kacur.cz/';
Readonly::Scalar my $KACUR_CZ_ACTION1 => '/search.asp?doIt=search&menu=675&'.
	'kategorie=&nazev=&rok=&dosearch=Vyhledat';

our $VERSION = 0.02;

# Setup.
sub _native_setup_search {
	my ($self, $query) = @_;

	$self->{'_def'} = scraper {
		process '//div[@class="productItemX"]', 'books[]' => scraper {
			process '//div/h3/a', 'title' => 'TEXT';
			process '//div/h3/a', 'url' => '@href';
			process '//img', 'cover_url' => '@src';
			process '//p', 'author_publisher[]' => 'TEXT';
			process '//span[@class="price"]', 'price' => 'TEXT';
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

	if (defined $self->{search_from_file}) {
		my $content = slurp($self->{search_from_file});
		$self->_process_content($content);
	} else {
		# Query.
		my $i1 = Text::Iconv->new('utf-8', 'windows-1250');
		my $query = $i1->convert(decode_utf8($self->{'_query'}));

		# Get content.
		my $ua = LWP::UserAgent->new(
			'agent' => "WWW::Search::KacurCZ/$VERSION",
		);
		my $response = $ua->get($KACUR_CZ.$KACUR_CZ_ACTION1."&autor=$query");

		# Process.
		if ($response->is_success) {
			$self->_process_content($response->content);
		}
	}

	return;
}

# Fix URL to absolute path.
sub _fix_url {
	my ($book_hr, $url) = @_;

	if (exists $book_hr->{$url}) {
		$book_hr->{$url} = $KACUR_CZ.$book_hr->{$url};
	}

	return;
}

sub _process_content {
	my ($self, $content) = @_;

	my $i2 = Text::Iconv->new('windows-1250', 'utf-8');
	my $utf8_content = $i2->convert($content);

	# Get books structure.
	my $books_hr = $self->{'_def'}->scrape($utf8_content);

	# Process each book.
	foreach my $book_hr (@{$books_hr->{'books'}}) {
		_fix_url($book_hr, 'url');
		_fix_url($book_hr, 'cover_url');
		$book_hr->{'author'}
			= $book_hr->{'author_publisher'}->[0];
		$book_hr->{'author'} =~ s/\N{U+00A0}$//ms;
		$book_hr->{'publisher'}
			= $book_hr->{'author_publisher'}->[1];
		$book_hr->{'publisher'} =~ s/\N{U+00A0}$//ms;
		delete $book_hr->{'author_publisher'};
		($book_hr->{'old_price'}, $book_hr->{'price'})
			= split m/\s*\*\s*/ms, $book_hr->{'price'};
		push @{$self->{'cache'}}, $book_hr;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::Search::KacurCZ - Class for searching http://kacur.cz .

=head1 SYNOPSIS

 use WWW::Search;

 my $obj = WWW::Search->new('KacurCZ');
 $obj->native_query($query);
 my $maintainer = $obj->maintainer; 
 my $res_hr = $obj->next_result;
 my $version = $obj->version;

=head1 METHODS

For methods look to L<WWW::Search>.

=head1 EXAMPLE

=for comment filename=fetch_kacur_capek.pl

 use strict;
 use warnings;

 use Data::Printer;
 use WWW::Search::KacurCZ;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 match\n";
         exit 1;
 }
 my $match = $ARGV[0];

 # Object.
 my $obj = WWW::Search->new('KacurCZ');
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
 #     author          "Guillaume Apollinaire",
 #     cover_url       "http://kacur.cz/data/USR_001_OBRAZKY/small_196566.JPG",
 #     old_price       "2 000 Kč",
 #     price           "1 000 Kč",
 #     publisher       "Symposion",
 #     title           "Kacíř a spol"
 #     url             "http://kacur.cz/index.asp?menu=1123&record=140698",
 # }

=head1 DEPENDENCIES

L<Encode>,
L<LWP::UserAgent>,
L<Perl6::Slurp>,
L<Readonly>,
L<Text::Iconv>,
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

L<https://github.com/michal-josef-spacek/WWW-Search-KacurCZ>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2014-2023

BSD 2-Clause License

=head1 VERSION

0.02

=cut
