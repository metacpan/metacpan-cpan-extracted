use strict;
use warnings;
use Test::Weaken;
use Scalar::Util::Instance
  { for => 'Foo', as => 'is_a_Foo' };

# uncomment this to run the ### lines
use Smart::Comments;

my $tw = Test::Weaken::leaks
  ({ constructor => sub {
       return Scalar::Util::Instance->generate_for('Bar');
     },
   });
### $tw

my $coderef = Scalar::Util::Instance->generate_for('Bar');
### $coderef
Scalar::Util::weaken($coderef);
### $coderef

exit 0;
