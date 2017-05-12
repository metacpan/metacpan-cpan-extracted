use strict;
use lib 't', 'inc';
use Test::More tests => 4;
use onlyTest;
use File::Spec;
no warnings 'once';

my $versionlib = File::Spec->rel2abs(File::Spec->catdir(qw(t alternate)));

version_install('_Boom-0.77', versionlib => $versionlib, version => '0.11');
ok(-f File::Spec->catfile(qw(t alternate 0.11 _Boom.pm)));

eval qq{use only {versionlib => '$versionlib'}, _Boom => '0.11'};
is($@, '');
is($_Boom::VERSION, '0.77');
is($_Boom::boom, 'Bada-Boom');
