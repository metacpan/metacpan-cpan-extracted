# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More;
BEGIN { plan tests => 570 };

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# grab test document 1
# --------------------
print "Testing document t/rtml2.2/example_score.xml\n";
my $rtml1 = new XML::Document::RTML( File => 't/rtml2.2/example_score.xml' );

# check the parsed document
is( $rtml1->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml1->type(), 'score', "Comparing type of document" );
is( $rtml1->role(), 'score', "Comparing type of document" );
is( $rtml1->determine_type(), 'score', "Comparing type of document" );

is( $rtml1->version(), '2.2', "Comparing version of document" );

is( $rtml1->group_count(), 2, "Comparing the group count" );
is( $rtml1->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml1->exposure_time(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml1->exposuretime(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml1->exposure(), '==', 120.0, "Comparing the exposure time" );

is( $rtml1->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml1->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml1->series_count(), 3, "Comparing the series count" );
is( $rtml1->seriescount(), 3, "Comparing the series count" );

is( $rtml1->interval(), "PT1H", "Comparing the series intervals" );
is( $rtml1->tolerance(), "PT30M", "Comparing the tolerance of the intervals" );

is( $rtml1->priority(), "3", "Comparing the priority " );
is( $rtml1->schedule_priority(), "3", "Comparing the priority" );

my @times1a = $rtml1->time_constraint();
is( $times1a[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times1a[1], "2005-12-31T12:00:00", "Observation end time" );
my @times1b = $rtml1->timeconstraint();
is( $times1b[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times1b[1], "2005-12-31T12:00:00", "Observation end time" );
is( $rtml1->start_time(), "2005-01-01T12:00:00", "Observation start time" );
is( $rtml1->end_time(), "2005-12-31T12:00:00", "Observation end time" );

is( $rtml1->device_type(), "camera", "Comparing the device type" );
is( $rtml1->devicetype(), "camera", "Comparing the device type" );
is( $rtml1->device(), "camera", "Comparing the device type" );
is( $rtml1->filter(), "R", "Comparing the filter type" );
is( $rtml1->filtertype(), "R", "Comparing the filter type" );
is( $rtml1->filter_type(), "R", "Comparing the filter type" );

is( $rtml1->target_type(), "normal", "Comparing the target type" );
is( $rtml1->targettype(), "normal", "Comparing the target type" );
is( $rtml1->targetident(), "test-ident", "Comparing the target identity" );
is( $rtml1->target_ident(), "test-ident", "Comparing the target identity" );
is( $rtml1->identity(), "test-ident", "Comparing the target identity" );

is( $rtml1->target_name(), "test", "Comparing the target name" );
is( $rtml1->targetname(), "test", "Comparing the target name" );
is( $rtml1->target(), "test", "Comparing the target name" );

is( $rtml1->ra(), "01 02 03.0", "Comparing the RA" );
is( $rtml1->ra_format(), "hh mm ss.s", "Comparing the RA format" );
is( $rtml1->ra_units(), "hms", "Comparing the RA units" );

is( $rtml1->dec(), "+45 56 01.0", "Comparing the Dec" );
is( $rtml1->dec_format(), "sdd mm ss.s", "Comparing the Dec format" );
is( $rtml1->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml1->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml1->host(), "localhost", "Comparing the host" );
is( $rtml1->host_name(), "localhost", "Comparing the host" );
is( $rtml1->agent_host(), "localhost", "Comparing the host" );

is( $rtml1->port(), "1234", "Comparing the port" );
is( $rtml1->portnumber(), "1234", "Comparing the port" );
is( $rtml1->port_number(), "1234", "Comparing the port" );

is( $rtml1->id(), "12345", "Comparing the unique id" );
is( $rtml1->unique_id(), "12345", "Comparing the unique id" );

is( $rtml1->name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml1->observer_name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml1->real_name(), "Chris Mottram", "Comparing the observer's real name" );

is( $rtml1->user(), "TMC/estar", "Comparing the observer's user name" );
is( $rtml1->user_name(), "TMC/estar", "Comparing the observer's user name" );

is( $rtml1->institution(), "LJM", "Comparing the observer's instituiton" );
is( $rtml1->institution_affiliation(), "LJM", "Comparing the observer's instituiton" );

is( $rtml1->project(), undef, "Comparing the projects" );

is( $rtml1->score(), undef, "Comparing the score" );

is( $rtml1->completion_time(), undef, "Comparing the completion time" );
is( $rtml1->completiontime(), undef, "Comparing the completion time" );
is( $rtml1->time(), undef, "Comparing the completion time" );

my @data1 = $rtml1->data();
foreach my $i ( 0 ... $#data1 ) {
   is ( keys %{$data1[$i]}, 0, "Size of data hash $i" );
}
my @headers1 = $rtml1->headers();
is ( $#headers1, -1, "Number of headers" );
my @images1 = $rtml1->images();
is ( $#images1, -1, "Number of images" );
my @catalog1 = $rtml1->catalogues();
is ( $#catalog1, -1, "Number of catalogues" );

# grab test document 2
# --------------------
print "Testing document t/rtml2.2/example_score_reply.xml\n";
my $rtml2 = new XML::Document::RTML( File => 't/rtml2.2/example_score_reply.xml' );

# check the parsed document
is( $rtml2->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml2->type(), 'score', "Comparing type of document" );
is( $rtml2->role(), 'score', "Comparing type of document" );
is( $rtml2->determine_type(), 'score', "Comparing type of document" );

is( $rtml2->version(), '2.2', "Comparing version of document" );

is( $rtml2->group_count(), 2, "Comparing the group count" );
is( $rtml2->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml2->exposure_time(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml2->exposuretime(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml2->exposure(), '==', 120.0, "Comparing the exposure time" );

is( $rtml2->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml2->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml2->series_count(), 3, "Comparing the series count" );
is( $rtml2->seriescount(), 3, "Comparing the series count" );

is( $rtml2->interval(), "PT1H", "Comparing the series intervals" );
is( $rtml2->tolerance(), "PT30M", "Comparing the tolerance of the intervals" );

is( $rtml2->priority(), undef, "Comparing the priority " );
is( $rtml2->schedule_priority(), undef, "Comparing the priority" );

my @times2a = $rtml2->time_constraint();
is( $times2a[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times2a[1], "2005-12-31T12:00:00", "Observation end time" );
my @times2b = $rtml2->timeconstraint();
is( $times2b[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times2b[1], "2005-12-31T12:00:00", "Observation end time" );
is( $rtml2->start_time(), "2005-01-01T12:00:00", "Observation start time" );
is( $rtml2->end_time(), "2005-12-31T12:00:00", "Observation end time" );

is( $rtml2->device_type(), "camera", "Comparing the device type" );
is( $rtml2->devicetype(), "camera", "Comparing the device type" );
is( $rtml2->device(), "camera", "Comparing the device type" );
is( $rtml2->filter(), "R", "Comparing the filter type" );
is( $rtml2->filtertype(), "R", "Comparing the filter type" );
is( $rtml2->filter_type(), "R", "Comparing the filter type" );

is( $rtml2->target_type(), "normal", "Comparing the target type" );
is( $rtml2->targettype(), "normal", "Comparing the target type" );
is( $rtml2->targetident(), "test-ident", "Comparing the target identity" );
is( $rtml2->target_ident(), "test-ident", "Comparing the target identity" );
is( $rtml2->identity(), "test-ident", "Comparing the target identity" );

is( $rtml2->target_name(), "test", "Comparing the target name" );
is( $rtml2->targetname(), "test", "Comparing the target name" );
is( $rtml2->target(), "test", "Comparing the target name" );

is( $rtml2->ra(), "01 02 03.00", "Comparing the RA" );
is( $rtml2->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml2->ra_units(), "hms", "Comparing the RA units" );

is( $rtml2->dec(), "+45 56 01.00", "Comparing the Dec" );
is( $rtml2->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml2->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml2->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml2->host(), "localhost", "Comparing the host" );
is( $rtml2->host_name(), "localhost", "Comparing the host" );
is( $rtml2->agent_host(), "localhost", "Comparing the host" );

is( $rtml2->port(), "1234", "Comparing the port" );
is( $rtml2->portnumber(), "1234", "Comparing the port" );
is( $rtml2->port_number(), "1234", "Comparing the port" );

is( $rtml2->id(), "12345", "Comparing the unique id" );
is( $rtml2->unique_id(), "12345", "Comparing the unique id" );

is( $rtml2->name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml2->observer_name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml2->real_name(), "Chris Mottram", "Comparing the observer's real name" );

is( $rtml2->user(), "TMC/estar", "Comparing the observer's user name" );
is( $rtml2->user_name(), "TMC/estar", "Comparing the observer's user name" );

is( $rtml2->institution(), undef, "Comparing the observer's instituiton" );
is( $rtml2->institution_affiliation(), undef, "Comparing the observer's instituiton" );

is( $rtml2->project(), "agent_test", "Comparing the projects" );

is( $rtml2->score(), 0.25, "Comparing the score" );

is( $rtml2->completion_time(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml2->completiontime(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml2->time(), '2005-01-02T12:00:00', "Comparing the completion time" );

my @data2 = $rtml2->data();
foreach my $j ( 0 ... $#data2 ) {
   is ( keys %{$data2[$j]}, 0, "Size of data hash $j" );
}
my @headers2 = $rtml2->headers();
is ( $#headers2, -1, "Number of headers" );
my @images2 = $rtml2->images();
is ( $#images2, -1, "Number of images" );
my @catalog2 = $rtml2->catalogues();
is ( $#catalog2, -1, "Number of catalogues" );


# grab test document 3
# --------------------
print "Testing document t/rtml2.2/example_request.xml\n";
my $rtml3 = new XML::Document::RTML( File => 't/rtml2.2/example_request.xml' );

# check the parsed document
is( $rtml3->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml3->type(), 'request', "Comparing type of document" );
is( $rtml3->role(), 'request', "Comparing type of document" );
is( $rtml3->determine_type(), 'request', "Comparing type of document" );

is( $rtml3->version(), '2.2', "Comparing version of document" );

is( $rtml3->group_count(), 2, "Comparing the group count" );
is( $rtml3->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml3->exposure_time(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml3->exposuretime(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml3->exposure(), '==', 120.0, "Comparing the exposure time" );

is( $rtml3->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml3->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml3->series_count(), 3, "Comparing the series count" );
is( $rtml3->seriescount(), 3, "Comparing the series count" );

is( $rtml3->interval(), "PT1H", "Comparing the series intervals" );
is( $rtml3->tolerance(), "PT30M", "Comparing the tolerance of the intervals" );

is( $rtml3->priority(), undef, "Comparing the priority " );
is( $rtml3->schedule_priority(), undef, "Comparing the priority" );

my @times3a = $rtml3->time_constraint();
is( $times3a[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times3a[1], "2005-12-31T12:00:00", "Observation end time" );
my @times3b = $rtml3->timeconstraint();
is( $times3b[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times3b[1], "2005-12-31T12:00:00", "Observation end time" );
is( $rtml3->start_time(), "2005-01-01T12:00:00", "Observation start time" );
is( $rtml3->end_time(), "2005-12-31T12:00:00", "Observation end time" );

is( $rtml3->device_type(), "camera", "Comparing the device type" );
is( $rtml3->devicetype(), "camera", "Comparing the device type" );
is( $rtml3->device(), "camera", "Comparing the device type" );
is( $rtml3->filter(), "R", "Comparing the filter type" );
is( $rtml3->filtertype(), "R", "Comparing the filter type" );
is( $rtml3->filter_type(), "R", "Comparing the filter type" );

is( $rtml3->target_type(), "normal", "Comparing the target type" );
is( $rtml3->targettype(), "normal", "Comparing the target type" );
is( $rtml3->targetident(), "test-ident", "Comparing the target identity" );
is( $rtml3->target_ident(), "test-ident", "Comparing the target identity" );
is( $rtml3->identity(), "test-ident", "Comparing the target identity" );

is( $rtml3->target_name(), "test", "Comparing the target name" );
is( $rtml3->targetname(), "test", "Comparing the target name" );
is( $rtml3->target(), "test", "Comparing the target name" );

is( $rtml3->ra(), "01 02 03.00", "Comparing the RA" );
is( $rtml3->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml3->ra_units(), "hms", "Comparing the RA units" );

is( $rtml3->dec(), "+45 56 01.00", "Comparing the Dec" );
is( $rtml3->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml3->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml3->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml3->host(), "localhost", "Comparing the host" );
is( $rtml3->host_name(), "localhost", "Comparing the host" );
is( $rtml3->agent_host(), "localhost", "Comparing the host" );

is( $rtml3->port(), "1234", "Comparing the port" );
is( $rtml3->portnumber(), "1234", "Comparing the port" );
is( $rtml3->port_number(), "1234", "Comparing the port" );

is( $rtml3->id(), "12345", "Comparing the unique id" );
is( $rtml3->unique_id(), "12345", "Comparing the unique id" );

is( $rtml3->name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml3->observer_name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml3->real_name(), "Chris Mottram", "Comparing the observer's real name" );

is( $rtml3->user(), "TMC/estar", "Comparing the observer's user name" );
is( $rtml3->user_name(), "TMC/estar", "Comparing the observer's user name" );

is( $rtml3->institution(), undef, "Comparing the observer's instituiton" );
is( $rtml3->institution_affiliation(), undef, "Comparing the observer's instituiton" );

is( $rtml3->project(), "agent_test", "Comparing the projects" );

is( $rtml3->score(), 0.25, "Comparing the score" );

is( $rtml3->completion_time(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml3->completiontime(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml3->time(), '2005-01-02T12:00:00', "Comparing the completion time" );

my @data3 = $rtml3->data();
foreach my $k ( 0 ... $#data3 ) {
   is ( keys %{$data3[$k]}, 0, "Size of data hash $k" );
}
my @headers3 = $rtml3->headers();
is ( $#headers3, -1, "Number of headers" );
my @images3 = $rtml3->images();
is ( $#images3, -1, "Number of images" );
my @catalog3 = $rtml3->catalogues();
is ( $#catalog3, -1, "Number of catalogues" );

# grab test document 4
# --------------------
print "Testing document t/rtml2.2/example_confirmation.xml\n";
my $rtml4 = new XML::Document::RTML( File => 't/rtml2.2/example_confirmation.xml' );

# check the parsed document
is( $rtml4->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml4->type(), 'confirmation', "Comparing type of document" );
is( $rtml4->role(), 'confirmation', "Comparing type of document" );
is( $rtml4->determine_type(), 'confirmation', "Comparing type of document" );

is( $rtml4->version(), '2.2', "Comparing version of document" );

is( $rtml4->group_count(), 2, "Comparing the group count" );
is( $rtml4->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml4->exposure_time(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml4->exposuretime(), '==', 120.0, "Comparing the exposure time" );
cmp_ok( $rtml4->exposure(), '==', 120.0, "Comparing the exposure time" );

is( $rtml4->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml4->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml4->series_count(), 3, "Comparing the series count" );
is( $rtml4->seriescount(), 3, "Comparing the series count" );

is( $rtml4->interval(), "PT1H", "Comparing the series intervals" );
is( $rtml4->tolerance(), "PT30M", "Comparing the tolerance of the intervals" );

is( $rtml4->priority(), undef, "Comparing the priority " );
is( $rtml4->schedule_priority(), undef, "Comparing the priority" );

my @times4a = $rtml4->time_constraint();
is( $times4a[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times4a[1], "2005-12-31T12:00:00", "Observation end time" );
my @times4b = $rtml4->timeconstraint();
is( $times4b[0], "2005-01-01T12:00:00", "Observation start time" );
is( $times4b[1], "2005-12-31T12:00:00", "Observation end time" );
is( $rtml4->start_time(), "2005-01-01T12:00:00", "Observation start time" );
is( $rtml4->end_time(), "2005-12-31T12:00:00", "Observation end time" );

is( $rtml4->device_type(), "camera", "Comparing the device type" );
is( $rtml4->devicetype(), "camera", "Comparing the device type" );
is( $rtml4->device(), "camera", "Comparing the device type" );
is( $rtml4->filter(), "R", "Comparing the filter type" );
is( $rtml4->filtertype(), "R", "Comparing the filter type" );
is( $rtml4->filter_type(), "R", "Comparing the filter type" );

is( $rtml4->target_type(), "normal", "Comparing the target type" );
is( $rtml4->targettype(), "normal", "Comparing the target type" );
is( $rtml4->targetident(), "test-ident", "Comparing the target identity" );
is( $rtml4->target_ident(), "test-ident", "Comparing the target identity" );
is( $rtml4->identity(), "test-ident", "Comparing the target identity" );

is( $rtml4->target_name(), "test", "Comparing the target name" );
is( $rtml4->targetname(), "test", "Comparing the target name" );
is( $rtml4->target(), "test", "Comparing the target name" );

is( $rtml4->ra(), "01 02 03.00", "Comparing the RA" );
is( $rtml4->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml4->ra_units(), "hms", "Comparing the RA units" );

is( $rtml4->dec(), "+45 56 01.00", "Comparing the Dec" );
is( $rtml4->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml4->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml4->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml4->host(), "localhost", "Comparing the host" );
is( $rtml4->host_name(), "localhost", "Comparing the host" );
is( $rtml4->agent_host(), "localhost", "Comparing the host" );

is( $rtml4->port(), "1234", "Comparing the port" );
is( $rtml4->portnumber(), "1234", "Comparing the port" );
is( $rtml4->port_number(), "1234", "Comparing the port" );

is( $rtml4->id(), "12345", "Comparing the unique id" );
is( $rtml4->unique_id(), "12345", "Comparing the unique id" );

is( $rtml4->name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml4->observer_name(), "Chris Mottram", "Comparing the observer's real name" );
is( $rtml4->real_name(), "Chris Mottram", "Comparing the observer's real name" );

is( $rtml4->user(), "TMC/estar", "Comparing the observer's user name" );
is( $rtml4->user_name(), "TMC/estar", "Comparing the observer's user name" );

is( $rtml4->institution(), undef, "Comparing the observer's instituiton" );
is( $rtml4->institution_affiliation(), undef, "Comparing the observer's instituiton" );

is( $rtml4->project(), "agent_test", "Comparing the projects" );

is( $rtml4->score(), 0.25, "Comparing the score" );

is( $rtml4->completion_time(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml4->completiontime(), '2005-01-02T12:00:00', "Comparing the completion time" );
is( $rtml4->time(), '2005-01-02T12:00:00', "Comparing the completion time" );

my @data4 = $rtml4->data();
foreach my $k ( 0 ... $#data4 ) {
   is ( keys %{$data4[$k]}, 0, "Size of data hash $k" );
}
my @headers4 = $rtml4->headers();
is ( $#headers4, -1, "Number of headers" );
my @images4 = $rtml4->images();
is ( $#images4, -1, "Number of images" );
my @catalog4 = $rtml4->catalogues();
is ( $#catalog4, -1, "Number of catalogues" );

# grab test document 5
# --------------------
print "Testing document t/rtml2.2/example_observe.xml\n";
my $rtml5 = new XML::Document::RTML( File => 't/rtml2.2/example_observe.xml' );

# check the parsed document
is( $rtml5->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml5->type(), 'observation', "Comparing type of document" );
is( $rtml5->role(), 'observation', "Comparing type of document" );
is( $rtml5->determine_type(), 'observation', "Comparing type of document" );

is( $rtml5->version(), '2.2', "Comparing version of document" );

is( $rtml5->group_count(), 2, "Comparing the group count" );
is( $rtml5->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml5->exposure_time(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml5->exposuretime(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml5->exposure(), '==', 63.5, "Comparing the exposure time" );

is( $rtml5->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml5->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml5->series_count(), 8, "Comparing the series count" );
is( $rtml5->seriescount(), 8, "Comparing the series count" );

is( $rtml5->interval(), "PT2700.0S", "Comparing the series intervals" );
is( $rtml5->tolerance(), "PT1350.0S", "Comparing the tolerance of the intervals" );

is( $rtml5->priority(), undef, "Comparing the priority " );
is( $rtml5->schedule_priority(), undef, "Comparing the priority" );

my @times5a = $rtml5->time_constraint();
is( $times5a[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times5a[1], "2005-05-13T03:00:00", "Observation end time" );
my @times5b = $rtml5->timeconstraint();
is( $times5b[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times5b[1], "2005-05-13T03:00:00", "Observation end time" );
is( $rtml5->start_time(), "2005-05-12T09:00:00", "Observation start time" );
is( $rtml5->end_time(), "2005-05-13T03:00:00", "Observation end time" );

is( $rtml5->device_type(), "camera", "Comparing the device type" );
is( $rtml5->devicetype(), "camera", "Comparing the device type" );
is( $rtml5->device(), "camera", "Comparing the device type" );
is( $rtml5->filter(), "R", "Comparing the filter type" );
is( $rtml5->filtertype(), "R", "Comparing the filter type" );
is( $rtml5->filter_type(), "R", "Comparing the filter type" );

is( $rtml5->target_type(), "normal", "Comparing the target type" );
is( $rtml5->targettype(), "normal", "Comparing the target type" );
is( $rtml5->targetident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml5->target_ident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml5->identity(), "ExoPlanetMonitor", "Comparing the target identity" );

is( $rtml5->target_name(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml5->targetname(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml5->target(), "OGLE-2005-blg-158", "Comparing the target name" );

is( $rtml5->ra(), "18 06 04.24", "Comparing the RA" );
is( $rtml5->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml5->ra_units(), "hms", "Comparing the RA units" );

is( $rtml5->dec(), "-28 30 51.50", "Comparing the Dec" );
is( $rtml5->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml5->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml5->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml5->host(), "144.173.229.20", "Comparing the host" );
is( $rtml5->host_name(), "144.173.229.20", "Comparing the host" );
is( $rtml5->agent_host(), "144.173.229.20", "Comparing the host" );

is( $rtml5->port(), "2050", "Comparing the port" );
is( $rtml5->portnumber(), "2050", "Comparing the port" );
is( $rtml5->port_number(), "2050", "Comparing the port" );

is( $rtml5->id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );
is( $rtml5->unique_id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );

is( $rtml5->name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml5->observer_name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml5->real_name(), "Alasdair Allan", "Comparing the observer's real name" );

is( $rtml5->user(), "Robonet/keith.horne", "Comparing the observer's user name" );
is( $rtml5->user_name(), "Robonet/keith.horne", "Comparing the observer's user name" );

is( $rtml5->institution(), "University of Exeter", "Comparing the observer's instituiton" );
is( $rtml5->institution_affiliation(), "University of Exeter", "Comparing the observer's instituiton" );

is( $rtml5->project(), "Planetsearch1", "Comparing the projects" );

cmp_ok( $rtml5->score(), '==', 0.4530854938271604, "Comparing the score" );

is( $rtml5->completion_time(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml5->completiontime(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml5->time(), '2005-05-12T08:59:08', "Comparing the completion time" );

my @data5 = $rtml5->data();
#print Dumper( @data5 );

foreach my $k ( 0 ... $#data5 ) {
   my $size = keys %{$data5[$k]};
   is ( $size, 3, "Size of data hash $k (got $size, expected 3)" );
}
my @headers5 = $rtml5->headers();
is ( scalar(@headers5), 4, "Number of headers (got ". scalar(@headers5) . ", expected 4)" );
foreach my $head ( 0 ... $#headers5 ) {
   is ( $headers5[$head], undef, "Header $head is undefined as expected" );
}   
my @images5 = $rtml5->images();
is ( scalar(@images5), 4, "Number of images (got ". scalar(@images5) . ", expected 4)" );
is ( $images5[0], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_198_1_1_1.fits', "Image 1 present as expected" );
is ( $images5[1], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_198_2_1_1.fits', "Image 2 present as expected" );
is ( $images5[2], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_208_1_1_1.fits', "Image 3 present as expected" );
is ( $images5[3], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_208_2_1_1.fits', "Image 3 present as expected" );
my @catalog5 = $rtml5->catalogues();
is ( scalar(@catalog5), 4, "Number of catalogues (got ". scalar(@catalog5) . ", expected 4)" );
foreach my $cat ( 0 ... $#catalog5 ) {
   is ( $catalog5[$cat], undef, "Catalogue $cat is undefined as expected" );
} 

# grab test document 6
# --------------------
print "Testing document t/rtml2.2/problem_1.xml\n";
my $rtml6 = new XML::Document::RTML( File => 't/rtml2.2/problem_1.xml' );

# check the parsed document
is( $rtml6->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml6->type(), 'update', "Comparing type of document" );
is( $rtml6->role(), 'update', "Comparing type of document" );
is( $rtml6->determine_type(), 'update', "Comparing type of document" );

is( $rtml6->version(), '2.2', "Comparing version of document" );

is( $rtml6->group_count(), 2, "Comparing the group count" );
is( $rtml6->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml6->exposure_time(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml6->exposuretime(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml6->exposure(), '==', 63.5, "Comparing the exposure time" );

is( $rtml6->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml6->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml6->series_count(), 8, "Comparing the series count" );
is( $rtml6->seriescount(), 8, "Comparing the series count" );

is( $rtml6->interval(), "PT2700.0S", "Comparing the series intervals" );
is( $rtml6->tolerance(), "PT1350.0S", "Comparing the tolerance of the intervals" );

is( $rtml6->priority(), undef, "Comparing the priority " );
is( $rtml6->schedule_priority(), undef, "Comparing the priority" );

my @times6a = $rtml6->time_constraint();
is( $times6a[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times6a[1], "2005-05-13T03:00:00", "Observation end time" );
my @times6b = $rtml6->timeconstraint();
is( $times6b[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times6b[1], "2005-05-13T03:00:00", "Observation end time" );
is( $rtml6->start_time(), "2005-05-12T09:00:00", "Observation start time" );
is( $rtml6->end_time(), "2005-05-13T03:00:00", "Observation end time" );

is( $rtml6->device_type(), "camera", "Comparing the device type" );
is( $rtml6->devicetype(), "camera", "Comparing the device type" );
is( $rtml6->device(), "camera", "Comparing the device type" );
is( $rtml6->filter(), "R", "Comparing the filter type" );
is( $rtml6->filtertype(), "R", "Comparing the filter type" );
is( $rtml6->filter_type(), "R", "Comparing the filter type" );

is( $rtml6->target_type(), "normal", "Comparing the target type" );
is( $rtml6->targettype(), "normal", "Comparing the target type" );
is( $rtml6->targetident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml6->target_ident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml6->identity(), "ExoPlanetMonitor", "Comparing the target identity" );

is( $rtml6->target_name(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml6->targetname(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml6->target(), "OGLE-2005-blg-158", "Comparing the target name" );

is( $rtml6->ra(), "18 06 04.24", "Comparing the RA" );
is( $rtml6->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml6->ra_units(), "hms", "Comparing the RA units" );

is( $rtml6->dec(), "-28 30 51.50", "Comparing the Dec" );
is( $rtml6->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml6->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml6->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml6->host(), "144.173.229.20", "Comparing the host" );
is( $rtml6->host_name(), "144.173.229.20", "Comparing the host" );
is( $rtml6->agent_host(), "144.173.229.20", "Comparing the host" );

is( $rtml6->port(), "2050", "Comparing the port" );
is( $rtml6->portnumber(), "2050", "Comparing the port" );
is( $rtml6->port_number(), "2050", "Comparing the port" );

is( $rtml6->id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );
is( $rtml6->unique_id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );

is( $rtml6->name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml6->observer_name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml6->real_name(), "Alasdair Allan", "Comparing the observer's real name" );

is( $rtml6->user(), "Robonet/keith.horne", "Comparing the observer's user name" );
is( $rtml6->user_name(), "Robonet/keith.horne", "Comparing the observer's user name" );

is( $rtml6->institution(), "University of Exeter", "Comparing the observer's instituiton" );
is( $rtml6->institution_affiliation(), "University of Exeter", "Comparing the observer's instituiton" );

is( $rtml6->project(), "Planetsearch1", "Comparing the projects" );

cmp_ok( $rtml6->score(), '==', 0.4530854938271604, "Comparing the score" );

is( $rtml6->completion_time(), '2005-05-12T15:55:24', "Comparing the completion time" );
is( $rtml6->completiontime(), '2005-05-12T15:55:24', "Comparing the completion time" );
is( $rtml6->time(), '2005-05-12T15:55:24', "Comparing the completion time" );

my @data6 = $rtml6->data();
#print Dumper( @data6 );

foreach my $m ( 0 ... $#data6 ) {
   my $size = keys %{$data6[$m]};
   is ( $size, 3, "Size of data hash $m (expected 3)" );
}
my @headers6 = $rtml6->headers();
is ( scalar(@headers6), 1, "Number of headers (got ". scalar(@headers6) . ", expected 1)" );
foreach my $head ( 0 ... $#headers6 ) {
   is ( $headers6[$head], undef, "Header $head is undefined as expected" );
}   
my @images6 = $rtml6->images();
is ( scalar(@images6), 1, "Number of images (got ". scalar(@images6) . ", expected 1)" );
foreach my $head ( 0 ... $#headers6 ) {
   is ( $images6[$head], "http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_208_1_1_1.fits", "Header $head is undefined as expected" );
} 
my @catalog6 = $rtml6->catalogues();
is ( scalar(@catalog6), 1, "Number of catalogues (got ". scalar(@catalog6) . ", expected 1)" );
foreach my $cat ( 0 ... $#catalog6 ) {
   is ( $catalog6[$cat], undef, "Catalogue $cat is undefined as expected" );
} 

# grab test document 7
# --------------------
print "Testing document t/rtml2.2/problem_2.xml\n";
my $rtml7 = new XML::Document::RTML( File => 't/rtml2.2/problem_2.xml' );

# check the parsed document
is( $rtml7->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml7->type(), 'failed', "Comparing type of document" );
is( $rtml7->role(), 'failed', "Comparing type of document" );
is( $rtml7->determine_type(), 'failed', "Comparing type of document" );

is( $rtml7->version(), '2.2', "Comparing version of document" );

is( $rtml7->group_count(), 4, "Comparing the group count" );
is( $rtml7->groupcount(), 4, "Comparing the group count" );

cmp_ok( $rtml7->exposure_time(), '==', 106, "Comparing the exposure time" );
cmp_ok( $rtml7->exposuretime(), '==', 106, "Comparing the exposure time" );
cmp_ok( $rtml7->exposure(), '==', 106, "Comparing the exposure time" );

is( $rtml7->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml7->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml7->series_count(), 1, "Comparing the series count" );
is( $rtml7->seriescount(), 1, "Comparing the series count" );

is( $rtml7->interval(), "PT21600.0S", "Comparing the series intervals" );
is( $rtml7->tolerance(), "PT10800.0S", "Comparing the tolerance of the intervals" );

is( $rtml7->priority(), undef, "Comparing the priority" );
is( $rtml7->schedule_priority(), undef, "Comparing the priority" );

my @times7a = $rtml7->time_constraint();
is( $times7a[0], "2005-05-11T15:00:00", "Observation start time" );
is( $times7a[1], "2005-05-12T15:00:00", "Observation end time" );
my @times7b = $rtml7->timeconstraint();
is( $times7b[0], "2005-05-11T15:00:00", "Observation start time" );
is( $times7b[1], "2005-05-12T15:00:00", "Observation end time" );
is( $rtml7->start_time(), "2005-05-11T15:00:00", "Observation start time" );
is( $rtml7->end_time(), "2005-05-12T15:00:00", "Observation end time" );

is( $rtml7->device_type(), "camera", "Comparing the device type" );
is( $rtml7->devicetype(), "camera", "Comparing the device type" );
is( $rtml7->device(), "camera", "Comparing the device type" );
is( $rtml7->filter(), "R", "Comparing the filter type" );
is( $rtml7->filtertype(), "R", "Comparing the filter type" );
is( $rtml7->filter_type(), "R", "Comparing the filter type" );

is( $rtml7->target_type(), "normal", "Comparing the target type" );
is( $rtml7->targettype(), "normal", "Comparing the target type" );
is( $rtml7->targetident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml7->target_ident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml7->identity(), "ExoPlanetMonitor", "Comparing the target identity" );

is( $rtml7->target_name(), "OGLE-2005-blg-006", "Comparing the target name" );
is( $rtml7->targetname(), "OGLE-2005-blg-006", "Comparing the target name" );
is( $rtml7->target(), "OGLE-2005-blg-006", "Comparing the target name" );

is( $rtml7->ra(), "17 52 32.36", "Comparing the RA" );
is( $rtml7->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml7->ra_units(), "hms", "Comparing the RA units" );

is( $rtml7->dec(), "-32 32 54.70", "Comparing the Dec" );
is( $rtml7->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml7->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml7->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml7->host(), "144.173.229.20", "Comparing the host" );
is( $rtml7->host_name(), "144.173.229.20", "Comparing the host" );
is( $rtml7->agent_host(), "144.173.229.20", "Comparing the host" );

is( $rtml7->port(), "2050", "Comparing the port" );
is( $rtml7->portnumber(), "2050", "Comparing the port" );
is( $rtml7->port_number(), "2050", "Comparing the port" );

is( $rtml7->id(), "000052:UA:v1-15:run#10:user#agent", "Comparing the unique id" );
is( $rtml7->unique_id(), "000052:UA:v1-15:run#10:user#agent", "Comparing the unique id" );

is( $rtml7->name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml7->observer_name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml7->real_name(), "Alasdair Allan", "Comparing the observer's real name" );

is( $rtml7->user(), "TEST/estar", "Comparing the observer's user name" );
is( $rtml7->user_name(), "TEST/estar", "Comparing the observer's user name" );

is( $rtml7->institution(), "University of Exeter", "Comparing the observer's instituiton" );
is( $rtml7->institution_affiliation(), "University of Exeter", "Comparing the observer's instituiton" );

is( $rtml7->project(), "TEA01", "Comparing the projects" );

my $score7 = sprintf("%.3f", $rtml7->score() );
cmp_ok( $score7, '==', 0.319, "Comparing the score" );

is( $rtml7->completion_time(), '2005-05-12T16:26:39', "Comparing the completion time" );
is( $rtml7->completiontime(), '2005-05-12T16:26:39', "Comparing the completion time" );
is( $rtml7->time(), '2005-05-12T16:26:39', "Comparing the completion time" );

my @data7 = $rtml7->data();
#print Dumper( @data7 );

foreach my $m ( 0 ... $#data7 ) {
   my $size = keys %{$data7[$m]};
   is ( $size, 0, "Size of data hash $m" );
}
my @headers7 = $rtml7->headers();
is ( scalar(@headers7), 0, "Number of headers (got ". scalar(@headers7) . ", expected 0)" );
foreach my $head ( 0 ... $#headers7 ) {
   is ( $headers7[$head], undef, "Header $head is undefined as expected" );
}   
my @images7 = $rtml7->images();
is ( scalar(@images7), 0, "Number of images (got ". scalar(@images7) . ", expected 0)" );
foreach my $head ( 0 ... $#headers7 ) {
   is ( $images7[$head], undef, "Header $head is undefined as expected" );
} 
my @catalog7 = $rtml7->catalogues();
is ( scalar(@catalog7), 0, "Number of catalogues (got ". scalar(@catalog7) . ", expected 0)" );
foreach my $cat ( 0 ... $#catalog7 ) {
   is ( $catalog7[$cat], undef, "Catalogue $cat is undefined as expected" );
} 


# grab test document 8
# --------------------
print "Testing document t/rtml2.2/example_update.xml\n";
my $rtml8 = new XML::Document::RTML( File => 't/rtml2.2/example_update.xml' );

# check the parsed document
is( $rtml8->dtd(), '2.2', "Comparing the RTML specification version used" );

is( $rtml8->type(), 'update', "Comparing type of document" );
is( $rtml8->role(), 'update', "Comparing type of document" );
is( $rtml8->determine_type(), 'update', "Comparing type of document" );

is( $rtml8->version(), '2.2', "Comparing version of document" );

is( $rtml8->group_count(), 2, "Comparing the group count" );
is( $rtml8->groupcount(), 2, "Comparing the group count" );

cmp_ok( $rtml8->exposure_time(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml8->exposuretime(), '==', 63.5, "Comparing the exposure time" );
cmp_ok( $rtml8->exposure(), '==', 63.5, "Comparing the exposure time" );

is( $rtml8->exposure_type(), "time", "Comparing the type of exposure" );
is( $rtml8->exposuretype(), "time", "Comparing the type of exposure" );

is( $rtml8->series_count(), 8, "Comparing the series count" );
is( $rtml8->seriescount(), 8, "Comparing the series count" );

is( $rtml8->interval(), "PT2700.0S", "Comparing the series intervals" );
is( $rtml8->tolerance(), "PT1350.0S", "Comparing the tolerance of the intervals" );

is( $rtml8->priority(), undef, "Comparing the priority " );
is( $rtml8->schedule_priority(), undef, "Comparing the priority" );

my @times8a = $rtml8->time_constraint();
is( $times8a[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times8a[1], "2005-05-13T03:00:00", "Observation end time" );
my @times8b = $rtml8->timeconstraint();
is( $times8b[0], "2005-05-12T09:00:00", "Observation start time" );
is( $times8b[1], "2005-05-13T03:00:00", "Observation end time" );
is( $rtml8->start_time(), "2005-05-12T09:00:00", "Observation start time" );
is( $rtml8->end_time(), "2005-05-13T03:00:00", "Observation end time" );

is( $rtml8->device_type(), "camera", "Comparing the device type" );
is( $rtml8->devicetype(), "camera", "Comparing the device type" );
is( $rtml8->device(), "camera", "Comparing the device type" );
is( $rtml8->filter(), "R", "Comparing the filter type" );
is( $rtml8->filtertype(), "R", "Comparing the filter type" );
is( $rtml8->filter_type(), "R", "Comparing the filter type" );

is( $rtml8->target_type(), "normal", "Comparing the target type" );
is( $rtml8->targettype(), "normal", "Comparing the target type" );
is( $rtml8->targetident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml8->target_ident(), "ExoPlanetMonitor", "Comparing the target identity" );
is( $rtml8->identity(), "ExoPlanetMonitor", "Comparing the target identity" );

is( $rtml8->target_name(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml8->targetname(), "OGLE-2005-blg-158", "Comparing the target name" );
is( $rtml8->target(), "OGLE-2005-blg-158", "Comparing the target name" );

is( $rtml8->ra(), "18 06 04.24", "Comparing the RA" );
is( $rtml8->ra_format(), "hh mm ss.ss", "Comparing the RA format" );
is( $rtml8->ra_units(), "hms", "Comparing the RA units" );

is( $rtml8->dec(), "-28 30 51.50", "Comparing the Dec" );
is( $rtml8->dec_format(), "sdd mm ss.ss", "Comparing the Dec format" );
is( $rtml8->dec_units(), "dms", "Comparing the Dec units" );

is( $rtml8->equinox(), "J2000", "Comparing the Equinox" );

is( $rtml8->host(), "144.173.229.20", "Comparing the host" );
is( $rtml8->host_name(), "144.173.229.20", "Comparing the host" );
is( $rtml8->agent_host(), "144.173.229.20", "Comparing the host" );

is( $rtml8->port(), "2050", "Comparing the port" );
is( $rtml8->portnumber(), "2050", "Comparing the port" );
is( $rtml8->port_number(), "2050", "Comparing the port" );

is( $rtml8->id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );
is( $rtml8->unique_id(), "000106:UA:v1-15:run#10:user#agent", "Comparing the unique id" );

is( $rtml8->name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml8->observer_name(), "Alasdair Allan", "Comparing the observer's real name" );
is( $rtml8->real_name(), "Alasdair Allan", "Comparing the observer's real name" );

is( $rtml8->user(), "Robonet/keith.horne", "Comparing the observer's user name" );
is( $rtml8->user_name(), "Robonet/keith.horne", "Comparing the observer's user name" );

is( $rtml8->institution(), "University of Exeter", "Comparing the observer's instituiton" );
is( $rtml8->institution_affiliation(), "University of Exeter", "Comparing the observer's instituiton" );

is( $rtml8->project(), "Planetsearch1", "Comparing the projects" );

cmp_ok( $rtml8->score(), '==', 0.4530854938271604, "Comparing the score" );

is( $rtml8->completion_time(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml8->completiontime(), '2005-05-12T08:59:08', "Comparing the completion time" );
is( $rtml8->time(), '2005-05-12T08:59:08', "Comparing the completion time" );

my @data8 = $rtml8->data();
#print Dumper( @data8 );

foreach my $k ( 0 ... $#data8 ) {
   my $size = keys %{$data8[$k]};
   is ( $size, 3, "Size of data hash $k (got $size, expected 3)" );
}
my @headers8 = $rtml8->headers();
is ( scalar(@headers8), 1, "Number of headers (got ". scalar(@headers8) . ", expected 1)" );
foreach my $head ( 0 ... $#headers8 ) {
   is ( $headers8[$head], undef, "Header $head is undefined as expected" );
}   
my @images8 = $rtml8->images();
is ( scalar(@images8), 1, "Number of images (got ". scalar(@images8) . ", expected 1)" );
is ( $images8[0], 'http://150.204.240.8/~estar/data/home/estar/data/c_e_20050511_198_1_1_1.fits', "Image 1 present as expected" );
my @catalog8 = $rtml8->catalogues();
is ( scalar(@catalog8), 1, "Number of catalogues (got ". scalar(@catalog8) . ", expected 1)" );
foreach my $cat ( 0 ... $#catalog8 ) {
   is ( $catalog8[$cat], undef, "Catalogue $cat is undefined as expected" );
} 


exit;
