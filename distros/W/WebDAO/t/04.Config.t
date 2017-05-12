# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MetaStore.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
use Data::Dumper;

BEGIN {
    use_ok('WebDAO::Config');
}

isa_ok my $conf = ( new WebDAO::Config::('t/data/test1.ini') ),
  'WebDAO::Config';
is_deeply $conf->section1,
  {
    'var3' => [ 't,\'', 'sss' ],
    'var1' => [ '1',    '2' ],
    'var4' => 4,
    'var2' => 'test text'
  },
  'test section1';
is_deeply WebDAO::Config::convert_ini2hash('t/data/test2.ini'),
  {
    'general'  => { 'test' => '1' },
    'section1' => {
        'var1' => [ 'Overwrite value', 'add also' ],
        'var2' => 'defined'
    }
  },
  'test += ?=';
my $processed = WebDAO::Config::process_includes('t/data/test2.ini');
is_deeply WebDAO::Config::convert_ini2hash( \$processed ),
  {
    'general'  => { 'test' => '1' },
    'section1' => {
        'var3' => [ 't,\'',            'sss' ],
        'var1' => [ 'Overwrite value', 'add also' ],
        'var4' => '4',
        'var2' => 'defined'
    }
  },
  'check includes';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

