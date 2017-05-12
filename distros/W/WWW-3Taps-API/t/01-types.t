use Test::More;
use Test::Exception;
use Moose::Util::TypeConstraints qw(find_type_constraint);
BEGIN { use_ok( 'WWW::3Taps::API::Types', qw/:all/ ) }


my @tests = (
  {
    name => 'Source',
    ok   => ['abc12'],
    fail => [qw/11 ab abcdefgh/]
  },
  {
    name => 'Category',
    ok   => [qw/FOOB FooB+OR+BarB FooB+OR+BARB+OR+BAzI/],
    fail => [qw/FOO+ FOOO+ FOoD+BARB+ FOo+BARB+ FOOB+OR+BaR+OR FOOO+OR+BARB+/]
  },
  {
    name => 'Location',
    ok   => [qw/FOO BAR/],
    fail => [qw/F B FO BA QUUX ZING/]
  },
  {
    name => 'Timestamp',
    ok   => [ '2001-02-02 20:00:01', '1998-05-05 17:22:10' ],
    fail =>
      [ '1970-02-31 12:00:00', '1999-xx-89 33:33:33', '22-22-22 90-01-01' ]
  },
  {
    name => 'JSONMap',
    ok   => [qw/{} {"foo":11}/],
    fail => [qw/{] 55 []/]
  },
  {
    name => 'Retvals',
    ok   => [ q{source,category}, q{heading,body,image} ],
    fail => [ q{foo,bar,baz}, q{biz}, q{baz}, q{body,image,foo} ]
  },
  {
    name => 'Dimension',
    ok   => [qw(source category location)],
    fail => [ q{foo}, q{bar}, q{foo,bar} ]
  },
  {
    name => 'List',
    ok   => [ q{foo}, q{foo,bar}, q{foo,bar,baz} ],
    fail => [ 'foo,', 'foo bar' ],
  },
  {
    name => 'JSONBoolean',
    ok   => [ qw(true false), 0, 1, 7, -9 ],
    fail => [ qw(foo bar) ]
  },
           {
            name => 'NotificationFormat',
            ok => [qw(push brief html extended text140 full)],
            fail => [qw(foo bar)]
          }

);


foreach my $type (@tests) {
  ok __PACKAGE__->can( $type->{name} ), "can $type->{name}";
  ok my $is_type = __PACKAGE__->can("is_$type->{name}"), "can is_$type->{name}";

  my $tc = find_type_constraint('WWW::3Taps::API::Types::'.$type->{name});

  for ( @{ $type->{ok} } ) {
    if ($tc->has_coercion) {
      lives_ok { $tc->assert_coerce($_) } "$_ as $type->{name} lives as expected";;
    }
    else {
       ok( $is_type->($_), "$_ is $type->{name}" );
    }
  }

  for ( @{ $type->{fail} } ) {
    if ($tc->has_coercion) {
      dies_ok { $tc->assert_coerce($_) } "$_ as $type->{name} dies as expected";
    }
    else {
      ok( !$is_type->($_), "$_ isnt $type->{name}" );
    }
  }

}

done_testing;
