use Test::More;

BEGIN {
  require namespace::clean;
  if (
    namespace::clean::_Util::DEBUGGER_NEEDS_CV_RENAME()
      and
    my $missing_xs = namespace::clean::_Util::_namer_load_error()
  ) {
    plan skip_all => $missing_xs;
  }
  else {
    plan tests => 4;
  }
}

BEGIN {
  # shut up the debugger
  $ENV{PERLDB_OPTS} = 'NonStop';
}

BEGIN {

#line 1
#!/usr/bin/perl -d
#line 27

}

{
    package Foo;

    BEGIN { *baz = sub { 42 } }
    sub foo { 22 }

    use namespace::clean;

    sub bar {
        ::is(baz(), 42);
        ::is(foo(), 22);
    }
}

ok( !Foo->can("foo"), "foo cleaned up" );
ok( !Foo->can("baz"), "baz cleaned up" );

Foo->bar();
