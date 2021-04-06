use 5.010001;
use Test2::V0;
use Test2::Tools::Spec;
use Types::Standard qw( Int );
use Types::TypedCodeRef::Factory;

describe 'Use default name generator' => sub {

  my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => []);

  describe 'Sequenced parameters' => sub {

    it 'One parameter' => sub {
      is(
        $factory->name_generator->($factory->name, Int ,=> Int),
        $factory->name . '[ Int => Int ]'
      );
    };

    it 'Multiple parameters' => sub {
      is(
        $factory->name_generator->($factory->name, [Int, Int, Int] => Int),
        $factory->name . '[ [Int, Int, Int] => Int ]'
      );
    };

  };

  describe 'Named parameters' => sub {
    
    it 'One parameter' => sub {
      is(
        $factory->name_generator->($factory->name, +{ a => Int } => Int),
        $factory->name . '[ { a => Int } => Int ]'
      );
    };
    
    it 'Multiple parameters' => sub {
      is(
        $factory->name_generator->($factory->name, +{ b => Int, a => Int, c => Int } => Int),
        $factory->name . '[ { a => Int, b => Int, c => Int } => Int ]'
      );
    };

  };

  describe 'Multiple return values' => sub {

    it 'Multiple return values' => sub {
      is(
        $factory->name_generator->($factory->name, [Int] => [Int, Int]),
        $factory->name . '[ [Int] => [Int, Int] ]'
      );
    };

  };

  describe 'Use instance of Sub::Meta directly' => sub {

    it q{Name generator returns instance's display} => sub {
      my $meta = Sub::Meta->new(
        args => [Int, Int],
        returns => Int,
      );
      is $factory->name_generator->($factory->name, $meta), $factory->name . "[Sub::Meta=sub(Int, Int) => Int]";
    };
  };

  describe 'Empty parameters' => sub {
    
    it q{Empty parameters} => sub {
      is(
        $factory->name_generator->($factory->name),
        $factory->name . '[]'
      );
    };

  };
  
};

done_testing;
