#!perl

use strict;
use warnings;

use Test::More tests => 4 * 8 + 4 * (2 * 6 + 1) + 10 + 1 + 1;

use lib 't/lib';
use VPIT::TestHelpers 'capture';

use Variable::Magic qw<wizard cast VMG_UVAR>;

sub expect {
 my ($name, $where, $suffix) = @_;
 $where  = defined $where ? quotemeta $where : '\(eval \d+\)';
 my $end = defined $suffix ? "$suffix\$" : '$';
 qr/^\Q$name\E at $where line \d+\.$end/
}

my @scalar_tests = (
 [ 'data', sub { \(my $x) },   sub { }                    ],
 [ 'get',  sub { \(my $x) },   sub { my $y = ${$_[0]} }   ],
 [ 'set',  sub { \(my $x) },   sub { ${$_[0]} = 1 }       ],
 [ 'len',  sub { [ 1 .. 3 ] }, sub { my $res = @{$_[0]} } ],
);

# Data, get, set, len

for my $t (@scalar_tests) {
 my ($name, $init, $code) = @$t;

 my $wiz = wizard $name => sub { die 'leek' };

 {
  local $@;
  eval {
   my $x = $init->();
   &cast($x, $wiz);
   $code->($x);
  };
  like $@, expect('leek', $0),
                            "die in $name callback (direct, \$@ unset) in eval";
 }

 {
  local $@;
  eval {
   my $x = $init->();
   &cast($x, $wiz);
   $@ = 'artichoke';
   $code->($x);
  };
  like $@, expect('leek', $0),
                              "die in $name callback (direct, \$@ set) in eval";
 }

 {
  local $@;
  eval q{BEGIN {
   my $x = $init->();
   &cast($x, $wiz);
   $code->($x);
  }};
  like $@, expect('leek', $0, "\nBEGIN.*"),
                           "die in $name callback (direct, \$@ unset) in BEGIN";
 }

 {
  local $@;
  eval q{BEGIN {
   my $x = $init->();
   &cast($x, $wiz);
   $@ = 'artichoke';
   $code->($x);
  }};
  like $@, expect('leek', $0, "\nBEGIN.*"),
                             "die in $name callback (direct, \$@ set) in BEGIN";
 }

 $wiz = wizard(
  ($name eq 'data' ? () : (data  => sub { $_[1] })),
   $name => sub { $_[1]->(); () },
 );

 {
  local $@;
  eval {
   my $x = $init->();
   &cast($x, $wiz, sub { die 'lettuce' });
   $code->($x);
  };
  like $@, expect('lettuce', $0),
                          "die in $name callback (indirect, \$@ unset) in eval";
 }

 {
  local $@;
  eval {
   my $x = $init->();
   &cast($x, $wiz, sub { die 'carrot' });
   $@ = 'artichoke';
   $code->($x);
  };
  like $@, expect('carrot', $0),
                          "die in $name callback (indirect, \$@ unset) in eval";
 }

 {
  local $@;
  eval q{BEGIN {
   my $x = $init->();
   &cast($x, $wiz, sub { die "pumpkin" });
   $code->($x);
  }};
  like $@, expect('pumpkin', undef, "\nBEGIN.*"),
                         "die in $name callback (indirect, \$@ unset) in BEGIN";
 }

 {
  local $@;
  eval q{BEGIN {
   my $x = $init->();
   &cast($x, $wiz, sub { die "chard" });
   $@ = 'artichoke';
   $code->($x);
  }};
  like $@, expect('chard', undef, "\nBEGIN.*"),
                           "die in $name callback (indirect, \$@ set) in BEGIN";
 }
}

# Free

{
 my $wiz   = wizard free => sub { die 'avocado' };
 my $check = sub { like $@, expect('avocado', $0), $_[0] };

 for my $local_out (0, 1) {
  for my $local_in (0, 1) {
   my $desc   = "die in free callback";
   if ($local_in or $local_out) {
    $desc .= ' with $@ localized ';
    if ($local_in and $local_out) {
     $desc .= 'inside and outside';
    } elsif ($local_in) {
     $desc .= 'inside';
    } else {
     $desc .= 'outside';
    }
   }

   local $@ = $local_out ? 'xxx' : undef;
   eval {
    local $@ = 'yyy' if $local_in;
    my $x;
    cast $x, $wiz;
   };
   $check->("$desc at eval BLOCK 1a");

   local $@ = $local_out ? 'xxx' : undef;
   eval q{
    local $@ = 'yyy' if $local_in;
    my $x;
    cast $x, $wiz;
   };
   $check->("$desc at eval STRING 1a");

   local $@ = $local_out ? 'xxx' : undef;
   eval {
    my $x;
    local $@ = 'yyy' if $local_in;
    cast $x, $wiz;
   };
   $check->("$desc at eval BLOCK 1b");

   local $@ = $local_out ? 'xxx' : undef;
   eval q{
    my $x;
    local $@ = 'yyy' if $local_in;
    cast $x, $wiz;
   };
   $check->("$desc at eval STRING 1b");

   local $@ = $local_out ? 'xxx' : undef;
   eval {
    local $@ = 'yyy' if $local_in;
    my $x;
    my $y = \$x;
    &cast($y, $wiz);
   };
   $check->("$desc at eval BLOCK 2a");

   local $@ = $local_out ? 'xxx' : undef;
   eval q{
    local $@ = 'yyy' if $local_in;
    my $x;
    my $y = \$x;
    &cast($y, $wiz);
   };
   $check->("$desc at eval STRING 2a");

   local $@ = $local_out ? 'xxx' : undef;
   eval {
    my $x;
    my $y = \$x;
    local $@ = 'yyy' if $local_in;
    &cast($y, $wiz);
   };
   $check->("$desc at eval BLOCK 2b");

   local $@ = $local_out ? 'xxx' : undef;
   eval q{
    my $x;
    my $y = \$x;
    local $@ = 'yyy' if $local_in;
    &cast($y, $wiz);
   };
   $check->("$desc at eval STRING 2b");

   local $@ = $local_out ? 'xxx' : undef;
   eval {
    local $@ = 'yyy' if $local_in;
    my $x;
    cast $x, $wiz;
    my $y = 1;
   };
   $check->("$desc at eval BLOCK 3");

   local $@ = $local_out ? 'xxx' : undef;
   eval q{
    local $@ = 'yyy' if $local_in;
    my $x;
    cast $x, $wiz;
    my $y = 1;
   };
   $check->("$desc at eval STRING 3");

   local $@ = $local_out ? 'xxx' : undef;
   eval {
    local $@ = 'yyy' if $local_in;
    {
     my $x;
     cast $x, $wiz;
    }
   };
   $check->("$desc at block in eval BLOCK");

   local $@ = $local_out ? 'xxx' : undef;
   eval q{
    local $@ = 'yyy' if $local_in;
    {
     my $x;
     cast $x, $wiz;
    }
   };
   $check->("$desc at block in eval STRING");

   ok defined($desc), "$desc did not over-unwind the save stack";
  }
 }
}

my $wiz;

eval {
 $wiz = wizard data => sub { $_[1] },
               free => sub { $_[1]->(); () };
 my $x;
 cast $x, $wiz, sub { die "spinach" };
};

like $@, expect('spinach', $0), 'die in sub in free callback';

eval {
 $wiz = wizard free => sub { die 'zucchini' };
 $@ = "";
 {
  my $x;
  cast $x, $wiz;
 }
 die 'not reached';
};

like $@, expect('zucchini', $0),
                          'die in free callback in block in eval with $@ unset';

eval {
 $wiz = wizard free => sub { die 'eggplant' };
 $@ = "artichoke";
 {
  my $x;
  cast $x, $wiz;
 }
 die 'not reached again';
};

like $@, expect('eggplant', $0),
                            'die in free callback in block in eval with $@ set';

eval q{BEGIN {
 $wiz = wizard free => sub { die 'onion' };
 my $x;
 cast $x, $wiz;
}};

like $@, expect('onion', undef, "\nBEGIN.*"), 'die in free callback in BEGIN';

eval q{BEGIN {
 $wiz = wizard data => sub { $_[1] },
               len  => sub { $_[1]->(); $_[2] },
               free => sub { my $x = @{$_[0]}; () };
 my @a = (1 .. 5);
 cast @a, $wiz, sub { die "pepperoni" };
}};

like $@, expect('pepperoni', undef, "\nBEGIN.*"),
                                'die in free callback in len callback in BEGIN';

# Inspired by B::Hooks::EndOfScope

eval q{BEGIN {
 $wiz = wizard data => sub { $_[1] },
               free => sub { $_[1]->(); () };
 $^H |= 0x020000;
 cast %^H, $wiz, sub { die 'cabbage' };
}};

like $@, expect('cabbage'), 'die in free callback at end of scope';

use lib 't/lib';

my $vm_tse_file = 't/lib/Variable/Magic/TestScopeEnd.pm';

eval "use Variable::Magic::TestScopeEnd";
like $@, expect('turnip', $vm_tse_file, "\nBEGIN(?s:.*)"),
        'die in BEGIN in require in eval string triggers hints hash destructor';

eval q{BEGIN {
 Variable::Magic::TestScopeEnd::hook {
  pass 'in hints hash destructor 2';
 };
 die "tomato";
}};

like $@, expect('tomato', undef, "\nBEGIN.*"),
                          'die in BEGIN in eval triggers hints hash destructor';

SKIP: {
 my $count = 1;

 my ($stat, $out, $err) = capture_perl <<' CODE';
use Variable::Magic qw<wizard cast>; { BEGIN { $^H |= 0x020000; cast %^H, wizard free => sub { die q[cucumber] } } }
 CODE
 skip CAPTURE_PERL_FAILED($out) => $count unless defined $stat;
 like $err, expect('cucumber', '-e', "\nExecution(?s:.*)"),
            'die in free callback at compile time and not in eval string';
 --$count;
}

# Uvar

SKIP:
{
 my $count = 1;

 skip 'No nice uvar magic for this perl' => $count unless VMG_UVAR;

 my ($stat, $out, $err) = capture_perl <<' CODE';
use Variable::Magic qw<wizard cast>; BEGIN { cast %derp::, wizard fetch => sub { die q[raddish] } } derp::hlagh()
 CODE
 skip CAPTURE_PERL_FAILED($out) => $count unless defined $stat;
 like $err, expect('raddish', '-e', "\nExecution(?s:.*)"),
            'die in free callback at compile time and not in eval string';
 --$count;
}
