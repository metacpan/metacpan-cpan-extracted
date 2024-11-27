use Test::Most;

{
  package Local::Task;

  use Valiant::Validations;
  use Moo;

  has priority => (is => 'ro');
  has description => (is => 'ro');
  has due_date => (is => 'ro');

  validates priority => (
    presence => 1,
    numericality => { only_integer => 1, between => [0,10] },
  );

  validates description => (
    presence => 1,
    length => [10,60],
  );

  validates due_date => (
    presence => 1,
    date => 'is_future',
  );
}

{
  ok my $task = Local::Task->new(
    priority => '21',
    due_date => '2000-01-01',
    description => 'Bills',
  );

  $task->validate;
  ok my $today = DateTime->now->strftime($Valiant::Validator::Date::_pattern);

  is_deeply +{ $task->errors->to_hash },{
    description => [
      "is too short (minimum is 10 characters)",
    ],
    due_date => [
      "chosen date can't be earlier than $today",
    ],
    priority => [
      "must be less than or equal to 10",
    ],
  }; 
}

{
  ok my $task = Local::Task->new(
    priority => '21',
    due_date => '2000-01-01',
    description => 'Bills',
  );

  {
    $task->validate_only('due_date');
    ok my $today = DateTime->now->strftime($Valiant::Validator::Date::_pattern);
    is_deeply +{ $task->errors->to_hash },{
      due_date => [
        "chosen date can't be earlier than $today",
      ], 
    }; 
  }
  {
    $task->validate_only('description');
    is_deeply +{ $task->errors->to_hash },{
      description => [
        "is too short (minimum is 10 characters)",
     ],
    }; 
  }
  {
    $task->validate_only(['description', 'priority']);
    is_deeply +{ $task->errors->to_hash },{
      description => [
        "is too short (minimum is 10 characters)",
      ],
      priority => [
        "must be less than or equal to 10",
      ],
    }; 
  }
}

done_testing;



