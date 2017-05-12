use 5.010;
use Test::More tests => 18;
use lib 'blib', 'lib';
use WebService::Libris;
use utf8;
binmode STDOUT, ':encoding(UTF-8)';

ok my $book = WebService::Libris->new(
    type        => 'bib',
    id          => '9604288',
    cache_dir   => 't/data/',

), 'Can get a book by id';

is $book->title, 'Låt den rätte komma in : [skräckroman]', 'title';
is $book->language, 'sv', 'language';
is $book->isbn, '9170370192', 'ISBN';
is join(', ', $book->authors_text),
    'Ajvide Lindqvist, John, 1968-, John Ajvide Lindqvist',
    'Authors (text)';
is $book->language, 'sv', 'language';

is join(',', $book->authors_ids), '246603', 'author ids';
my @authors = $book->authors_obj;
is scalar(@authors), 1, 'got the right number of author objects';
my $author = $authors[0];
is $author->id, ($book->authors_ids)[0], 'consistency of author IDs';

is $author->libris_key, 'Ajvide Lindqvist, John, 1968-', 'author: libris key';
is join(', ', $author->names), 'Ajvide Lindkvist, Jun, 1968-, John Ajvide Lindqvist, Jon Ajvide Lindkvist, Lindqvist, John Ajvide, 1968-, Lindkvist, Jon Ajvide, 1968-, Ajvide Lindqvist, John, 1968-, Jun Ajvide Lindkvist', 'all name variants';
is $author->birthyear, '1968', 'birth year';
is $author->same_as, 'http://viaf.org/viaf/72579864/#foaf:Person', 'same_as URL';
my @libs = $book->held_by;
is scalar(@libs), 13, 'correct number of libraries that hold our book';
is $libs[1]->name, 'Umeå universitetsbibliotek', 'library name';
is $libs[1]->lat, '63.823181', 'lattitude';
is $libs[1]->long, '20.305824', 'longitude';
is $libs[1]->homepage, 'http://www.ub.umu.se', 'homepage';

