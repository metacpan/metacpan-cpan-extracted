use strict;
use warnings;
use Test::More;
## skip Test::Tabs

use Type::Nano ();

my %values = (
  'undef'   => undef,
  'true'    => !!1,
  'false'   => !!0,
  'zero'    => 0,
  'one'     => 1,
  'integer' => 999,
  'float'   => 3.1416,
  'empty'   => '',
  'string'  => 'Hello world',
  'array'   => [],
  'hash'    => {},
  'scalar'  => \999,
  'code'    => sub {},
  'object'  => bless( {}, 'Local::Foo' ),
  'regexp'  => qr/xyz/,
  'neg'     => -42,
);

my @value_names = qw( undef true false zero one integer float empty string array hash scalar code object regexp neg );
my %expected = (
  Any        => [ qw( P     P    P     P    P   P       P     P     P      P     P    P      P    P      P      P   )],
  Defined    => [ qw( F     P    P     P    P   P       P     P     P      P     P    P      P    P      P      P   )],
  Undef      => [ qw( P     F    F     F    F   F       F     F     F      F     F    F      F    F      F      F   )],
  Ref        => [ qw( F     F    F     F    F   F       F     F     F      P     P    P      P    P      P      F   )],
  ArrayRef   => [ qw( F     F    F     F    F   F       F     F     F      P     F    F      F    F      F      F   )],
  HashRef    => [ qw( F     F    F     F    F   F       F     F     F      F     P    F      F    F      F      F   )],
  CodeRef    => [ qw( F     F    F     F    F   F       F     F     F      F     F    F      P    F      F      F   )],
  Object     => [ qw( F     F    F     F    F   F       F     F     F      F     F    F      F    P      ?      F   )],
  Str        => [ qw( F     P    P     P    P   P       P     P     P      F     F    F      F    F      F      P   )],
  Bool       => [ qw( P     P    P     P    P   F       F     P     F      F     F    F      F    F      F      F   )],
  Num        => [ qw( F     ?    ?     P    P   P       P     F     F      F     F    F      F    F      F      P   )],
  Int        => [ qw( F     ?    ?     P    P   P       F     F     F      F     F    F      F    F      F      P   )],
);

for my $type_name ( sort keys %expected ) {
  subtest "Tests for type $type_name" => sub {
    my $type = Type::Nano->can( $type_name )->();
    ok( $type, 'type exists' );
    my $i = 0;
    for my $value_name ( @value_names ) {
      my $expectation = $expected{$type_name}[$i++];
      my $result = $type->check( $values{$value_name} );
      if ( $expectation eq 'P' ) {
        ok( $result, "type check pass for $value_name" );
      }
      elsif ( $expectation eq 'F' ) {
        ok( !$result, "type check fail for $value_name" );
      }
      else {
        pass( "undefined result for $value_name" );
      }
    }
  };
}

done_testing;
