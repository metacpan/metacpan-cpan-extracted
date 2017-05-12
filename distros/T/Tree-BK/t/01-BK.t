#Test all of the functionality of the BK tree

use strict;
use warnings;
use Test::More;
plan tests => 6;
use Test::Exception;
use Tree::BK;

throws_ok {
    my $bk = Tree::BK->new('foo');
    } qr'argument to new\(\) should be a code reference implementing a metric',
    'Constructor dies with bad metric argument';
test_insert();
test_find();

sub test_insert {
    my $bk = Tree::BK->new();
    is($bk->size, 0, 'size before insert is zero');

    subtest 'insert' => sub {
        plan tests => 4;
        is($bk->insert('stuff'), 'stuff',
            'returns newly inserted items');
        is($bk->size, 1, 'increments size when given a new item');
        ok(!defined $bk->insert('stuff'),
            'returns nothing for previously inserted items');
        is($bk->size, 1,
            'does not increment size for previously inserted items');
    };

    is($bk->insert_all('stuff', 'foo', 'bar', 'qux'), 3,
        'insert_all returns number of new items inserted');
    return;
}

sub test_find {
    my $bk = Tree::BK->new();
    $bk->insert_all(qw(cuba cubic cube cubby thing foo bar));
    my @found = sort @{ $bk->find('cube', 2) };
    is_deeply(\@found, [qw(cuba cubby cube cubic)],
        'correctly finds strings using default distance metric');

    $bk = Tree::BK->new(
        sub {
            my ($a, $b) = @_;
            my $diff = $a - $b;
            if($diff < 0){
                return -$diff;
            }
            return $diff;
        }
    );
    $bk->insert_all(2, 3, 4, 5, 6);
    @found = sort @{ $bk->find(3, 1) };
    is_deeply(\@found, [2, 3, 4],
        'finds correct words within distance of');
}
