use Test2::V0;
use Test2::Require::Module 'Valiant', '0.002004';
use Test2::Require::Module 'Type::Tiny', '2.000000';

package Local::Person {
    use Moo;
    use Valiant::Validations;
    use Valiant::Filters;

    has name => (is=>'ro');

    validates name => (
      length => {
        maximum => 10,
        minimum => 3,
      }
    )
}

use Types::Standard qw(InstanceOf);

subtest 'Test `kura` with Valiant' => sub {
    use kura ValidLocalPerson => InstanceOf['Local::Person'] & sub { $_->valid };

    isa_ok ValidLocalPerson, 'Type::Tiny';

    my $person1 = Local::Person->new(name=>'foo');
    my $person2 = Local::Person->new(name=>'too long naaaaaaame');

    ok ValidLocalPerson->check($person1);
    ok !ValidLocalPerson->check($person2);
};

done_testing;
