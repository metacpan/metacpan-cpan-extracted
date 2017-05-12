# $Id: unqualified.t 113 2006-08-13 05:42:19Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 9;
}

lives_ok( sub {
    use classes name=>'Unqual', new=>'classes::new_only', attrs=>['foo'], unqualified=>1;
    use classes name=>'Qual', new=>'classes::new_only', attrs=>['foo'];
}, 'unqualifed');
isa_ok my $o1 = Unqual->new, 'Unqual'; 
isa_ok my $o2 = Qual->new, 'Qual'; 
is $o1->set_foo(1), undef;
is $o2->set_foo(2), undef;
is $o1->{'foo'}, 1;
is $o1->{'Unqual::foo'}, undef;
is $o2->{'Qual::foo'}, 2;
is $o2->{'foo'}, undef;

