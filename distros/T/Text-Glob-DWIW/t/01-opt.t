#! /usr/bin/perl -wT
# Options handling which is not tested anywhere else.

use v5.10; use strict; use warnings;
use Test::More tests => 30; use Config;       BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};
use Text::Glob::DWIW qw':all';
my $p; my @v; my $sec='tilde';

sub handling ($$$)
{ my ($what,$arg,$delim)=@_;
  return unless $what eq '~' && $arg!~/[^a-z]/ && $delim=~qr'^/?$'; # dont change
  return '/home/my_sweet' if $arg eq '';
  return "/home/$arg"
}

is_deeply [tg_expand $p='~{foo,bar}{,/,/bla}',{tilde=>'/home/'}],
          [tg_expand '/home/{foo,bar}{,/,/bla}'],"$sec: $p";
is_deeply [tg_expand $p='{~foo,~bar}{,/,/bla}',{tilde=>'/home/'}],
          [tg_expand '/home/{foo,bar}{,/,/bla}'],"$sec: $p";
is_deeply [tg_expand $p='{foo,bar}~{,/,/bla}',{tilde=>'/home/'}],
          [tg_expand $p],"$sec: $p";
is_deeply [tg_expand $p='~{foo,bar,,+10}{,/,/bla}',{tilde=>\&handling}],
          [tg_expand '/home/{foo,bar,my_sweet}{,/,/bla}','~+10{,/,/bla}'],"$sec: $p";

$sec='overload';
is int(tg_expand '[ab]'), 2, "$sec: int";
is_deeply [@{tg_expand '[ab]'}], [qw'a b'], "$sec: \@ 1";
{ my $obj=tg_expand '[ab]';
  SKIP: { skip "no qr overload before 5.12",3 if $]<=5.012;
    ok 'a'=~$obj,   "$sec: re 1"; # 5.10 failed
    ok 'a'=~/$obj/, "$sec: re 2"; # 5.10 failed
    is qr/$obj/,   qr/^(?:a|b)\z/s, "$sec: re 3"; # 5.10 failed (?-xism:2)
  }
  is $obj->as_re,qr/^(?:a|b)\z/s, "$sec: re 4";
  is $$obj, 'a',   "$sec: iter 1";
  is $$obj, 'b',   "$sec: iter 2";
  is $$obj, undef, "$sec: iter 3";
  is $$obj, 'a',   "$sec: iter 4";
  is <$obj>, 'b',  "$sec: iter 5";
  is_deeply \@$obj, [qw'a b'], "$sec: \@ 2";
}

my $def=tg_options;
$sec='use & option hash';
subtest $sec => sub { plan tests => 4;
  { use Text::Glob::DWIW ':all', { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    { use Text::Glob::DWIW ':all', { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use if & option hash'; # if in core since 5.6.2
subtest $sec => sub { plan tests => 4;
  { use if 1, 'Text::Glob::DWIW', ':all', { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    { use if 1, 'Text::Glob::DWIW', ':all', { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use maybe & option hash'; # if in core since 5.6.2
our $maybe;
BEGIN { $maybe=eval { require maybe }; }
subtest $sec => sub {
  plan skip_all => 'yes or no, but no maybe' if !$maybe;
  plan tests => 4;
  { use if $maybe, 'maybe', 'Text::Glob::DWIW', ':all', { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    { use if $maybe, 'maybe', 'Text::Glob::DWIW', ':all', { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use & tg_options';
subtest $sec => sub { plan tests => 7;
  { use Text::Glob::DWIW; tg_options { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    { use Text::Glob::DWIW; tg_options { case => 0 };
      is tg_options->{capture},1,"$sec: capture=>1 thro";
      is tg_options->{case},0,"$sec: case=>0";
      tg_options { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
      is tg_options->{case},0,"$sec: case=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use {} & tg_options';
subtest $sec => sub { plan tests => 13;
  { use Text::Glob::DWIW { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    is tg_options->{case},1,"$sec: case=>1";
    tg_options { case => 0 };
    is tg_options->{capture},1,"$sec: capture=>1";
    is tg_options->{case},0,"$sec: case=>0";
    { use Text::Glob::DWIW { case => 1 };
      is tg_options->{capture},1,"$sec: capture=>1";
      is tg_options->{case},1,"$sec: case=>1";
      tg_options { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
      is tg_options->{case},1,"$sec: case=>1";
      tg_options { case => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
      is tg_options->{case},0,"$sec: case=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
    is tg_options->{case},0,"$sec: case=>0";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='multiple use';
subtest $sec => sub { plan tests => 2;
  use Text::Glob::DWIW { case => 2 };
  is tg_options->{case},2,"$sec: case=>2";
  use Text::Glob::DWIW { case => 3 };
  is tg_options->{case},3,"$sec: case=>3";
};

$sec='use inside loop';
subtest $sec => sub { plan tests => 5;
  for my $val (1..4)
  { use Text::Glob::DWIW { case => 0 }; # only set at compile time
    tg_options case=>1+tg_options->{case};
    is tg_options->{case},$val,"$sec: case=>$val";
  }
  is tg_options->{case},$def->{case},"$sec: l0"; # back in outer scope
};

# ----

use Text::Glob::DWIW ':use';
$sec='use & option hash';
subtest $sec => sub { plan tests => 4;
  { use TGDWIW { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    { use TGDWIW { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use if & option hash'; # if in core since 5.6.2
subtest $sec => sub { plan tests => 4;
  { use if 1, 'TGDWIW', { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    { use if 1, 'TGDWIW', { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use & tg_options';
subtest $sec => sub { plan tests => 7;
  { use TGDWIW; tg_options { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    { use TGDWIW; tg_options { case => 0 };
      is tg_options->{capture},1,"$sec: capture=>1 thro";
      is tg_options->{case},0,"$sec: case=>0";
      tg_options { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
      is tg_options->{case},0,"$sec: case=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='use {} & tg_options';
subtest $sec => sub { plan tests => 13;
  { use TGDWIW { capture => 1 };
    is tg_options->{capture},1,"$sec: capture=>1";
    is tg_options->{case},1,"$sec: case=>1";
    tg_options { case => 0 };
    is tg_options->{capture},1,"$sec: capture=>1";
    is tg_options->{case},0,"$sec: case=>0";
    { use TGDWIW { case => 1 };
      is tg_options->{capture},1,"$sec: capture=>1";
      is tg_options->{case},1,"$sec: case=>1";
      tg_options { capture => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
      is tg_options->{case},1,"$sec: case=>1";
      tg_options { case => 0 };
      is tg_options->{capture},0,"$sec: capture=>0";
      is tg_options->{case},0,"$sec: case=>0";
    }
    is tg_options->{capture},1,"$sec: capture=>1 back";
    is tg_options->{case},0,"$sec: case=>0";
  }
  is_deeply scalar tg_options,$def,"$sec: l0";
};

$sec='multiple use';
subtest $sec => sub { plan tests => 2;
  use TGDWIW { case => 2 };
  is tg_options->{case},2,"$sec: case=>2";
  use TGDWIW { case => 3 };
  is tg_options->{case},3,"$sec: case=>3";
};

$sec='use inside loop';
subtest $sec => sub { plan tests => 5;
  for my $val (1..4)
  { use TGDWIW { case => 0 }; # only set at compile time
    tg_options case=>1+tg_options->{case};
    is tg_options->{case},$val,"$sec: case=>$val";
  }
  is tg_options->{case},$def->{case},"$sec: l0"; # back in outer scope
};

had_no_warnings();
#done_testing;

# todo; star, twin, ...: unterschiedliche Optionen
