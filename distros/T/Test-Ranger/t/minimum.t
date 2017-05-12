{
    package Acme::Teddy;
    sub one{ 1 };
}
use strict;
use warnings;

use Acme::Teddy;
use Test::Ranger;

#~ use Devel::Comments;

# Minimum
my $single      = Test::Ranger->new(
    {
        -coderef    => \&Acme::Teddy::one,
    },
    
); ## end new

### $single

$single->test();
$single->done();

__END__
