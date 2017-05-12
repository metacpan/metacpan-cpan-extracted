BEGIN { $ENV{PERL_ANYEVENT_MODEL} = 'Perl' }
# only use the Perl AnyEvent implementation
# necessary because AnyEvent::Impl::EV
#  doesn't play well with the test library's timeout function
use Test::Class::Moose::Load 't/lib';
use Test::Class::Moose::Runner;
Test::Class::Moose::Runner->new(test_classes => \@ARGV)->runtests;
