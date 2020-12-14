use 5.010001;
use Test2::V0;
use Test2::Tools::Spec;

use Types::TypedCodeRef -types;
use Types::Standard qw( Int );

describe 'Coerce with typed code ref' => sub {
  
  it 'Has type parameters' => sub {

    my $adder_type = TypedCodeRef[ [Int, Int] => Int ];
    
    my $check_int_type = object {
      prop blessed => 'Type::Tiny';
      call name => 'Int';
    };
    
    is $adder_type->coerce(sub { $_[0] + $_[1] }), object {
      prop blessed => 'Sub::WrapInType';
      call params => array {
        item $check_int_type;
        item $check_int_type;
        end();
      };
      call returns => $check_int_type;
    };

  };

  it 'No type parameters' => sub {
    my $notype_code = TypedCodeRef;
    ok dies { $notype_code->coerce(sub {}) }, qr/^No coercion for this type constraint/;
  };

  it 'Empty type parameters' => sub {
    my $notype_code = TypedCodeRef[];
    ok dies { $notype_code->coerce(sub {}) }, qr/^No coercion for this type constraint/;
  };

};


done_testing;
