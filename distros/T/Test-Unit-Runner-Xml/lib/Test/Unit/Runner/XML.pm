package Test::Unit::Runner::XML;

use XML::Generator;
use Time::HiRes qw(time);

use strict;
use warnings;
use vars qw($VERSION);
use base qw(Test::Unit::Runner);

# $Id: XML.pm 27 2004-08-24 11:22:24Z andrew $
$VERSION = '0.1';

sub new {
    my ($class, $directory, $generator) = @_;

    unless(defined($generator)) {
        $generator = XML::Generator->new(escape => 'always', pretty => 2);
    }

    return bless({directory => $directory, gen => $generator, 
                  all_tests_passed => 1,
                  last_class => undef}, 
                 $class);
}

sub all_tests_passed {
    my ($self) = @_;

    return $self->{all_tests_passed};
}

sub start {
    my ($self, $suite) = @_;

    my $result = $self->create_test_result();
    $result->add_listener($self);
    my $start_time = time();
    $suite->run($result, $self);
    if(defined($self->{last_class})) {
        $self->_end_class($self->{last_class});
    }
}

sub add_pass {}
    
sub add_failure {
    my ($self, $test, $exception) = @_;

    $self->{failures}++;
    $self->{all_tests_passed} = 0;
    push(@{$self->{test_child_nodes}},
         $self->{gen}->failure({message => $exception->get_message()},
                               $exception->stringify()));
}

sub add_error {
    my ($self, $test, $exception) = @_;

    $self->{errors}++;
    $self->{all_tests_passed} = 0;
    push(@{$self->{test_child_nodes}},
         $self->{gen}->error({message => $exception->get_message()},
                             $exception->stringify()));
}

sub start_test {
    my ($self, $test) = @_;

    if(!defined($self->{last_class}) || ref($test) ne $self->{last_class}) {
        if(defined($self->{last_class})) {
            $self->_end_class($self->{last_class});
        }
        $self->_start_class();
        $self->{last_class} = ref($test);
    }

    $self->{test_start_time} = time();
    $self->{test_child_nodes} = [];
    $self->{tests}++;
}


sub end_test {
    my ($self, $test) = @_;

    my $time = time() - $self->{test_start_time};
    push(@{$self->{child_nodes}},
         $self->{gen}->testcase({name => $test->name(), 
                                 time => sprintf('%.4f', $time)},
                                @{$self->{test_child_nodes}}));
    $self->{time} += $time;
}

sub _start_class {
    my ($self) = @_;

    $self->{tests} = 0;
    $self->{failures} = 0;
    $self->{errors} = 0;
    $self->{time} = 0;
    $self->{child_nodes} = [];
}

sub _end_class {
    my ($self, $class) = @_;

    my $output = IO::File->new(">" . $self->_xml_filename($class));
    unless(defined($output)) {
        die("Can't open " . $self->_xml_filename($class) . ": $!");
    }

    my $time = sprintf('%.4f', $self->{time});
    my $xml = $self->{gen}->testsuite({tests => $self->{tests},
                                       failures => $self->{failures},
                                       errors => $self->{errors},
                                       time => $time,
                                       name => $class},
                                      @{$self->{child_nodes}});
                                      
    $output->print($xml);
    $output->close();
}

sub _xml_filename {
    my ($self, $class) = @_;

    $class =~ s/::/./g;
    return File::Spec->catfile($self->{directory}, "TEST-${class}.xml");
}

1;

__END__


=head1 NAME

Test::Unit::Runner::XML - Generate XML reports from unit test results 

=head1 SYNOPSIS

    use Test::Unit::Runner::XML;

    mkdir("test_reports");
    my $runner = Test::Unit::Runner::XML->new("test-reports");
    $runner->start($test);
    exit(!$runner->all_tests_passed());

=head1 DESCRIPTION

Test::Unit::Runner::XML generates XML reports from unit test results. The
reports are in the same format as those produced by Ant's JUnit task, 
allowing them to be used with Java continuous integration and reporting tools.

=head1 CONSTRUCTOR

    Test::Unit::Runner::XML->new($directory)

Construct a new runner that will write XML reports into $directory

=head1 METHODS 

=head2 start

    $runner->start($test);

Run the L<Test::Unit::Test> $test and generate XML reports from the results.

=head2 all_tests_passed

    exit(!$runner->all_tests_passed());

Return true if all tests executed by $runner since it was constructed passed.

=head1 AUTHOR

Copyright (c) 2004 Andrew Eland, E<lt>andrew@andreweland.orgE<gt>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Test::Unit>

=item *

L<Test::Unit::TestRunner>

=item *

The Ant JUnit task, http://ant.apache.org/

=cut


