use Test::More tests => 4;

BEGIN { mkdir 'mylib' }

use scriptname lib => '../mylib';
use lib 'gaga';
BEGIN { ok $INC[1] =~ m:/mylib$:, 'mylib in @INC' }
no scriptname lib => '../mylib';

ok $INC[1] !~ m:/mylib$:, 'mylib not in @INC';
ok scriptname::mybase eq '02.use', 'mybase';
ok $0 =~ /02\.use\.t$/, "\$0 = '$0'";

rmdir 'mylib';

diag "Testing scriptname $scriptname::VERSION";
