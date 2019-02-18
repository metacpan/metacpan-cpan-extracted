use Test2::V0 -no_srand => 1;
use Alien::libt2t;

subtest 'basics' => sub {

  isa_ok(Alien::libt2t->new, 'Alien::libt2t'); # we don't actually use this.

  ok(Alien::libt2t->cflags);
  ok(Alien::libt2t->libs);

  diag '';
  diag '';
  diag '';
  diag("cflags = @{[ Alien::libt2t->cflags ]}");
  diag("libs   = @{[ Alien::libt2t->libs   ]}");
  diag '';
  diag '';

};

done_testing;
