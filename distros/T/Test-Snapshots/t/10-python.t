use strict;
use warnings;

use Test::More;
use Test::Snapshots;

my $python = `python --version 2>&1`;
#diag $python;

if (not defined $python or $python !~ /^Python/) {
	plan skip_all => 'Could not find python on this system';
}

Test::Snapshots::command('python');
Test::Snapshots::set_glob('*.py');
test_all_snapshots('eg/python');

