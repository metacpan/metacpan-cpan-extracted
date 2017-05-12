############################################
# WWW::Wuala - Perl OO interface to www.wuala.com
# v0.1
# Made by Perforin - www.virii.lu
############################################

package WWW::Wuala;

$VERSION = "0.1";

use LWP::Simple qw ($ua getstore get);
use File::Temp qw(tempfile);


sub new {

$Objekt = shift;
$Referenz = {};
bless($Referenz,$Objekt);
return($Referenz);

}


sub server {

my ($return,$wantedserver) = @_;
if ($wantedserver ne [1..6]) {
our $usercontentserver = $wantedserver || 1;
} else {
return(0);
}
}

sub download {

($return,$link,$filename,$key) = @_;

if (length($key) eq 0) {
@empfangen = get('http://content' . $usercontentserver . '.wuala.com/contents/' . $link) || return(0);
} else {
@empfangen = get('http://content' . $usercontentserver . '.wuala.com/contents/' . $link . '?key=' . $key) || return(0);
}

######
# Does only check once.
# Note that if you already got _WualaDL_XYZ.txt and you now download XYZ.txt which does also already exists, _WualaDL_XYZ.txt will be overwritten!
######

foreach $file (glob("*.*")) { if ($file =~ m/$filename/i) { $filename = '_WualaDL_' . $filename; } }
 
open(DAT,">",$filename) || die "Keine Schreibrechte!";
binmode(DAT);
print DAT @empfangen;
close(DAT);

}

sub preview {

undef(@RETURN);
undef(@TAG);
undef(@PFN);
undef(@PFU);
undef(@PGN);
undef(@PGU);
undef(%RETURN);

($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$user,@prev) = @_;
%RETURN;

@empfangen = getstore("http://api.wua.la/preview/" . $user,$tmpfile);

if (@prev eq 0) {
@prev = qw(type fullname gender birthday contact countrycode prouser name url
creator creationdate sizestring description tag views links favorites comments
familyfriendly publicFolders_name publicFolders_url publicGroups_name publicGroups_url);
}

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
foreach $user_want (@prev) {
undef(@RETURN);
if ($user_want =~ m/^type$/i)  {
if ($_ =~ m/(\<type\>)(\w*)(\<\/type\>)/img) {
$type = $2;
push(@RETURN,$type);
$RETURN{type} = [ @RETURN ];
}
} elsif ($user_want =~ m/^fullName$/i) {
if ($_ =~ m/(\<fullName\>)(\w*)(\<\/fullName\>)/img) {
$fullname = $2;
push(@RETURN,$fullname);
$RETURN{fullName} = [ @RETURN ];
}
} elsif ($user_want =~ m/^gender$/i) {
if ($_ =~ m/(\<gender\>)(\w*)(\<\/gender\>)/img) {
$gender = $2;
push(@RETURN,$gender);
$RETURN{gender} = [ @RETURN ];
}
} elsif ($user_want =~ m/^birthday$/i) {
if ($_ =~ m/(\<birthday\>)(\d*)(\<\/birthday\>)/img) {
$birthday = $2;
push(@RETURN,$birthday);
$RETURN{birthday} = [ @RETURN ];
}
} elsif ($user_want =~ m/^contact$/i) {
if ($_ =~ m/(\<contact name="\w*"\>)(.*)(\<\/contact\>)/img) {
$contact = $2;
push(@RETURN,$contact);
$RETURN{contact} = [ @RETURN ];
}
} elsif ($user_want =~ m/^countryCode$/i) {
if ($_ =~ m/(\<countryCode\>)(\w*)(\<\/countryCode\>)/img) {
$cntry = $2;
push(@RETURN,$cntry);
$RETURN{countryCode} = [ @RETURN ];
}
} elsif ($user_want =~ m/^proUser$/i) {
if ($_ =~ m/(\<proUser\>)(\w*)(\<\/proUser\>)/img) {
$proUser = $2;
push(@RETURN,$proUser);
$RETURN{proUser} = [ @RETURN ];
}
} elsif ($user_want =~ m/^name$/i) {
if($_ =~ m/(\<name\>)(\w*)(\<\/name\>)/img) {
$name = $2;
push(@RETURN,$name);
$RETURN{name} = [ @RETURN ];
}
} elsif ($user_want =~ m/^url$/i) {
if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$url = $2;
push(@RETURN,$url);
$RETURN{url} = [ @RETURN ];
}
} elsif ($user_want =~ m/^creator$/i) {
if ($_ =~ m/(\<creator\>)(\w*)(\<\/creator\>)/img) {
$creator = $2;
push(@RETURN,$creator);
$RETURN{creator} = [ @RETURN ];
}
} elsif ($user_want =~ m/^creationDate$/i) {
if ($_ =~ m/(\<creationDate\>)(\d*)(\<\/creationDate\>)/img) {
$creationDate = $2;
push(@RETURN,$creationDate);
$RETURN{creationDate} = [ @RETURN ];
}
} elsif ($user_wanted =~ m/^sizeString$/i) {
if ($_ =~ m/(\<sizeString\>)(.*)(\<\/sizeString\>)/img) {
$sizeString = $2;
push(@RETURN,$sizeString);
$RETURN{sizeString} = [ @RETURN ];
}
} elsif ($user_want =~ m/^description$/i) {
if ($_ =~ m/(\<description\>)(.*)(\<\/description\>)/img) {
$quote = $2;
push(@RETURN,$quote);
$RETURN{description} = [ @RETURN ];
}
} elsif ($user_want =~ m/^tag$/i) {
if ($_ =~ m/(\<tag\>)(.*)(\<\/tag\>)/img) {
$tag = $2;
push(@TAG,$tag);
$RETURN{tag} = [ @TAG ];
}
} elsif ($user_want =~ m/^views$/i) {
if ($_ =~ m/(\<views\>)(\d*)(\<\/views\>)/img) {
$views = $2;
push(@RETURN,$views);
$RETURN{views} = [ @RETURN ];
}
} elsif ($user_want =~ m/^links$/i) {
if ($_ =~ m/(\<links\>)(\d*)(\<\/links\>)/img) {
$links = $2;
push(@RETURN,$links);
$RETURN{links} = [ @RETURN ];
}
} elsif ($user_want =~ m/^favorites$/i) {
if ($_ =~ m/(\<favorites\>)(\d*)(\<\/favorites\>)/img) {
$favorites = $2;
push(@RETURN,$favorites);
$RETURN{favorites} = [ @RETURN ];
}
} elsif ($user_want =~ m/^comments$/i) {
if ($_ =~ m/(\<comments\>)(\d*)(\<\/comments\>)/img) {
$comments = $2;
push(@RETURN,$comments);
$RETURN{comments} = [ @RETURN ];
}
} elsif ($user_want =~ m/^familyFriendly$/i) {
if ($_ =~ m/(\<familyFriendly\>)(\w*)(\<\/familyFriendly\>)/img) {
$familyFriendly = $2;
push(@RETURN,$familyFriendly);
$RETURN{familyFriendly} = [ @RETURN ];
}
} elsif ($user_want =~ m/^publicFolders_name$/i) {                                                          ############# SPECIAL
if ($_ =~ m/(\<item isEmpty="\w*" modificationDate="\d+" name="\w+" url=")(.*)"\>(.*)(\<\/item\>)/img) {
$publicFolders_name = $3;
push(@PFN,$publicFolders_name);
$RETURN{publicFolders_name} = [ @PFN ];
}
} elsif ($user_want =~ m/^publicFolders_url$/i) {                                                           ############# SPECIAL
if ($_ =~ m/(\<item isEmpty="\w*" modificationDate="\d+" name="\w+" url=")(.*)"\>(.*)(\<\/item\>)/img) {
$publicFolders_url = $2;
push(@PFU,$publicFolders_url);
$RETURN{publicFolders_url} = [ @PFU ];
}
} elsif ($user_want =~ m/^publicGroups_name$/i) {                                                          ############# SPECIAL
if ($_ =~ m/(\<item name=".*" url=")(.*)"\>(.*)(\<\/item\>)/img) {
$publicGroups_name = $3;
push(@PGN,$publicGroups_name);
$RETURN{publicGroups_name} = [ @PGN ];
}
} elsif ($user_want =~ m/^publicGroups_url$/i) {                                                          ############# SPECIAL
if ($_ =~ m/(\<item name=".*" url=")(.*)"\>(.*)(\<\/item\>)/img) {
$publicGroups_url = $2;
push(@PGU,$publicGroups_url);
$RETURN{publicGroups_url} = [ @PGU ];
}
}

}
}

close(OUTPUT);
return(%RETURN);

}

sub preview_xml {

($return,$user) = @_;
@empfangen = get("http://api.wua.la/preview/" . $user);

return(@empfangen);

}

sub search {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$searchstring,$to,$searchtype) = @_;
@empfangen = getstore("http://api.wua.la/search/" . $searchstring . '?from=0&to=' . $to . '&type=' . $searchtype,$tmpfile);

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {

if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$surl = $2;
push(@RETURN,$surl);
}

}
close(OUTPUT);
return(@RETURN);

}

sub search_xml {

($return,$searchstring,$to,$searchtype) = @_;
@empfangen = get("http://api.wua.la/search/" . $searchstring . '?from=0&to=' . $to . '&type=' . $searchtype);

return(@empfangen);

}


sub metadata {

($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$input_meta,$type,$key) = @_;

if (length($key) eq 0) {
@empfangen = getstore("http://api.wua.la/metadata/" . $input_meta,$tmpfile) || return(0);
} else {
@empfangen = getstore("http://api.wua.la/metadata/" . $input_meta . '?key=' . $key,$tmpfile) || return(0);
}

if ($type =~ m/user/i) {

undef(@RETURN);
open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {

if ($_ =~ m/(\<type\>)(\w*)(\<\/type\>)/img) {
$type = $2;
push(@RETURN,$type); }
if ($_ =~ m/(\<fullName\>)(\w*)(\<\/fullName\>)/img) {
$fullname = $2;
push(@RETURN,$fullname); }
if ($_ =~ m/(\<gender\>)(\w+)(\<\/gender\>)/img) {
$gender = $2;
push(@RETURN,$gender); }
if ($_ =~ m/(\<type\>)(\d*)(\<\/type\>)/img) {
$birthday = $2;
push(@RETURN,$birthday); }
if ($_ =~ m/(\<contact name="\w*"\>)(.*)(\<\/contact\>)/img) {
$contact = $2;
push(@RETURN,$contact); }
if ($_ =~ m/(\<countryCode\>)(\w*)(\<\/countryCode\>)/img) {
$cntry = $2;
push(@RETURN,$cntry); }
if ($_ =~ m/(\<proUser\>)(\w*)(\<\/proUser\>)/img) {
$proUser = $2;
push(@RETURN,$proUser); }
if($_ =~ m/(\<name\>)(\w*)(\<\/name\>)/img) {
$name = $2;
push(@RETURN,$name); }
if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$url = $2;
push(@RETURN,$url); }
if ($_ =~ m/(\<creator\>)(\w*)(\<\/creator\>)/img) {
$creator = $2;
push(@RETURN,$creator); }
if ($_ =~ m/(\<creationDate\>)(\d*)(\<\/creationDate\>)/img) {
$creationDate = $2;
push(@RETURN,$creationDate); }
if ($_ =~ m/(\<sizeString\>)(.*)(\<\/sizeString\>)/img) {
$sizeString = $2;
push(@RETURN,$sizeString); }
if ($_ =~ m/(\<description\>)(.*)(\<\/description\>)/img) {
$quote = $2;
push(@RETURN,$quote); }
if ($_ =~ m/(\<tag\>)(.*)(\<\/tag\>)/img) {
$tag = $2;
push(@RETURN,$tag); }
if ($_ =~ m/(\<views\>)(\d*)(\<\/views\>)/img) {
$views = $2;
push(@RETURN,$views); }
if ($_ =~ m/(\<links\>)(\d*)(\<\/links\>)/img) {
$links = $2;
push(@RETURN,$links); }
if ($_ =~ m/(\<favorites\>)(\d*)(\<\/favorites\>)/img) {
$favorites = $2;
push(@RETURN,$favorites); }
if ($_ =~ m/(\<comments\>)(\d*)(\<\/comments\>)/img) {
$comments = $2;
push(@RETURN,$comments); }
if ($_ =~ m/(\<familyFriendly\>)(\w*)(\<\/familyFriendly\>)/img) {
$familyFriendly = $2;
push(@RETURN,$familyFriendly); }

}

close(OUTPUT);
return(@RETURN);

} elsif ($type =~ m/file/i) {

undef(@RETURN);
open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {

if ($_ =~ m/(\<type\>)(\w*)(\<\/type\>)/img) {
$type = $2;
push(@RETURN,$type); }
if ($_ =~ m/(\<size\>)(\d*)(\<\/size\>)/img) {
$size = $2;
push(@RETURN,$size); }
if ($_ =~ m/(\<itemType\>)(\w*)(\<\/itemType\>)/img) {
$itemType = $2;
push(@RETURN,$itemType); }
if ($_ =~ m/(\<hash\>)(.*)(\<\/hash\>)/img) {
$hash = $2;
push(@RETURN,$hash); }
if ($_ =~ m/(\<name\>)(.*\..*)(\<\/name\>)/img) {
$size = $2;
push(@RETURN,$size); }
if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$url = $2;
push(@RETURN,$url); }
if ($_ =~ m/(\<creator\>)(\w*)(\<\/creator\>)/img) {
$creator = $2;
push(@RETURN,$creator); }
if ($_ =~ m/(\<creationDate\>)(\d*)(\<\/creationDate\>)/img) {
$creationDate = $2;
push(@RETURN,$creationDate); }
if ($_ =~ m/(\<firstPublishingDate\>)(\d*)(\<\/firstPublishingDate\>)/img) {
$firstPublishingDate = $2;
push(@RETURN,$firstPublishingDate); }
if ($_ =~ m/(\<sizeString\>)(.*)(\<\/sizeString\>)/img) {
$sizeString = $2;
push(@RETURN,$sizeString); }
if ($_ =~ m/(\<views\>)(\d*)(\<\/views\>)/img) {
$views = $2;
push(@RETURN,$views); }
if ($_ =~ m/(\<links\>)(\d*)(\<\/links\>)/img) {
$links = $2;
push(@RETURN,$links); }
if ($_ =~ m/(\<favorites\>)(\d*)(\<\/favorites\>)/img) {
$favorites = $2;
push(@RETURN,$favorites); }
if ($_ =~ m/(\<comments\>)(\d*)(\<\/comments\>)/img) {
$comments = $2;
push(@RETURN,$comments); }
if ($_ =~ m/(\<familyFriendly\>)(\w*)(\<\/familyFriendly\>)/img) {
$familyFriendly = $2;
push(@RETURN,$familyFriendly); }

}

close(OUTPUT);
return(@RETURN);

} elsif ($type =~ m/group/i) {

undef(@RETURN);
open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {

if ($_ =~ m/(\<type\>)(\w*)(\<\/type\>)/img) {
$type = $2;
push(@RETURN,$type); }
if ($_ =~ m/(\<members\>)(.*)(\<\/members\>)/img) {
$type = $2;
push(@RETURN,$type); }
if ($_ =~ m/(\<homepage\>)(.*)(\<\/homepage\>)/img) {
$homepage = $2;
push(@RETURN,$homepage); }
if ($_ =~ m/(\<name\>)(.*)(\<\/name\>)/img) {
$name = $2;
push(@RETURN,$name); }
if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$url = $2;
push(@RETURN,$url); }
if ($_ =~ m/(\<creator\>)(\w*)(\<\/creator\>)/img) {
$creator = $2;
push(@RETURN,$creator); }
if ($_ =~ m/(\<creationDate\>)(\d*)(\<\/creationDate\>)/img) {
$creationDate = $2;
push(@RETURN,$creationDate); }
if ($_ =~ m/(\<firstPublishingDate\>)(\d*)(\<\/firstPublishingDate\>)/img) {
$firstPublishingDate = $2;
push(@RETURN,$firstPublishingDate); }
if ($_ =~ m/(\<sizeString\>)(.*)(\<\/sizeString\>)/img) {
$sizeString = $2;
push(@RETURN,$sizeString); }
if ($_ =~ m/(\<description\>)(.*)(\<\/description\>)/img) {
$quote = $2;
push(@RETURN,$quote); }
if ($_ =~ m/(\<tag\>)(.*)(\<\/tag\>)/img) {
$tag = $2;
push(@RETURN,$tag); }
if ($_ =~ m/(\<views\>)(\d*)(\<\/views\>)/img) {
$views = $2;
push(@RETURN,$views); }
if ($_ =~ m/(\<links\>)(\d*)(\<\/links\>)/img) {
$links = $2;
push(@RETURN,$links); }
if ($_ =~ m/(\<favorites\>)(\d*)(\<\/favorites\>)/img) {
$favorites = $2;
push(@RETURN,$favorites); }
if ($_ =~ m/(\<comments\>)(\d*)(\<\/comments\>)/img) {
$comments = $2;
push(@RETURN,$comments); }
if ($_ =~ m/(\<familyFriendly\>)(\w*)(\<\/familyFriendly\>)/img) {
$familyFriendly = $2;
push(@RETURN,$familyFriendly); }

}

close(OUTPUT);
return(@RETURN);

} elsif ($type =~ m/folder/i) {

undef(@RETURN);
open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {

if ($_ =~ m/(\<type\>)(\w*)(\<\/type\>)/img) {
$type = $2;
push(@RETURN,$type); }
if ($_ =~ m/(\<modificationDate\>)(\d*)(\<\/modificationDate\>)/img) {
$type = $2;
push(@RETURN,$type); }
if ($_ =~ m/(\<name\>)(.*)(\<\/name\>)/img) {
$name = $2;
push(@RETURN,$name); }
if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$url = $2;
push(@RETURN,$url); }
if ($_ =~ m/(\<creator\>)(\w*)(\<\/creator\>)/img) {
$creator = $2;
push(@RETURN,$creator); }
if ($_ =~ m/(\<creationDate\>)(\d*)(\<\/creationDate\>)/img) {
$creationDate = $2;
push(@RETURN,$creationDate); }
if ($_ =~ m/(\<firstPublishingDate\>)(\d*)(\<\/firstPublishingDate\>)/img) {
$firstPublishingDate = $2;
push(@RETURN,$firstPublishingDate); }
if ($_ =~ m/(\<sizeString\>)(.*)(\<\/sizeString\>)/img) {
$sizeString = $2;
push(@RETURN,$sizeString); }
if ($_ =~ m/(\<description\>)(.*)(\<\/description\>)/img) {
$quote = $2;
push(@RETURN,$quote); }
if ($_ =~ m/(\<tag\>)(.*)(\<\/tag\>)/img) {
$tag = $2;
push(@RETURN,$tag); }
if ($_ =~ m/(\<views\>)(\d*)(\<\/views\>)/img) {
$views = $2;
push(@RETURN,$views); }
if ($_ =~ m/(\<links\>)(\d*)(\<\/links\>)/img) {
$links = $2;
push(@RETURN,$links); }
if ($_ =~ m/(\<favorites\>)(\d*)(\<\/favorites\>)/img) {
$favorites = $2;
push(@RETURN,$favorites); }
if ($_ =~ m/(\<comments\>)(\d*)(\<\/comments\>)/img) {
$comments = $2;
push(@RETURN,$comments); }
if ($_ =~ m/(\<familyFriendly\>)(\w*)(\<\/familyFriendly\>)/img) {
$familyFriendly = $2;
push(@RETURN,$familyFriendly); }

}

close(OUTPUT);
return(@RETURN);

} else { 
return(0);
}

}

sub metadata_xml {

($return,$metadata,$key) = @_;
if (length($key) eq 0) {
@empfangen = get("http://api.wua.la/metadata/" . $metadata) || return(0);
} else {
@empfangen = get("http://api.wua.la/metadata/" . $metadata . '?key=' . $key) || return(0);
}


return(@empfangen);

}

sub tops {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$typus,$to,$period) = @_;
@empfangen = getstore("http://api.wua.la/search/tops?type=" . $typus . "&from=0&to=" . $to . "&period=" .$period,$tmpfile) || return(0);

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$turl = $2;
push(@RETURN,$turl);
}
}

close(OUTPUT);
return(@RETURN);

}

sub tops_xml {

($return,$typus,$to,$period) = @_;
@empfangen = get("http://api.wua.la/search/tops?type=" . $typus . "&from=0&to=" . $to . "&period=" .$period);

return(@empfangen);

}

sub mostRecent {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$typus,$to) = @_;
@empfangen = getstore("http://api.wua.la/search/tops?type=" . $typus . "&from=0&to=" . $to,$tmpfile) || return(0);

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
if ($_ =~ m/(\<url\>)(.*)(\<\/url\>)/img) {
$mrurl = $2;
push(@RETURN,$mrurl);
}
}

close(OUTPUT);
return(@RETURN);

}

sub mostRecent_xml {

($return,$typus,$to) = @_;
@empfangen = get("http://api.wua.la/search/mostRecent?type=" . $typus . "&from=0&to=" . $to);

return(@empfangen);

}

sub breadcrumb {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$bread,$key) = @_;

if (length($key) eq 0) {
@empfangen = getstore("http://api.wua.la/breadcrumb/" . $bread,$tmpfile) || return(0);
} else {
@empfangen = getstore("http://api.wua.la/breadcrumb/" . $bread . '?key=' . $key,$tmpfile) || return(0);
}

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
if ($_ =~ m/(\<item id="\d*" url=")(.*)("\>.*\<\/item\>)/img) {
$burl = $2;
push(@RETURN,$burl);
}
}

close(OUTPUT);
return(@RETURN);

}

sub breadcrumb_xml {

($return,$bread,$key) = @_;

if (length($key) eq 0) {
@empfangen = get("http://api.wua.la/breadcrumb/" . $bread);
} else {
@empfangen = get("http://api.wua.la/breadcrumb/" . $bread . '?key=' . $key);
}

return(@empfangen);

}

sub publicFiles {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$publicfiles,$key) = @_;

if (length($key) eq 0) {
@empfangen = getstore("http://api.wua.la/publicFiles/" . $publicfiles,$tmpfile);
} else {
@empfangen = getstore("http://api.wua.la/publicFiles/" . $publicfiles . '?key=' . $key,$tmpfile);
}

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
if ($_ =~ m/(\<item modificationDate="\d*" name=".*" size="\d*" url=")(.*)("\>.*\<\/item\>)/img) {
$pfurl = $2;
push(@RETURN,$pfurl);
}
}

close(OUTPUT);
return(@RETURN);

}

sub publicFiles_xml {

($return,$publicfiles,$key) = @_;

if (length($key) eq 0) {
@empfangen = get("http://api.wua.la/publicFiles/" . $publicfiles);
} else {
@empfangen = get("http://api.wua.la/publicFiles/" . $publicfiles . '?key=' . $key);
}

return(@empfangen);

}

sub publicFolders {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$publicfolders,$key) = @_;

if (length($key) eq 0) {
@empfangen = getstore("http://api.wua.la/publicFolders/" . $publicfolders,$tmpfile);
} else {
@empfangen = getstore("http://api.wua.la/publicFolders/" . $publicfolders . '?key=' . $key,$tmpfile);
}

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
if ($_ =~ m/(\<item isEmpty="\w*" modificationDate="\d*" name=".*" url=")(.*)("\>.*\<\/item\>)/img) {
$pfourl = $2;
push(@RETURN,$pfourl);
}
}

close(OUTPUT);
return(@RETURN);

}

sub publicFolders_xml {

($return,$publicfolders,$key) = @_;

if (length($key) eq 0) {
@empfangen = get("http://api.wua.la/publicFolders/" . $publicfolders);
} else {
@empfangen = get("http://api.wua.la/publicFolders/" . $publicfolders . '?key=' . $key);
}

return(@empfangen);

}

sub publicGroups {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$publicgroups) = @_;
@empfangen = getstore("http://api.wua.la/publicGroups/" . $publicgroups,$tmpfile);

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
if ($_ =~ m/(\<item name=".*" url=")(.*)("\>.*\<\/item\>)/img) {
$pgurl = $2;
push(@RETURN,$pgurl);
}
}

close(OUTPUT);
return(@RETURN);

}

sub publicGroups_xml {

($return,$publicgroups,$key) = @_;

if (length($key) eq 0) {
@empfangen = get("http://api.wua.la/publicGroups/" . $publicgroups);
} else {
@empfangen = get("http://api.wua.la/publicGroups/" . $publicgroups . '?key=' . $key);
}

return(@empfangen);

}

sub comments {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$comments,$to,$key) = @_;

if (length($key) eq 0) {
@empfangen = getstore("http://api.wua.la/comments/" . $comments . '?from=0&to=' . $to,$tmpfile);
} else {
@empfangen = getstore("http://api.wua.la/comments/" . $comments . '?from=0&to=' . $to . '?key=' . $key,$tmpfile);
}

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {

if ($_ =~ m/(\<author\>)(.*)(\<\/author\>)/img) {
$author = $2;
push(@RETURN,$author);
} elsif ($_ =~ m/(\<timestamp\>)(\d*)(\<\/timestamp\>)/img) {
$timestamp = $2;
push(@RETURN,$timestamp);
} elsif ($_ =~ m/(\<content\>)(.*)(\<\/content\>)/img) {
$timestamp = $2;
push(@RETURN,$timestamp);
}

}

close(OUTPUT);
return(@RETURN);

}

sub comments_xml {

($return,$comments,$to,$key) = @_;

if (length($key) eq 0) {
@empfangen = get("http://api.wua.la/comments/" . $comments . '?from=0&to=' . $to);
} else {
@empfangen = get("http://api.wua.la/comments/" . $comments . '?from=0&to=' . $to . '?key=' . $key);
}

return(@empfangen);

}

sub commentCount {

undef(@RETURN);
($fh, $tmpfile) = tempfile(X x 23, UNLINK => 1);
($return,$commentcount,$key) = @_;

if (length($key) eq 0) {
@empfangen = getstore("http://api.wua.la/commentCount/" . $commentcount,$tmpfile);
} else {
@empfangen = getstore("http://api.wua.la/commentCount/" . $commentcount . '?key=' . $key,$tmpfile);
}

open(OUTPUT,"<",$tmpfile);
while (<OUTPUT>) {
if ($_ =~ m/(\<commentCount\>)(\d*)(\<\/commentCount\>)/img) {
$cc = $2;
push(@RETURN,$cc);
}
}

close(OUTPUT);
return(@RETURN);

}

sub commentCount_xml {

($return,$commentcount,$key) = @_;

if (length($key) eq 0) {
@empfangen = get("http://api.wua.la/commentCount/" . $commentcount);
} else {
@empfangen = get("http://api.wua.la/commentCount/" . $commentcount . '?key=' . $key);
}

return(@empfangen);

}

sub wualaFilescounter {
@empfangen = get("http://www.wuala.com/") || return(0);

foreach $ligne (@empfangen) {
if ($ligne =~ m/\<span class="red" id="fileticker"\>(.*)\<\/span\>/i) {
$wualaFilescounter = $1;
return($wualaFilescounter);
}
}

}


1;
__END__

=head1 NAME

Wuala - Interface to the Wuala API


=head1 SYNOPSIS

    use WWW::Wuala;
	
  $wu = WWW::Wuala->new();
  
  $counter = $wu->wualaFilescounter();
  print $counter . "\n";

  @search = $wu->search('Wuala',5,1);
  foreach $pr (@search) {
  print $pr . "\n";
  }

  $wu->server(1) || die "wtf";
  chomp($fname = <STDIN>);
  $wu->download('Perforin/Images/WUALA3.JPG',$fname) || die "wtf";

  #$wu->preview_xml("Perforin"); 

  %prev = $wu->preview("Perforin");
  print "@{ $prev{name} }\n"; # Show only the Name
  print "@{ $prev{publicGroups_name} }\n"; # Show only the public group names
  for $all ( keys %prev ) { print "@{ $prev{$all} }\n"; } # Show everything

  
=head1 DESCRIPTION

Wuala is a free social online storage which allows its users to securely store,
backup, and access files from anywhere and to share files easily with friends,
groups, and the world.

This moduls allows you to interact with the Wuala API.

Supported API calls:

download
preview
search
metadata
tops
mostRecent
breadcrumb
publicFiles
publicFolders
publicGroups
commentCount
comments

Extra:

wualaFilescounter


=head1 METHODS

___Downloading:

There are at the moment 6 Server from which you can download content.
I let you decide which one you want to use! If you don´t specifie one
the module will take the first server. Changing the Server MAY increase
the download speed.

$wu->server(2) || die "wtf";
chomp($fname = <STDIN>);
$wu->download('Perforin/Images/WUALA3.JPG',$fname) || die "wtf";

You can also download password protected content!

$wu->server(2) || die "wtf";
chomp($fname = <STDIN>);
$wu->download('Perforin/verysecretandprotectedfolder/lulz.PNG',$fname,'KEY') || die "wtf";


___Preview:

%prev = $wu->preview("Perforin");
for $all ( keys %prev ) {
print "@{ $prev{$all} }\n";
}

This example will show us, all of the preview information.
But we can specifie what exactly we want!

@arguments = qw(name url tag);

%prev = $wu->preview("Perforin",@arguments);
for $all ( keys %prev ) {
print "@{ $prev{$all} }\n";
}

OR

@arguments = qw(name url tag);

%prev = $wu->preview("Perforin",@arguments); # OR %prev = $wu->preview("Perforin");
print "@{ $prev{name} }\n"; # Show only the name
print "@{ $prev{url} }\n";  # Show only the url
print "@{ $prev{tag} }\n";  # Show only the tags


Here is the list of all possible values:

type fullname gender birthday contact countrycode prouser name url
creator creationdate sizestring description tag views links favorites comments
familyfriendly publicFolders_name publicFolders_url publicGroups_name publicGroups_url


___Top Items list:

@top = $wu->tops(6,3,4); # Typus To Period
foreach $la (@top) {
print $la . "\n";
}

Well, this here looks a bit confusing but here is the explanation:

The first number stands for the _type_.
Here you got 6 possibilities.
0 Images
1 Videos
2 Music
3 Documents
4 Other file types
5 Users
6 Groups

Then there comes _To_.
This is just a number higher or equal than 1 which indicate the number of Top
Items you want to be showed.

And finaly there is the _Period_.
This one defindes the time period. The following values are possible:
0 Day
1 Week
2 Month
3 Year
4 All Time

In this example, we get 3 top Group Items of all time. Not this hard? :-)


___Metadata:

@res = $wu->metadata('Wuala/Buttons',folder);
foreach $lol (@res) {
print $lol . "\n";
}

This will show you the Metadata of a folder.
The second argument can be changed to:
user
file
group
folder


___mostRecent:

@mr = $wu->mostRecent(1,10); # Typus To
foreach $ma (@mr) {
print $ma . "\n";
}

The first number stands for the _type_.
Here you got 6 possibilities.
0 Images
1 Videos
2 Music
3 Documents
4 Other file types
5 Users
6 Groups

Then there comes _To_.
This is just a number higher or equal than 1 which indicate the number of 
Items you want to be showed.


___Search:

@search = $wu->search('Wuala',5,1);
foreach $pr (@search) {
print $pr . "\n";
}

The first value is your searchstring.

The second is just a number higher or equal than 1 which indicate the number of 
results you want to be showed.

The last value is the search type!
The possible values are:
0 Images
1 Videos
2 Music
3 Documents
4 Other file types
5 Users
6 Groups



And so on and so on. It continues like this ;)
At least I´ll give you a list where you can use a password:

download
preview
metadata
breadcrumb
publicFiles
publicFolgers
comments
commentCount

___XML:

All of those API calls can also be called by putting an _xml behind.
This will give you the XML File send by the Wuala server.

$wu->preview_xml();
$wu->publicFiles_xml();

And so on and so on...

___wualaFilescounter:

Returns the number shown on the Wuala Webpage.


=head1 MORE

If there is something unclear on how to use this Module, let me know

admin[At]virii[d0t]lu

or check out the source of the module or, get you a copy of the API documentation
=> http://www.wuala.com/Wuala%20API/Documentation/documentation.pdf


=head1 AUTHOR

Perforin <admin[AT]virii[d0t]lu>.

=head1 GREETINGS

MereX
Neo2k8
Sph1nX
Rayden
double_check
sollniss
the_janky
zeco
katsumi
SkyOut

EOF-Project
vx.netlux.org
vxnet.ws

For all those I forgot to greet, I´m sorry :-P


=head1 COPYRIGHT

http://creativecommons.org/licenses/by-sa/3.0/lu/deed.de

Creative Commons

Attribution-Share Alike 3.0 Luxembourg

To Share — To copy, distribute, display, and perform the work
To Remix — To make derivative works

Under the following conditions:

Attribution.
You must attribute the work in the manner specified by the author or licensor
(but not in any way that suggests that they endorse you or your use of the work). 

Share Alike.
If you alter, transform, or build upon this work, you may distribute the resulting
work only under the same, similar or a compatible license. 
For any reuse or distribution, you must make clear to others the license terms of this work.
The best way to do this is with a link to this web page.
Any of the above conditions can be waived if you get permission from the copyright holder.
Nothing in this license impairs or restricts the author's moral rights.

=cut