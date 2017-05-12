use Test::More 'no_plan';

use strict;
use warnings;
use lib 't/v0_test/validator-custom';
use utf8;
use Validator::Custom::Rule;

$SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /DEPRECATED!/ };

my $value;
my $r;
my $js;

use Validator::Custom;

# to_array_remove_blank filter
{
  my $vc = Validator::Custom->new;
  my $data = {key1 => 1, key2 => [1, 2], key3 => '', key4 => [1, 3, '', '']};
  my $rule = $vc->create_rule;
  $rule->require('key1')->filter('to_array_remove_blank');
  $rule->require('key2')->filter('to_array_remove_blank');
  $rule->require('key3')->filter('to_array_remove_blank');
  $rule->require('key4')->filter('to_array_remove_blank');
  
  my $vresult = $vc->validate($data, $rule);
  is_deeply($vresult->data->{key1}, [1]);
  is_deeply($vresult->data->{key2}, [1, 2]);
  is_deeply($vresult->data->{key3}, []);
  is_deeply($vresult->data->{key4}, [1, 3]);
}

# Validator::Custom::Resut filter method
{
  my $vc = Validator::Custom->new;
  my $data = {
    k1 => ' 123 ',
  };
  my $rule = $vc->create_rule;
  $rule->require('k1')->filter('trim');

  my $vresult= Validator::Custom->new->validate($data, $rule)->data;

  is_deeply($vresult, {k1 => '123'});
}

# array validation new syntax
{
  my $vc = Validator::Custom->new;
  my $rule = $vc->create_rule;
  my $data = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a', k5 => []};
  $rule->require('k1')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k1Error1');
  $rule->require('k2')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k2Error1');
  $rule->require('k3')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k3Error1');
  $rule->require('k4')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k4Error1');
  $rule->require('k5')->filter('to_array')->check({selected_at_least => 1})->each(1)->check('int')->message('k5Error1');
  
  my $messages = $vc->validate($data, $rule)->messages;

  is_deeply($messages, [qw/k3Error1 k4Error1 k5Error1/], 'array validate');
}

# check_or
{
  my $vc = Validator::Custom->new;

  # check_or - basic
  {
    my $rule = $vc->create_rule;
    my $data = {k1 => '3', k2 => '', k3 => 'a'};
    $rule->require('k1')
      ->check_or('blank', 'int');
    $rule->require('k2')
      ->check_or('blank', 'int');
    $rule->require('k3')
      ->check_or('blank', 'int');
    
    my $vresult = $vc->validate($data, $rule);
    ok($vresult->is_valid('k1'));
    ok($vresult->is_valid('k2'));
    ok(!$vresult->is_valid('k3'));
  }

  # check_or - args
  {
    my $rule = $vc->create_rule;
    my $data = {k1 => '2', k2 => '7', k3 => '4'};
    $rule->require('k1')
      ->check_or({greater_than => 5}, {less_than => 3});
    $rule->require('k2')
      ->check_or({greater_than => 5}, {less_than => 3});
    $rule->require('k3')
      ->check_or({greater_than => 5}, {less_than => 3})->message('k3_error');
    
    my $vresult = $vc->validate($data, $rule);
    ok($vresult->is_valid('k1'));
    ok($vresult->is_valid('k2'));
    ok(!$vresult->is_valid('k3'));
    ok($vresult->message('k3'), 'k3_error');
  }
}

{
  my $data = { k1 => 1, k2 => 2, k3 => 3 };
  my $rule = [
    k1 => [
      [sub{$_[0] == 1}, "k1Error1"],
      [sub{$_[0] == 2}, "k1Error2"],
      [sub{$_[0] == 3}, "k1Error3"],
    ],
    k2 => [
      [sub{$_[0] == 2}, "k2Error1"],
      [sub{$_[0] == 3}, "k2Error2"]
    ]
  ];
  my $validator = Validator::Custom->new;
  my $vresult   = $validator->validate($data, $rule);
  
  my $errors      = $vresult->errors;
  my $errors_hash = $vresult->errors_to_hash;
  
  is_deeply($errors, [qw/k1Error2 k2Error2/], 'rule');
  is_deeply($errors_hash, {k1 => 'k1Error2', k2 => 'k2Error2'}, 'rule errors hash');
  
  my $errors_hash2 = $vresult->messages_to_hash;
  is_deeply($errors_hash2, {k1 => 'k1Error2', k2 => 'k2Error2'}, 'rule errors hash');
  
  my @errors = Validator::Custom->new(rule => $rule)->validate($data)->errors;
  is_deeply([@errors], [qw/k1Error2 k2Error2/], 'rule');
  
  $validator = Validator::Custom->new->error_stock(0);
  $vresult = $validator->validate($data, $rule);
  @errors = $vresult->errors;
  is(scalar @errors, 1, 'error_stock is 0');
  is($errors[0], 'k1Error2', 'error_stock is 0');
}

{
  ok(!Validator::Custom->new->rule, 'rule default');
}

{
  my $result = Validator::Custom::Result->new;
  $result->data({k => 1});
  is_deeply($result->data, {k => 1}, 'data attribute');
}

{
  eval{Validator::Custom->new->validate({k => 1}, [ k => [['===', 'error']]])->validate};
  like($@, qr/\QConstraint name '===' must be [A-Za-z0-9_]/, 'constraint invalid name')
}

use T1;
{
  my $data = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
  my $rule = [
    k1 => [
      ['Int', "k1Error1"],
    ],
    k2 => [
      ['Int', "k2Error1"],
    ],
    k3 => [
      ['Num', "k3Error1"],
    ],
    k4 => [
      ['Num', "k4Error1"],
    ],
  ];
  my $vc = T1->new;
  my $result= $vc->validate($data, $rule);
  is_deeply([$result->errors], [qw/k2Error1 k4Error1/], 'Custom validator');
  is_deeply(scalar $result->invalid_keys, [qw/k2 k4/], 'invalid keys hash');
  is_deeply($result->invalid_rule_keys, [qw/k2 k4/], 'invalid params hash');
  is_deeply([$result->invalid_keys], [qw/k2 k4/], 'invalid keys hash');  
  ok(!$result->is_ok, 'is_ok');
  
  my $constraints = $vc->constraints;
  ok(exists($constraints->{Int}), 'get constraints');
  ok(exists($constraints->{Num}), 'get constraints');
}

{
  my $data = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
  my $rule = [
    k1 => [
      ['Int', "k1Error1"],
    ],
    k2 => [
      ['Int', "k2Error1"],
    ],
    k3 => [
      ['Num', "k3Error1"],
    ],
    k4 => [
      ['Num', "k4Error1"],
    ],
  ];
  
  my $t = T1->new;
  my $errors = $t->validate($data, $rule)->errors;
  is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator one');
  
  $errors = $t->validate($data, $rule)->errors;
  is_deeply($errors, [qw/k2Error1 k4Error1/], 'Custom validator two');
  
}

{
  my $data = {k1 => 1};
  my $rule = [
    k1 => [
      ['No', "k1Error1"],
    ],
  ];
  eval{T1->new->validate($data, $rule)};
  like($@, qr/"No" is not registered/, 'no custom type');
}

{
  use T2;
  my $data = { k1 => 1, k2 => 'a', k3 => 3.1, k4 => 'a' };
  my $rule = [
    k1 => [
      ['Int', "k1Error1"],
    ],
    k2 => [
      ['Int', "k2Error1"],
    ],
    k3 => [
      ['Num', "k3Error1"],
    ],
    k4 => [
      ['Num', "k4Error1"],
    ],
  ];    
  my $vc = T2->new;
  my $errors = $vc->new->validate($data, $rule)->errors;
  is_deeply($errors, [qw/k2Error1 k4Error1/], 'mearge Custom validator');
  
  my $constraints = $vc->constraints;
  ok(exists($constraints->{Int}), 'merge get constraints');
  ok(exists($constraints->{Num}), 'merge get constraints');
  
}

{
  my $data = { k1 => 1, k2 => [1,2], k3 => [1,'a', 'b'], k4 => 'a'};
  my $rule = [
    k1 => [
      ['@Int', "k1Error1"],
    ],
    k2 => [
      ['@Int', "k2Error1"],
    ],
    k3 => [
      ['@Int', "k3Error1"],
    ],
    k4 => [
      ['@Int', "k4Error1"],
    ],
  ];    
  
  my $vc = T1->new;
  my $errors = $vc->validate($data, $rule)->errors;

  is_deeply($errors, [qw/k3Error1 k4Error1/], 'array validate');
}

{
  my $data = {k1 => [1,2]};
  my $rule = [
    k1 => [
      ['@C1', "k1Error1"],
      ['@C1', "k1Error1"]
    ],
  ];    
  
  my $vc = T1->new;
  my $result= $vc->validate($data, $rule);
  is_deeply(scalar $result->errors, [], 'no error');
  
  is_deeply(scalar $result->data, {k1 => [4,8]}, 'array validate2');
}


{
  my $data = { k1 => 1};
  my $rule = [
    k1 => [
      ['Int', "k1Error1"],
    ],
  ];    
  my @errors = T1->new->validate($data, $rule)->errors;
  is(scalar @errors, 0, 'no error');
}

{
  use T5;
  my $data = { k1 => 1, k2 => 'a', k3 => '  3  ', k4 => 4, k5 => 5, k6 => 5, k7 => 'a', k11 => [1,2]};
  my $rule = [
    k1 => [
      [{'C1' => [3, 4]}, "k1Error1"],
    ],
    k2 => [
      [{'C2' => [3, 4]}, "k2Error1" ],
    ],
    k3 => [
      'TRIM_LEAD',
      'TRIM_TRAIL'
    ],
    k4 => [
      ['NO_ERROR']
    ],
    [qw/k5 k6/] => [
      [{'C3' => [5]}, 'k5 k6 Error']
    ],
    k7 => [
      {'C2' => [3, 4]},
    ],
    k11 => [
      '@C6'
    ]
  ];
  
  my $vc = T5->new;
  my $result= $vc->validate($data, $rule);
  is_deeply([$result->errors], 
            ['k2Error1', 'Error message not specified',
             'Error message not specified'
            ], 'variouse options');
  
  is_deeply([$result->invalid_keys], [qw/k2 k4 k7/], 'invalid key');
  
  is_deeply($result->data->{k1},[1, [3, 4]], 'data');
  ok(!$result->data->{k2}, 'data not exist in error case');
  cmp_ok($result->data->{k3}, 'eq', 3, 'filter');
  ok(!$result->data->{k4}, 'data not set in case error');
  isa_ok($result->data->{k11}->[0], 'T5');
  isa_ok($result->data->{k11}->[1], 'T5');

  $data = {k5 => 5, k6 => 6};
  $rule = [
    [qw/k5 k6/] => [
      [{'C3' => [5]}, 'k5 k6 Error']
    ]
  ];
  
  $result= $vc->validate($data, $rule);
  local $SIG{__WARN__} = sub {};
  ok(!$result->is_valid, 'corelative invalid_keys');
  is(scalar @{$result->invalid_keys}, 1, 'corelative invalid_keys');
}

{
  my $data = { k1 => 1, k2 => 2};
  my $constraint = sub {
    my $values = shift;
    return $values->[0] eq $values->[1];
  };
  
  my $rule = [
    {k1_2 => [qw/k1 k2/]}  => [
      [$constraint, 'error_k1_2' ]
    ]
  ];
  
  my $vc = Validator::Custom->new;
  my @errors = $vc->validate($data, $rule)->errors;
  is_deeply([@errors], ['error_k1_2'], 'specify key');
}

{
  eval{Validator::Custom->new->validate([])};
  like($@, qr/First argument must be hash ref/, 'Data not hash ref');
}

{
  eval{Validator::Custom->new->rule({})->validate({})};
  like($@, qr/Invalid rule structure/sm,
           'Validation rule not array ref');
}

{
  eval{Validator::Custom->new->rule([key => 'Int'])->validate({})};
  like($@, qr/Invalid rule structure/sm, 
           'Constraints of key not array ref');
}

use T6;
{
  my $vc = T6->new;
  
  my $data = {
    name => 'zz' x 30,
    age => 'zz',
  };
  
  my $rule = [
    name => [
      {length => [1, 2]}
    ]
  ];
  
  my $vresult = $vc->rule($rule)->validate($data);
  my @invalid_keys = $vresult->invalid_keys;
  is_deeply([@invalid_keys], ['name'], 'constraint argument first');
  
  my $errors_hash = $vresult->errors_to_hash;
  is_deeply($errors_hash, {name => 'Error message not specified'},
            'errors_to_hash message not specified');
  
  is($vresult->error('name'), 'Error message not specified', 'error default message');
  
  @invalid_keys = $vc->rule($rule)->validate($data)->invalid_keys;
  is_deeply([@invalid_keys], ['name'], 'constraint argument second');
}

{
  my $result = Validator::Custom->new->rule([])->validate({key => 1});
  ok($result->is_ok, 'is_ok ok');
}

{
  my $vc = T1->new;
  $vc->register_constraint(
   'C1' => sub {
      my $value = shift;
      return $value > 1 ? 1 : 0;
    },
   'C2' => sub {
      my $value = shift;
      return $value > 5 ? 1 : 0;
    }
  );
  
  my $data = {k1_1 => 1, k1_2 => 2, k2_1 => 5, k2_2 => 6};
  
  $vc->rule([
    k1_1 => [
      'C1'
    ],
    k1_2 => [
      'C1'
    ],
    k2_1 => [
      'C2'
    ],
    k2_2 => [
      'C2'
    ]
  ]);
  
  is_deeply([$vc->validate($data)->invalid_keys], [qw/k1_1 k2_1/], 'register_constraints object');
}

my $vc;
my $params;
my $rule;
my $vresult;
my $errors;
my @errors;
my $data;


# or expression
$vc = T1->new;
$rule = [
  key0 => [
    ['Int', 'Error-key0']
  ],
  key1 => [
    ['Int', 'Error-key1-0'],
    'Int'
  ],
  key1 => [
    ['aaa', 'Error-key1-1'],
    'aaa'
  ],
  key1 => [
    ['bbb', 'Error-key1-2']
  ],
  key2 => [
    ['Int', 'Error-key2']
  ]
];
$params = {key1 => 1, key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_ok, "first key");

$params = {key1 => 'aaa', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_ok, "second key");

$params = {key1 => 'bbb', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok($vresult->is_ok, "third key");
ok(!$vresult->error_reason('key1'), "third key : error reason");
eval { $vresult->error_reason };
like($@, qr/Parameter name must be specified/, 'error_reason not Parameter name');

$params = {key1 => 'ccc', key0 => 1, key2 => 2};
$vresult = $vc->validate($params, $rule);
ok(!$vresult->is_ok, "invalid");
is_deeply([$vresult->invalid_keys], ['key1'], "invalid_keys");
is_deeply([$vresult->errors], ['Error-key1-0'], "errors");
is_deeply($vresult->messages, ['Error-key1-0'], "messages");
is($vresult->error_reason('key1'), 'Int', "error reason");
is($vresult->error('key1'), 'Error-key1-0', "error");
is($vresult->message('key1'), 'Error-key1-0', "error");
eval{ $vresult->error };
like($@, qr/Parameter name must be specified/, 'error not Parameter name');

$vc = T1->new(error_stock => 0);
$params = {key1 => 'ccc', key0 => 1, key2 => 'no_num'};
$vresult = $vc->validate($params, $rule);
ok(!$vresult->is_ok, "invalid");
is_deeply([$vresult->invalid_keys], ['key1'], "invalid_keys");
is_deeply([$vresult->errors], ['Error-key1-0'], "errors");
is($vresult->error_reason('key1'), 'Int', "error reason");


# data_filter
$vc = T1->new;
$params = {key1 => 1};
$vc->data_filter(sub {
  my $data = shift;
  
  $data->{key1} = 'a';
  
  return $data;
});
$vc->rule([
  key1 => [
    'Int'
  ]
]);
$vresult = $vc->validate($params);
is_deeply([$vresult->invalid_keys], ['key1'], "basic");
is_deeply($vresult->raw_data, {key1 => 'a'}, "raw_data");


# Validator::Custom::Result raw_invalid_rule_keys'
$vc = Validator::Custom->new;
$vc->register_constraint(p => sub {
  my $values = shift;
  return $values->[0] eq $values->[1];
});
$vc->register_constraint(q => sub {
  my $value = shift;
  return $value eq 1;
});


$data = {k1 => 1, k2 => 2, k3 => 3, k4 => 1};
$rule = [
  {k12 => ['k1', 'k2']} => [
    'p'
  ],
  k3 => [
    'q'
  ],
  k4 => [
    'q'
  ]
];
$vresult = $vc->validate($data, $rule);

is_deeply($vresult->invalid_rule_keys, ['k12', 'k3'], 'invalid_rule_keys');
is_deeply($vresult->invalid_params, ['k1', 'k2', 'k3'],
        'invalid_params');

# shared_rule;
$vc = Validator::Custom->new;
$vc->register_constraint(
  defined   => sub { defined $_[0] },
  not_blank => sub { $_[0] ne '' },
  int       => sub { $_[0] =~ /\d+/ }
);
$data = {
  k1 => undef,
  k2 => 'a',
  k3 => 1
};
$rule = [
  k1 => [
    # Nothing
  ],
  k2 => [
    # Nothing
  ],
  k3 => [
    'int'
  ]
];
$vc->shared_rule([
  ['defined', 'Must be defined'],
  ['not_blank',   'Must be blank']
]);
$vresult = $vc->validate($data, $rule);
is_deeply($vresult->messages_to_hash, {k1 => 'Must be defined'},
        'shared rule');

# constraints default;

my @infos = (
  [
    'not_defined',
    {
      k1 => undef,
      k2 => 'a',
    },
    [
      k1 => [
        'not_defined'
      ],
      k2 => [
        'not_defined'
      ],
    ],
    [qw/k2/]
  ],
  [
    'defined',
    {
      k1 => undef,
      k2 => 'a',
    },
    [
      k1 => [
        'defined'
      ],
      k2 => [
        'defined'
      ],
    ],
    [qw/k1/]
  ],
  [
    'not_space',
    {
      k1 => '',
      k2 => ' ',
      k3 => ' a '
    },
    [
      k1 => [
        'not_space'
      ],
      k2 => [
        'not_space'
      ],
      k3 => [
        'not_space'
      ],
    ],
    [qw/k1 k2/]
  ],
  [
    'not_blank',
    {
      k1 => '',
      k2 => 'a',
      k3 => ' '
    },
    [
      k1 => [
        'not_blank'
      ],
      k2 => [
        'not_blank'
      ],
      k3 => [
        'not_blank'
      ],
    ],
    [qw/k1/]
  ],
  [
    'blank',
    {
      k1 => '',
      k2 => 'a',
      k3 => ' '
    },
    [
      k1 => [
        'blank'
      ],
      k2 => [
        'blank'
      ],
      k3 => [
        'blank'
      ],
    ],
    [qw/k2 k3/]
  ],    
  [
    'int',
    {
      k8  => '19',
      k9  => '-10',
      k10 => 'a',
      k11 => '10.0',
    },
    [
      k8 => [
        'int'
      ],
      k9 => [
        'int'
      ],
      k10 => [
        'int'
      ],
      k11 => [
        'int'
      ],
    ],
    [qw/k10 k11/]
  ],
  [
    'uint',
    {
      k12  => '19',
      k13  => '-10',
      k14 => 'a',
      k15 => '10.0',
    },
    [
      k12 => [
        'uint'
      ],
      k13 => [
        'uint'
      ],
      k14 => [
        'uint'
      ],
      k15 => [
        'uint'
      ],
    ],
    [qw/k13 k14 k15/]
  ],
  [
    'ascii',
    {
      k16 => '!~',
      k17 => ' ',
      k18 => "\0x7f",
    },
    [
      k16 => [
        'ascii'
      ],
      k17 => [
        'ascii'
      ],
      k18 => [
        'ascii'
      ],
    ],
    [qw/k17 k18/]
  ],
  [
    'length',
    {
      k19 => '111',
      k20 => '111',
    },
    [
      k19 => [
        {'length' => [3, 4]},
        {'length' => [2, 3]},
        {'length' => [3]},
        {'length' => 3},
      ],
      k20 => [
        {'length' => [4, 5]},
      ]
    ],
    [qw/k20/],
  ],
  [
    'duplication',
    {
      k1_1 => 'a',
      k1_2 => 'a',
      
      k2_1 => 'a',
      k2_2 => 'b'
    },
    [
      {k1 => [qw/k1_1 k1_2/]} => [
        'duplication'
      ],
      {k2 => [qw/k2_1 k2_2/]} => [
        'duplication'
      ]
    ],
    [qw/k2/]
  ],
  [
    'regex',
    {
      k1 => 'aaa',
      k2 => 'aa',
    },
    [
      k1 => [
        {'regex' => "a{3}"}
      ],
      k2 => [
        {'regex' => "a{4}"}
      ]
    ],
    [qw/k2/]
  ],
  [
    'http_url',
    {
      k1 => 'http://www.lost-season.jp/mt/',
      k2 => 'iii',
    },
    [
      k1 => [
        'http_url'
      ],
      k2 => [
        'http_url'
      ]
    ],
    [qw/k2/]
  ],
  [
    'selected_at_least',
    {
      k1 => 1,
      k2 =>[1],
      k3 => [1, 2],
      k4 => [],
      k5 => [1,2]
    },
    [
      k1 => [
        {selected_at_least => 1}
      ],
      k2 => [
        {selected_at_least => 1}
      ],
      k3 => [
        {selected_at_least => 2}
      ],
      k4 => [
        'selected_at_least'
      ],
      k5 => [
        {'selected_at_least' => 3}
      ]
    ],
    [qw/k5/]
  ],
  [
    'greater_than',
    {
      k1 => 5,
      k2 => 5,
      k3 => 'a',
    },
    [
      k1 => [
        {'greater_than' => 5}
      ],
      k2 => [
        {'greater_than' => 4}
      ],
      k3 => [
        {'greater_than' => 1}
      ]
    ],
    [qw/k1 k3/]
  ],
  [
    'less_than',
    {
      k1 => 5,
      k2 => 5,
      k3 => 'a',
    },
    [
      k1 => [
        {'less_than' => 5}
      ],
      k2 => [
        {'less_than' => 6}
      ],
      k3 => [
        {'less_than' => 1}
      ]
    ],
    [qw/k1 k3/]
  ],
  [
    'equal_to',
    {
      k1 => 5,
      k2 => 5,
      k3 => 'a',
    },
    [
      k1 => [
        {'equal_to' => 5}
      ],
      k2 => [
        {'equal_to' => 4}
      ],
      k3 => [
        {'equal_to' => 1}
      ]
    ],
    [qw/k2 k3/]
  ],
  [
    'between',
    {
      k1 => 5,
      k2 => 5,
      k3 => 5,
      k4 => 5,
      k5 => 'a',
    },
    [
      k1 => [
        {'between' => [5, 6]}
      ],
      k2 => [
        {'between' => [4, 5]}
      ],
      k3 => [
        {'between' => [6, 7]}
      ],
      k4 => [
        {'between' => [5, 5]}
      ],
      k5 => [
        {'between' => [5, 5]}
      ]
    ],
    [qw/k3 k5/]
  ],
  [
    'decimal',
    {
      k1 => '12.123',
      k2 => '12.123',
      k3 => '12.123',
      k4 => '12',
      k5 => '123',
      k6 => '123.a',
      k7 => '1234.1234',
      k8 => '',
      k9 => 'a',
      k10 => '1111111.12',
      k11 => '1111111.123',
      k12 => '12.1111111',
      k13 => '123.1111111'
    },
    [
      k1 => [
        {'decimal' => [2,3]}
      ],
      k2 => [
        {'decimal' => [1,3]}
      ],
      k3 => [
        {'decimal' => [2,2]}
      ],
      k4 => [
        {'decimal' => [2]}
      ],
      k5 => [
        {'decimal' => 2}
      ],
      k6 => [
        {'decimal' => 2}
      ],
      k7 => [
        'decimal'
      ],
      k8 => [
        'decimal'
      ],
      k9 => [
        'decimal'
      ],
      k10 => [
        {'decimal' => [undef, 2]}
      ],
      k11 => [
        {'decimal' => [undef, 2]}
      ],
      k12 => [
        {'decimal' => [2, undef]}
      ],
      k13 => [
        {'decimal' => [2, undef]}
      ]
    ],
    [qw/k2 k3 k5 k6 k8 k9 k11 k13/]
  ],
  [
    'in_array',
    {
      k1 => 'a',
      k2 => 'a',
      k3 => undef
    },
    [
      k1 => [
        {'in_array' => [qw/a b/]}
      ],
      k2 => [
        {'in_array' => [qw/b c/]}
      ],
      k3 => [
        {'in_array' => [qw/b c/]}
      ]
    ],
    [qw/k2 k3/]
  ],
  [
    'shift array',
    {
      k1 => [1, 2]
    },
    [
      k1 => [
        'shift'
      ]
    ],
    [],
    {k1 => 1}
  ],
  [
    'shift scalar',
    {
      k1 => 1
    },
    [
      k1 => [
        'shift'
      ]
    ],
    [],
    {k1 => 1}
  ],
);

foreach my $info (@infos) {
  validate_ok(@$info);
}

# exception
my @exception_infos = (
  [
    'length need parameter',
    {
      k1 => 'a',
    },
    [
      k1 => [
        'length'
      ]
    ],
    qr/\QConstraint 'length' needs one or two arguments/
  ],
  [
    'greater_than target undef',
    {
      k1 => 1
    },
    [
      k1 => [
        'greater_than'
      ]
    ],
    qr/\QConstraint 'greater_than' needs a numeric argument/
  ],
  [
    'greater_than not number',
    {
      k1 => 1
    },
    [
      k1 => [
        {'greater_than' => 'a'}
      ]
    ],
    qr/\QConstraint 'greater_than' needs a numeric argument/
  ],
  [
    'less_than target undef',
    {
      k1 => 1
    },
    [
      k1 => [
        'less_than'
      ]
    ],
    qr/\QConstraint 'less_than' needs a numeric argument/
  ],
  [
    'less_than not number',
    {
      k1 => 1
    },
    [
      k1 => [
        {'less_than' => 'a'}
      ]
    ],
    qr/\QConstraint 'less_than' needs a numeric argument/
  ],
  [
    'equal_to target undef',
    {
      k1 => 1
    },
    [
      k1 => [
        'equal_to'
      ]
    ],
    qr/\QConstraint 'equal_to' needs a numeric argument/
  ],
  [
    'equal_to not number',
    {
      k1 => 1
    },
    [
      k1 => [
        {'equal_to' => 'a'}
      ]
    ],
    qr/\QConstraint 'equal_to' needs a numeric argument/
  ],
  [
    'between target undef',
    {
      k1 => 1
    },
    [
      k1 => [
        {'between' => [undef, 1]}
      ]
    ],
    qr/\QConstraint 'between' needs two numeric arguments/
  ],
  [
    'between target undef or not number1',
    {
      k1 => 1
    },
    [
      k1 => [
        {'between' => ['a', 1]}
      ]
    ],
    qr/\QConstraint 'between' needs two numeric arguments/
  ],
  [
    'between target undef or not number2',
    {
      k1 => 1
    },
    [
      k1 => [
        {'between' => [1, undef]}
      ]
    ],
    qr/\QConstraint 'between' needs two numeric arguments/
  ],
  [
    'between target undef or not number3',
    {
      k1 => 1
    },
    [
      k1 => [
        {'between' => [1, 'a']}
      ]
    ],
    qr/\Qbetween' needs two numeric arguments/
  ],
);

foreach my $exception_info (@exception_infos) {
  validate_exception(@$exception_info)
}

sub validate_ok {
  my ($test_name, $data, $validation_rule, $invalid_keys, $result_data) = @_;
  my $vc = Validator::Custom->new;
  my $r = $vc->validate($data, $validation_rule);
  is_deeply([$r->invalid_keys], $invalid_keys, "$test_name invalid_keys");
  
  if (ref $result_data eq 'CODE') {
      $result_data->($r);
  }
  elsif($result_data) {
      is_deeply($r->data, $result_data, "$test_name result data");
  }
}

sub validate_exception {
  my ($test_name, $data, $validation_rule, $error) = @_;
  my $vc = Validator::Custom->new;
  eval{$vc->validate($data, $validation_rule)};
  like($@, $error, "$test_name exception");
}

# trim;
{
  my $data = {
    int_param => ' 123 ',
    collapse  => "  \n a \r\n b\nc  \t",
    left      => '  abc  ',
    right     => '  def  '
  };

  my $validation_rule = [
    int_param => [
      ['trim']
    ],
    collapse  => [
      ['trim_collapse']
    ],
    left      => [
      ['trim_lead']
    ],
    right     => [
      ['trim_trail']
    ]
  ];

  my $result_data= Validator::Custom->new->validate($data,$validation_rule)->data;

  is_deeply(
    $result_data, 
    { int_param => '123', left => "abc  ", right => '  def', collapse => "a b c"},
    'trim check'
  );
}

# Negative validation
$data = {key1 => 'a', key2 => 1};
$vc = Validator::Custom->new;
$rule = [
  key1 => [
    'not_blank',
    '!int',
    'not_blank'
  ],
  key2 => [
    'not_blank',
    '!int',
    'not_blank'
  ]
];
my $result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2'], "single value");

$data = {key1 => ['a', 'a'], key2 => [1, 1]};
$vc = Validator::Custom->new;
$rule = [
  key1 => [
    '@not_blank',
    '@!int',
    '@not_blank'
  ],
  key2 => [
    '@not_blank',
    '@!int',
    '@not_blank'
  ]
];
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2'], "multi values");

$data = {key1 => 2, key2 => 1};
$vc = Validator::Custom->new;
$vc->register_constraint(
  one => sub {
    my $value = shift;
    
    if ($value == 1) {
      return [1, $value];
    }
    else {
      return [0, $value];
    }
  }
);
$rule = [
  key1 => [
    '!one',
  ],
  key2 => [
    '!one'
  ]
];
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2'], "filter value");


# missing_params
$data = {key1 => 1};
$vc = Validator::Custom->new;
$rule = [
  key1 => [
    'int'
  ],
  key2 => [
    'int'
  ],
  {rkey1 => ['key2', 'key3']} => [
    'duplication'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_ok, "invalid");
is_deeply($result->missing_params, ['key2', 'key3'], "names");

# has_missing
$data = {};
$vc = Validator::Custom->new;
$rule = [
  key1 => [
    'int'
  ]
];
$result = $vc->validate($data, $rule);
ok($result->has_missing, "missing");

$data = {key1 => 'a'};
$vc = Validator::Custom->new;
$rule = [
  key1 => [
    'int'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->has_missing, "missing");


# duplication result value
$data = {key1 => 'a', key2 => 'a'};
$rule = [
  {key3 => ['key1', 'key2']} => [
    'duplication'
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is($result->data->{key3}, 'a');


# message option
$data = {key1 => 'a'};
$rule = [
  key1 => {message => 'error'} => [
    'int'
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is($result->message('key1'), 'error');


# default option
$data = {};
$rule = [
  key1 => {default => 2} => [
  
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->is_ok);
is($result->data->{key1}, 2, "data value");

$data = {};
$rule = [
  key1 => {default => 2, copy => 0} => [
  
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->is_ok, "has missing ");
ok(!exists $result->data->{key1}, "missing : data value and no copy");

$data = {key1 => 'a'};
$rule = [
  key1 => {default => 2} => [
    'int'
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->is_ok);
is($result->data->{key1}, 2, "invalid : data value");

$data = {key1 => 'a'};
$rule = [
  key1 => {default => 2, copy => 0} => [
    'int'
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->is_ok);
ok(!exists $result->data->{key1}, "invalid : data value and no copy");

$data = {key1 => 'a', key3 => 'b'};
$rule = [
  key1 => {default => sub { return $_[0] }} => [
    'int'
  ],
  key2 => {default => sub { return 5 }} => [
    'int'
  ],
  key3 => {default => undef} => [
    'int'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is($result->data->{key1}, $vc, "data value");
is($result->data->{key2}, 5, "data value");
ok(exists $result->data->{key3} && !defined $result->data->{key3});

# copy
$data = {key1 => 'a', 'key2' => 'a'};
$rule = [
  {key3 => ['key1', 'key2']} => {copy => 0} => [
    'duplication'
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->is_ok, "ok");
is_deeply($result->data, {}, "not copy");


# error_stock plus
$data = {key1 => 'a', 'key2' => 'b', key4 => 'a'};
$rule = [
  key4  => {message => 'e1'} => [
    'int'
  ],
  {key3 => ['key1', 'key2']} => {message => 'e2'} => [
    'duplication'
  ],
];
$vc = Validator::Custom->new;
$vc->error_stock(0);
$result = $vc->validate($data, $rule);
is_deeply($result->messages, ['e1']);


# is_valid
$data = {key1 => 'a', key2 => 'b', key3 => 2};
$rule = [
  key1 => [
    'int'
  ],
  key2 => [
    'int'
  ],
  key3 => [
    'int'
  ]
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));


# merge
$data = {key1 => 'a', key2 => 'b', key3 => 'c'};
$rule = [
  {key => ['key1', 'key2', 'key3']} => [
    'merge'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is($result->data->{key}, 'abc');

# Multi-Paramater validation using regex
$data = {key1 => 'a', key2 => 'b', key3 => 'c', p => 'd'};
$rule = [
  {key => qr/^key/} => [
    'merge'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
$value = $result->data->{key};
ok(index($value, 'a') > -1);
ok(index($value, 'b') > -1);
ok(index($value, 'c') > -1);
ok(index($value, 'd') == -1);

$data = {key1 => 'a'};
$rule = [
  {key => qr/^key/} => [
    'merge'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
$value = $result->data->{key};
ok(index($value, 'a') > -1);


# or condition new syntax
$data = {key1 => '3', key2 => '', key3 => 'a'};
$rule = [
  key1 => [
    'blank || int'
  ],
  key2 => [
    'blank || int'
  ],
  key3 => [
    'blank || int'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_rule_keys, ['key3']);


# or condition new syntax
$data = {key1 => '3', key2 => '', key3 => 'a'};
$rule = [
  key1 => [
    'blank || !int'
  ],
  key2 => [
    'blank || !int'
  ],
  key3 => [
    'blank || !int'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_rule_keys, ['key1']);


# space
$data = {key1 => '', key2 => ' ', key3 => 'a'};
$rule = [
  key1 => [
    'space'
  ],
  key2 => [
    'space'
  ],
  key3 => [
    'space'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_rule_keys, ['key3']);


# or condition filter
$data = {key1 => '2010/11/04', key2 => '2010-11-04', key3 => '2010 11 04'};
$rule = [
  key1 => [
    'date1 || date2 || date3'
  ],
  key2 => [
    'date1 || date2 || date3'
  ],
  key3 => [
    'date1 || date2 || date3'
  ],
];
$vc = Validator::Custom->new;
$vc->register_constraint(
  date1 => sub {
    my $value = shift;
    if ($value =~ m#(\d{4})/(\d{2})/(\d{2})#) {
      return [1, "$1$2$3"];
    }
    else {
      return [0, undef];
    }
  },
  date2 => sub {
    my $value = shift;
    if ($value =~ /(\d{4})-(\d{2})-(\d{2})/) {
      return [1, "$1$2$3"];
    }
    else {
      return [0, undef];
    }
  },
  date3 => sub {
    my $value = shift;
    if ($value =~ /(\d{4}) (\d{2}) (\d{2})/) {
      return [1, "$1$2$3"];
    }
    else {
      return [0, undef];
    }
  }

);
$result = $vc->validate($data, $rule);
ok($result->is_ok);
is_deeply($result->data, {key1 => '20101104', key2 => '20101104',
                        key3 => '20101104'});

$data = {key1 => 'aaa', key2 => 'bbb'};
$rule = [
  key1 => [
    'not_blank || blank'
  ],
  key2 => [
    'blank || not_blank'
  ]
];
$result = $vc->validate($data, $rule);
ok($result->is_ok);

# or condition filter array
$data = {
  key1 => ['2010/11/04', '2010-11-04', '2010 11 04'],
  key2 => ['2010/11/04', '2010-11-04', 'xxx']
};
$rule = [
  key1 => [
    '@ date1 || date2 || date3'
  ],
  key2 => [
    '@ date1 || date2 || date3'
  ],
];
$vc = Validator::Custom->new;
$vc->register_constraint(
  date1 => sub {
    my $value = shift;
    if ($value =~ m#(\d{4})/(\d{2})/(\d{2})#) {
      return [1, "$1$2$3"];
    }
    else {
      return [0, undef];
    }
  },
  date2 => sub {
    my $value = shift;
    if ($value =~ /(\d{4})-(\d{2})-(\d{2})/) {
      return [1, "$1$2$3"];
    }
    else {
      return [0, undef];
    }
  },
  date3 => sub {
    my $value = shift;
    if ($value =~ /(\d{4}) (\d{2}) (\d{2})/) {
      return [1, "$1$2$3"];
    }
    else {
      return [0, undef];
    }
  }

);
$result = $vc->validate($data, $rule);
is_deeply($result->invalid_params, ['key2']);
is_deeply($result->data, {key1 => ['20101104', '20101104', '20101104'],
                        });


# _parse_random_string_rule
$rule = {
  name1 => '[ab]{3}@[de]{2}.com',
  name2 => '[ab]{2}c{2}p{1}',
  name3 => '',
  name4 => 'abc',
  name5 => 'a{10}'
};
$vc = Validator::Custom->new;
$r = $vc->_parse_random_string_rule($rule);
is_deeply(
  $r,
  {
    name1 => [['a', 'b'], ['a', 'b'], ['a', 'b'], ['@'], ['d', 'e'], ['d', 'e'], ['.'], ['c'], ['o'], ['m']],
    name2 => [['a', 'b'], ['a', 'b'], ['c'], ['c'], ['p']],
    name3 => [],
    name4 => [['a'], ['b'], ['c']],
    name5 => [['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a'], ['a']]
  });


# any
$data = {
  key1 => undef, key2 => 1
};
$rule = [
  key1 => [
    'any'
  ],
  key2 => [
    'any'
  ],
];
$vc = Validator::Custom->new;
$result = $vc->validate($data, $rule);
ok($result->is_ok);


# to_hash
$vc = Validator::Custom->new;
$data = {key1 => 1, key2 => 'a', key3 => 'a'};
$rule = [
  key1 => [
    'int'
  ],
  key2 => {message => 'a'} => [
    'int'
  ],
  key3 => {message => 'b'} => [
    'int'
  ],
  key4 => {message => 'key4 must be int'} => [
    'int'
  ],
  key5 => {message => 'key5 must be int'} => [
    'int'
  ],
];
$result = $vc->validate($data, $rule);
is_deeply($result->to_hash, {
  ok => $result->is_ok, invalid => $result->has_invalid,
  missing => $result->has_missing,
  missing_params => $result->missing_params,
  messages => $result->messages_to_hash
});
is_deeply($result->to_hash, {
  ok => 0, invalid => 1,
  missing => 1,
  missing_params => ['key4', 'key5'],
  messages => {key2 => 'a', key3 => 'b', key4 => 'key4 must be int', key5 => 'key5 must be int'}
});

# not_required
$vc = Validator::Custom->new;
$data = {key1 => 1};
$rule = [
  key1 => [
    'int'
  ],
  key2 => {message => 'a'} => [
    'int'
  ],
  key3 => {require => 0} => [
    'int'
  ],
];
$result = $vc->validate($data, $rule);
is_deeply($result->missing_params, ['key2']);
ok(!$result->is_ok);

$vc = Validator::Custom->new;
$data = {key1 => 1};
$rule = [
  key1 => {require => 0} => [
    'int'
  ],
  key2 => {require => 0} => [
    'int'
  ],
  key3 => {require => 0} => [
    'int'
  ],
];
$result = $vc->validate($data, $rule);
ok($result->is_ok);
ok(!$result->has_invalid);

# to_array filter
$vc = Validator::Custom->new;
$data = {key1 => 1, key2 => [1, 2]};
$rule = [
  key1 => [
    'to_array'
  ],
  key2 => [
    'to_array'
  ],
];
$result = $vc->validate($data, $rule);
is_deeply($result->data->{key1}, [1]);
is_deeply($result->data->{key2}, [1, 2]);


# loose_data
$vc = Validator::Custom->new;
$data = {key1 => 1, key2 => 2};
$rule = [
  key1 => [
    'to_array'
  ],
];
$result = $vc->validate($data, $rule);
is_deeply($result->loose_data->{key1}, [1]);
is_deeply($result->loose_data->{key2}, 2);

$vc = Validator::Custom->new;
$data = {key1 => 'a'};
$rule = [
  key1 => {default => 5} => [
    'int'
  ]
];
$result = $vc->validate($data, $rule);
is_deeply($result->loose_data->{key1}, 5);

# undefined value
$vc = Validator::Custom->new;
$data = {key1 => undef, key2 => '', key3 => 'a'};
$rule = [
  key1 => [
    'ascii'
  ],
  key2 => [
    'ascii'
  ],
  key3 => [
    'ascii'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => '2'};
$rule = [
  key1 => [
    {between => [1, 3]}
  ],
  key2 => [
    {between => [1, 3]}
  ],
  key3 => [
    {between => [1, 3]}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => ''};
$rule = [
  key1 => [
    'blank'
  ],
  key2 => [
    'blank'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok($result->is_valid('key2'));

$data = {key1 => undef, key2 => '', key3 => '2.1'};
$rule = [
  key1 => [
    {decimal => 1}
  ],
  key2 => [
    {decimal => 1}
  ],
  key3 => [
    {decimal => [1, 1]}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => 'a', key2 => 'a', key3 => '', key4 => '', key5 => undef, key6 => undef};
$rule = [
  {'key1-2' => ['key1', 'key2']} => [
    'duplication'
  ],
  {'key3-4' => ['key3', 'key4']} => [
    'duplication'
  ],
  {'key1-5' => ['key1', 'key5']} => [
    'duplication'
  ],
  {'key5-1' => ['key5', 'key1']} => [
    'duplication'
  ],
  {'key5-6' => ['key5', 'key6']} => [
    'duplication'
  ],
];
$result = $vc->validate($data, $rule);
ok($result->is_valid('key1-2'));
ok($result->is_valid('key3-4'));
ok(!$result->is_valid('key1-5'));
ok(!$result->is_valid('key5-1'));
ok(!$result->is_valid('key5-6'));

$data = {key1 => undef, key2 => '', key3 => '1'};
$rule = [
  key1 => [
    {equal_to => 1}
  ],
  key2 => [
    {equal_to => 1}
  ],
  key3 => [
    {equal_to => 1}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => '5'};
$rule = [
  key1 => [
    {greater_than => 1}
  ],
  key2 => [
    {greater_than => 1}
  ],
  key3 => [
    {greater_than => 1}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => 'http://aaa.com'};
$rule = [
  key1 => [
    'http_url'
  ],
  key2 => [
    'http_url'
  ],
  key3 => [
    'http_url'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => '1'};
$rule = [
  key1 => [
    'int'
  ],
  key2 => [
    'int'
  ],
  key3 => [
    'int'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => '1'};
$rule = [
  key1 => [
    {'in_array' => [1, 2]}
  ],
  key2 => [
    {'in_array' => [1, 2]}
  ],
  key3 => [
    {'in_array' => [1, 2]}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => 'aaa'};
$rule = [
  key1 => [
    {'length' => [1, 4]}
  ],
  key2 => [
    {'length' => [1, 4]}
  ],
  key3 => [
    {'length' => [1, 4]}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => 3};
$rule = [
  key1 => [
    {'less_than' => 4}
  ],
  key2 => [
    {'less_than' => 4}
  ],
  key3 => [
    {'less_than' => 4}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => 3};
$rule = [
  key1 => [
    'not_blank'
  ],
  key2 => [
    'not_blank'
  ],
  key3 => [
    'not_blank'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => 3};
$rule = [
  key1 => [
    'not_space'
  ],
  key2 => [
    'not_space'
  ],
  key3 => [
    'not_space'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => 3};
$rule = [
  key1 => [
    'uint'
  ],
  key2 => [
    'uint'
  ],
  key3 => [
    'uint'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => 3};
$rule = [
  key1 => [
    {'regex' => qr/3/}
  ],
  key2 => [
    {'regex' => qr/3/}
  ],
  key3 => [
    {'regex' => qr/3/}
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok(!$result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key1 => undef, key2 => '', key3 => ' '};
$rule = [
  key1 => [
    'space'
  ],
  key2 => [
    'space'
  ],
  key3 => [
    'space'
  ]
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok($result->is_valid('key2'));
ok($result->is_valid('key3'));

$data = {key2 => 2};
$rule = [
  key1 => {message => 'key1 is undefined'} => [
    'defined'
  ]
];
$result = $vc->validate($data, $rule);
is_deeply($result->missing_params, ['key1']);
is_deeply($result->messages, ['key1 is undefined']);
ok(!$result->is_valid('key1'));

# between 0-9
$data = {key1 => 0, key2 => 9};
$rule = [
  key1 => [
    {between => [0, 9]}
  ],
  key2 => [
    {between => [0, 9]}
  ]
];
$result = $vc->validate($data, $rule);
ok($result->is_ok);

# between decimal
$data = {key1 => '-1.5', key2 => '+1.5', key3 => 3.5};
$rule = [
  key1 => [
    {between => [-2.5, 1.9]}
  ],
  key2 => [
    {between => ['-2.5', '+1.9']}
  ],
  key3 => [
    {between => ['-2.5', '+1.9']}
  ]
];
$result = $vc->validate($data, $rule);
ok($result->is_valid('key1'));
ok($result->is_valid('key2'));
ok(!$result->is_valid('key3'));

# equal_to decimal
$data = {key1 => '+0.9'};
$rule = [
  key1 => [
    {equal_to => '0.9'}
  ]
];
$result = $vc->validate($data, $rule);

# greater_than decimal
$data = {key1 => '+10.9'};
$rule = [
  key1 => [
    {greater_than => '9.1'}
  ]
];
$result = $vc->validate($data, $rule);

# int unicode
$data = {key1 => 0, key2 => 9, key3 => '２'};
$rule = [
  key1 => [
    'int'
  ],
  key2 => [
    'int'
  ],
  key3 => [
    'int'
  ]
];
$result = $vc->validate($data, $rule);
ok($result->is_valid('key1'));
ok($result->is_valid('key2'));
ok(!$result->is_valid('key3'));

# less_than decimal
$data = {key1 => '+0.9'};
$rule = [
  key1 => [
    {less_than => '10.1'}
  ]
];
$result = $vc->validate($data, $rule);

# uint unicode
$data = {key1 => 0, key2 => 9, key3 => '２'};
$rule = [
  key1 => [
    'uint'
  ],
  key2 => [
    'uint'
  ],
  key3 => [
    'uint'
  ]
];
$result = $vc->validate($data, $rule);
ok($result->is_valid('key1'));
ok($result->is_valid('key2'));
ok(!$result->is_valid('key3'));

# space unicode
$data = {key1 => ' ', key2 => '　'};
$rule = [
  key1 => [
    'space'
  ],
  key2 => [
    'space'
  ],
];
$result = $vc->validate($data, $rule);
ok($result->is_valid('key1'));
ok(!$result->is_valid('key2'));

# not_space unicode
$data = {key1 => ' ', key2 => '　'};
$rule = [
  key1 => [
    'not_space'
  ],
  key2 => [
    'not_space'
  ],
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1'));
ok($result->is_valid('key2'));

# not_space unicode
$data = {key1 => '　', key2 => '　', key3 => '　', key4 => '　'};
$rule = [
  key1 => [
    'trim'
  ],
  key2 => [
    'trim_lead'
  ],
  key3 => [
    'trim_collapse'
  ],
  key4 => [
    'trim_trail'
  ]
];
$result = $vc->validate($data, $rule);
is($result->data->{key1}, '　');
is($result->data->{key2}, '　');
is($result->data->{key3}, '　');
is($result->data->{key4}, '　');

# lenght {min => ..., max => ...}
$data = {
  key1_1 => 'a',
  key1_2 => 'aa',
  key1_3 => 'aaa',
  key1_4 => 'aaaa',
  key1_5 => 'aaaaa',
  key2_1 => 'a',
  key2_2 => 'aa',
  key2_3 => 'aaa',
  key3_1 => 'aaa',
  key3_2 => 'aaaa',
  key3_3 => 'aaaaa'
};
$rule = [
  key1_1 => [
    {'length' => {min => 2, max => 4}}
  ],
  key1_2 => [
    {'length' => {min => 2, max => 4}}
  ],
  key1_3 => [
    {'length' => {min => 2, max => 4}}
  ],
  key1_4 => [
    {'length' => {min => 2, max => 4}}
  ],
  key1_5 => [
    {'length' => {min => 2, max => 4}}
  ],
  key2_1 => [
    {'length' => {min => 2}}
  ],
  key2_2 => [
    {'length' => {min => 2}}
  ],
  key2_3 => [
    {'length' => {min => 2}}
  ],
  key3_1 => [
    {'length' => {max => 4}}
  ],
  key3_2 => [
    {'length' => {max => 4}}
  ],
  key3_3 => [
    {'length' => {max => 4}}
  ],
];
$result = $vc->validate($data, $rule);
ok(!$result->is_valid('key1_1'));
ok($result->is_valid('key1_2'));
ok($result->is_valid('key1_3'));
ok($result->is_valid('key1_4'));
ok(!$result->is_valid('key1_5'));
ok(!$result->is_valid('key2_1'));
ok($result->is_valid('key2_2'));
ok($result->is_valid('key2_3'));
ok($result->is_valid('key3_1'));
ok($result->is_valid('key3_2'));
ok(!$result->is_valid('key3_3'));

# trim_uni
{
  my $data = {
    int_param => '　　123　　',
    collapse  => "　　\n a \r\n b\nc  \t　　",
    left      => '　　abc　　',
    right     => '　　def　　'
  };

  my $validation_rule = [
    int_param => [
      ['trim_uni']
    ],
    collapse  => [
      ['trim_uni_collapse']
    ],
    left      => [
      ['trim_uni_lead']
    ],
    right     => [
      ['trim_uni_trail']
    ]
  ];

  my $result_data= Validator::Custom->new->validate($data,$validation_rule)->data;

  is_deeply(
    $result_data, 
    { int_param => '123', left => "abc　　", right => '　　def', collapse => "a b c"},
    'trim check'
  );
}

{
  # Rule object
  my $vc = Validator::Custom->new;
  my $rule = [
    k1 => [
      ['int' => 'a']
    ],
    k2 => 'int'
  ];
  my $vresult = eval { $vc->validate({}, $rule) };
  my $rule_obj = $vc->rule_obj;
  
  is($rule_obj->rule->[0]{key}, 'k1');
  is($rule_obj->rule->[0]{constraints}[0]{original_constraint}, 'int');
  is($rule_obj->rule->[0]{constraints}[0]{message}, 'a');
  is($rule_obj->rule->[1]{constraints}{ERROR}{value}, 'int');
  like($rule_obj->rule->[1]{constraints}{ERROR}{message}, qr/Constraints must be array reference/);
}

# Custom error message
{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(
    c1 => sub {
      my $value = shift;
      
      if ($value eq 'a') {
        return 1;
      }
      else {
        return {result => 0, message => 'error1'};
      }
    },
    c2 => sub {
      my $value = shift;
      
      if ($value eq 'a') {
        return {result => 1};
      }
      else {
        return {message => 'error2'};
      }
    }
  );
  my $rule = [
    k1 => [
      'c1'
    ],
    k2 => [
      '@c2'
    ]
  ];
  my $vresult = $vc->validate({k1 => 'a', k2 => 'a'}, $rule);
  ok($vresult->is_ok);
  $vresult = $vc->validate({k1 => 'b', k2 => 'b'}, $rule);
  ok(!$vresult->is_ok);
  is_deeply($vresult->messages, ['error1', 'error2']);
}

# Filter hash representation
{
  my $vc = Validator::Custom->new;
  $vc->register_constraint(
    c1 => sub {
      my $value = shift;
      
      return {result => 1, output => $value * 2};
    }
  );
  my $rule = [
    k1 => [
      'c1'
    ],
    k2 => [
      '@c1'
    ]
  ];
  my $vresult = $vc->validate({k1 => 1, k2 => [2, 3]}, $rule);
  ok($vresult->is_ok);
  is($vresult->data->{k1}, 2);
  is_deeply($vresult->data->{k2}, [4, 6]);
}

# Pass rule object to validate method
{
  my $vc = Validator::Custom->new;
  my $rule = [
    k1 => [
      'not_blank'
    ],
    k2 => [
      'not_blank'
    ]
  ];
  my $rule_obj = $vc->create_rule;
  $rule_obj->parse($rule);
  
  my $vresult = $vc->validate({k1 => 'a', k2 => ''}, $rule_obj);
  ok($vresult->is_valid('k1'));
  ok(!$vresult->is_valid('k2'));
}

# Use constraints function from $_
{
  my $vc = Validator::Custom->new;
  my $rule = [
    k1 => [
      sub { $_->blank(@_) || $_->regex($_[0], qr/[0-9]+/) }
    ],
    k2 => [
      sub { $_->blank(@_) || $_->regex($_[0], qr/[0-9]+/) }
    ],
    k3 => [
      sub { $_->blank(@_) || $_->regex($_[0], qr/[0-9]+/) }
    ],
  ];
  
  my $vresult = $vc->validate({k1 => '', k2 => '123', k3 => 'abc'}, $rule);
  ok($vresult->is_valid('k1'));
  ok($vresult->is_valid('k2'));
  ok(!$vresult->is_valid('k3'));
}

# new rule syntax
{
  my $vc = Validator::Custom->new;

  # new rule syntax - basic
  {
    my $rule = $vc->create_rule;
    $rule->require('k1')->check(
      'not_blank'
    );
    $rule->require('k2')->check(
      'not_blank'
    );
    $rule->require('k3')->check(
      ['not_blank' => 'k3 is empty']
    );
    $rule->optional('k4')->check(
      'not_blank'
    )->default(5);
    my $vresult = $vc->validate({k1 => 'aaa', k2 => '', k3 => '', k4 => ''}, $rule);
    ok($vresult->is_valid('k1'));
    is($vresult->data->{k1}, 'aaa');
    ok(!$vresult->is_valid('k2'));
    ok(!$vresult->is_valid('k3'));
    is($vresult->messages_to_hash->{k3}, 'k3 is empty');
    is($vresult->data->{k4}, 5);
  }
  
  # new rule syntax - message option
  {
    my $rule = $vc->create_rule;
    $rule->require('k1')->check(
      'not_blank'
    )->message('k1 is invalid');

    my $vresult = $vc->validate({k1 => ''}, $rule);
    ok(!$vresult->is_valid('k1'));
    is($vresult->message('k1'), 'k1 is invalid');
  }
  
  # new rule syntax - copy option
  {
    my $rule = $vc->create_rule;
    $rule->require('k1')->check(
      'not_blank'
    )->copy(0);

    my $vresult = $vc->validate({k1 => 'aaa'}, $rule);
    ok($vresult->is_valid('k1'));
    ok(!defined $vresult->data->{'k1'});
  }
}

# string constraint
{
  my $vc = Validator::Custom->new;

  {
    my $data = {
      k1 => '',
      k2 => 'abc',
      k3 => 3.1,
      k4 => undef,
      k5 => []
    };
    my $rule = $vc->create_rule;
    $rule->require('k1')->check('string');
    $rule->require('k2')->check('string');
    $rule->require('k3')->check('string');
    $rule->require('k4')->check('string');
    $rule->require('k5')->check('string');
    
    my $vresult = $vc->validate($data, $rule);
    ok($vresult->is_valid('k1'));
    ok($vresult->is_valid('k2'));
    ok($vresult->is_valid('k3'));
    ok(!$vresult->is_valid('k4'));
    ok(!$vresult->is_valid('k5'));
  }
}

# call multiple check
{
  my $vc = Validator::Custom->new;
  
  {
    my $rule = $vc->create_rule;
    $rule->require('k1')
      ->check(['string' => 'k1_string_error'])
      ->check(['not_blank' => 'k1_not_blank_error'])
      ->check([{'length' => {max => 3}} => 'k1_length_error']);
;
    $rule->require('k2')
      ->check(['int' => 'k2_int_error'])
      ->check([{'greater_than' => 3} => 'k2_greater_than_error']);
    
    my $vresult = $vc->validate({k1 => 'aaaa', k2 => 2}, $rule);
    ok(!$vresult->is_valid('k1'));
    ok(!$vresult->is_valid('k2'));
    my $messages_h = $vresult->messages_to_hash;
    is($messages_h->{k1}, 'k1_length_error');
    is($messages_h->{k2}, 'k2_greater_than_error');
  }
}

# No constraint
{
  my $vc = Validator::Custom->new;
  
  # No constraint - valid
  {
    my $rule = $vc->create_rule;
    my $data = {k1 => 1, k2 => undef};
    $rule->require('k1');
    $rule->require('k2');
    my $vresult = $vc->validate($data, $rule);
    ok($vresult->is_ok);
  }
  
  # No constraint - invalid
  {
    my $rule = $vc->create_rule;
    my $data = {k1 => 1};
    $rule->require('k1');
    $rule->require('k2');
    my $vresult = $vc->validate($data, $rule);
    ok(!$vresult->is_ok);
  }
}

# call message by each constraint
{
  my $vc = Validator::Custom->new;
  
  # No constraint - valid
  {
    my $rule = $vc->create_rule;
    $rule->require('k1')
      ->check('not_blank')->message('k1_not_blank_error')
      ->check('int')->message('k1_int_error');
    $rule->require('k2')
      ->check('int')->message('k2_int_error');
    my $vresult1 = $vc->validate({k1 => '', k2 => 4}, $rule);
    is_deeply(
      $vresult1->messages_to_hash,
      {k1 => 'k1_not_blank_error'}
    );
    my $vresult2 = $vc->validate({k1 => 'aaa', k2 => 'aaa'}, $rule);
    is_deeply(
      $vresult2->messages_to_hash,
      {
        k1 => 'k1_int_error',
        k2 => 'k2_int_error'
      }
    );
  }
}

# message fallback
{
  my $vc = Validator::Custom->new;
  
  # No constraint - valid
  {
    my $rule = $vc->create_rule;
    $rule->require('k1')
      ->check('not_blank')
      ->check('int')->message('k1_int_not_blank_error');
    my $vresult1 = $vc->validate({k1 => ''}, $rule);
    is_deeply(
      $vresult1->messages_to_hash,
      {k1 => 'k1_int_not_blank_error'}
    );
    my $vresult2 = $vc->validate({k1 => 'aaa'}, $rule);
    is_deeply(
      $vresult2->messages_to_hash,
      {k1 => 'k1_int_not_blank_error'}
    );
  }
}


