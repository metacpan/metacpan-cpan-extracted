
use strict;
use warnings;

use Test::More tests => 13;
use Data::Dumper;
use File::Temp qw<tempfile>;

use feature "say";
BEGIN { use_ok('uSAC::MIME') };


#Make a new object
my $db=uSAC::MIME->new;

#Index default
my ($forward, $backward)=$db->index;
ok $forward, "Forward lookup is defined";
ok $backward, "Backward lookup is defined";
#do a forward lookup
ok $forward->{"txt"} eq "text/plain",  "Plain text OK";

#do a backward lookup
ok grep("txt", $backward->{"text/plain"}), "Plain text OK";


#test adding to existing
my $new_ext="my_ext";
my $new_mime="txt";
($forward,$backward)=$db->add($new_ext, $new_mime)->index;

#do a forward lookup
ok $forward->{$new_ext} eq $new_mime, "Forward lookup of new extension";

#do a backward lookup
ok grep("txt", $backward->{"text/plain"}), "Old extension still ok";
ok grep($new_ext, $backward->{"text/plain"}->@*), "New extension ok";


#add a completely new

ok !$forward->{test}, "Not existing";

($forward,$backward)=$db->add("test"=>"dummy/mime")->index;
ok $forward->{test} eq "dummy/mime", "Completely new added";


($forward, $backward)=$db->rem(test=>"dummy/mime")->index;
ok !$forward->{test} , "Completely removed";


$db=uSAC::MIME->new_empty(txt=>"text/plain");
($forward,$backward)=$db->index;
ok $forward->{"txt"} eq "text/plain", "Empty db, added entry";
ok !$forward->{"mp4"}, "Empty db ok";


my ($fh, $filename)=tempfile;
$db=uSAC::MIME->new_from_file("/opt/local/etc/nginx/mime.types");
$db->save_to_handle($fh);
