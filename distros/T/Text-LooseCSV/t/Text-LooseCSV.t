# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-LooseCSV.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Text::LooseCSV') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $f = new Text::LooseCSV();

$f->input_text('"Debbie Does Dallas",30.00,"VHS","Classic"');

my $rec = $f->next_record();

ok( $rec->[3] eq 'Classic', 'split' );

$f->always_quote(1);
my $line = $f->form_record($rec);

ok( $line eq '"Debbie Does Dallas","30.00","VHS","Classic"', 'join' );

