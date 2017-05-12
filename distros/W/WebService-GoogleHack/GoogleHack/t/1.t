# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

##################################################################
# This testing method was based on the testing method that	 #
# Aaron Straup Cope, the author of Net::Google had implemented   #
# The basic idea belongs to the above mentioned author.          # 
##################################################################


use constant TMPFILE => "../Datafiles/initconfig.txt";

use Test::More tests => 2;
BEGIN { use_ok('WebService::GoogleHack') };

#########################

$ans='n';
$correction="";
	
#Trying to make sure that i get the right key

while (($ans ne "y") && ($ans ne "yes") )
{
$flag="false";

diag("\n".
     "The Google API web service requires that you provide create a Google Account and obtain a license key\n".
     "This key is then passed with each request you make to the Google servers.\n".
     "If you do not already have a Google Account, you can sign up for one here:\n".
     "http://www.google.com/apis/\n".
     "\n");

diag("\n"."Please Enter your Google API key here:\n");

$key = <STDIN>;
chomp $key;
#print $key;


diag("\n".     "The Google-API Key you Entered is $key, Thanks".
     "\n");


diag("\n".     "Please Enter the Entire Path to the wsdl File, \n EG, /home/public/GoogleSearch.wsdl".
     "\n");

$wsdl = <STDIN>;
chomp $wsdl;
diag("\n".     "This is the path to the WSDL file: $wsdl, Thanks".
     "\n");

diag("\n".     "Please Enter path to the directory in which the untarred GoogleHack resides , \n EG, /home/username/WebService/GoogleHack/".
     "\n");

$basedir = <STDIN>;
chomp $basedir;
diag("\n".     "This is the path to the Google Hack directory: $basedir, Thanks".
     "\n");

diag("\n".     "Please Enter path to the directory in which the  Brill Tagger executable, \n EG, /home/username/RULE_BASED_TAGGER_V1.14/Bin_and_Data/".
     "\n");

$tagger = <STDIN>;
chomp $tagger;
diag("\n".     "This is the path to the tagger executable: $tagger, Thanks".
     "\n");


diag("\n".     "Is the above information accurate y-yes, n-no".
     "\n");

$ans = <STDIN>;
chomp $ans;

$ans=lc($ans);

if($ans eq 'y' || $ans eq "yes")
{

open(WSDL,"$wsdl") || die("\n\n\n\nIllegal WSDL File Location - $wsdl\n\n\n\n");

close(WSDL) ;

my $google = new WebService::GoogleHack;
  
#isa_ok($google,"GoogleHack");

$google->init("$key","$wsdl");

$google->Search("duluth");

$correction= $google->phraseSpelling("dulut");

diag("\n".     "The Suggested spelling for dulut is $correction".
     "\n");

is($correction,"duluth");

if($correction eq "No Spelling Suggested")
{
$flag="true";
print "\n\n\n Incorrect Key \n\n\n\n";
}

if($flag ne "true")
{
$temp="GoogleHack

basedir::$basedir     # Give path to base dir in which googlehack is installed

taggerdir::$tagger		    # Give path to the directory in which the brill tagger resides

key::$key  	#give key to google access

wsdl::$wsdl	#give path to wsdl file";

$config="Datafiles\/initconfig.txt";
diag("\n\n The file name is $config \n\n");

open(DAT,">$config") || die("Cannot Open File to write");

print DAT $temp;

close(DAT);

diag("\n".     "$temp".
     "\n");
}


}

else
{
next;
}

}


print "\nThe correction is $correction\n";

#ok($correction eq "duluth", 1 );











