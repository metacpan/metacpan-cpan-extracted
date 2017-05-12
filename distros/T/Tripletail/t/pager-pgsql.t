# -*- perl -*-
use Test::More;
use Test::Exception;
use strict;
use warnings;

my %DBINFO;
BEGIN {
    %DBINFO = (
        dbname   => $ENV{PGSQL_DBNAME} || 'test',
        user     => $ENV{PGSQL_USER  } || 'postgres',
        password => $ENV{PGSQL_PASS  } || '',
        host     => $ENV{PGSQL_HOST  } || '',
       );
}

use lib '.';
use t::make_ini {
    ini => {
        TL => {
            trap => 'none',
        },
        DB => {
            type       => 'pgsql',
            defaultset => 'Default',
            Default    => 'DBR1',
        },
        DBR1 => \%DBINFO,
    }
};
use Tripletail $t::make_ini::INI_FILE;

my $has_DBD_Pg = eval 'use DBD::Pg;1';
if (!$has_DBD_Pg) {
    plan skip_all => 'no DBD::Pg';
}

if (!$DBINFO{dbname}) {
    plan skip_all => 'no PGSQL_DBNAME';
}

eval {
    $TL->trapError(
        -DB   => 'DB',
        -main => sub {},
       );
};
if ($@) {
    plan skip_all => "Failed to connect to the PostgreSQL: $@";
}

$TL->trapError(
    -DB   => 'DB',
    -main => \&main,
   );

sub trim ($) {
    $_ = shift;
    s/^\s*|\s*$//mg;
    $_;
}

sub main {
    my $TMPL = q{
  <!begin:paging>
    <!begin:PrevLink><a href="<&PREVLINK>">←前ページ</a><!end:PrevLink>
    <!begin:NoPrevLink>←前ページ<!end:NoPrevLink>
    <!begin:PageNumLinks>
      <!begin:ThisPage><&PAGENUM><!end:ThisPage>
      <!begin:OtherPage>
        <a href="<&PAGELINK>"><&PAGENUM></a>
      <!end:OtherPage>
    <!end:PageNumLinks>
    <!begin:NextLink><a href="<&NEXTLINK>">次ページ→</a><!end:NextLink>
    <!begin:NoNextLink>次ページ→<!end:NoNextLink>
    ...
    <!begin:MaxRows>全<&MAXROWS>件<!end:MaxRows>
    <!begin:FirstRow><&FIRSTROW>件目から<!end:FirstRow>
    <!begin:LastRow><&LASTROW>件目までを表示中<!end:LastRow>
    <!begin:MaxPages>全<&MAXPAGES>ページ<!end:MaxPages>
    <!begin:CurPage>現在<&CURPAGE>ページ目<!end:CurPage>
    ...
    <!begin:Row>
      <&FOO> <&BAR> <&BAZ>
    <!end:Row>
    ...
  <!end:paging>
  <!-- 以下は Pager クラスの処理とは関係ないため、無くても良い -->
  <!begin:nodata>
    一件もありません
  <!end:nodata>
  <!begin:overpage>
    最大ページ数は<&MAXPAGES>です。
  <!end:overpage>
};

    my $ANS = q{
←前ページ
1
<a href="./?pageid=2&amp;INT=1">2</a>
<a href="./?pageid=3&amp;INT=1">3</a>
<a href="./?pageid=4&amp;INT=1">4</a>
<a href="./?pageid=2&amp;INT=1">次ページ→</a>
...
全100件
1件目から
30件目までを表示中
全4ページ
現在1ページ目
...
0 WWW EEE
1 WWW EEE
2 WWW EEE
3 WWW EEE
4 WWW EEE
5 WWW EEE
6 WWW EEE
7 WWW EEE
8 WWW EEE
9 WWW EEE
10 WWW EEE
11 WWW EEE
12 WWW EEE
13 WWW EEE
14 WWW EEE
15 WWW EEE
16 WWW EEE
17 WWW EEE
18 WWW EEE
19 WWW EEE
20 WWW EEE
21 WWW EEE
22 WWW EEE
23 WWW EEE
24 WWW EEE
25 WWW EEE
26 WWW EEE
27 WWW EEE
28 WWW EEE
29 WWW EEE
...
<!mark:paging>
<!-- 以下は Pager クラスの処理とは関係ないため、無くても良い -->
<!mark:nodata>
<!mark:overpage>};

    plan tests => 86;

    my $DB = $TL->getDB('DB');
    $DB->tx(
        sub {
            $DB->execute(q{
                DROP TABLE IF EXISTS TripletaiL_DB_Test
              });
            $DB->execute(q{
                CREATE TABLE TripletaiL_DB_Test (
                    foo BYTEA,
                    bar BYTEA,
                    baz BYTEA
                )
              });
            for (my $i = 0; $i < 100; $i++) {
                $DB->execute(q{
                    INSERT INTO TripletaiL_DB_Test
                           (foo, bar, baz)
                    VALUES (?,   ?,   ?  )
                  }, $i, 'WWW', 'EEE');
            }
        });

    my $pager;
    ok($pager = $TL->newPager($DB), 'newPager');

    ok($pager->setCurrentPage(1), 'setCurrentPage');

    my $t = $TL->newTemplate;
    $t->setTemplate($TMPL);

    dies_ok {$pager->paging} 'paging die';
    dies_ok {$pager->paging(\123)} 'paging die';
    dies_ok {$pager->paging($t)} 'paging die';
    dies_ok {$pager->paging($t->node('paging'))} 'paging die';
    dies_ok {$pager->paging($t->node('paging'),\123)} 'paging die';
    dies_ok {$pager->paging($t->node('paging'),['SELECT * FROM TripletaiL_DB_Test',\123])} 'paging die';
    dies_ok {$pager->paging($t->node('paging'),['SELECT * FROM TripletaiL_DB_Test',-10])} 'paging die';

    my $paging;
    ok($pager = $TL->newPager($DB), 'newPager');
    ok($paging = $pager->paging($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'),'paging');
    if (!defined($paging)) {
        my $info = $pager->getPagingInfo;
        $t->node('overpage')->add(MAXPAGES => $info->{maxpages});
    }
    elsif ($paging == 0) {
        $t->node('nodata')->add;
    }
    else {
        $t->node('paging')->add;
    }

    is(trim $t->getHtml, trim $ANS, 'paging (1)');


    ok(my $info = $pager->getPagingInfo,'getPagingInfo');
    isa_ok($info->{db}, 'Tripletail::DB', 'db');
    is($info->{pagesize},30,'pagesize');
    is($info->{current},1,'current');
    is($info->{maxlinks},10,'maxlinks');
    is($info->{formkey},'pageid','formkey');
    #is($info->{formparam},undef,'formparam');
    is($info->{pagingtype},0,'pagingtype');
    is($info->{maxpages},4,'maxpage');
    is($info->{linkstart},1,'linkstart');
    is($info->{linkend},4,'linkend');
    is($info->{maxrows},100,'maxrows');
    is($info->{beginrow},0,'beginrow');
    is($info->{rows},30,'rows');

    ok($pager->setCurrentPage(2), 'setCurrentPage');
    ok($paging = $pager->paging($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'),'paging');

    ok($pager->setCurrentPage(3), 'setCurrentPage');
    ok($paging = $pager->paging($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'),'paging');

    ok($pager->setCurrentPage(4), 'setCurrentPage');
    ok($paging = $pager->paging($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'),'paging');

    is($pager->paging($t->node('paging'),['SELECT * FROM TripletaiL_DB_Test',0]), 0 ,'setCurrentPage');

    ok($pager = $TL->newPager, 'newPager');
    ok($pager = $TL->newPager('DB'), 'newPager (obsolute)');
    ok($pager = $TL->newPager($DB), 'newPager');

    dies_ok {$pager->setDbGroup(\123)} 'setDbGroup die (obsolute)';
    ok($pager->setDbGroup('DB'), 'setDbGroup (obsolute)');

    dies_ok {$pager->setPageSize} 'setPageSize die';
    dies_ok {$pager->setPageSize(\123)} 'setPageSize die';
    dies_ok {$pager->setPageSize('aaa')} 'setPageSize die';
    dies_ok {$pager->setPageSize(0)} 'setPageSize die';
    dies_ok {$pager->setPageSize(-10)} 'setPageSize die';
    ok($pager->setPageSize(100), 'setPageSize');

    dies_ok {$pager->setCurrentPage} 'setCurrentPage die';
    dies_ok {$pager->setCurrentPage(\123)} 'setCurrentPage die';
    dies_ok {$pager->setCurrentPage('aaa')} 'setCurrentPage die';
    dies_ok {$pager->setCurrentPage(0)} 'setCurrentPage die';
    dies_ok {$pager->setCurrentPage(-10)} 'setCurrentPage die';
    ok($pager->setCurrentPage(2), 'setCurrentPage');

    dies_ok {$pager->setMaxLinks} 'setMaxLinks die';
    dies_ok {$pager->setMaxLinks(\123)} 'setMaxLinks die';
    dies_ok {$pager->setMaxLinks('aaa')} 'setMaxLinks die';
    dies_ok {$pager->setMaxLinks(0)} 'setMaxLinks die';
    dies_ok {$pager->setMaxLinks(-10)} 'setMaxLinks die';
    ok($pager->setMaxLinks(1), 'setMaxLinks');

    dies_ok {$pager->setFormKey} 'setFormKey die';
    dies_ok {$pager->setFormKey(\123)} 'setFormKey die';
    ok($pager->setFormKey('PAGE'), 'setFormKey');

    dies_ok {$pager->setFormParam(\123)} 'setFormKey die';
    ok($pager->setFormParam($TL->newForm(ddd => 666)), 'setFormKey');
    ok($pager->setFormParam({ddd => 666}), 'setFormKey');

    dies_ok {$pager->setToLink(\123)} 'setToLink die';
    ok($pager->setToLink('PAGE'), 'setToLink');

    dies_ok {$pager->setPagingType} 'setPagingType die';
    dies_ok {$pager->setPagingType(\123)} 'setPagingType die';
    dies_ok {$pager->setPagingType('aaa')} 'setPagingType die';
    dies_ok {$pager->setPagingType(2)} 'setPagingType die';
    dies_ok {$pager->setPagingType(-10)} 'setPagingType die';
    ok($pager->setPagingType(1), 'setPagingType');

    my $TMPL2 = q{
  <!begin:paging>
    <!begin:PrevLink><a href="<&PREVLINK>">←前ページ</a><!end:PrevLink>
    <!begin:NoPrevLink>←前ページ<!end:NoPrevLink>
    <!begin:PageNumLinks>
      <!begin:ThisPage><&PAGENUM><!end:ThisPage>
      <!begin:OtherPage>
        <a href="<&PAGELINK>"><&PAGENUM></a>
      <!end:OtherPage>
    <!end:PageNumLinks>
    <!begin:NextLink><a href="<&NEXTLINK>">次ページ→</a><!end:NextLink>
    <!begin:NoNextLink>次ページ→<!end:NoNextLink>
    ...
    <!begin:Row>
      <&FOO> <&BAR> <&BAZ>
    <!end:Row>
    ...
  <!end:paging>
  <!-- 以下は Pager クラスの処理とは関係ないため、無くても良い -->
  <!begin:nodata>
    一件もありません
  <!end:nodata>
  <!begin:overpage>
    最大ページ数は<&MAXPAGES>です。
  <!end:overpage>
};

    $t->setTemplate($TMPL2);

    ok($paging = $pager->pagingArray($t->node('paging'), ['SELECT * FROM TripletaiL_DB_Test',100]),'pagingArray');
    if (!defined($paging)) {
        $info = $pager->getPagingInfo;
        $t->node('overpage')->add(MAXPAGES => $info->{maxpages});
    }
    elsif ($paging == 0) {
        $t->node('nodata')->add;
    }
    else {
        foreach my $key (@$paging) {
            $t->node('paging')->add(FOO => $key->[0],BAR => $key->[1],BAZ => $key->[2],);
        }
    }

    $t->setTemplate($TMPL2);

    ok($paging = $pager->pagingHash($t->node('paging'), ['SELECT * FROM TripletaiL_DB_Test',100]),'pagingHash');
    if (!defined($paging)) {
        $info = $pager->getPagingInfo;
        $t->node('overpage')->add(MAXPAGES => $info->{maxpages});
    }
    elsif ($paging == 0) {
        $t->node('nodata')->add;
    }
    else {
        foreach my $key (@$paging) {
            $t->node('paging')->add(FOO => $key->{foo},BAR => $key->{bar},BAZ => $key->{baz},);
        }
    }

    $t->setTemplate($TMPL);
    $pager = $TL->newPager('DB');
    ok($pager->setCurrentPage(5), 'setCurrentPage');
    is($pager->paging($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'), undef ,'paging');

    $t->setTemplate($TMPL);
    $pager = $TL->newPager('DB');
    ok($pager->setCurrentPage(5), 'setCurrentPage');
    is($pager->pagingArray($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'), undef ,'pagingArray');

    $t->setTemplate($TMPL);
    $pager = $TL->newPager('DB');
    ok($pager->setCurrentPage(5), 'setCurrentPage');
    is($pager->pagingHash($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'), undef ,'pagingHash');

    $t->setTemplate($TMPL);
    $pager = $TL->newPager('DB');
    ok($pager->setPagingType(1), 'setPagingType');
    ok($pager->setCurrentPage(5), 'setCurrentPage');
    ok($pager->paging($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'), 'paging');

    $t->setTemplate($TMPL);
    $pager = $TL->newPager('DB');
    ok($pager->setPagingType(1), 'setPagingType');
    ok($pager->setCurrentPage(5), 'setCurrentPage');
    ok($pager->pagingArray($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'), 'pagingArray');

    $t->setTemplate($TMPL);
    $pager = $TL->newPager('DB');
    ok($pager->setPagingType(1), 'setPagingType');
    ok($pager->setCurrentPage(5), 'setCurrentPage');
    ok($pager->pagingHash($t->node('paging'), 'SELECT * FROM TripletaiL_DB_Test'), 'pagingHash');

    $DB->execute(q{
        DROP TABLE TripletaiL_DB_Test
      });

}
