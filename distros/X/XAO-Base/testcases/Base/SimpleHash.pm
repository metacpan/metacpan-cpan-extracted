package testcases::Base::SimpleHash;
use strict;
use XAO::SimpleHash;

use base qw(testcases::Base::base);

sub test_everything {
    my $self=shift;

    my $sh=new XAO::SimpleHash(a => 1, b => 2);
    $self->assert($sh->get('a') == 1,
                  "get() - wrong value");
    $self->assert($sh->defined('a'),
                  "'a' is not defined and should be");
    $self->assert(! $sh->defined('A'),
                  "'A' is defined but should not be");

    $sh->put(c => 3);
    $self->assert($sh->get('c') == 3,
                  "Wrong value for 'c'");

    $sh->fill({ a => 11, d => 4});
    $self->assert($sh->get('a') == 11 && $sh->get('d') == 4,
                  "Fill() breaks on hash reference");

    $sh->fill(b => 22, c => 33);
    $self->assert($sh->get('b') == 22 && $sh->get('c') == 33,
                  "Fill() breaks on hash");

    $sh->fill([d => 44], [e => 55]);
    $self->assert($sh->get('d') == 44 && $sh->get('e') == 55,
                  "Fill() breaks on array references");

    my $got=join(',',sort $sh->values);
    $self->assert($got eq '11,22,33,44,55',
                  "Wrong list from values ($got)");

    $self->assert(join(',',sort $sh->keys) eq 'a,b,c,d,e',
                  "Wrong list from keys()");

    $sh->delete('a');
    $self->assert(! $sh->contains(12),
                  "Value is still available after delete");

    $self->assert($sh->contains(22) eq 'b',
                  "Contains(22) returned wrong value");

    $self->assert($sh->put('/test/foo/bar' => 123) == 123,
                  "Put doesn't work with URI");

    $self->assert(ref($sh->get('test/foo')) eq 'HASH',
                  "Put(uri) created incorrect structure");

    $self->assert($sh->exists('//test//foo///bar'),
                  "Exists does not work on URIs");
    $self->assert(! $sh->exists('//test//foo///BAR'),
                  "Exists does not work on URIs (2)");

    $self->assert($sh->get('test')->{foo}->{bar} == 123,
                  "Get returned incorrect hash structure");

    $sh->put('test/foo/bar' => undef);
    $self->assert($sh->exists('//test//foo///bar'),
                  "Exists does not work right on URI");

    $self->assert(! $sh->defined('//test//foo///bar'),
                  "Defined does not work right on URI");

    $sh->put('test//foo/aaa' => 'AAA');
    $self->assert($sh->get('test/foo/aaa') eq 'AAA',
                  "Deep put does not work");

    $sh->delete('test/foo');
    $self->assert(! $sh->exists('//test//foo'),
                  "Element still exists after deleting an URI");
    $self->assert(! $sh->exists('//test//foo/bar'),
                  "Element still exists after deleting an URI (2)");

    my $clone=$sh->new(foo => 'bar');
    $self->assert(ref($clone),
                  "Can't clone SimpleHash object");
    $self->assert($clone->get('foo') eq 'bar',
                  "Passing initialization parameters does not work");
}

1;
