#!perl

use strict;
use warnings;

use Test::More;
use Wurm::Grub::REST;

sub one {$_[0]->{_}}

my $grub = Wurm::Grub::REST->new
  ->get   ((\&one) x 2)
  ->post  (\&one)
  ->put   ((\&one) x 2)
  ->patch (\&one)
  ->delete(\&one)
;
isa_ok($grub, 'Wurm::let');

my $bulk = $grub->molt;

is($bulk->{body}{get}   ->(_meal('nde', undef)),    'nde', 'list');
is($bulk->{body}{get}   ->(_meal(undef, undef))->[0], 404, 'list (404)');
is($bulk->{body}{get}   ->(_meal('nde', 'nde')),    'nde', 'get');
is($bulk->{body}{get}   ->(_meal(undef, 'nde'))->[0], 404, 'get (404)');
is($bulk->{body}{put}   ->(_meal('nde', undef)),    'nde', 'put');
is($bulk->{body}{put}   ->(_meal(undef, undef))->[0], 400, 'put (400)');
is($bulk->{body}{put}   ->(_meal('nde', 'nde')),    'nde', 'put');
is($bulk->{body}{put}   ->(_meal(undef, 'nde'))->[0], 302, 'put (302)');
is($bulk->{body}{patch} ->(_meal('nde', undef))->[0], 404, 'patch (404)');
is($bulk->{body}{patch} ->(_meal(undef, undef))->[0], 404, 'patch (404)');
is($bulk->{body}{patch} ->(_meal('nde', 'nde')),    'nde', 'patch');
is($bulk->{body}{patch} ->(_meal(undef, 'nde'))->[0], 404, 'patch (404)');
is($bulk->{body}{delete}->(_meal('nde', undef))->[0], 404, 'delete (404)');
is($bulk->{body}{delete}->(_meal(undef, undef))->[0], 404, 'delete (404)');
is($bulk->{body}{delete}->(_meal('nde', 'nde')),    'nde', 'delete');
is($bulk->{body}{delete}->(_meal(undef, 'nde'))->[0], 404, 'delete (404)');

done_testing();

sub _meal {
  my ($cast, $id) = @_;

  return {
    _    => $cast,
    grit => {id => $id},
    env  => { }
  }
}
