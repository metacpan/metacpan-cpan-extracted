#!/usr/bin/perl -wT

#stolen from: RegexpShellish.t - Test suite for RegexpShellish

use strict; use warnings;
use Test::More;

use Text::Glob::DWIW ':all';

my @samples = qw(
   ac   AC    abc  ABC
   a/c  A/C   xaz  xbz  xcz   q...t
) ;

sub k {
   my $expected ;
   (my $re, $expected ) = @_ ;
   #$re = compile_shellish( $re, @_ > 2 ? pop : () ) ;
   #@_ = ( join( ',', shellish_glob( $re, @samples ) ), $expected,  "/$re/" ) ;
   #goto &ok;
   my @o=@_>2 ? pop : ();
   @_=(join(',',tg_grep($re,@samples,@o)),$expected,"resh: $re");
   goto &is; # goto &... => line number fits
}


my @tests = (
  #sub {k( qr/a.*c/,     'ac,abc,a/c'         )},          # qr fallthrough not supported
  sub {k( 'a.*c',       ''                    )},
  sub {k( 'a?c',        'abc',                {unchar=>'/'} )}, # unchar=>'/' is not default
  sub {k( 'a?c',        'abc,a/c',            )},              # +
  sub {k( 'a?c',        'abc,a/c',            {unchar=>''}  )}, # +
  sub {k( 'a\*c',       '',                   )},
  sub {k( 'a\?c',       '',                   )},
  #sub {k( 'a\bc',       'abc',               )},              # no 'a\\bc' ne 'abc'
  sub {k( 'a\(c',       '',                   )},
  sub {k( 'a\)c',       '',                   )},
  sub {k( 'a\{c',       '',                   )},
  sub {k( 'a\}c',       '',                   )},

  sub {k( 'a*c',        'ac,abc',             { unchar=>'/'} )},
  sub {k( 'a*c',        'ac,abc',             { unchar=>'/',case => 1 } )},#case_sensitive
  sub {k( 'a*c',        'ac,AC,abc,ABC',      { unchar=>'/',case => 0 } )},

  sub {k( 'a**c',       'ac,abc,a/c',         )}, # / isn't special
  sub {k( 'a***c',      'ac,abc,a/c',         )}, # / isn't special
  sub {k( 'a**c',       'a/c',                   { unchar=>'/' }   )},
  sub {k( 'a***c',      'ac,abc,a/c',            { unchar=>'/' }   )},
  sub {k( 'a**c',       'a/c',                   { unchar=>'/', case => 1 } )},
  sub {k( 'a***c',      'ac,abc,a/c',            { unchar=>'/', case => 1 } )},
  sub {k( 'a**c',       'ac,AC,abc,ABC,a/c,A/C', { case => 0 } )}, #case_sensitive
  sub {k( 'a***c',      'ac,AC,abc,ABC,a/c,A/C', { case => 0 } )}, #case_sensitive

  sub {k( 'a**c',       'a/c,A/C',        { unchar=>'/',case => 0 } )}, #case_sensitive
  sub {k( 'a***c',      'ac,AC,abc,ABC,a/c,A/C', { unchar=>'/',case => 0 } )}, #case_sensitive
  sub {k( 'a**c',       'a/c',         { unchar=>'/'} )},
  sub {k( 'a***c',      'ac,abc,a/c',         { unchar=>'/'} )},
  sub {k( 'a**c',       'a/c',         { unchar=>'/',twin => 1 } )}, # star_star
  sub {k( 'a***c',      'ac,abc,a/c',         { unchar=>'/',twin => 1 } )}, # star_star
  sub {k( 'a**c',       'ac,abc',             { unchar=>'/',twin => 0 } )},
  sub {k( 'a***c',      'ac,abc',             { unchar=>'/',twin => 0 } )},

  sub {k( 'b',       'abc,xbz',               { anchored=>0 } )}, # + (anchors)
  sub {k( 'b',       '',                      )},                 # +

  #sub {k( 'a...c',      'ac,abc,a/c',                                 )},
  #sub {k( 'a...c',      'ac,abc,a/c',            { dot_dot_dot => 1 } )},
  sub {k( 'a...c',      '',                       )}, # { dot_dot_dot => 0 }
  sub {k( 'q...t',      'q...t',                  )}, # { dot_dot_dot => 0 }

  #sub { 'abc' =~ compile_shellish( 'a(?)c'                 ) ; ok( $1, 'b' ) },
  #sub { 'abc' =~ compile_shellish( 'a(?)c', {parens => 1 } ) ; ok( $1, 'b' ) },
  #sub { ok( 'a(b)c' =~ compile_shellish( 'a(b)c', { parens => 0 } ) )},

  sub {k( 'x{y}z',      '',                   )},
  sub {k( 'x{a}z',      'xaz',                )},

  sub {k( 'x{a,b}z',    'xaz,xbz',                           )},
  #sub {k( 'x{a,b}z',    'xaz,xbz',   { braces => 1 }         )},
  #sub {k( 'x{a,b}z',    '',          { braces => 0 }         )},
  #sub { ok( 'x{a}z' =~ compile_shellish( 'x{a}z', { braces => 0 } ) )},

  #sub { ok( 'abc' !~ compile_shellish( 'c' ) ) },
  #sub { ok( 'abc' =~ compile_shellish( 'c', { anchors => 0 } ) ) },
);

plan tests => scalar @tests;

$_->() for @tests;
