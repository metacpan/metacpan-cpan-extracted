use strict;
use warnings;

use Test::More;
use File::Spec;

use Text::Extract::Word qw(get_all_text);

my $string;
my ($volume, $directory, $file) = File::Spec->splitpath(File::Spec->rel2abs(__FILE__));

# This test file is for the additional functionality needed to handle Word-based
# forms. Forms are implemented as fields combined with bookmarks. We therefore 
# need to handle a little more of the binary file structure, especially fields and
# bookmarks.

my $x1 = Text::Extract::Word->new(File::Spec->catpath($volume, $directory, "test8.doc"));
my $bookmarks = $x1->get_bookmarks();
ok($bookmarks, "Found some bookmarks");

is($bookmarks->{TestBookmark}, "Morag says hello", "Got correct value for TestBookmark");
is($bookmarks->{Text1}, "Form text", "Got correct value for Text1");

$bookmarks = $x1->get_bookmarks(':raw');
is($bookmarks->{TestBookmark}, "Morag says hello", "Got correct value for TestBookmark");
like($bookmarks->{Text1}, qr/FORMTEXT/, "Found raw contents");

my $x2 = Text::Extract::Word->new(File::Spec->catpath($volume, $directory, "test7.doc"));
ok(my $body = $x2->get_body(), "Got body for test7.doc");
ok(my $headers = $x2->get_headers(), "Got headers for test7.doc");
ok(my $footnotes = $x2->get_footnotes(), "Got footnotes for test7.doc");
ok(my $text = $x2->get_text(), "Got text for test7.doc");
ok(defined($x2->get_annotations()), "Got empty annotations for test7.doc");

ok(1 + index($text, $body), "Found body in text");
ok(1 + index($text, $headers), "Found headers in text");
ok(1 + index($text, $footnotes), "Found footnotes in text");

$bookmarks = $x2->get_bookmarks();
ok($bookmarks, "Found some bookmarks");
is($bookmarks->{Text9}, "Online environments", "Got correct value for Text9");
is($bookmarks->{Text10}, "Design research", "Got correct value for Text10");
is($bookmarks->{Text11}, "Pedagogy", "Got correct value for Text11");
is($bookmarks->{startdate}, "January 2005", "Got correct value for startdate");
is($bookmarks->{Text29}, "599", "Got correct value for Text29");
is($bookmarks->{Applicant2}, "Dr S Watt", "Got correct value for Applicant2");

done_testing();

1;