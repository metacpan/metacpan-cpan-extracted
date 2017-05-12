use Test::More tests => 8;
use Test::Exception;

use VM::JiffyBox; # we have checked this already in 00_load.t

my $module = 'VM::JiffyBox';

my $token = 'MyToken';
my $jiffy = $module->new(token => $token);

can_ok($jiffy, 'create_vm'); 

dies_ok  { $jiffy->create_vm() }                     'die if no args';
dies_ok  { $jiffy->create_vm( name   => 'foo',
                              planid => 'bar',
                            ) }                      'die if no image';
dies_ok  { $jiffy->create_vm( name     => 'foo',
                              backupid => 'bar',
                            ) }                      'die if no planid';
dies_ok  { $jiffy->create_vm( planid       => 'foo',
                              distribution => 'bar',
                            ) }                      'die if no name';
dies_ok  { $jiffy->create_vm( name         => 'foo',
                              planid       => 'bar',
                              backupid     => 'baz',
                              distribution => 'boo',
                            ) }                      'die if 2 images';
lives_ok { $jiffy->create_vm( name     => 'foo',
                              planid   => 'bar',
                              backupid => 'baz',
                            ) }                      'live 1';
lives_ok { $jiffy->create_vm( name         => 'foo',
                              planid       => 'bar',
                              distribution => 'baz',
                            ) }                      'live 2';

