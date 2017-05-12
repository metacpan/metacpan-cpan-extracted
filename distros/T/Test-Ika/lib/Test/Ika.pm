package Test::Ika;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.08';

use Module::Load;
use Test::Name::FromLine;

use Test::Ika::ExampleGroup;
use Test::Ika::Example;

use parent qw/Exporter/;

our @EXPORT = (qw(
    describe context it
    xdescribe xcontext xit
    when
    before_suite after_suite
    before_all after_all before_each after_each
    runtests
));


our $FINISHED;
our $ROOT = our $CURRENT = Test::Ika::ExampleGroup->new(name => 'root', root => 1);

our $REPORTER;
{
    my $module = $ENV{TEST_MAX_REPORTER};
    unless ($module) {
        $module = $ENV{HARNESS_ACTIVE} || $^O eq 'MSWin32' ? 'TAP' : 'Spec';
    }
    __PACKAGE__->set_reporter($module);
}

sub reporter { $REPORTER }

sub build_reporter_option {
    my $class = shift;
    return +{
        color => ! $ENV{TEST_IKA_NOCOLOR},
    };
}

sub set_reporter {
    my ($class, $module) = @_;
    $REPORTER = $class->load_reporter($module);
}

sub load_reporter {
    my ($class, $module) = @_;
    $module = ($module =~ s/^\+// ? $module : "Test::Ika::Reporter::$module");
    Module::Load::load($module);

    return $module->new(__PACKAGE__->build_reporter_option);
}

sub describe {
    my $code = ref $_[-1] eq 'CODE' ? pop : sub {};
    my ($name, $cond) = @_;

    my $current = $CURRENT;
    my $context = Test::Ika::ExampleGroup->new(
        name   => $name,
        parent => $current,
        cond   => $cond,
    );
    {
        local $CURRENT = $context;
        $code->();
    }
    $current->add_example_group($context);
}
*context = *describe;

sub when (&) {
    return $_[0];
}

sub it {
    my $code = ref $_[-1] eq 'CODE' ? pop : undef;
    my ($name, $cond) = @_;
    my $it = Test::Ika::Example->new(name => $name, code => $code, cond => $cond);
    $CURRENT->add_example($it);
}

sub xit {
    my $code = ref $_[-1] eq 'CODE' ? pop : undef;
    my ($name, $cond) = @_;
    my $it = Test::Ika::Example->new(name => $name, code => $code, cond => $cond, skip => 1);
    $CURRENT->add_example($it);
}

sub xdescribe {
    my $caller = caller(0);

    no strict 'refs';
    no warnings 'redefine';

    local *{"${caller}::it"} = \&xit;

    my $noop = sub {};
    local *{"${caller}::before_all"}  = $noop;
    local *{"${caller}::after_all"}   = $noop;
    local *{"${caller}::before_each"} = $noop;
    local *{"${caller}::after_each"}  = $noop;

    describe(@_);
}
*xcontext = \&xdescribe;

sub before_suite(&) {
    my $code = shift;
    $ROOT->add_trigger(before_all => $code);
}

sub after_suite(&) {
    my $code = shift;
    $ROOT->add_trigger(after_all => $code);
}

sub before_all(&) {
    my $code = shift;
    $CURRENT->add_trigger(before_all => $code);
}

sub after_all(&) {
    my $code = shift;
    $CURRENT->add_trigger(after_all => $code);
}

sub before_each(&) {
    my $code = shift;
    $CURRENT->add_trigger(before_each => $code);
}

sub after_each(&) {
    my $code = shift;
    $CURRENT->add_trigger(after_each => $code);
}

sub runtests {
    $ROOT->run();

    $FINISHED++;
    $REPORTER->finalize();
}

END {
    unless ($FINISHED) {
        runtests();
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Test::Ika - Yet another BDD testing library(Development Release)

=head1 SYNOPSIS

    use Test::Ika;

    describe 'MessageFilter' => sub {
        my $filter;

        before_each {
            $filter = MessageFilter->new();
        };

        it 'should detect message with profanity word' => sub {
            ok $filter->detect('foo');
        };

        it 'should not detect message without profanity word' => sub {
            ok ! $filter->detect('bar');
        };
    };

    runtests;

=head1 DESCRIPTION

Test::Ika is yet another BDD framework for Perl5.

This module provides pretty output for testing.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 FAQ

=over 4

=item Ika?

This module is dedicated to ikasam_a, a famous Japanese testing engineer.

=item Why another one?

This module focused to pretty output. Another modules doesn't provide this feature.

=item Where is 'should'?

I think the keyword 'should' is not a core feature of BDD.

=back

=head1 Reporters

Test::Ika provides some reporters.

=over 4

=item The spec mode(default)

=begin html

<div><img src="https://raw.github.com/tokuhirom/Test-Ika/master/img/spec.png"></div>

<div><img src="https://raw.github.com/tokuhirom/Test-Ika/master/img/spec2.png"></div>

=end html

=item TAP output(it's enabled under $ENV{HARNESS_ACTIVE} is true)

=begin html

<img src="https://raw.github.com/tokuhirom/Test-Ika/master/img/tap.png">

=end html

=back

=head1 FUNCTIONS

=over 4

=item C<< describe($name, $code) >>

Create new L<Test::Ika::ExampleGroup>.

=item context

It's alias of 'describe' function.

=item C<< it($name, \&code) >>

Create new L<Test::Ika::Example>.

=item C<< it($name, $cond, \&code) >>

Create new conditional L<Test::Ika::Example>.

C<$cond> is usually a sub-routine reference.
You can set it with "when" statement.

  # run this example, if C<$ENV{TEST_MESSAGE}> returns true

  my $cond = sub { $ENV{TEST_MESSAGE} };

  it 'should detect message', $cond => sub {
      my $filter = MessageFilter->new('foo');
      ok $filter->detect('hello foo');
  };

=item C<< when(\&code) >>

Specify conditional sub-routine.

You can write conditional example as shown below:

  it 'should detect message', when { $ENV{TEST_MESSAGE} } => sub {
      my $filter = MessageFilter->new('foo');
      ok $filter->detect('hello foo');
  };

=item C<< xit($name, \&code) >>

=item C<< xit($name, $cond, \&code) >>

Create new L<Test::Ika::Example> which marked "disabled".

=item C<< before_suite(\&code) >>

Register hook for before running suite.

=item C<< before_all(\&code) >>

Register hook for before running example group.

=item C<< before_each(\&code) >>

Register hook for before running each examples.

This block can receive example and example group.

  before_each {
      my ($example, $group) = @_;
      # ...
  };

=item C<< after_suite(\&code) >>

Register hook for after running suite.

=item C<< after_all(\&code) >>

Register hook for after running example group.

=item C<< after_each(\&code) >>

Register hook for after running each examples.

This block can receive example and example group.

  after_each {
      my ($example, $group) = @_;
      # ...
  };

=item C<< runtests() >>

Do run test cases immediately.

Normally, you don't call this method expressly. Test::Ika runs test cases on END { } phase.

=back

=head1 CLASS METHODS

=over 4

=item C<< Test::Ika->reporter() >>

Get a reporter instance.

=item C<< Test::Ika->set_reporter($module) >>

Load a reporter class.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Test::Spec>

L<Test::Behavior::Spec>

L<Test::More::Behaviours>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
