use Test::More;

use lib 't/lib';

use Test;
use Okay;

my $test = eval { Test->new(three => 3, four => 1) };

like($@, qr/The required six attribute is not defined in the Test object/);

my $okay = Okay->new(three => 3, six => 'bug exists');

is_deeply($okay->one->{e}, [qw/1 2 3/]);

is_deeply($okay->six, 'bug exists');

is_deeply($okay->testing, 'okay');

done_testing();
