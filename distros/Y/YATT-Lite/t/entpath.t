#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::Test::TestUtil;

use YATT::Lite ();
use YATT::Lite::Util qw(catch terse_dump);
use YATT::Lite::LRXML::FormatEntpath qw(format_entpath);
use Test::Differences;

my $parser;
sub is_entpath (@) {
  my ($in, $expect, $formated) = @_;
  local $_ = $in;
  my @entpath = eval {$parser->_parse_entpath};
  if ($@) {
    Test::More::fail "$in\n $@";
  } else {
    is(terse_dump(@entpath)
       , terse_dump(defined $expect ? @$expect : $expect)
       , $in);

    if (ref $formated) {
    TODO: {
	local $TODO = $$formated;
	eq_or_diff(format_entpath(@entpath).";", $in
		     , "$in => roundtrip");
      }
    } else {
      eq_or_diff(format_entpath(@entpath).";", $formated // $in
		   , ($formated ? " => $formated" : "$in => roundtrip"));
    }
  }
}

my @test; sub add {push @test, [@_]} sub break {push @test, undef}
sub Todo {push @test, bless [@_], "TODO"}
{
  add q{:foo;}
    , [[var => 'foo']];

  add q{:foo:bar;}
    , [[var => 'foo'], [prop => 'bar']];

  add q{:foo:bar();}
    , [[var => 'foo'], [invoke => 'bar']];

  add q{:foo:bar():baz;}
    , [[var => 'foo'], [invoke => 'bar'], [prop => 'baz']];

  add q{:foo();}
    , [[call => foo =>]];

  add q{:fn(tt,:foo:bar);}
    , [[call => fn => [text => 'tt'], [[var => 'foo'], [prop => 'bar']]]];

  add q{:foo(,);}
    , [[call => foo => [text => '']]];

  add q{:foo(,,);}
    , [[call => foo => [text => ''], [text => '']]];

  add q{:foo(bar);}
    , [[call => foo => [text => 'bar']]];

  add q{:foo(bar,);}
    , [[call => foo => [text => 'bar']]]
    , q{:foo(bar);}
    ;

  add q{:foo(bar,,);}
    , [[call => foo => [text => 'bar'], [text => '']]];

  add q{:foo():bar();}
    , [[call => foo =>], [invoke => bar =>]];

  add q{:foo(bar,:baz(),,);}
    , [[call => foo => [text => 'bar'], [call => 'baz']
       , [text => '']]];

  add q{:x{foo}{:y};}
    , [[var => 'x'], [href => [text => 'foo']]
       , [href => [var => 'y']]];

  # break;
  add q{:foo({key,val});}
    , [[call => foo => , [hash => [text => 'key'], [text => 'val']]]];

  # add q{:foo({key:val});}
  #   , [[call => foo => , [hash => [text => 'key'], [text => 'val']]]]
  #   , q{:foo({key,val});}
  #   ;

  add q{:foo(bar,{key,val,k2,v2},,);}
    , [[call => foo => [text => 'bar']
	, [hash => [text => 'key'], [text => 'val']
	   , [text => 'k2'], [text => 'v2']]
	, [text => '']]];

  # add q{:foo(bar,{key:val,k2:v2},,);}
  #   , [[call => foo => [text => 'bar']
  #       , [hash => [text => 'key'], [text => 'val']
  #          , [text => 'k2'], [text => 'v2']]
  #       , [text => '']]]
  #   , q{:foo(bar,{key,val,k2,v2},,);}
  #   ;

  add q{:foo(bar,{key,val,k2,:v2:path},,);}
    , [[call => foo => [text => 'bar']
	, [hash => [text => 'key'], [text => 'val']
	   , [text => 'k2'], [[var => 'v2'],[prop => 'path']]]
	, [text => '']]];

  # add q{:foo(bar,{key:val,k2,:v2:path},,);}
  #   , [[call => foo => [text => 'bar']
  #       , [hash => [text => 'key'], [text => 'val']
  #          , [text => 'k2'], [[var => 'v2'],[prop => 'path']]]
  #       , [text => '']]]
  #   , q{:foo(bar,{key,val,k2,:v2:path},,);}
  #   ;

  add q{:yaml(config):title;}
    , [[call => yaml => [text => 'config']]
       , [prop  => 'title']
      ];

  add q{:foo(:config,title);}
    , [[call => foo => [var => 'config'], [text => 'title']]];

  add q{:foo[3][8];}
    , [[var => 'foo'], [aref => [expr => '3']], [aref => [expr => '8']]]
    , \"TODO - aref expr"
    ;

  add q{:x[0][:y][1];}
    , [[var => 'x']
       , [aref => [expr => '0']]
       , [aref => [var => 'y']]
       , [aref => [expr => '1']]]
    , \"TODO - aref expr"
    ;

  add q{:x[:y[0][:z]][1];}
    , [[var => 'x']
       , [aref =>
	  [[var => 'y']
	   , [aref => [expr => '0']]
	   , [aref => [var => 'z']]]]
       , [aref => [expr => '1']]]
    , \"TODO - aref expr"
    ;

  add q{:foo([3][8]);}
    , [[call => foo =>
	[[array => [text => '3']]
	 , [aref => [expr => '8']]]]]
    , \"TODO - aref expr"
    ;

  add q{:foo([3,5][7]);}
    , [[call => foo =>
	[[array => [text => '3'], [text => '5']]
	 , [aref => [expr => '7']]]]]
    , \"TODO - aref expr"
    ;

  add q{:foo([3][8],,[5][4],,);}
    , [[call => foo =>
	[[array => [text => '3']]
	 , [aref => [expr => '8']]]
	, [text => '']
	, [[array => [text => '5']]
	   , [aref => [expr => '4']]]
	, [text => '']
       ]]
    , \"TODO - aref expr"
    ;

  add q{:mkhash(:lexpand(:CON:param(:name)));}
    , [[call => mkhash =>
	[call => lexpand =>
	 [[var => 'CON']
	  , [invoke => param => [var => 'name']]]
	]
       ]];

  #----------------------------------------

  add q{:where({user,hkoba,status,[assigned,:status,pending]});}
    , [[call => 'where'
	, [hash => [text => 'user'], [text => 'hkoba']
	   , [text => 'status'], [array => [text => 'assigned']
				  , [var  => 'status']
				  , [text => 'pending']]]]];

  # add q{:where({user:hkoba,status,[assigned,:status,pending]});}
  #   , [[call => 'where'
  #       , [hash => [text => 'user'], [text => 'hkoba']
  #          , [text => 'status'], [array => [text => 'assigned']
  #       			  , [var  => 'status']
  #       			  , [text => 'pending']]]]]
  #   , q{:where({user,hkoba,status,[assigned,:status,pending]});}
  #   ;

  add q{:where({user,hkoba,status,{!=,:status}});}
    , [[call => 'where'
	, [hash => [text => 'user'], [text => 'hkoba']
	   , [text => 'status'], [hash => [text => '!=']
				  , [var => 'status']]]]];

  # add q{:where({user:hkoba,status:{!=,:status}});}
  #   , [[call => 'where'
  #       , [hash => [text => 'user'], [text => 'hkoba']
  #          , [text => 'status'], [hash => [text => '!=']
  #       			  , [var => 'status']]]]]
  #   , q{:where({user,hkoba,status,{!=,:status}});}
  #   ;

  add q{:where({user,hkoba,status,{!=,[assigned,in-progress,pending]}});}
    , [[call => 'where'
	, [hash => [text => 'user'], [text => 'hkoba']
	   , [text => 'status'], [hash => [text => '!=']
				  , [array => [text => 'assigned']
				     , [text => 'in-progress']
				     , [text => 'pending']]]]]];

  # add q{:where({user:hkoba,status:{!=,[assigned,in-progress,pending]}});}
  #   , [[call => 'where'
  #       , [hash => [text => 'user'], [text => 'hkoba']
  #          , [text => 'status'], [hash => [text => '!=']
  #       			  , [array => [text => 'assigned']
  #       			     , [text => 'in-progress']
  #       			     , [text => 'pending']]]]]]
  #   , q{:where({user,hkoba,status,{!=,[assigned,in-progress,pending]}});}
  #   ;

  add q{:where({user,hkoba,status,{!=,completed,-not_like,pending%}});}
    , [[call => 'where'
	, [hash => [text => 'user'], [text => 'hkoba']
	   , [text => 'status']
	   , [hash => [text => '!='], [text => 'completed']
	      , [text => -not_like], [text => 'pending%']]]]];

  # add q{:where({user:hkoba,status:{!=,completed,-not_like:pending%}});}
  #   , [[call => 'where'
  #       , [hash => [text => 'user'], [text => 'hkoba']
  #          , [text => 'status']
  #          , [hash => [text => '!='], [text => 'completed']
  #             , [text => -not_like], [text => 'pending%']]]]]
  #   , q{:where({user,hkoba,status,{!=,completed,-not_like,pending%}});}
  #   ;

  add q{:where({priority,{<,2},workers,{>=,100}});}
    , [[call => 'where'
	, ['hash'
	   , [text => 'priority'], [hash => [text => '<'],  [text => '2']]
	   , [text => 'workers'],[hash => [text => '>='], [text => '100']]]]];

  # add q{:where({priority:{<,2},workers:{>=,100}});}
  #   , [[call => 'where'
  #       , ['hash'
  #          , [text => 'priority'], [hash => [text => '<'],  [text => '2']]
  #          , [text => 'workers'],[hash => [text => '>='], [text => '100']]]]]
  #   , q{:where({priority,{<,2},workers,{>=,100}});}
  #   ;

  #----------------------------------------

  add q{:schema:resultset(Artist):all();}
    , [[var => 'schema']
       , [invoke => resultset => [text => 'Artist']]
       , [invoke => 'all']];

  add q{:schema:resultset(Artist):search({name,{like,John%}});}
    , [[var => 'schema']
       , [invoke => resultset => [text => 'Artist']]
       , [invoke => 'search'
	  , [hash => [text => 'name']
	     , [hash => [text => 'like']
		, [text => 'John%']]]]
	 ];
  # add q{:schema:resultset(Artist):search({name:{like:John%}});}
  #   , [[var => 'schema']
  #      , [invoke => resultset => [text => 'Artist']]
  #      , [invoke => 'search'
  #         , [hash => [text => 'name']
  #            , [hash => [text => 'like']
  #       	, [text => 'John%']]]]
  #     ]
  #   , q{:schema:resultset(Artist):search({name,{like,John%}});}
  #   ;

  add q{:john_rs:search_related(cds):all();}
    , [[var => 'john_rs']
       , [invoke => search_related => [text => 'cds']]
       , [invoke => 'all']];

  add q{:first_john:cds(=undef,{order_by,title});}
    , [[var => 'first_john']
       , [invoke => 'cds'
	  , [expr => 'undef']
	  , [hash => [text => 'order_by']
	     , [text => 'title']]]];

  # add q{:first_john:cds(=undef,{order_by:title});}
  #   , [[var => 'first_john']
  #      , [invoke => 'cds'
  #         , [expr => 'undef']
  #         , [hash => [text => 'order_by']
  #            , [text => 'title']]]]
  #   , q{:first_john:cds(=undef,{order_by,title});}
  #   ;

  add q{:schema:resultset(CD):search({year,2000},{prefetch,artist});}
    , [[var => 'schema']
       , [invoke => resultset => [text => 'CD']]
       , [invoke => 'search'
	  , [hash => [text => 'year'], [text => '2000']]
	  , [hash => [text => 'prefetch'], [text => 'artist']]]];

  # add q{:schema:resultset(CD):search({year:2000},{prefetch:artist});}
  #   , [[var => 'schema']
  #      , [invoke => resultset => [text => 'CD']]
  #      , [invoke => 'search'
  #         , [hash => [text => 'year'], [text => '2000']]
  #         , [hash => [text => 'prefetch'], [text => 'artist']]]]
  #   , q{:schema:resultset(CD):search({year,2000},{prefetch,artist});}
  #   ;


  add q{:cd:artist():name();}
    , [[var => 'cd']
       , [invoke => 'artist']
       , [invoke => 'name']];

  #----------------------------------------

  add qq{:query((select *\r
from user
where\tuid = ?),:uid);}
    , [[call => 'query'
	, [text => "select *\r\nfrom user\nwhere\tuid = ?"]
	, [var => 'uid']]
       ];

  add qq{:query((select * from [x] where a = 'foo' and b = "bar" and `baz` = 1));}
    , [[call => 'query'
	, [text => q|select * from [x] where a = 'foo' and b = "bar" and `baz` = 1|]]
       ];

  add q{:query((select x, y, z from t1, t2));}
      , [[call => 'query'
	  , [text => q|select x, y, z from t1, t2|]]
	];

  add q{:select(node,{uid,foobar,nid,{<=,2}});}
    , [[call => 'select'
	, [text => 'node']
	, [hash => [text => 'uid'], [text => 'foobar']
	   , [text => 'nid'], [hash => [text => '<='], [text => '2']]]]
       ];

  add q{:query_string(merge,{dir,back,:idkey,:paged{back_key}});}
    , [[call => 'query_string'
        , [text => 'merge']
        , [hash => [text => 'dir'], [text => 'back']
           , [var => 'idkey'], [[var => 'paged'], [href => [text => 'back_key']]]
         ]
      ]];

  #----------------------------------------

  add q{:foo(bar):baz():bang;}
    , [[call => foo => [text => 'bar']]
       , [invoke => 'baz']
       , [prop  => 'bang']
      ];

  add q{:foo(:bar:baz(:bang()),hoe,:moe);}
    , [[call => 'foo'
	, [[var => 'bar'], [invoke => 'baz', [call => 'bang']]]
	, [text => 'hoe']
	, [var  => 'moe']]];

  add q{:foo((bar(,)baz()),bang);}
    , [[call => 'foo'
	, [text => 'bar(,)baz()']
	, [text => 'bang']]];


  add q{:foo((=$i*($j+$k)),,=$x[8]{y}{z}):hoe;}
    , [[call => 'foo'
	, [expr => '$i*($j+$k)']
	, [text => '']
	, [expr => '$x[8]{y}{z}']]
       , [prop => 'hoe']]
    , \"TODO - paren expr"
    ;

  add q{:foo(bar${q}baz);}
    , [[call => 'foo'
	, [text => 'bar${q}baz']]]
    , \"TODO - matching paren"
    ;

  add q{:foo(bar,baz,[3]);}
    , [[call => 'foo'
	, [text => 'bar']
	, [text => 'baz']
	, [array => [text => '3']]]];

  add q{:if(=$$list[0]*$$list[1]==24,yes,no);}
    , [[call => 'if'
	, [expr => '$$list[0]*$$list[1]==24']
	, [text => 'yes']
	, [text => 'no']]];

  add q{:if((=($$list[0]+$$list[1])==11),yes,no);}
    , [[call => 'if'
	, [expr => '($$list[0]+$$list[1])==11']
	, [text => 'yes']
	, [text => 'no']]]
    , \"TODO - paren expr"
    ;

  add q{:if((=($x+$y)==$z),baz);}
    , [[call => 'if'
	, [expr => '($x+$y)==$z']
	, [text => 'baz']]]
    , \"TODO - paren expr"
    ;
    
  add q{:foo(=@bar);}
    , [[call => 'foo'
	, [expr => '@bar']]];

  my $chrs = q{|,@,$,-,+,*,/,<,>,!}; # XXX: % is ng for sprintf...
  add qq{:foo($chrs);}
    , [[call => 'foo'
	, map {[text => $_]} split /,/, $chrs]];

  add q{:dispatch_one(for_,1,:atts{for},:atts,:lexpand(:list));}
    , [[call => 'dispatch_one'
	, [text => 'for_']
	, [text => '1']
	, [[var => 'atts'], [href => [text => 'for']]]
	, [var => 'atts']
	, [call => 'lexpand'
	   , [var => 'list']]]];
}

my @error
  = ([":foo", qr/^Entity has no terminator: ':foo'[^\n]*\n?$/]
     , [":bar\n\n", qr/^Entity has no terminator: ':bar'[^\n]*\n?$/]
     , [":baz()\n\n", qr/^Entity has no terminator: \Q':baz()'\E[^\n]*\n?$/]

     , ["::foo", qr/^Syntax error in entity: '::foo'[^\n]*\n?$/]
     , ["::bar\n\n", qr/^Syntax error in entity: '::bar'[^\n]*\n?$/]
     , ["::baz()\n\n", qr/^Syntax error in entity: \Q'::baz()'\E[^\n]*\n?$/]

     , [":foo(bar];\n\n", qr/^Paren mismatch: expect \) got \][^\n]*\n?$/]
     , [":foo[bar);\n\n", qr/^Paren mismatch: expect \] got \)[^\n]*\n?$/]
     , [":foo{bar];\n\n", qr/^Paren mismatch: expect \} got \][^\n]*\n?$/]

     , [":baz(\n\n", qr/^Syntax error in entity: \Q':baz('\E[^\n]*\n?$/]
   );

sub detect_entpath_error {
  my ($in, $error) = @_;
  local $_ = $in;
  eval {$parser->_parse_entpath};
  $in =~ s/\n/\\n/g;
  like $@, $error, "detect_entpath_error: $in";
}

my $class = 'YATT::Lite::LRXML';

plan tests => 2 + 2*grep(defined $_, @test) + @error;

require_ok($class);
ok($parser = $class->new, "new $class");

foreach my $test (@test) {
  unless (defined $test) {
    YATT::Lite::Breakpoint::breakpoint();
  } elsif (ref $test eq 'TODO') {
    TODO: {
	(local $TODO, my ($in, $expect)) = @$test;
	local $_ = $in;

	is(eval {terse_dump($parser->_parse_entpath)} || $@
	   , terse_dump(defined $expect ? @$expect : $expect)
	   , $in);
      }
  } else {
    is_entpath @$test;
  }
}

foreach my $test (@error) {
  detect_entpath_error(@$test);
}

done_testing();
