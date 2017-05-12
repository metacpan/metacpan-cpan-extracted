use strict;
use warnings;

use Test::More;

{
  package Some::Exception;
  use Moose;

  with 'Throwable::X';
  use Throwable::X -all;

  sub x_tags { qw(whatever) }

  has size => (
    is   => 'ro',
    isa  => 'Int',
    lazy => 1,
    traits  => [ Payload ],
    default => 36,
  );

  has private_thing => (
    is      => 'ro',
    isa     => 'Int',
    default => 13,
  );
}

{
  my $ok = eval {
    Some::Exception->throw({
      ident   => 'pants too small',
      message => "can't fit into pants under %{size;inch}n",
      tags    => [ qw(foo-bar zug) ],
    });
    1;
  };

  my $err = $@;
  ok(!$ok, "->throw died");
  isa_ok($err, 'Some::Exception', '...the thrown error');

  is_deeply(
    $err->payload,
    {
      size => 36,
    },
    "...and the payload is correct",
  );

  is(
    $err->message,
    "can't fit into pants under 36 inches",
    "...and msg formats",
  );

  ok(
    $err->has_tag('foo-bar') && $err->has_tag('whatever') && ! $err->has_tag('xyz'),
    "...and its tags seem correct via ->has_tag",
  );
}

{
  my $ok = eval { Some::Exception->throw("everything is broken"); };
  my $err = $@;
  ok(!$ok, "->throw died");
  isa_ok($err, 'Some::Exception', '...the thrown error');

  is($err->message, "everything is broken", "...single-arg-generated message");
  is($err->ident,   "everything is broken", "...single-arg-generated ident");
}

done_testing;
