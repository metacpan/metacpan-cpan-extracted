use strict;
use warnings;
use Test::More;

# Every class module must work when it is the first one loaded. Each case
# runs in a fresh perl so that nothing else is loaded yet.
my @include = map { "-I$_" } grep { !ref } @INC;

my %first_use = (
    'Text::KDL::XS::Parser'   => [ q{Text::KDL::XS::Parser->new("a 1\n")->next_event->{name}}, 'a' ],
    'Text::KDL::XS::Emitter'  => [ q{Text::KDL::XS::Emitter->_emit_tree({ a => 1 })}, "a 1\n" ],
    'Text::KDL::XS::Document' => [ q{Text::KDL::XS::Document->new(nodes => [ Text::KDL::XS::Node->new(name => 'a') ])->nodes->[0]->name}, 'a' ],
    'Text::KDL::XS::Node'     => [ q{Text::KDL::XS::Node->new(name => 'a', props => [ [ k => 1 ] ])->prop('k')}, '1' ],
    'Text::KDL::XS::Value'    => [ q{Text::KDL::XS::Value->new(type => 'number', value => 0.5)->as_string}, '0.5' ],
);

for my $module (sort keys %first_use) {
    my ($expression, $expected) = @{ $first_use{$module} };
    open my $child, '-|', $^X, @include, '-e', "use $module; print $expression"
        or die "cannot run $^X: $!";
    my $output = do { local $/; <$child> };
    close $child;
    is $output, $expected, "$module works when loaded on its own";
}

done_testing;
