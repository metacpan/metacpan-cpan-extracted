
use strict;
use Test;
use XML::CuteQueries;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $CQ = XML::CuteQueries->new->parse(q{
    <r>
        <users>
            <user name="1" pass="$x$1$"/>
            <user name="2" pass="$x$2$"/>
            <user name="3" pass="$x$3$"/>
            <user name="4" pass="$x$4$"/>
            <user name="5" pass="$x$5$"/>
        </users>
    </r>
});

plan tests => 4;

# just for sanity, not really a kar-attr test:
ok( Dumper({$CQ->hash_query(users=>{'[]user'=>{'@name'=>'', '@pass'=>''}})}),  Dumper({
    users=>{
        user=>[
            {name=>"1", pass=>'$x$1$'},
            {name=>"2", pass=>'$x$2$'},
            {name=>"3", pass=>'$x$3$'},
            {name=>"4", pass=>'$x$4$'},
            {name=>"5", pass=>'$x$5$'},
        ],
    },
}));

ok( Dumper({$CQ->hash_query('[]users/user/@name'=>'')}), Dumper({name=>[qw(1 2 3 4 5)]}) );

ok( Dumper({$CQ->hash_query('[]//@*'=>'')}), Dumper({
    name=>[qw(1 2 3 4 5)],
    pass=>[qw( $x$1$ $x$2$ $x$3$ $x$4$ $x$5$)],
}) );

ok( Dumper({$CQ->hash_query('[]//user/@*'=>'')}), Dumper({
    name=>[qw(1 2 3 4 5)],
    pass=>[qw( $x$1$ $x$2$ $x$3$ $x$4$ $x$5$)],
}) );

