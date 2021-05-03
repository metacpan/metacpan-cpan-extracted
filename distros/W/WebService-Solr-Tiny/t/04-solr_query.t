use Test2::V0;
use WebService::Solr::Tiny 'solr_query';

subtest 'Basic queries' => sub {
    # default field
    is solr_query({ -default => 'space' }), '("space")';

    is solr_query({ -default => [ 'star trek', 'star wars' ] }),
        '(("star trek" OR "star wars"))';

    # scalarref pass-through
    is solr_query({ '*' => \'*' }), '(*:*)';

    # field
    is solr_query({ title => 'Spaceballs' }), '(title:"Spaceballs")';

    is solr_query({ first => 'Roger', last => 'Moore' }),
        '(first:"Roger" AND last:"Moore")';

    is solr_query({ first => [ 'Roger', 'Dodger' ] }),
        '((first:"Roger" OR first:"Dodger"))';

    is solr_query({ first => [ 'Roger', 'Dodger' ], last => 'Moore' }),
        '((first:"Roger" OR first:"Dodger") AND last:"Moore")';

    is solr_query([ { first => [ 'Roger', 'Dodger' ] }, { last => 'Moore' } ]),
        '((first:"Roger" OR first:"Dodger") OR last:"Moore")';

    is solr_query({
        first    => [ 'Roger',     'Dodger' ],
        -default => [ 'star trek', 'star wars' ]
    }), '(("star trek" OR "star wars") AND (first:"Roger" OR first:"Dodger"))';
};

subtest 'Basic query with escape' => sub {
    is solr_query({ -default => 'sp(a)ce' }), '("sp\(a\)ce")';

    is solr_query({ title => 'Spaceb(a)lls' }), '(title:"Spaceb\(a\)lls")';
};

subtest 'Simple ops' => sub {
    # range (inc)
    is solr_query({ title => { -range => [ 'a', 'z' ] } }), '(title:[a TO z])';

    is solr_query({
        first => [ 'Roger', 'Dodger' ],
        title => { -range => [ 'a', 'z' ] }
    }), '((first:"Roger" OR first:"Dodger") AND title:[a TO z])';

    # range (exc)
    is solr_query({ title => { -range_exc => [ 'a', 'z' ] } }),
        '(title:{a TO z})';

    is solr_query({
        first => [ 'Roger', 'Dodger' ],
        title => { -range_exc => [ 'a', 'z' ] }
    }), '((first:"Roger" OR first:"Dodger") AND title:{a TO z})';

    # boost
    is solr_query({ title => { -boost => [ 'Space', '2.0' ] } }),
        '(title:"Space"^2.0)';

    is solr_query({
        first => [ 'Roger', 'Dodger' ],
        title => { -boost => [ 'Space', '2.0' ] }
    }), '((first:"Roger" OR first:"Dodger") AND title:"Space"^2.0)';

    # proximity
    is solr_query({ title => { -proximity => [ 'space balls', '10' ] } }),
        '(title:"space balls"~10)';

    is solr_query({
        first => [ 'Roger', 'Dodger' ],
        title => { -proximity => [ 'space balls', '10' ] }
    }), '((first:"Roger" OR first:"Dodger") AND title:"space balls"~10)';

    # fuzzy
    is solr_query({ title => { -fuzzy => [ 'space', '0.8' ] } }),
        '(title:space~0.8)';

    is solr_query({
        first => [ 'Roger', 'Dodger' ],
        title => { -fuzzy => [ 'space', '0.8' ] }
    }), '((first:"Roger" OR first:"Dodger") AND title:space~0.8)';
};

subtest 'Ops with escape' => sub {
    is solr_query({ title => { -boost => [ 'Sp(a)ce', '2.0' ] } }),
        '(title:"Sp\(a\)ce"^2.0)';

    is solr_query({ title => { -proximity => [ 'sp(a)ce balls', '10' ] } }),
        '(title:"sp\(a\)ce balls"~10)';

    is solr_query({ title => { -fuzzy => [ 'sp(a)ce', '0.8' ] } }),
        '(title:sp\(a\)ce~0.8)';
};

subtest 'Require and prohibit' => sub {
    is solr_query({ title => { -require => 'star' } }), '(+title:"star")';

    is solr_query({
        first => [ 'Roger', 'Dodger' ],
        title => { -require => 'star' }
    }), '((first:"Roger" OR first:"Dodger") AND +title:"star")';

    is solr_query({ title => { -prohibit => 'star' } }), '(-title:"star")';

    is solr_query({ default => { -prohibit => 'foo' } }), '(-default:"foo")';

    is solr_query({
        first => [ 'Roger', 'Dodger' ],
        title => { -prohibit => 'star' }
    }), '((first:"Roger" OR first:"Dodger") AND -title:"star")';

    is solr_query({
        title => [ -and => { -prohibit => 'star' }, { -prohibit => 'wars' } ],
    }), '(((-title:"star") AND (-title:"wars")))';

    is solr_query({
        first => [ 'Bob' ],
        title => [ -and => { -prohibit => 'star' }, { -prohibit => 'wars' } ],
    }), '((first:"Bob") AND ((-title:"star") AND (-title:"wars")))';
};

subtest 'Nested and/or operators' => sub {
    is solr_query({
        title => [ -and => { -require => 'star' }, { -require => 'wars' } ],
    }), q[(((+title:"star") AND (+title:"wars")))];

    is solr_query({
        title => [
            -or => (
                { -range_exc => [ 'a', 'c' ] },
                { -range_exc => [ 'e', 'k' ] },
            ),
        ],
    }), q[(((title:{a TO c}) OR (title:{e TO k})))];
};

done_testing;
