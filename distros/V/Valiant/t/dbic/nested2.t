use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Nested';

{
  ok my $top = Schema
    ->resultset('XTop')
    ->create({
      top_value => 'aaaaaa',
      middle => {
        middle_value => 'bbbbbb',
        bottom => {
          bottom_value => 'cccccc',
          children => [
            {child_value=>'aaaaaa'},
            {child_value=>'bbbbb'},
            {child_value=>'ccccccc'},
          ],
        },
      },
    });

  ok $top->valid;
}

{
  ok my $top = Schema
    ->resultset('XTop')
    ->create({
      top_value => 'aaa',
      middle => {
        middle_value => 'bb',
        bottom => {
          bottom_value => 'ccc',
          children => [
            {child_value=>'aa'},
            {child_value=>'ccccccc'},
          ],
        },
      },
    });

  ok $top->invalid;
  
  is_deeply +{$top->errors->to_hash(full_messages=>1)}, +{
    middle => [
      "Middle Is Invalid",
    ],
    "middle.bottom" => [
      "Middle Bottom Is Invalid",
    ],
    "middle.bottom.*" => [
      "Middle Bottom * No CCC",
    ],
    "middle.bottom.bottom_value" => [
      "Middle Bottom Bottom Value is too short (minimum is 4 characters)",
    ],
    "middle.bottom.children" => [
      "Middle Bottom Children has too few rows (minimum is 3)",
      "Middle Bottom Children Is Invalid",
    ],
    "middle.bottom.children.0.child_value" => [
      "Middle Bottom Children Child Value is too short (minimum is 5 characters)",
    ],
    "middle.middle_value" => [
      "Middle Middle Value is too short (minimum is 4 characters)",
    ],
    top_value => [
      "Top Value is too short (minimum is 4 characters)",
    ],
  }, 'Got expected errors';

  is_deeply +{$top->middle->bottom->errors->to_hash(full_messages=>1)}, +{
    "*" => [
      "No CCC",
    ],
    bottom_value => [
      "Bottom Value is too short (minimum is 4 characters)",
    ],
    children => [
      "Children has too few rows (minimum is 3)",
      "Children Is Invalid",
    ],
    "children.0.child_value" => [
      "Children Child Value is too short (minimum is 5 characters)",
    ],
  }, 'Got expected errors';
}

done_testing;
