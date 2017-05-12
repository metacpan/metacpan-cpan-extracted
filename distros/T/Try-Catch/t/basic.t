use strict;
use warnings;

use Test::More qw(no_plan);

use Try::Catch;

sub _eval {
  local $@;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return ( scalar(eval { $_[0]->(); 1 }), $@ );
}

sub lives_ok (&$) {
  my ( $code, $desc ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ( $ok, $error ) = _eval($code);

  ok($ok, $desc );

  diag "error: $@" unless $ok;
}


sub throws_ok (&$$) {
  my ( $code, $regex, $desc ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ( $ok, $error ) = _eval($code);

  if ( $ok ) {
    fail($desc);
  } else {
    like($error || '', $regex, $desc );
  }
}


my $prev;

lives_ok {
  try {
    die "foo";
  } catch {};
} "basic try";


throws_ok {
  try {
    die "foo";
  } catch { die $_ };
} qr/foo/, "rethrow";


{
  local $@ = "magic";
  is( (try { 42 } catch {}), 42, "try block evaluated" );
  is( $@, "magic", '$@ untouched' );
}

{
  local $@ = "magic";
  is( ( try { die "foo" } catch {} ), undef, "try block died" );
  is( $@, "magic", '$@ untouched' );
}

{
  local $@ = "magic";
  like( (try { die "foo" } catch { $_ }), qr/foo/, "catch block evaluated" );
  is( $@, "magic", '$@ untouched' );
}
#
is( scalar(try { "foo", "bar", "gorch" } catch {} ), "gorch", "scalar context try" );
is_deeply( [ try {qw(foo bar gorch)} catch {} ], [qw(foo bar gorch)], "list context try" );
#
is( scalar(try { die } catch { "foo", "bar", "gorch" }), "gorch", "scalar context catch" );
is_deeply( [ try { die } catch {qw(foo bar gorch)} ], [qw(foo bar gorch)], "list context catch" );


lives_ok {
  try {
    die "foo";
  } catch {
    my $err = shift;

    try {
      like $err, qr/foo/;
    } catch {
      fail("shouldn't happen");
    };

    pass "got here";
  }
} "try in try catch block";

throws_ok {
  try {
    die "foo";
  } catch {
    my $err = shift;

    try { } catch { };

    die "rethrowing $err";
  }
} qr/rethrowing foo/, "rethrow with try in catch block";


sub Evil::DESTROY {
  eval { "oh noes" };
}

sub Evil::new { bless { }, $_[0] }

{
  local $@ = "magic";
  local $_ = "other magic";

  try {
    my $object = Evil->new;
    die "foo";
  } catch {
    pass("catch invoked");
    SKIP: {
      # i don't think we can ever make this work sanely, maybe with SIG{__DIE__}
      skip "Perl 5.14 required", 1 if $] < 5.014;
      like($_, qr/foo/);
    }
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}


{
  my ( $caught, $prev );

  {
    local $@;

    eval { die "bar\n" };

    is( $@, "bar\n", 'previous value of $@' );

    try {
      die {
        prev => $@,
      }
    } catch {
      $caught = $_;
      $prev = $@;
    }
  }

  is_deeply( $caught, { prev => "bar\n" }, 'previous value of $@ available for capture' );
  is( $prev, "bar\n", 'previous value of $@ also available in catch block' );
}
