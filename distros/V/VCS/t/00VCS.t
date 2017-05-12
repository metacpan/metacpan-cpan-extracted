use strict;
use warnings;
use Test::More;
use File::Temp;

use_ok('VCS');

my @s = qw(localhost VCS::Cvs /file/path/ query=1);
is_deeply([ VCS->parse_url("vcs://$s[0]/$s[1]$s[2]?$s[3]") ], \@s, 'parse');

{
  package VCS::Dummy::Dir;
  our @ISA = 'VCS::Dir';
  $INC{'VCS/Dummy/Dir.pm'} = 1;
  sub new { shift->init(@_); }
}
{ package VCS::Dummy; $INC{'VCS/Dummy.pm'} = 1; }
my $h = VCS::Dir->new("vcs://localhost/VCS::Dummy/path/");

ok(scalar(grep { $_ eq 't/00VCS.t' } $h->recursive_read_dir('t')), 'recurse');

done_testing;
