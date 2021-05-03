use Test2::V0;
use WebService::Solr::Tiny;

my $solr = WebService::Solr::Tiny->new( agent => mock {} => add =>
    [ get => sub { $::req = pop; { content => '{}', success => 1 } } ] );

$solr->search;

is $::req, 'http://localhost:8983/solr/select?q=';

$solr->search('UTF-8 FTW ☃');

is $::req, 'http://localhost:8983/solr/select?q=UTF-8+FTW+%E2%98%83';

$solr->search(
    '{!lucene q.op=AND df=text}myfield:foo +bar -baz',
    debugQuery => 'true',
    fl         => 'id,name,price',
    fq         => [ 'popularity:[10 TO *]', 'section:0' ],
    omitHeader => 'true',
    rows       => 20,
    sort       => 'inStock desc, price asc',
    start      => 10,
);

is [ split /[?&]/, $::req ] => [qw[
    http://localhost:8983/solr/select
    debugQuery=true
    fl=id%2Cname%2Cprice
    fq=popularity%3A%5B10+TO+*%5D
    fq=section%3A0
    omitHeader=true
    q=%7B!lucene+q.op%3DAND+df%3Dtext%7Dmyfield%3Afoo+%2Bbar+-baz
    rows=20
    sort=inStock+desc%2C+price+asc
    start=10
]];

done_testing;
