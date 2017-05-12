=head1 NAME

Test::Presenter::Query - A submodule for Test::Presenter
    This module provides methods for gathering some standard information that
    is common to a wide set of test results data.  A method is also provided to
    allow for direct querying of the DBXml Perl object.

=head1 SYNOPSIS

    $report->query_header("doc_name");
    $report->query_all("doc_name");


=head1 DESCRIPTION

Test::Presenter::Query is a helper module to give Test::Presenter the
    ability to query DBXml Containers.  This is supported through the
    use of the Test::Presenter::DbXml module.

=head1 FUNCTIONS

=cut
use strict;
use warnings;
use Data::Dumper;
use IO::File;

use Sleepycat::DbXml 'simple';

# FIXME: Some of the methods overlap here... query_header() and query_all()
# are the worst offenders

=head2 query_header()

    Purpose: Populate the 'header' perl object with the necessary information
        from the DBXml Container
    Input: Document to query
    Output: 1

=cut
sub query_header {
    my $self = shift;
    my $doc = shift;

    # These are all 'top-level' elements in the Extended TRPI format
    my @labels = ('description', 'summary', 'license', 'vendor', 'release', 'url', 'platform');
    my @attribs = ('');

    # The prefix determines where the results go in the perl data structure
    my @prefix = ('header');

    $self->_query_spec(\@labels, \@attribs, $doc, \@prefix) or warn("Unable to query header information\n") and return undef;

    return 1;
}


=head2 query_all()

    Purpose: Populate the 'component' perl object with all information
        from the DBXml Container.
    Input: NA
    Output: 1

=cut
sub query_all {
    my $self = shift;
    my $doc = shift;

    my @hash = {};

    # The easy labels to grab... these must always be in the XML file (based on the TRPI Schema)
    my @labels = ('description', 'summary', 'license', 'vendor', 'release', 'url', 'platform', 'kernel', 'component');

    my %resi = ();
    my $val;

    foreach my $key (@labels) {

        my $fq = $self->_create_query("/*/$key/string()", $doc);
        if (defined($fq)) {
            $resi{$key} = $self->_doQuery( $self->{'manager'}, $self->{'container'}, $fq );
        }

        while ( $resi{$key}->next($val) ) {
            $self->{'component'}{'header'}{$key} = $val;
        }

        # Special cases where we can have more than one of each kind of tag (based on the TRPI Schema)
        if ($key eq "build") {
            warn "Entering $key Query" if $self->{_debug}>2;
            $self->_query_build($doc);
        }

        if ($key eq "test") {
            warn "Entering $key Query" if $self->{_debug}>2;
            $self->_query_test($doc);
        }

        if ($key eq "component" ) {
            warn "Entering $key Query" if $self->{_debug}>2;
            $self->_query_component($doc);
        }

        if ($key eq "coverage-report") {
            warn "Entering $key Query" if $self->{_debug}>2;
            $self->_query_coverage_report($doc);
        }

        if ($key eq "code-convention-report") {
            warn "Entering $key Query" if $self->{_debug}>2;
            $self->_query_code_convention_report($doc);
        }
    }

    return 1;
}


# _query_build()
#
# Purpose: A "private" function to parse the "build" tags in the DBXml
#          Document.
# Input: NA
# Output: 1
sub _query_build {
    my $self = shift;
    my $doc = shift;

    my @elements = ('build');
    my @attribs = ('status');
    my @prefix = ('header');

    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn("Unable to query build information\n") and return undef;

    @elements = ('build', 'log-file');
    @attribs = ('name', 'path');
    @prefix = ('header');

    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn("Unable to query build/log-file information\n") and return undef;

    return 1;
}


# _query_component()
#
# Purpose: A "private" function to parse the "component" tags in the DBXml
#          Document.
# Input: NA
# Output: 1
sub _query_component {
    my $self = shift;
    my $doc = shift;
    my $count = 0;
#    $self->{'component'}{'build'} = ();
    # With each "output", we want to query the attributes of that output
    my @elements = ('');
    my @attribs = ('name', 'version');
    my @prefix = ('header');

    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn ("Unable to query component information\n") and return undef;

    return 1;
}


# _query_test()
#
# Purpose: A "private" function to parse the "test" tags in the DBXml
#          Document.
# Input: NA
# Output: 1
sub _query_test {
    my $self = shift;
    my $doc = shift;

    my @elements = ('test');
    my @attribs = ('log-filename', 'path', 'suite-type');
    my @prefix = ('header');

    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn("Unable to query test information\n") and return undef;

    @elements = ('test', 'result');
    @attribs = ('executed', 'passed', 'failed', 'skipped');
    @prefix = ('header');

    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn("Unable to query test/result information\n") and return undef;

    @elements = ('test', 'expected-result');
    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn("Unable to query test/expected-result information\n") and return undef;

    return 1;
}


# _query_coverage_report()
#
# Purpose: A "private" function to parse the "coverage-report" tags in
#          the DBXml Document.
# Input: NA
# Output: 1
sub _query_coverage_report {
    my $self = shift;
    my $doc = shift;

    my @elements = ('coverage-report');
    my @attribs = ('percentage', 'path');
    my @prefix = ('header');

    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn("Unable to query coverage-report information\n") and return undef;

    return 1;
}


# _query_code_convention_report()
#
# Purpose: A "private" function to parse the "code-convention-report"
#          tags in the DBXml Document.
# Input: NA
# Output: 1
sub _query_code_convention_report {
    my $self = shift;
    my $doc = shift;

    my @elements = ('code-convention-report');
    my @attribs = ('path');
    my @prefix = ('header');

    $self->_query_spec(\@elements, \@attribs, $doc, \@prefix) or warn("Unable to query code-convention-report information\n") and return undef;

    return 1;
}


# _query_spec()
#
# Purpose: A "private" function to parse the "code-convention-report"
#          tags in the DBXml Document.
# Input: NA
# Output: 1 or undef on error
sub _query_spec {
    my $self = shift;

    my $elements = shift;
    my $attribs = shift;
    my $doc = shift;
    my $prefix = shift;

    my %query_results = ();

    my $query_string = "/*";

    my $target = $self->{'component'};

    foreach my $pre ( @$prefix ) {
        if (defined $pre) {
            if ( !defined($target->{$pre}) ) {
                $target->{$pre} = {};
            }
            $target = $target->{$pre};
        }
    }

    # We use the @$ because the arrays were passed by reference.
    foreach my $ele ( @$elements ) {
        if ( ! $ele ) {
#            warn("No elements to query in query_spec()\n");
#            return undef;
        }
        else {
            $query_string .= "/" . $ele;
            if ( !defined($target->{$ele}) ) {
                $target->{$ele} = {};
            }
            $target = $target->{$ele}
        }
    }

    foreach my $att ( @$attribs ) {
        my $temp_query_string = $query_string;

        if ( $att ne "" ) {
            $temp_query_string .= "/\@$att";
            if ( !defined($target->{$att}) ) {
                $target->{$att} = {};
            }
        }
        else {
            warn "Empty Attribute\n";
        }

        warn "_query_spec() Query_string: " . $temp_query_string . "\n" if $self->{_debug}>3;

        my $fq = $self->_create_query($temp_query_string, $doc);
        if (defined($fq)) {

            $query_results{$att} = $self->_doQuery( $self->{'manager'}, $self->{'container'}, $fq );

            my $value;
            while ( $query_results{$att}->next($value) ) {
                $value =~ s/{}$att=//g;
                $value =~ s/^\"//g;
                $value =~ s/\"$//g;
                $target->{$att} = $value;
            }
        }

    }

    return 1;
}


# _doQuery()
#
# Purpose: Query the given DBXml container.
# Input: DBXml Manager, DBXml Container, a simple DBXml Query
# Output: DBXml XMLResults object
sub _doQuery($$$)
{
    my $self = shift;

    my $theMgr = shift or warn("_doQuery missing manager\n") and return undef;;
    my $container = shift or warn("_doQuery missing container\n") and return undef;
    my $query = shift or warn("_doQuery missing query\n") and return undef;

    my $results = "";

    eval {
        $results = $theMgr->query($query);

        warn "_doQuery() " . $results->size() . " objects returned for expression '$query'\n" if $self->{_debug}>1;
	};

    if (my $e = catch std::exception) {
        warn "Query $query failed\n";
        warn $e->what() . "\n";
        return undef;
    }
    elsif ($@) {
        warn "Query $query failed\n";
        warn $@;
        return undef;
    }
    return $results;
}

=head2 data_get_id(<column>)

Input:  a column name for a data type.
Returns:  a data point id value

=cut

sub data_get_id {
    my $self = shift;
    my $label = shift;
    my @test_type = ();
    my $xquery = 'collection("' . $self->{'container_name'} . '")/*/test/data/columns/c[@name="' . $label . '"]/@id/string()';
    @test_type = grep { /^testname=/ } @{$self->{'config'}};
    $test_type[0] =~ s/testname=(.*)/$1/ or $test_type[0]='*';

    my $test_constraint = '[testname=' . $test_type[0] . ']';
    $xquery =~ s/(.*\*)(.*)/$1$test_constraint$2/;

    my $my_ids = $self->_doQuery( $self->{'manager'}, $self->{'container'}, $xquery );
    if (defined $my_ids){
        # This is a kludge to work around until I find 'limit 1' for xquery.
        my $val;
        $my_ids->next($val);
        return $val;
    } else {
        return $my_ids;
    }
}

1;
