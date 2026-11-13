use 5.016;
use warnings;

use Test::More;
use Twilio;

# Between releases the newest entry is {{NEXT}}; otherwise it must be this version, dated.
# make dist refuses {{NEXT}} too, through the same script, whose complaint shows above.
system $^X, 'tools/check-changes.pl', '--allow-next', $Twilio::VERSION, 'Changes';
is($?, 0, 'Changes starts with {{NEXT}} or this version and its date');

done_testing;
