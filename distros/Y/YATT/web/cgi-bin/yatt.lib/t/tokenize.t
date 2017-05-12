#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
use lib "$FindBin::Bin/..";

use Test::More qw(no_plan);

sub extract1_by ($$$$) {
  my ($re, $title, $from, $to) = @_;
  unless ($from =~ $re) {
    fail $title;
  } else {
    is $1, $to, $title;
  }
}

sub like_deeply_by ($$$$) {
  my ($re, $title, $from, $to) = @_;
  my @match = $from =~ $re;
  unless (@match) {
    fail $title;
  } else {
    is_deeply \@match, $to, $title;
  }
}

sub likeall_deeply_by ($$$$) {
  my ($re, $title, $from, $to) = @_;
  my @match = $from =~ m/$re/g;
  unless (@match) {
    fail $title;
  } else {
    is_deeply \@match, $to, $title;
  }
}

my $class = q(YATT::LRXML::Parser);

use_ok($class);

my $me = YATT::LRXML::Parser->new(namespace => [qw(yatt perl)]);

my $VERBOSE = $ENV{VERBOSE};

my $res;

# print $me->re_tag(1), "\n";

  extract1_by($me->re_tag(1), "perl tag"
	      , "foo<perl:var>bar"
	      , "<perl:var>");

  extract1_by($me->re_tag(1), "perl tag with leading ':'"
	      , "foo<:perl:var>bar"
	      , "<:perl:var>");

  extract1_by($me->re_tag(1), "perl tag with attr"
	      , q{foo<perl:var href="foo" name='bar' id=baz>bar}
	      , q{<perl:var href="foo" name='bar' id=baz>});

  like_deeply_by($me->re_tag(2), "perl tag with attr, detailed capture"
		 , q{foo<perl:var href="foo" name =  'bar' id=baz>bar}
		 , [undef, undef, 'perl', 'var',
		    q{ href="foo" name =  'bar' id=baz}, undef]);

  likeall_deeply_by($me->re_attlist(2), "html attlist"
		    , q{ href="foo" name =  'bar' id=baz}
		    , [' ', 'href', '=', undef, 'foo', undef,
		       ' ', 'name', ' =  ', 'bar', undef, undef,
		       ' ', 'id', '=', undef, undef, 'baz']);

  likeall_deeply_by($me->re_attlist(2), "html attlist without eq"
		    , q{ href "foo" name 'bar' id baz }
		    , [' ', undef, undef, undef, undef, 'href',
		       ' ', undef, undef, undef, 'foo', undef,
		       ' ', undef, undef, undef, undef, 'name',
		       ' ', undef, undef, 'bar', undef, undef,
		       ' ', undef, undef, undef, undef, 'id',
		       ' ', undef, undef, undef, undef, 'baz']);

  likeall_deeply_by($me->re_attlist(2), "html odd attlist"
		    , q{ type=radio checked}
		    , [' ', 'type', '=', undef, undef,'radio',
		       ' ', undef, undef, undef, undef, 'checked']);

  likeall_deeply_by($me->re_attlist(2), "attlist with my: prefix"
		    , q{ my:foo=vfoo my:bar='vbar' my:baz="vbaz" my:bang}
		    , [' ', 'my:foo', '=', undef, undef, 'vfoo'
		       , ' ', 'my:bar', '=', 'vbar', undef, undef
		       , ' ', 'my:baz', '=', undef, 'vbaz', undef
		       , ' ', undef, undef, undef, undef, 'my:bang']);
  # my:bang is first tokenized as value, then swapped to name in parse_match.

  extract1_by($me->re_tag(1), "form tag"
	      , q{foo<form method=post>bar}
	      , q{<form method=post>});

  like_deeply_by($me->re_tag(2), "form tag capture"
		 , q{foo<form method=post>bar}
		 , [undef, 'form', undef, undef, ' method=post', undef]);


  extract1_by($me->re_pi(1), "perl processing instruction"
	      , q{foo<?perl print "<FOO>BAR"?>bar}
	      , q{ print "<FOO>BAR"});

  extract1_by($me->re_pi(1, ''), "default processing instruction"
	      , q{foo<?print "<FOO>BAR"?>bar}
	      , q{print "<FOO>BAR"});

  print "re_entity: ", $me->re_entity(1), "\n" if $ENV{VERBOSE};

  extract1_by($me->re_entity(1), "entity (standard, :colon sep)"
	      , q{foo&perl:bar:baz;bang}
	      , q{&perl:bar:baz;});

  extract1_by($me->re_entity(1), "entity (standard, .dot sep)"
	      , q{foo&perl.bar.baz;bang}
	      , q{&perl.bar.baz;});

  like q{foo:$bar:baz;}, $me->re_subscript(1)
    , "entity subscript. :\$var";

  extract1_by($me->re_entity_subscripted(1), "extended entity. :\$var"
	      , q{foo&perl:var:$bar:baz;bar}
	      , q{&perl:var:$bar:baz;});

  extract1_by($me->re_entity_subscripted(1), "extended entity. [\$subscript]"
	      , q{foo&perl:var[$i]{foo};bar}
	      , q{&perl:var[$i]{foo};});

  extract1_by($me->re_entity_subscripted(1), "extended entity. (call?)"
	      , q{foo&perl:_[1].param(q);bar}
	      , q{&perl:_[1].param(q);});

  extract1_by($me->re_comment(1, ''), "bare comment"
	      , q{foo<!--foo bar -->baz}
	      , q{foo bar });

  extract1_by($me->re_comment(1), "ns comment"
	      , q{foo<!--foo bar <!--#perl baz-->bang}
	      , q{ baz});

  extract1_by($me->re_declarator(1), "declarator"
	      , q{foo<!yatt:widget foo bar='hoe' baz="moe">bang}
	      , q{<!yatt:widget foo bar='hoe' baz="moe">});

  extract1_by($me->re_declarator(1), "declarator 2"
	      , q{foo<!yatt:test>bang}
	      , q{<!yatt:test>});

#----------------------------------------

my $splitter = $me->re_splitter(1, "perl");
print "[[$splitter]]\n" if $ENV{VERBOSE};
my ($src);

is_deeply [split $splitter, $src = q(
<html>
<body>
<form>
  <input type=radio name=q1 value=1>foo
  <input type=radio name=q1 value=2>bar
</form>
</html>
)], [q(
<html>
<body>
), q(<form>), q(
  ), q(<input type=radio name=q1 value=1>), q(foo
  ), q(<input type=radio name=q1 value=2>), q(bar
), q(</form>), q(
</html>
)], "html with forms";
use Data::Dumper;
print Dumper($res), "\n" if $ENV{VERBOSE};

ok(do {
  my @tok = split $splitter, q(
<html>
<body>
<?perl my $user = $CGI.param("user"); ?>
<h2>Welcom &perl:user;</h2>
</body>
</html>
);
  scalar @tok;
} == 5, "html with perl pi and entity");

#----------------------------------------

my %except = qw(re_ns 1 re_prefix 1);
my @re_methods = grep(/^re_/ && $me->can($_) && ! $except{$_},
		      sort keys %YATT::LRXML::Parser::);
is_deeply [grep(ref($me->$_()) ne 'Regexp' && $_
		, grep {$_ ne 're_arg_decls'} @re_methods)]
  , [], 'all ->re_ZZZ(0) returns Regexp obj';

is_deeply [grep(ref($me->$_(1)) ne 'Regexp' && $_, @re_methods)]
  , [], 'all ->re_ZZZ(1) returns Regexp obj';

is_deeply [grep(ref($me->$_(2)) ne 'Regexp' && $_, @re_methods)]
  , [], 'all ->re_ZZZ(2) returns Regexp obj';

if (1) {
  my $splitter = $me->re_splitter(1, "yatt");
  is_deeply [split $splitter
	     , $src = q(<li><input&yatt:type;&yatt:name;></li>)]
    , [q(<li>), q(<input&yatt:type;&yatt:name;>), q(</li>)]
      , "html with forms";
}
