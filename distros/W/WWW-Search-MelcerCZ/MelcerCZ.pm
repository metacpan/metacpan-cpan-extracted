package WWW::Search::MelcerCZ;

# Pragmas.
use base qw(WWW::Search);
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use LWP::UserAgent;
use Readonly;
use Text::Iconv;
use Web::Scraper;
use WWW::Search qw(generic_option);

# Constants.
Readonly::Scalar our $MAINTAINER => 'Michal Spacek <skim@cpan.org>';
Readonly::Scalar my $MELCER_CZ => 'http://melcer.cz/';
Readonly::Scalar my $MELCER_CZ_ACTION1 => 'index.php?akc=hledani&s=0&kos=0'.
	'&hltext=$hltex&kateg=';

# Version.
our $VERSION = 0.01;

# Setup.
sub native_setup_search {
	my ($self, $query) = @_;
	$self->{'_def'} = scraper {
		process '//meta[@http-equiv="Content-Type"]', 'encoding' => [
			'@content',
			\&_get_encoding,
		];
		process '//table[@width="100"]/tr/td[5]/a',
			'next_url' => '@href';
		process '//td[@height="330"]/node()[3]', 'records' => 'RAW';
		process '//td[@height="330"]/table[@width="560"]', 'books[]'
			=> scraper {

			process '//tr/td/font/a', 'title' => 'RAW',
				'url' => '@href';
			process '//tr/td[@width="136"]/font[2]',
				'price' => 'RAW';
			process '//tr[2]/td/font/strong', 'author' => 'RAW';
			process '//tr[3]/td/font/div', 'info' => 'RAW';
			process '//tr[4]/td/div/a', 'cover_url' => '@href';
			process '//tr[5]/td[1]/font[2]', 'publisher' => 'RAW';
			process '//tr[5]/td[2]/font[2]', 'year' => 'RAW';
			return;
		};
		return;
	};
	$self->{'_offset'} = 0;
	$self->{'_query'} = $query;
	return 1;
}

# Get data.
sub native_retrieve_some {
	my $self = shift;

	# Query.
	my $i = Text::Iconv->new('utf-8', 'windows-1250');
	my $query = $i->convert(decode_utf8($self->{'_query'}));

	# Get content.
	my $ua = LWP::UserAgent->new(
		'agent' => "WWW::Search::MelcerCZ/$VERSION",
	);
	my $response = $ua->post($MELCER_CZ.$MELCER_CZ_ACTION1,
		'Content' => {
			'hltex' => $query,
			'hledani' => 'Hledat',
		},
	);

	# Process.
	if ($response->is_success) {
		my $content = $response->content;

		# Get books structure.
		my $books_hr = $self->{'_def'}->scrape($content);

		# Iconv.
		if (! $self->{'_iconv'} && $books_hr->{'encoding'}) {
			$self->{'_iconv'} = Text::Iconv->new(
				$books_hr->{'encoding'}, 'utf-8');
		}

		# Process each book.
		foreach my $book_hr (@{$books_hr->{'books'}}) {
			_fix_url($book_hr, 'cover_url');
			_fix_url($book_hr, 'url');
			push @{$self->{'cache'}}, $self->_process($book_hr);
		}

		# Next url.
		_fix_url($books_hr, 'next_url');
		$self->next_url($books_hr->{'next_url'});
	}

	return;
}

# Get enconding from Content-Type string.
sub _get_encoding {
	my $content_type = shift;
	if ($content_type =~ m/.*charset=(.*)$/ms) {
		return $1;
	} else {
		return;
	}
}

# Fix URL to absolute path.
sub _fix_url {
	my ($book_hr, $url) = @_;
	if (exists $book_hr->{$url}) {
		$book_hr->{$url} = $MELCER_CZ.$book_hr->{$url};
	}
	return;
}

# Process each parameter of structure.
sub _process {
	my ($self, $book_hr) = @_;
	$self->_process_one($book_hr, 'author');
	$self->_process_one($book_hr, 'info');
	$self->_process_one($book_hr, 'publisher');
	$self->_process_one($book_hr, 'price');
	$self->_process_one($book_hr, 'title');
	return $book_hr;
}

# Process string to right output:
# - Encode to utf8.
# - Remove trailing whitespace.
sub _process_one {
	my ($self, $book_hr, $key) = @_;

	# No value.
	if (! exists $book_hr->{$key}) {
		return;
	}

	# Encode to utf8.
	if ($self->{'_iconv'}) {
		$book_hr->{$key} = $self->{'_iconv'}->convert(
			$book_hr->{$key});
	}

	# Encode to perl internal form.
	$book_hr->{$key} = decode_utf8($book_hr->{$key});

	# Remove trailing whitespace.
	$book_hr->{$key} =~ s/^\s+//gms;
	$book_hr->{$key} =~ s/\s+$//gms;

	# Encode to octets for output.
	$book_hr->{$key} = encode_utf8($book_hr->{$key});

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::Search::MelcerCZ - Class for searching http://melcer.cz .

=head1 SYNOPSIS

 use WWW::Search::MelcerCZ;
 my $obj = WWW::Search->new('MelcerCZ');
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
 use WWW::Search::MelcerCZ;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 match\n";
         exit 1;
 }
 my $match = $ARGV[0];

 # Object.
 my $obj = WWW::Search->new('MelcerCZ');
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
 #     author      "Čapek Karel",
 #     cover_url   "http://melcer.cz//img/books/images_big/142829.jpg",
 #     info        "obálky a typo Zdenek Seydl, 179 + 156 stran, původní brože 8°, stav velmi dobrý",
 #     price       "97.00 Kč",
 #     publisher   "Československý spisovatel",
 #     title       "Povídky z jedné a druhé kapsy (2 svazky)",
 #     url         "http://melcer.cz//index.php?akc=detail&idvyrb=53259&hltex=%C8apek&autor=&nazev=&odroku=&doroku=&vydavatel=",
 #     year        1967
 # }

=head1 DEPENDENCIES

L<Encode>,
L<LWP::UserAgent>,
L<Readonly>,
L<Text::Iconv>,
L<Web::Scraper>,
L<WWW::Search>.

=head1 SEE ALSO

L<WWW::Search>.

=head1 REPOSITORY

L<https://github.com/tupinek/WWW-Search-MelcerCZ>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.01

=cut
