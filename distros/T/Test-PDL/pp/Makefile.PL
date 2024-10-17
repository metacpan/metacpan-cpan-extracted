use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;

my $package = ['helper.pd', 'Helper', 'Test::PDL::Helper', undef, 1];
my %args= (pdlpp_stdargs($package));
undef &MY::postamble; *MY::postamble = sub { pdlpp_postamble($package) };
WriteMakefile(%args);
