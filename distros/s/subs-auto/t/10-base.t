#!perl -T

use strict;
use warnings;

use Test::More tests => 92;

# ... Helpers .................................................................

my %_re = (
 bareword => sub { qr/^Bareword\s+['"]?\s*$_[0]\s*['"]?\s+not\s+allowed\s+while\s+["']?\s*strict\s+subs\s*['"]?\s+in\s+use\s+at\s+$_[1]\s+line\s+$_[2]/ },
 undefined => sub { qr/^Undefined\s+subroutine\s+\&$_[0]\s+called\s+at\s+$_[1]\s+line\s+$_[2]/ },
);

sub _got_test {
 my $sub  = shift;
 my $line = shift;
 my %args = @_;
 my $msg  = delete $args{msg};
 $msg     = join ' ', $args{name}, $sub, 'line', $line unless $msg;
 my $file = $args{eval} ? '\\(eval\\s+\\d+\\)' : quotemeta $0;
 my $re   = $_re{$args{name}}->($sub, $file, $line);
 if ($args{todo}) {
  TODO: {
   local $TODO = $args{todo};
   like($@, $re, $msg);
  }
 } else {
  like($@, $re, $msg);
 }
}

sub _got_bareword { _got_test(@_, name => 'bareword'); }

sub _got_undefined {
 my $sub = shift;
 $sub = 'main::' . $sub if $sub !~ /::/;
 _got_test($sub, @_, name => 'undefined');
}

sub _got_ok { is($@, '', $_[0]); }

my $warn;

# ... First test that the default behaviour apply to all the subs .............

my $bar;
sub bar { $bar = 1 }

eval "yay 11, 13"; # Defined on the other side of the scope
_got_ok('compiling to yay(11,13)');
our @yay;
is_deeply(\@yay, [ 11, 13 ], 'yay really was executed');

eval "flip"; # Not called in sub::auto zone, not declared, not defined
_got_bareword('flip', 1, eval => 1);

eval "flop"; # Not called in sub::auto zone, declared outside, not defined
_got_undefined('flop', 1, eval => 1);

my $qux;
eval "qux"; # Called in sub::auto zone, not declared, not defined
_got_bareword('qux', 1, eval => 1);

my $blech;
eval "blech"; # Called in sub::auto zone, declared outside, not defined
_got_undefined('blech', 1, eval => 1);

my $wut;
eval "wut"; # Called in sub::auto zone, declared and defined outside
_got_ok('compiling to wut()');

# === Starting from here ======================================================
use subs::auto;

# ... Called in sub::auto zone only, not declared, not defined ................

eval { onlycalledonce 1, 2 };
_got_undefined('onlycalledonce', __LINE__-1);

# ... Method calls, anyone? ...................................................

eval { Test::More->import() };
_got_ok('don\'t touch class names');

my $strict;
sub strict { $strict = 1; undef }
eval { strict->import };
is($strict, 1, 'the strict subroutine was called');

# ... Test hash keys ..........................................................

my $c = 0;
my %h = (
 a => 5,
 b => 7,
);
sub a { ++$c }
sub b { ++$c }
is($c, 0, "hash keys shouldn't be converted");

my $foo;
our @foo;

# ... Called in sub::auto zone, declared and defined inside ...................

eval { foo 1, 2, \%h };
_got_ok('compiling to foo(1,2,\\\%h)');
is($foo, 15, 'foo really was executed');

eval { foo(3, 4, \%h) };
_got_ok('compiling to foo(3,4,\\\%h)');
is($foo, 19, 'foo() really was executed');

eval { local @_ = (5, 6, \%h); &foo };
_got_ok('compiling to foo(5,6,\\\%h)');
is($foo, 23, '&foo really was executed');

eval { &foo(7, 8, \%h) };
_got_ok('compiling to foo(7,8,\\\%h)');
is($foo, 27, '&foo() really was executed');

# ... Called in sub::auto zone, declared and defined outside ..................

eval { wut 13, "what" };
_got_ok('compiling to wut(13,"what")');
is($wut, 17, 'wut really was executed');

eval { wut(17, "what") };
_got_ok('compiling to wut(17,"what")');
is($wut, 21, 'wut() really was executed');

eval { local @_ = (21, "what"); &wut };
_got_ok('compiling to wut(21,"what")');
is($wut, 25, '&wut really was executed');

eval { &wut(25, "what") };
_got_ok('compiling to wut(25,"what")');
is($wut, 29, '&wut() really was executed');

# ... Called in sub::auto zone, not declared, not defined .....................

eval { qux };
_got_undefined('qux', __LINE__-1);

eval { qux() };
_got_undefined('qux', __LINE__-1);

eval { &qux };
_got_undefined('qux', __LINE__-1);

eval { &qux() };
_got_undefined('qux', __LINE__-1);

# ... Are our subs visible in the symbol table entry or what? .................

{
 no strict 'refs';
 is(*{'::feh'}{CODE}, undef, 'feh isn\'t defined');
 is(*{'::feh'}{CODE}, undef, 'feh isn\'t defined, really');
 isnt(*{'::yay'}{CODE}, undef, 'yay is defined');
 isnt(*{'::foo'}{CODE}, undef, 'foo is defined');
 is(*{'::flip'}{CODE}, undef, 'flip isn\'t defined');
 isnt(*{'::flop'}{CODE}, undef, 'flop is defined');
 is(*{'::qux'}{CODE}, undef, 'qux isn\'t defined');
 isnt(*{'::blech'}{CODE}, undef, 'blech is defined');
 isnt(*{'::wut'}{CODE}, undef, 'wut is defined');
}

# ... Let's check that this didn't induce any quantic effect ..................

eval { no warnings; no strict; qux };
_got_undefined('qux', __LINE__-1);

eval { no warnings; no strict; blech };
_got_undefined('blech', __LINE__-1);

# ... Define foo ..............................................................

sub foo {
 if ($_[2]) {
  my %h = %{$_[2]};
  $foo = $_[0] + $_[1] + (($h{a} || 0 == 5) ? 4 : 0)
                       + (($h{b} || 0 == 7) ? 8 : 0);
  undef;
 } else {
  $foo = '::foo'; # for symbol table tests later
 }
}

eval { foo 3, 4, { } };
_got_ok('compiling to foo(3,4,{})');
is($foo, 7, 'foo really was executed');

# ... Locally define qux (declared outside, not defined) ......................

$warn = undef;
eval {
 local $SIG{__WARN__} = sub { $warn = $_[0] =~ /Subroutine\s+\S+redefined/ };
 local *qux = sub { $qux = $_[0] };
 qux 5;
};
_got_ok('compiling to qux(5)');
is($qux, 5, 'qux really was executed');
is($warn, undef, 'no redefine warning');

# ... Locally define blech (declared and defined outside) .....................

$warn = undef;
eval {
 local $SIG{__WARN__} = sub { $warn = $_[0] =~ /Subroutine\s+\S+redefined/ };
 local *blech = sub { $blech = $_[0] };
 blech 7;
};
_got_ok('compiling to blech(7)');
is($blech, 7, 'blech really was executed');
is($warn, undef, 'no redefine warning');

# ... But now they aren't anymore .............................................

eval { qux };
_got_undefined('qux', __LINE__-1);

eval { blech };
_got_undefined('blech', __LINE__-1);

# === Up to there =============================================================
no subs::auto;

# ... Barewords are strings when the pragma isn't in effect ...................

my $b;
my $cb = eval {
 sub {
  $b = do {
   no strict;
   no warnings 'reserved';
   blech;
  }
 }
};
_got_ok('compiling to bareword');
$cb->();
is($b, 'blech', 'bareword ok');

# ... Does foo's definition still valid outside of the pragma scope? ..........

eval { foo 13, 1, { } };
_got_ok('compiling to foo(13,1,{})');
is($foo, 14, 'foo really was executed');

# ... Locally define qux ......................................................

$warn = undef;
{
 local $SIG{__WARN__} = sub { $warn = $_[0] =~ /Subroutine\s+\S+redefined/; diag $_[0] };
 local *qux = sub { $qux = 2 * $_[0] };
 qux(3);
}
_got_ok('compiling to qux(3)');
is($qux, 6, 'new qux really was executed');
is($warn, undef, 'no redefine warning');

# ... Locally define blech ....................................................

$warn = undef;
{
 local $SIG{__WARN__} = sub { $warn = $_[0] =~ /Subroutine\s+\S+redefined/ };
 local *blech = sub { $blech = 2 * $_[0] };
 blech(9);
}
_got_ok('compiling to blech(9)');
is($blech, 18, 'new blech really was executed');
is($warn, undef, 'no redefine warning');

# ... But now they aren't anymore .............................................

eval "qux";
_got_bareword('qux', 1, eval => 1);

eval "blech";
_got_undefined('blech', 1, eval => 1);

# ... How's my symbol table, Doug Hastings? ...................................

{
 no strict qw<refs subs>;
 is(*{::feh}{CODE}, undef, 'feh isn\'t defined');
 is(*{::feh}{CODE}, undef, 'feh isn\'t defined, really');
 isnt(*{::yay}{CODE}, undef, 'yay is defined');
 isnt(*{::foo}{CODE}, undef, 'foo is defined'); # calls foo
 is($foo, '::foo', 'foo was called');
 is(*{::flip}{CODE}, undef, 'flip isn\'t defined');
 isnt(*{::flop}{CODE}, undef, 'flop is defined');
 is(*{::qux}{CODE}, undef, 'qux isn\'t defined');
 isnt(*{::blech}{CODE}, undef, 'blech is defined');
 isnt(*{::wut}{CODE}, undef, 'wut is defined');
}

# ... Declareth thy oneth thad shalt be .......................................

sub blech;
eval { blech };
_got_undefined('blech', __LINE__-1);

sub flop;

bar();
is($bar, 1, 'bar ok');

sub wut { $wut = ($_[0] || 0) + length($_[1] || ''); '::wut' }

sub yay { @yay = @_; '::yay' }

# === Restarting from there ===================================================
use subs::auto;

# ... How does the pragma propagates through eval STRING? .....................

eval "no subs::auto; meh";
_got_bareword("meh", 1, eval => 1);
# eval "use subs::auto; meh";
# _got_undefined('meh', 1, eval => 1, todo => 'Fails because of some bug in perl or Variable::Magic');
# eval "meh";
# _got_undefined('meh', 1, eval => 1, todo => 'Fails because of some bug in perl or Variable::Magic');

# ... Try filehandles .........................................................

my $buf = '';
{
 no subs::auto;
 open DONGS, '>', \$buf or die "open-in-memory: $!";
}
print DONGS "hlagh\n";
is($buf, "hlagh\n", 'filehandles should\'t be touched');
close DONGS;

# ... Try default filehandles .................................................

seek DATA, 0, 1;
my @fruits = <DATA>;
chomp @fruits;
is_deeply(\@fruits, [ qw<apple pear banana> ], 'DATA filehandle ok');

# ... Retest foo (declared and defined inside) ................................

eval { foo 7, 9, { } };
_got_ok('compiling to foo(7,9,{})');
is($foo, 16, 'foo really was executed');

eval { foo(8, 10, { }) };
_got_ok('compiling to foo(8,10,{})');
is($foo, 18, 'foo() really was executed');

eval { local @_ = (9, 11, { }); &foo };
_got_ok('compiling to foo(9,11,{})');
is($foo, 20, '&foo really was executed');

eval { &foo(10, 12, { }) };
_got_ok('compiling to foo(10,12,{})');
is($foo, 22, '&foo() really was executed');

# ... Retest blech (declared outside, not defined) ............................

eval { blech };
_got_undefined('blech', __LINE__-1);

eval { blech() };
_got_undefined('blech', __LINE__-1);

eval { &blech };
_got_undefined('blech', __LINE__-1);

eval { &blech() };
_got_undefined('blech', __LINE__-1);

# ... Try _ in a filetest .....................................................

ok(-f $0 && -r _, '-X _');

__DATA__
apple
pear
banana
