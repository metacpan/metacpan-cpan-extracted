# XML::Document::RTML::Parse test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 17 };

# load modules
use XML::Document::RTML;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# define variables
my ( $type );

# SCORE REQUEST
# -------------

# grab the test document
my $message1 = new XML::Document::RTML( File => 't/rtml2.1/ia_score_request.xml' );
$type = $message1->determine_type();

# check the parsed document
ok( $message1->dtd(), '2.1' );
ok( $message1->type(), 'score' );

#print Dumper($message1);

# OBS REQUEST
# -----------

# grab the test document
my $message2 = new XML::Document::RTML( File => 't/rtml2.1/ia_observation_request.xml' );

# check the parsed document
ok( $message2->dtd(), '2.1' );
ok( $message2->type(), 'request' );

#print Dumper($message2);

# ERS MESSAGES
# ============

my $accept_message = new XML::Document::RTML( File =>'t/rtml2.1/ers_observation_accepted.xml');

# check the parsed document
ok( $accept_message->dtd(), '2.1' );
ok( $accept_message->type(), 'confirmation' );

#print Dumper($accept_message);

# REJECT
# ------

my $reject_message = new XML::Document::RTML( File =>'t/rtml2.1/ers_observation_rejected.xml');

# check the parsed document
ok( $reject_message->dtd(), '2.1' );
ok( $reject_message->type(), 'reject' );

#print Dumper($reject_message);

# COMPLETED
# ---------

my $finish_message = new XML::Document::RTML(File =>'t/rtml2.1/ers_observations_complete.xml');

# check the parsed document
ok( $finish_message->dtd(), '2.1' );
ok( $finish_message->type(), 'observation' );

#print Dumper($finish_message);

# SCORE
# -----

my $score_message = new XML::Document::RTML( File =>'t/rtml2.1/ers_score_reply.xml');

my $target_ident = $score_message->targetident();
ok( $target_ident, 'Observation' );

# check the parsed document
ok( $score_message->dtd(), '2.1' );
ok( $score_message->type(), 'score' );

#print Dumper($score_message);

# UPDATE
# ------

my $update_message = new XML::Document::RTML( File =>'t/rtml2.1/ers_target_observed.xml');

# check the parsed document
ok( $update_message->dtd(), '2.1' );
ok( $update_message->type(), 'update' );
ok( $update_message->score(), undef );

#print Dumper($update_message);

exit;
