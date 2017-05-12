#! /usr/bin/perl -wT
use 5.010; use strict; use warnings;
use Test::More 0.92; BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};

#use re 'regexp_pattern';

my @cases = (
  [ 'Hello' => 'Hello' => "Plain text" ],
  [ 'He?lo' => 'He.lo' => "Dot in middle" ],
  [ 'He*lo' => 'He.*?lo' => "Wildcard in middle" ], # was: % .*
  [ 'Hello ?' => 'Hello\ .' => "Trailing dot" ], # spaces were \
  [ '? World' => '.\ World' => "Leading dot" ],
  [ 'Hello *' => 'Hello\ .*?' => "Trailing wildcard" ],
  [ '* World' => '.*?\ World' => "Leading wildcard" ],
  [ 'He\\.lo' => 'He\.lo' => "Escaped dot" ],
  [ 'He\\*lo' => 'He\*lo' => "Escaped wildcard" ],
  [ 'He\\\\o' => 'He\\\\o' => "Escaped backslash" ],
  [ 'He\\\\.o' => 'He\\\\\.o' => "Backslash and dot" ],
  [ 'He\\\\?o' => 'He\\\\.o' => "Backslash and dot" ],
  [ 'He\\\\*o' => 'He\\\\.*?o' => "Backslash and wildcard" ],
  [ 'He\\\\\\?o' => 'He\\\\\?o' => "Backslashx2 and ?" ],
  [ 'He\\\\\\*o' => 'He\\\\\*o' => "Backslashx2 and *" ],
  [ 'Hello W?*?d' => 'Hello\\ W..*?.d' => "Mixed ? and *" ],
  [ 'Hello W?\\*?d' => 'Hello\\ W.\\*.d' => "Mixed ? and escaped *" ],
);

#use Regexp::SQL::LIKE qw/to_regexp/;
use Text::Glob::DWIW 'tg_re';

plan tests => 1+@cases;

for my $c ( @cases ) {
  my ( $like, $expect, $label) = @$c;
  #my ($pat, $mods) = regexp_pattern(to_regexp($like));
  my $pat=tg_re $like; $expect=qr/^(?:$expect)\z/s;
  is ($pat, $expect, $label );
}

had_no_warnings();
#done_testing;
