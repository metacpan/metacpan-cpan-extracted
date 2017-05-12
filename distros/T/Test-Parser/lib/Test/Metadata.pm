=head1 NAME

Test::Metadata - Class for capturing build and test log data and 
generating an XML Metadata file about it.

=head1 SYNOPSIS

 use Test::Metadata;
 use Test::Parser::KernelBuild;
 use Test::Parser::MyTest;

 my $build_results = new Test::Parser::KernelBuild;
 $build_results->parse("kernel_build.log");

 my $test_results  = new Test::Parser::MyTest;
 $test_results->parse("my_test.log");

 my $metadata = new Test::Metadata;
 $metadata->add_build($build_results);
 $metadata->add_test($test_results);

 print $metadata->to_xml();

=head1 DESCRIPTION

This module provides an interface for creating metadata summaries of 
software build and test results.  It is designed to work in conjunction
with Test::Parser subclasses, to allow you to gather and report on a set
of tests run atop a given set of built software.

Essentially, you use Test::Parser to parse all your build and test files,
and then add each of them to a Test::Metadata object.  You can then 
generate an XML file for the combined results, suitable for use with
other tools.

The XML format used is the 'Test Result Publication Interface' (TRPI)
XML schema, developed by SpikeSource.  See
http://www.spikesource.com/testresults/index.jsp?show=trpi-schema

=head1 FUNCTIONS

=cut

package Test::Metadata;

use strict;
use warnings;
use Test::Parser;
use XML::Twig;

use fields qw(
             id
             suite_type
             total_executed
             total_passed
             total_failed
             total_skipped
             builds
             results
             properties
             _RETAINED_XML
             );

use vars qw( %FIELDS $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Metadata object.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    $self->{properties} = {
        description => "",
        summary => "Test results",
        license => "GPL",
        product => "",
        version => "",
        url => "",
        root => "",
        coverage_percent => "",
        coverage_report_path => "",
        };
    $self->{builds} = [];
    $self->{results} = [];

    $self->{total_executed} = 0;
    $self->{total_passed}   = 0;
    $self->{total_failed}   = 0;
    $self->{total_skipped}  = 0;

    return $self;
}

=head3 add_build($build)

Takes a Test::Parser object and extracts information about it and builds an
internal build metadata representation.

=cut
sub add_build {
    my $self = shift;
    my $build = shift or return undef;

    my $build_metadata = {
        'name'           => $build->name(),
        'path'           => $build->path(),
        'build_status'   => $build->errors()==0? 'pass' : 'fail',
    };

    push @{$self->{builds}}, $build_metadata;
}

sub add_test {
    my $self = shift;
    my $test = shift or return undef;

    # TODO:  Need a better way to specify the expected values
    # TODO:  Need a way to specify reports
    my $test_metadata = {
        'name'              => $test->name(),
        'path'              => $test->path(),
        'suite_type'        => $test->type(),
        'num_executed'      => $test->num_executed(),
        'num_passed'        => $test->num_passed(),
        'num_failed'        => $test->num_failed(),
        'num_skipped'       => $test->num_skipped(),

        'expect_executed'   => $test->num_executed(),
        'expect_passed'     => $test->num_executed(),
        'expect_failed'     => 0,
        'expect_skipped'    => 0,

        'report_name'       => "",
        'report_path'       => "",        
    };

    push @{$self->{results}}, $test_metadata;
}


sub total_executed {
    my $self = shift;
    my $total_executed = 0;

    foreach my $test (@{$self->{results}}) {
        $total_executed += $test->{num_executed};
    }
    return $total_executed;
}
sub total_passed {
    my $self = shift;
    my $total = 0;

    foreach my $test (@{$self->{results}}) {
        $total += $test->{num_passed};
    }
    return $total;
}
sub total_failed {
    my $self = shift;
    my $total = 0;

    foreach my $test (@{$self->{results}}) {
        $total += $test->{num_failed};
    }
    return $total;
}

sub total_skipped {
    my $self = shift;
    my $total = 0;

    foreach my $test (@{$self->{results}}) {
        $total += $test->{num_skipped};
    }
    return $total;
}

sub properties {
    my $self = shift;
    my $properties = shift;

    if ($properties and ref($properties) eq 'HASH') {
        $self->{properties} = $properties;
    }
    return $self->{properties};
}

=head2 substitute_template($template, $data_hashref)

Performs substitutions of values in the form '[%variable%]' with the
corresponding value given by $data_hashref->{variable}.  Any undefined
items are replaced with blank strings.

=cut

sub substitute_template {
    my $self = shift;
    my ($text, $data) = @_;

    foreach my $key (keys %{$data}) {
        my $value = $data->{$key} || '';
        $text =~ s/\[%\s*$key\s*%\]/$value/g;
    }
    $text =~ s/\[%\s*\w+\s*%\]//g;

    return $text;
}

=head2 to_xml()

Returns the parsed test result data in the TRPI XML syntax
(http://www.spikesource.com/testresults/index.jsp?show=trpi-schema).

In the case of an error, undef will be returned.  The error message 
can be retrieved via error().

=cut

sub to_xml {
    my $self = shift;

    my $xml = qq|
<component name="[%product%]" version="[%version%]"
    xmlns="http://www.spikesource.com/xsd/2005/04/TRPI">
    <description>
      [%description%]
    </description>
    <summary>[%summary%]</summary>
    <license>[%license%]</license>
    <vendor>[%vendor%]</vendor>
    <release>[%release%]</release>
    <url>[%url%]</url>
    <root>[%root%]</root>

    <platform>[%platform%]</platform>

|;

    # If build logs available, substitute the build info
    if (defined($self->{builds}) and @{$self->{builds}} > 0) {
        my $build_xml = '';
        my $build_status = 'pass';
        foreach my $build (@{$self->{builds}}) {
            my $text = qq|      <log-file name="[%name%]" path="[%path%]"/>\n|;
        warn "Substituting build info\n";
        $build_xml .= $self->substitute_template($text, $build);
            if ($build_status eq 'pass' && defined $build->{build_status}) {
                $build_status = $build->{build_status};
            }
        }
        if ($build_xml) {
            $xml .= qq|    <build status="$build_status">\n|;
            $xml .= $build_xml;
            $xml .= qq|    </build>\n\n|;
        }
    }

    # Substitute all the results
    foreach my $result (@{$self->{results}}) {
        my $result_xml = qq|
    <test log-filename="[%filename%]" path="[%path%]" suite-type="[%suite_type%]">
        <result executed="[%num_executed%]" passed="[%num_passed%]" failed="[%num_failed%]" skipped="[%num_skipped%]"/>
        <expected-result executed="[%expect_executed%]" passed="[%expect_passed%]" failed="[%expect_failed%]" skipped="[%expect_skipped%]"/>
        <report name="[%report_name%]" path="[%report_path%]"/>
    </test>
    |;
        warn "Substituting a result\n";
        $xml .= $self->substitute_template($result_xml, $result);
    }

    $xml .= qq|
    <coverage-report percentage="[%coverage_percent%]" path="[%coverage_report_path%]"/>

</component>
|;

    warn "Substituting properties...\n";
    return $self->substitute_template($xml, $self->{properties});
}

=head2 parse($file) 

Parses the given xml (TRPI) file or url and loads the data into the
current object.

=cut
sub parse {
    my $self = shift;
    my $file = shift;

    # TODO:  Parse XML
    my $twig = XML::Twig->new( map_xmlns => {
        'http://www.spikesource.com/xsd/2005/04/TRPI' => 'trpi'
        },
                               pretty_print => 'indented',
                               comments     => 'keep',
                               pi           => 'keep',
                               keep_original_prefix => 1
                               );
    if ($file =~ m/n.*\n/ || (ref $file eq 'IO::Handle')) {
        eval { $twig->parse($file); };
        if ($@) {
            $self->{_errormsg} = "XML::Twig died; this may mean invalid XML:  $@\n";
            return undef;
        }
    } elsif ($file =~ /^http/ or $file =~ /^ftp/) {
        eval { $twig->parseurl($file); };
        if ($@) {
            $self->{_errormsg} = "XML::Twig died; this may mean invalid XML:  $@\n";
            return undef;
        }
    } elsif (! -e $file) {
        $self->{_errormsg} = "No such file '$file'\n";
        return undef;
    } else {
        eval { $twig->parsefile($file); };
        if ($@) {
            $self->{_errormsg} = "XML::Twig died; this may mean invalid XML:  $@\n";
            return undef;
        }
    }

    if (not ref $twig) {
        $self->{_errormsg} = "XML::Twig did not return a valid XML object";
        return undef;
    }

    # TODO:  Load data into structure
    my $component = $twig->root()->first_descendant('component');
    if (not ref $component) {
        $self->{_errormsg} = "No 'component' element found in document";
        return undef;
    }

    $self->{id} = '';
    $self->{suite_type} = '';
    $self->{total_executed} = '';
    $self->{total_passed} = '';
    $self->{total_failed} = '';
    $self->{builds} = ();
    $self->{results} = ();
    $self->{properties} = {};

    # TODO:  Extract items from the XML

    return 1;
}

=head2 id()

Returns the id of the parsed test.

=head2 total_executed

Returns the total number of executed test cases

=head2 total_passed

Returns the total number of passed test cases

=head2 total_failed

Returns the total number of failed test cases

=head2 total_skipped

Returns the total number of test cases that were not run

=head1 PREREQUISITES

None

=head1 AUTHOR

Bryce Harrington <bryce@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2005 Bryce Harrington.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<XML::Twig>

=cut


1;
