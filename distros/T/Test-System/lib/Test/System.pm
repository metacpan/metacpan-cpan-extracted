#
# Test::System
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/07/2009 17:36:17 PST 17:36:17
package Test::System;

=head1 NAME

Test::System - Test suite oriented for testing system administration tasks

=head1 SYNOPSIS

    use Test::System;

    my $suite = Test::System->new(
            format => 'consoletable',
            nodes => 'example.com',
            test_groups => '~/code/my/system/tests.yaml'
            );
    $suite->runtests;

=head1 DESCRIPTION

Loads and runs a set of tests for verifying a system administration task
before a possible incident happens or after a task is executed.

Tests can be run as perl scripts and actually in any format L<TAP::Harness>
supports.

Some examples of how L<Test::System> can help you:

=over 4

=item *

Before a deployment probably you want to make sure your systems and
configuration files are ready to go. Also you probably want to make sure
that if you needed to apply patches to your configuration files, they
really got applied (even in a development server or verify directly on
production servers). So here L<Test::System> can help you verifying this
in the form of a test case. Of course, you write the test case :-)

=item *

What about if you have many servers and although you have nagios to verify
the speed of the CPU sometimes you need to verify it "on-demand" (perhaps when
you get new servers in your datacenter). Here L<Test::System> can help you to
verify that these servers are ready to go before even they get connected to nagios
or your favorite monitoring tool.

=back

One of the things you need to keep in mind is that L<Test::System> is B<NOT> a
monitoring system. It will let you verify things on demand, things that are
repetitive and perhaps you want them to be automated.

=cut
use 5.006;

use Moose; # it turns strict and warnings
use File::Basename qw(dirname);
use YAML::Syck;
use Test::System::Output::Factory;
use TAP::Harness;

our $VERSION = '0.17';

=head1 Attributes

The module offers a list of attributes, some of them are read-only.

=over 6

=item B<test_groups>

YAML filename that has a list of available tests. This is not required but
can be useful if you want to group tests (like I<hardware.yaml>, I<net.yaml>,
etc). Comes also handy when user does not provide a list of tests to execute,
so all the tests listed in this file are executed.

An example of a YAML file:

    ping:
        description: Test the ping and do foo and make bar
        code: test/foo.pl
    cpu:
        description: Test the CPU of nodes
        code: test/cpu.pl

=cut
has 'test_groups' => (
        is => 'rw',
        isa => 'Str',
        trigger => \&_read_test_groups_file
        );

=item B<available_tests>

Is a read only attribute that contains a list of all available tests found in
the YAML file provided by C<test_groups>.

=cut
has 'available_tests' => (
        is => 'ro',
        isa => 'ArrayRef[Str]',
        );

=item B<nodes>

Is an attribute that can be represented as a string (like a hostname) or as a
list (where each item will be a node/hostname). This attribute has write access
and is where the tests are going to be executed to.

Another way of setting this value is when C<runtests()> is called, a test plan
(in the form of a YAML file) can be provided and it can contain the list of
nodes to use.

=cut
has 'nodes' => (
        is => 'rw',
        isa => 'Any',
        trigger => \&_verify_nodes_datatype
        );

=item B<format>

A write access string that has the format of how the tests should be presented,
please refer to the modules available under L<Test::System::Output> or in your
custom factory (C<format_factory_class> attribute) class if this is the case.

=cut
has 'format' => (
        is => 'rw',
        isa => 'Str',
        default => 'console',
        trigger => \&_verify_format
        );

=item B<available_formats>

A list of available formats, read only.

=cut
has 'available_formats' => (
        is => 'ro',
        isa => => 'HashRef',
        default => \&_fill_available_formats_hash
        );

=item B<format_factory_class>

If you want to use your own Factory for creating your output you can set this
to your class name (B<NOT the object>).

Please note that L<Test::System> will continue to use
L<Test::System::Output::Factory>, the reason of this is that any factory
subclasses should add/register their classes via their parent class. So in this
case all your new format classes should be added to L<Test::System::Output::Factory>.
For more information please take a look to L<Class::Factory>.

=cut
has 'format_factory_class' => (
        is => 'rw',
        isa => 'Str',
        trigger => \&_fill_available_formats_hash
        );

=item B<harness>

Is (or will be) the harness instance once C<runtests> is executed.

=cut
has 'harness' => (
        is => 'rw',
        isa => 'TAP::Harness');

=item B<parameters>

An attribute with write access permission. This attribute will transform all
the items of this hash to environment variables.

The use of this attribute is very handy if you want to provide some additional
data for your tests and since the tests are run in separate forks with
L<Test::Harness> then the only possible way to keep them is to make them
available through the environment (C<%ENV> hash).

Please be warned that only scalars are stored in environment variables, those
that are an array will be converted to CSV values while the rest of the data
types will be lost.

In your tests if you want to use any of these parameters they will be available
through the environment variables with a prefix of: C<TEST_SYSTEM_> or you
can use L<Test::System::Helper> to get their values.

=cut
has 'parameters' => (
        is => 'rw',
        isa => 'HashRef[Str]',
        );


=item B<results>

A hash reference that contains the results of the tests. This information is
generated by the L<TAP::Parser::Aggregator>.

=over 4

=item * passed: Total of passed tests

=item * total: Total number of tests (passed or not)

=item * skipped: Total of skipped tests

=item * failed: Total of failed tests.

=back

=cut
has 'results' => (
        is => 'ro',
        isa => 'HashRef[Str]',
        );

=item B<status>

A string (read-only) that contains a word that describes the status of all
the tests. This value is also generated by L<TAP::Parser::Aggregator>.

=cut
has 'status' => (
        is => 'ro',
        isa => 'Str'
        );

=item B<show_warnings>

By default we show warnings of all things that can make your tests to run
in a different way than expected.

=back

=cut
has 'show_warnings' => (
        is => 'rw',
        isa => 'Bool',
        default => 1
        );

=head1 Methods

=head2 B<runtests(@tests,%options)>

It will run the given test cases (C<@tests>). The C<@tests> can be:

=over 4

=item * An array of test files to execute.

=item * Or, a string pointing to a test plan file (YAML).

=back

If no C<@tests> are given but we have a C<test_groups> then B<ALL> the tests
listed inside this file will be executed.

The C<%options> is a hash of options that will be passed to the L<TAP::Harness>
object, some useful parameters are:

=over 4

=item * verbosity

By default we mute everything with C<-9>.

=item * color

If you want the output (in console) to have color

=item * formatter

Although we use L<Test::System::Output::Factory> to offer a set of formatters
you can provide your own formatter object. See C<available_formats>.

=item * jobs

If you have many tests you probably want to increment this value (that defaults
to C<1>) so other tests can be run at the same time.

=back

=cut
sub runtests {
    my ($self, $tests, $options) = @_;
   
    if ($options and ref($options) ne 'HASH') {
        confess "Options should be a hash reference";
    }
    if ($tests and ref($tests) ne 'ARRAY') {
        confess "Tests parameter is not an array (" . ref($tests) . ")";
    }
   
    my @tests_to_run;
    if (!$tests and $self->test_groups) {
        @tests_to_run = keys(%{$self->available_tests});
    } else {
        @tests_to_run = @$tests;
    }

    $self->pretests_verification();
    # No duplicate tests and build the module name
    my (%seen, @test_files);
    foreach my $test (@tests_to_run) {
        my ($code, $description);
        # What if the item is an array? of code, description?
        if (ref($test) eq 'ARRAY') {
            ($code, $description) = (
                    $test->[0],
                    $test->[1]);
        } else {
            ($code, $description) = ($test, $test);
        }
        if (defined $self->available_tests) {
            if (defined $self->available_tests->{$test}) {
                if (defined $self->available_tests->{$test}->{'code'}) {
                    $code = $self->available_tests->{$test}->{'code'};
                }
                if (defined $self->available_tests->{$test}->{'description'}) {
                    $description = $self->available_tests->{$test}->{'description'};
                }
            } else {
                warn "$_ is not listed in the available tests list, forcing it"
                    if $self->show_warnings;
            }
            if (!-f $code) {
                if ($code eq $test) {
                    warn "$code does not exist as a file, skipping"
                        if $self->show_warnings;
                } else {
                    warn "$_ test file ($code) does not exist as a file, skipping"
                        if $self->show_warnings;
                }
                next;
            }
        } else {
            if (!-f $code) {
                warn "$code test does not exist as a file, skipping"
                    if $self->show_warnings;
                next;
            }
        }
        if ($code and $description) {
            push(@test_files, [ $code, $description ]);
        }
    }
    # Why not {format_factory_class}? because the registered types should be in the
    # Test::System::Output::Factory:
    # http://search.cpan.org/~phred/Class-Factory-1.06/lib/Class/Factory.pm#Gotchas
    my $factory_class = 'Test::System::Output::Factory';
    my $formatter_class = "$factory_class"->get_registered_class(
            $self->format
            );
    if (!defined $options->{'formatter_class'} && !defined $options->{'formatter'}) {
        $options->{'formatter_class'} = $formatter_class;
    }
    $options->{'merge'} = 1 unless defined $options->{'merge'};
    my @lib = @INC;
    if (defined $options->{'lib'} && ref($options->{'lib'}) eq 'ARRAY') {
        foreach (@{$options->{'lib'}}) {
            push(@lib, $_);
        }
    }
    $options->{'lib'} = \@lib;
    $self->prepare_environment(@test_files, $options);
    $self->{harness} = TAP::Harness->new($options);
    $self->{harness}->callback('after_runtests' =>
            sub { $self->set_results(shift) });
    $self->{harness}->callback('made_parser' =>
            sub { $self->setup_parser(shift); });
    $self->{harness}->runtests(@test_files);
    $self->clean_environment();
    return 1;
}

=head2 B<run_test_plan($test_plan, %options)>

It loads the given test plan file (should be written in YAML) in order to get
a list of tests to execute. Once it has a list of tests then it calls
C<runtests> with this list and with the C<%options>.

=cut
sub run_test_plan {
    my ($self, $test_plan, $options) = @_;

    if ($options and ref($options) ne 'HASH') {
        die "Options should be a hash reference";
    }

    my @tests_to_run = $self->get_tests_from_test_plan($test_plan);
    return $self->runtests(\@tests_to_run, $options);
}

=head2 B<setup_parser($parser)>

This method should B<never> be called directly since this is triggered by
L<TAP::Harness> when every L<TAP::Parser> object gets created.

This method is useful for setting the callbacks we want the parser to trigger.

C<$parser> should be a L<TAP::Parser> object.

=cut
sub setup_parser {
    my ($self, $parser) = @_;
    # We want to know what happens with every test.
    $parser->callback('ALL' => sub { $self->what_happened($parser, shift) });
}

=head2 B<pretests_verification(@tests, %options)>

Does some verification before the tests are executed. This method gets called
by C<runtests>.

The parameters it accepts are the same parameters passed to C<runtests> with
the main difference the tests are already filtered (eg, if a test plan in
YAML was provided we will use it or we will use all the tests listed inside
the C<test_groups>.

=cut
sub pretests_verification {
    my ($self, $tests, $options) = @_;
}


=head2 B<what_happened($parser, $result_test)>

Similar to I<setup_parser>, this should never be called since it will be
triggered by L<TAP::Parser> after each (sub)tests gets executed.

By default we check the reason of why the test failed so later we provide a
simple hash to parse with all the tests and the reasons of why they failed (if
this could be the case). And because we need to know what L<TAP::Parser>
instance we are processing we need to ask for it as a first parameter.

Parameters:

=over 4

=item * C<$parser> should be a L<TAP::Parser>

=item * C<$result_test> should be a L<TAP::Parser::Result::Test>.

=back

=cut
sub what_happened {
    my ($self, $parser, $result_test) = @_;

    # We are going to do a nasty thing with TAP::Parser, we are going to create
    # a new attribute/item that we can use later to get detailed results in the
    # format we want.
    if (!defined $parser->{'test_system_details'}) {
        $parser->{'test_system_details'} = [];
        $parser->{'test_system_notes'} = [];
    }

    if ($result_test->{'type'} eq 'test') {
        my $description = $result_test->{'description'};
        if (my $directive = $result_test->{'directive'}) {
            $description = $result_test->{'explanation'};
        }
        my %value = map { $_ => $result_test->{$_} } keys(%$result_test);
        $value{'is_ok'} = $result_test->is_ok;
        push(@{$parser->{'test_system_details'}}, \%value);
    } elsif ($result_test->{'type'} eq 'comment') { # for notes()
        push(@{$parser->{'test_system_notes'}}, {
                comment  => $result_test->{'comment'},
                raw      => $result_test->{'raw'},
                });
    }
}

=head2 B<set_results($aggregator)>

This is a callback and is only called/triggered by L<TAP::Harness> when all the
tests are done. It will fill the C<results> attribute with information of
everything.

Refer to the documentation of I<results> for more information.

The paramenter C<$aggregator> is a L<TAP::Parser::Aggregator>.

=cut
sub set_results {
    my ($self, $parser_aggregator) = @_;

    $self->{'status'} = $parser_aggregator->get_status;
    foreach my $key (qw(passed total skipped failed)) {
        $self->{'results'}->{$key} = $parser_aggregator->{$key};
    }

    # So we are done with all the test, now lets parse in detail what happened
    # But in the hash we want to keep we only want to have the test name (if
    # that's the case) or the test file, we don't care about the description.
    my %tests_ids;
    if (defined $self->available_tests) {
        foreach my $test (keys %{$self->available_tests}) {
            if (defined $self->available_tests->{$test}->{'description'}) {
                $tests_ids{$self->available_tests->{$test}->{'description'}} = $test;
            } elsif (defined $self->available_tests->{$test}->{'code'}) {
                $tests_ids{$self->available_tests->{$test}->{'code'}} = $test;
            }
        }
    }

    $self->{'results'}->{'details'} = {};
    $self->{'results'}->{'notes'} = {};
    foreach my $key (keys %{$parser_aggregator->{'parser_for'}}) {
        my $parser = $parser_aggregator->{'parser_for'}->{$key};
        foreach my $want (qw(details notes)) {
            my $parser_info_key = 'test_system_' . $want;
            if (defined $parser->{$parser_info_key}) {
                my $id_to_store = $key;
                if (defined $tests_ids{$id_to_store}) {
                    $id_to_store = $tests_ids{$id_to_store};
                }
                $self->{'results'}->{$want}->{$id_to_store} =
                    $parser->{$parser_info_key};
            }
        }
    }
}

=head2 B<prepare_environment()>

Prepares the environment by settings the needed environment values so they can
be used later by the tests

=cut
sub prepare_environment {
    my ($self) = @_;

    # Nodes are stored under the TEST_SYSTEM_NODES environment key
    if ($self->nodes) {
        $ENV{TEST_SYSTEM_NODES} = $self->nodes;
    }
    if ($self->parameters) {
        if (ref($self->parameters) eq 'HASH') {
            foreach my $k (keys %{$self->parameters}) {
                my $value = $self->parameters->{$k};
                $k = uc $k;
                if (!defined $ENV{'TEST_SYSTEM_' . $k}) {
                    if (ref \$value eq 'SCALAR') {
                        $ENV{'TEST_SYSTEM_' . $k} = $value;
                    } elsif (ref \$value eq 'ARRAY') {
                        $ENV{'TEST_SYSTEM_' . $k} = join(',', $value);
                    }
                }
            }
        }
    }
}

=head2 B<clean_environment()>

Cleans/deletes all the environment variables that match C<TEST_SYSTEM_*>

=cut
sub clean_environment {
    my ($self) = @_;

    my %environment_vars = %ENV;
    foreach my $k (keys %environment_vars) {
        if ($k =~ /^TEST_SYSTEM_/) {
            delete $ENV{$k};
        }
    }
}

=head2 B<get_tests_from_test_plan($yaml_file,
        $do_not_fill_parameters, 
        $do_not_fill_nodes)>

Reads the given tests yaml file (C<$yaml_file>). This YAML file should have at
least a list of tests and optionally can also have parameters the tests
should contain.

Although this method is used mostly internally there's the option to call it
as any other method I<Test::System> offers.

By default it will fill the parameters of your I<Test::System> instance but by
passing C<$do_not_fill_parameters> (second parameter) as true or something
that Perl understands as true then it will skip the part. This should be
presented as a hash in YAML syntax.

The above apply also to C<$do_not_fill_nodes> (third parameter). This should be
presented as an array in YAML syntax.

Once the file is read an array with all the tests will be returned.

All the tests should be contained inside a hash named 'tests'. All the tests
should be represented in the form of a list, each item of the list is the
test you want to execute. At least it should have a 'code' item, this is
the filepath of the test (or the ID from a C<test_groups>). Optionally you
can also provide the description of the test (cause otherwise the filename
will be used and it can make ugly your summary report).

An example of a YAML test plan file can be found inside the C<examples>
directory or:

    tests:
        - 
            code: ping
            description: Checking the ping
        - 
            code: example/tests/cpu.pl
            description: foobar
        -
            code: memory
            description: Ehmm.. my name?
    parameters:
        ping_count: 10
    nodes:
        - pablo.com.mx
        - example.com

=cut
sub get_tests_from_test_plan {
    my ($self, $yaml_file, $do_not_fill_parameters, $do_not_fill_nodes) = @_;

    if (!-f $yaml_file) {
        confess "YAML file ($yaml_file) does not exist";
        return;
    }

    my @tests;
    my $data = LoadFile($yaml_file);
    if (!defined $data->{'tests'}) {
        warn "YAML file ($yaml_file) does not have any tests to execute, skipping"
            if $self->show_warnings;
        return;
    } else {
        foreach my $test (@{$data->{'tests'}}) {
            if (!defined $test->{'code'}) {
                confess "Sorry but you need to provide the 'code' ID or " .
                    "filepath where your test is ($yaml_file)";
            }
            if (defined $test->{'description'}) {
                push(@tests, [
                        $test->{'code'},
                        $test->{'description'}
                        ]);
            } else {
                push(@tests, $test->{'code'});
            }
        }
    }
    if (!$do_not_fill_parameters) {
        if ($data->{'parameters'}) {
            $self->parameters($data->{'parameters'});
        }
    }

    if (!$do_not_fill_nodes) {
        if ($data->{'nodes'}) {
            $self->nodes($data->{'nodes'});
        }
    }
    return @tests;
}

################################# Triggers ##################################
# Trigger for test_dir, when test_dir gets modified we look for all tests
# available in the given directory and so on we populate/fill the tests list
# attribute
sub _read_test_groups_file {
    my ($self, $yaml_file) = @_;
    
    if (!-f $yaml_file) {
        confess "The YAML file ($yaml_file) does not exist"
            if $self->show_warnings;
    }

    $self->{test_groups} = $yaml_file;
    my $testdir = dirname($yaml_file);

    my $tests = LoadFile($yaml_file);
    foreach my $test (keys %$tests) {
        if (defined $tests->{$test}->{'code'}) {
            my $code = $tests->{$test}->{'code'};
            if (!-f $code) {
                $tests->{$test}->{'code'} = $testdir . '/' . $code;
            }
        }
    }
    $self->{'available_tests'} = $tests;
}

# Trigger for nodes, when nodes gets modified we don't really know if its
# a string or a list (and this is because we accept both) so we should make sure
# of what we get and validate it.
sub _verify_nodes_datatype {
    my ($self, $nodes) = @_;

    if (ref $nodes eq 'ARRAY') {
        $self->{'nodes'} = join(',', @$nodes);
    } else {
        $self->{'nodes'} = $nodes;
    }
}

# Trigger for format, when format gets modified we want to make sure the format
# is valid
sub _verify_format {
    my ($self, $format) = @_;

    if (!defined $self->available_formats->{$format}) {
        confess "The format you provided ($format) is not valid";
    }
    $self->{'format'} = $format;
}

# Fills the available_formats hash with the classes registered in the
# factory
sub _fill_available_formats_hash {
    my ($self, $new_factory) = @_;

    if (!$new_factory) {
        $new_factory = 'Test::System::Output::Factory';
    } else {
        $self->{'format_factory_class'} = $new_factory;
    }
    my @registered_types = "Test::System::Output::Factory"->get_registered_types;

    my %hash;
    foreach (@registered_types) {
        $hash{$_} = 1;
    }
    $self->{'available_formats'} = \%hash;
    return \%hash;
}

=head1 SEE ALSO

Take a look to an awesome and pretty similar CPAN module: L<Test::Server>.

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2009 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
