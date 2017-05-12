# This tests the main searches specified The Bath Profile, Release 2.0, 
# 	http://www.collectionscanada.gc.ca/bath/tp-bath2-e.htm
# Specifically section 5.A.0 ("Functional Area A: Level 0 Basic
# Bibliographic Search and Retrieval") and its subsections:
#	http://www.collectionscanada.gc.ca/bath/tp-bath2.7-e.htm#a
# And section 5.A.1 ("Functional Area A: Level 1 Bibliographic Search
# and Retrieval") and subsections 14 (Standard Identifier Search) and
# 15 (Date of Publication Search):
#	http://www.collectionscanada.gc.ca/bath/tp-bath2.10-e.htm#b
#
# The Bath Level 0 searches have different access-points, but share:
#	Relation (2)		3	equal
#	Position (3)		3	any position in field
#	Structure (4)		2	word
#	Truncation (5)		100	do not truncate
#	Completeness (6)	1	incomplete subfield
# But Seb's bug report at:
#	http://bugzilla.indexdata.dk/show_bug.cgi?id=3352#c0
# wants use to use s=al t=r,l, where "s" is structure (4) and "al" is
# AND-list, which apparently sends NO structure attribute; and "t" is
# truncation (5) and "r,l" is right-and-left truncation.
#
# AND-listing (and selection of word or phrase-structure) is now
# invoked in the Toroid, when the list of attributes is emitted; we
# test for we can't test for 5=100 here, as the Bath Profile says to
# do, and rather optimistically use that as justification for emitting
# t=l,r in the Toroid (which means that individual queries can request
# either left- or right-truncation using "?".
#
# Finally, we also make a test for "X-isbn", an ISBN number search,
# which is not actually in the Bath Profile.  This gives us something
# to back down to when the more general Standard Identifier search
# isn't supported.

package ZOOM::IRSpy::Test::Search::Bath;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

use ZOOM::IRSpy::Utils qw(isodate);


my @bath_queries = (
    # Name    =>  use, rel, pos, str, tru, com
    [ author  => 1003,   3,   3,   2, 100,   1 ],	# 5.A.0.1
    [ title   =>    4,   3,   3,   2, 100,   1 ],	# 5.A.0.2
    [ subject =>   21,   3,   3,   2, 100,   1 ],	# 5.A.0.3
    [ any     => 1016,   3,   3,   2, 100,   1 ],	# 5.A.0.4
    [ ident   => 1007,   3,   1,   1, 100,   1 ],	# 5.A.1.14
    [ date    =>   31,   3,   1,   4, 100,   1 ],	# 5.A.1.15
    [ "X-isbn"=>    7,   3,   1,   1, 100,   1 ],	# Not in Bath Profile
    );


sub start {
    my $class = shift();
    my($conn) = @_;

    start_search($conn, 0);
}


sub start_search {
    my($conn, $qindex) = @_;

    return ZOOM::IRSpy::Status::TEST_GOOD
	if $qindex >= @bath_queries;

    my $ref = $bath_queries[$qindex];
    my($name, @attrs) = @$ref;

    my $query = join(" ", map { "\@attr $_=" . $attrs[$_-1] } (1..6)) . " the";
    $conn->irspy_search_pqf($query, { qindex => $qindex }, {},
			    ZOOM::Event::ZEND, \&search_complete,
			    "exception", \&search_complete);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub search_complete {
    my($conn, $task, $udata, $event) = @_;
    my $ok = ref $event && $event->isa("ZOOM::Exception") ? 0 : 1;

    my $qindex = $udata->{qindex};
    my $ref = $bath_queries[$qindex];
    my($name) = @$ref;

    my $n = $task->{rs}->size();

    $conn->log("irspy_test", "bath search #$qindex ('$name') ",
	       $ok ? ("found $n record", $n==1 ? "" : "s") :
	              "had error: $event");

    my $rec = $conn->record();
    $rec->append_entry("irspy:status",
		       "<irspy:search_bath name='$name' ok='$ok'>" .
		       isodate(time()) . "</irspy:search_bath>");

    return start_search($conn, $qindex+1);
}


1;
