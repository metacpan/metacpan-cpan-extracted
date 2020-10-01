use 5.010001;
use Test2::V0;
use Test2::Tools::Spec;
use Types::Standard qw( Int );
use Sub::WrapInType qw( wrap_sub );
use Sub::Meta;
use Sub::Meta::Param;
use Sub::Meta::Parameters;
use Sub::Meta::Returns;
use Types::TypedCodeRef::Factory;

describe 'Use default constraint generator' => sub {

  describe 'Pass type parameter' => sub {
    
    describe 'Sequenced' => sub {

      it 'Succeed in check typed code reference that has same interface' => sub {
        my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => [
          sub {
            Sub::Meta->new(
              parameters => Sub::Meta::Parameters->new(
                args => [ Sub::Meta::Param->new(Int) ],
              ),
              returns    => Sub::Meta::Returns->new(Int),
            );
          }
        ]);
        my $constraint = $factory->constraint_generator->(Int ,=> Int);

        ok $constraint->(wrap_sub Int ,=> Int, sub { $_[0] ** 2 });
        ok $constraint->(wrap_sub [Int] => Int, sub { $_[0] ** 2 });
      };

      it 'Failed to check typed code reference that has difference interface' => sub {
        my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => [
          sub {
            Sub::Meta->new(
              parameters => Sub::Meta::Parameters->new(
                args => [
                  Sub::Meta::Param->new(Int),
                  Sub::Meta::Param->new(Int),
                ],
              ),
              returns    => Sub::Meta::Returns->new(Int),
            );
          }
        ]);
        my $constraint = $factory->constraint_generator->(Int ,=> Int);

        ok !$constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
      };

      it 'Succeed in check typed code reference that has same interface' => sub {
        my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => [
          sub {
            Sub::Meta->new(
              parameters => Sub::Meta::Parameters->new(
                args => [
                  Sub::Meta::Param->new(Int),
                  Sub::Meta::Param->new(Int),
                ],
              ),
              returns    => Sub::Meta::Returns->new(Int),
            );
          }
        ]);
        my $constraint = $factory->constraint_generator->([ Int, Int ] => Int);

        ok $constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
      };

      it 'Failed to check typed code reference that has difference interface' => sub {
        my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => [
          sub {
            Sub::Meta->new(
              parameters => Sub::Meta::Parameters->new(
                args => [
                  Sub::Meta::Param->new(Int),
                  Sub::Meta::Param->new(Int),
                ],
              ),
              returns    => Sub::Meta::Returns->new(Int),
            );
          }
        ]);
        my $constraint = $factory->constraint_generator->([ Int ] => Int);

        ok !$constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
      };

      it 'Failed to can not found sub-meta' => sub {
        my $factory    = Types::TypedCodeRef::Factory->new(sub_meta_finders => []);
        my $constraint = $factory->constraint_generator->([ Int, Int ] => Int);

        ok !$constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
      };

    };

    describe 'Named' => sub {

      it 'Succeed in check typed code reference that has same interface' => sub {
        my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => [
          sub {
            Sub::Meta->new(
              parameters => Sub::Meta::Parameters->new(
                args => [
                  Sub::Meta::Param->new({
                    name  => 'a',
                    type  => Int,
                    named => 1,
                  }),
                  Sub::Meta::Param->new({
                    name  => 'b',
                    type  => Int,
                    named => 1,
                  }),
                ],
              ),
              returns    => Sub::Meta::Returns->new(Int),
            );
          }
        ]);
        my $constraint = $factory->constraint_generator->(+{ a => Int, b => Int } => Int);

        ok $constraint->(wrap_sub +{ a => Int, b => Int } => Int, sub {});
      };

      it 'Failed to check typed code reference that has difference interface' => sub {
        my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => [
          sub {
            Sub::Meta->new(
              parameters => Sub::Meta::Parameters->new(
                args => [
                  Sub::Meta::Param->new({
                    name  => 'a',
                    type  => Int,
                    named => 1,
                  }),
                  Sub::Meta::Param->new({
                    name  => 'b',
                    type  => Int,
                    named => 1,
                  }),
                ],
              ),
              returns    => Sub::Meta::Returns->new(Int),
            );
          }
        ]);
        my $constraint = $factory->constraint_generator->([ Int, Int ] => Int);

        ok !$constraint->(wrap_sub +{ a => Int, b => Int } => Int, sub {});
      };

      it 'Failed to can not found sub-meta' => sub {
        my $factory    = Types::TypedCodeRef::Factory->new(sub_meta_finders => []);
        my $constraint = $factory->constraint_generator->(+{ a => Int, b => Int } => Int);

        ok !$constraint->(wrap_sub +{ a => Int, b => Int } => Int, sub {});
      };
    };

  };

  describe 'Pass instance of Sub::Meta as type parameter' => sub {

    my $sub_meta = Sub::Meta->new(
      parameters => Sub::Meta::Parameters->new(
        args => [
          Sub::Meta::Param->new(Int),
          Sub::Meta::Param->new(Int),
        ],
      ),
      returns    => Sub::Meta::Returns->new(Int),
    );

    it 'Succeed in check typed code reference that has same interface' => sub {
      my $factory 
        = Types::TypedCodeRef::Factory->new(sub_meta_finders => [ sub { $sub_meta } ]);
      my $constraint = $factory->constraint_generator->($sub_meta);

      ok $constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
    };

    it 'Failed to check typed code reference that has difference interface' => sub {
      my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => [
        sub {
          Sub::Meta->new(
            parameters => Sub::Meta::Parameters->new(args => [ Sub::Meta::Param->new(Int) ]),
            returns    => Sub::Meta::Returns->new(Int),
          );
        }
      ]);
      my $constraint = $factory->constraint_generator->($sub_meta);

      ok !$constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
    };

    it 'Failed to can not found sub-meta' => sub {
      my $factory    = Types::TypedCodeRef::Factory->new(sub_meta_finders => []);
      my $constraint = $factory->constraint_generator->($sub_meta);

      ok !$constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
    };

  };
  
  describe 'No type parameter' => sub {

    it 'Succeed in checking non-typed code reference' => sub {
      my $factory = Types::TypedCodeRef::Factory->new(sub_meta_finders => []);
      my $constraint = $factory->constraint_generator->();

      ok $constraint->(sub {});
    };

    it 'Failed to checking typed code reference' => sub {
      my $sub_meta_finders = [
        sub {
          Sub::Meta->new(
            parameters => Sub::Meta::Parameters->new(
              args => [
                Sub::Meta::Param->new(Int),
                Sub::Meta::Param->new(Int),
              ],
            ),
            returns    => Sub::Meta::Returns->new(Int),
          );
        }
      ];
      my $factory 
        = Types::TypedCodeRef::Factory->new(sub_meta_finders => $sub_meta_finders);
      my $constraint = $factory->constraint_generator->();

      ok !$constraint->(wrap_sub [ Int, Int ] => Int, sub { $_[0] + $_[1] });
    };

  };

  describe 'Pass too many type parameters' => sub {
    
    it 'die' => sub {
      my $factory    = Types::TypedCodeRef::Factory->new(sub_meta_finders => []);
      ok dies { $factory->constraint_generator->([] => Int, Int) };
    };

  };

};

done_testing;
