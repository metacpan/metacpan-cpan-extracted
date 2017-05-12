use Test::More;
use strict; use warnings FATAL => 'all';

use Text::ZPL::Stream;

my $zpl = do { local $/; <DATA> };

my $expected = +{
  toplevel  => 123,
  quoted    => 'foo bar',
  unmatched => q{"foo'},

  context => +{
    iothreads => 1,
    verbose   => 1,
  },

  main => +{
    type => 'zmq_queue',
    frontend => +{
      option => +{
        hwm  => 1000,
        swap => '25000000',
        subscribe => '#2',
      },
      bind => 'tcp://eth0:5555',
    },
    backend => +{
      bind => 'tcp://eth0:5556',
    },
  },

  emptysection => +{},

  other => +{
    list => [
      'foo bar', 'baz quux', 'weeble'
    ],
    deeper => +{
      list2 => [ 123, 456 ],
    },
  }
};


# One arg, two chars per:
{
  my $stream = Text::ZPL::Stream->new;
  no warnings 'substr';
  my $tmp = $zpl;
  while (length $tmp) {
    my $chrs = substr $tmp, 0, 2, '';
    $stream->push($chrs);
  }
  is_deeply $stream->get, $expected,
    'one arg push w/ two chars per ok';
}

# Multi-arg:
{
  my $stream = Text::ZPL::Stream->new;
  my @lines = split "\n", $zpl;
  my $expected_lcount = @lines;
  # push retval:
  cmp_ok
    $stream->push(map $_."\n", split "\n", $zpl),
    '==', 
    $expected_lcount,
    'push returned expected linecount';
  is_deeply $stream->get, $expected,
    'multi-arg push ok';
}

# Mixed newlines:
{
  my $stream = Text::ZPL::Stream->new;
  my $mixed_nl = "foo=1\015\012bar=2\012baz=3\015quux=weeble\n";
  $stream->push($mixed_nl);
  is_deeply $stream->get,
    +{ foo => 1, bar => 2, baz => 3, quux => 'weeble' },
    'mixed newlines push ok';
}

# Max buf size exceeded
{
  my $stream = Text::ZPL::Stream->new(
    max_buffer_size => 5,
  );
  cmp_ok $stream->max_buffer_size, '==', 5,
    'max_buffer_size accessor ok';
  $stream->push("foo=1\n");
  is_deeply $stream->get,
    +{ foo => 1 },
    'max_buffer_size push ok';
  $stream->push("bar=2\n");
  is_deeply $stream->get,
    +{ foo => 1, bar => 2 },
    'max_buffer_size push second line ok';
  eval {; $stream->push("baz=10\n") };
  like $@, qr/maximum buffer size/, 'exceeding buffer died ok';
}

# get_buffer
{
  my $stream = Text::ZPL::Stream->new;
  $stream->push("foo");
  cmp_ok $stream->get_buffer, 'eq', 'foo', 'get_buffer ok';
}

# Parser failures
{
  my $stream = Text::ZPL::Stream->new;
  $stream->push("foo\n");
  $stream->push(' ' x 8);
  eval {; $stream->push("bar = 1\n") };
  like $@, qr/parent/, "parser failure in stream dies";
}

# FIXME test other parse fails?

done_testing;

__DATA__
toplevel = 123
quoted   = "foo bar"
unmatched = "foo'
# There's a comment here
# and here

context #
    iothreads = 1   # With trailing comment
    verbose   = 1 #

main                # Section head with trailing comment
    type = zmq_queue
    frontend
        option
            hwm  = 1000
            swap = 25000000
            subscribe = "#2"
        bind = tcp://eth0:5555
    backend
        bind = tcp://eth0:5556

emptysection

other
    list = "foo bar"
    list = 'baz quux'  #
    list = weeble
    deeper
        list2 = 123
        list2 = 456
