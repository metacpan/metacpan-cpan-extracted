#!perl -w
use strict;
use utf8;
use Test::More;
binmode STDOUT, ":utf8";
use WordLists::Sort::Typical qw(/.*/);

#Résumé

ok( 
	('a' cmp 'b') == -1, 
	'Sanity: a sorts before b' 
);
ok( 
	(1 <=> 2) == -1, 
	'Sanity: 1 sorts before 2' 
);

ok( 
	(cmp_alnum ('a1' , 'a02')) == -1, 
	'a1<a02'
);
ok( 
	(cmp_alnum ('a' , 'a+')) == -1, 
	'cmp_alnum: a<a+'
);
ok( 
	(cmp_alnum_only ('a' , 'A')) == 0, 
	'cmp_alnum_only: a=A'
);
ok( 
	(cmp_alnum_only ('a' , 'A+')) == 0, 
	'cmp_alnum_only: a=A+'
);
ok( 
	(cmp_alnum_only ('a1' , 'a 2')) == -1, 
	'cmp_alnum_only: a1<a 2'
);
ok( 
	(cmp_alnum_only ('a1' , 'a02')) == -1,
	'cmp_alnum_only: a1<a02'
);
ok( 
	(cmp_accnum ('o' , 'õ')) == 0, 
	'cmp_accnum: o = õ'
);
ok( 
	(cmp_accnum ('O' , 'õ')) == 0, 
	'cmp_accnum: O = õ'
);
ok( 
	(cmp_accnum ('o' , 'õ')) == 0, 
	'cmp_accnum: o = o+[combining tilde]'
);
ok( 
	(cmp_accnum ('do' , 'dõ')) == 0, 
	'cmp_accnum: do = dõ'
);
ok( 
	(cmp_accnum ('doë' , 'dõë')) == 0, 
	'cmp_accnum: doë = dõë'
);
ok( 
	(cmp_accnum ('do ë' , 'dõë')) == -1, 
	'cmp_accnum: do ë < dõë'
);
ok( 
	(cmp_accnum_only ('do ë' , 'dõë')) == 0, 
	'cmp_accnum_only: do ë = dõë'
);
ok( 
	(cmp_accnum_only (' áb' , 'bb')) == -1, 
	'cmp_accnum_only: " áb" < "bb"'
);
ok( 
	(cmp_accnum_only ('a1' , 'a02')) == -1,
	'cmp_accnum_only: a1<a02'
);
ok( 
	(cmp_dict ('internet' , 'the internet')) == -1, 
	'cmp_dict: "internet" < "the internet"'
);
ok( 
	(cmp_dict ('the internet' , 'the Internet')) == -1, 
	'cmp_dict: "the internet" < "the Internet"'
);
ok( 
	(cmp_dict ('the internet' , 'internets')) == -1, 
	'cmp_dict: "the internet" < "internets"'
);
ok( 
	(cmp_dict ("ab" , "AB")) == -1, 
	'cmp_dict: "ab" < "AB"'
);
ok( 
	(cmp_dict ("ab" , "A B")) == -1, 
	'cmp_dict: "ab" < "A B"'
);
ok( 
	(cmp_dict ("ë" , "E")) == -1, 
	'cmp_dict: "ë" < "E"'
);
ok( 
	(cmp_dict ("E" , "Ë")) == -1, 
	'cmp_dict: "E" < "Ë"'
);
ok( 
	(cmp_ver ('1.1' , '1.01')) == 0, 
	'cmp_ver: 1.1=1.01'
);
ok( 
	(cmp_ver ('1:1' , '1:1')) == 0, 
	'cmp_ver: 1:1=1:1'
);
ok( 
	(cmp_ver ('1.1' , '1:1')) == 0, 
	'cmp_ver: 1.1=1:1'
);
ok( 
	(cmp_ver ('2' , '3')) == -1,
	'cmp_ver: 2<3'
);
ok( 
	(cmp_ver ('1:2' , '1:3')) == -1,
	'cmp_ver: 1:2<1:3'
);
ok( 
	(cmp_ver ('1:2a' , '1:2b')) == -1, 
	'cmp_ver: 1:2a<1:2b'
);
ok( 
	(cmp_ver ('v1.2' , '1.02')) == 0, 
	'cmp_ver: v1.2=1.02'
);
ok( 
	(cmp_ver ('1:2.a.' , '1:2.a.1')) == -1, 
	'cmp_ver: 1:2.a.<1:2.a.1'
);
ok( 
	(cmp_ver ('1:2a' , '1:2a1')) == -1, 
	'cmp_ver: 1:2a<1:2a1'
);

ok( 
	(cmp_ver ('1.11' , '1.11a')) == -1, 
	'cmp_ver: 1.11<1.11a'
);
ok( 
	(cmp_ver ('1.11.' , '1.11.a')) == -1, 
	'cmp_ver: 1.11.<1.11.a'
);
ok( 
	(cmp_ver ('1.11.a' , '1.11a')) == -1, 
	'cmp_ver: 1.11.a>1.11a'
);
ok( 
	(cmp_ver ('1.11.A' , '1.11.a')) == 0, 
	'cmp_ver: 1.11.A=1.11.a'
);
ok( 
	(cmp_ver ('1.11.a' , '1.11.1')) == -1, 
	'cmp_ver: 1.11.a<1.11.1'
);

done_testing;
