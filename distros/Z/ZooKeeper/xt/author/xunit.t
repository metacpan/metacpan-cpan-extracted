BEGIN { $ENV{PERL_ANYEVENT_MODEL} = 'Perl' }
use FindBin qw($Bin);
use lib "$Bin/../../t/lib";
use Test::Class::Moose::Load "$Bin/lib";
use Test::Class::Moose::Runner;
Test::Class::Moose::Runner->new(test_classes => \@ARGV)->runtests;
