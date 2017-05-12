use strict;
use utf8;
use warnings;

use Test::MockObject;
use Test::More;
use WebService::Solr::Tiny;

my $agent = Test::MockObject->new;

my @requests;

$agent->mock(
    get => sub {
        push @requests, "$_[1]";

        {
            content => '{}',
            success => 1,
        }
    },
);

my $solr  = WebService::Solr::Tiny->new( agent => $agent );

$solr->search;

is shift @requests, 'http://localhost:8983/solr/select?q=';

$solr->search('UTF-8 FTW ☃');

is shift @requests, 'http://localhost:8983/solr/select?q=UTF-8+FTW+%E2%98%83';

$solr->search(
    '{!lucene q.op=AND df=text}myfield:foo +bar -baz',
    debugQuery => 'true',
    fl         => 'id,name,price',
    fq         => [
        'popularity:[10 TO *]',
        'section:0',
    ],
    omitHeader => 'true',
    rows       => 20,
    sort       => 'inStock desc, price asc',
    start      => 10,
);

is_deeply [ sort split /[?&]/, shift @requests ], [
    'debugQuery=true',
    'fl=id%2Cname%2Cprice',
    'fq=popularity%3A%5B10+TO+*%5D',
    'fq=section%3A0',
    'http://localhost:8983/solr/select',
    'omitHeader=true',
    'q=%7B!lucene+q.op%3DAND+df%3Dtext%7Dmyfield%3Afoo+%2Bbar+-baz',
    'rows=20',
    'sort=inStock+desc%2C+price+asc',
    'start=10',
];

done_testing;
