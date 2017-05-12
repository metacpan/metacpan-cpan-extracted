# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Web::Scaffold;
*file2text = \&Web::Scaffold::file2text;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep($_ ne '.' && $_ ne '..', readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
}

my $dir = './tmp';
mkdir $dir,0755;

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

sub gotexp {
  my($got,$exp) = @_;
  if ($exp =~ /\D/) {
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
  } else {
    print "got: $got, exp: $exp\nnot "
        unless $got == $exp;
  }
  &ok;
}

################################################################
################################################################

my $pages = {
	TEST	=> 'null',
};

my $htmltext = q|Gotta line up the LINK's for inspection.
Here are all the varients for LINK's:

This is LINK with page only LINK<%TEST> no trailing separator,
LINK with          trailing LINK<#TEST#> separator,
LINK with         link text LINK<%TEST%some link text> no trailing separator,
then LINK with    link text LINK<#TEST#more link text#> and trailing separator,
then LINK with 
         link text + status LINK<&TEST&link text&status text> no
separator, then LINK 
with          link + status LINK<&TEST&link text&status text&>
separator, then LINK without 
link but        with status LINK<#TEST##status text>
but no separator, then LINK without 
link        but with status LINK<#TEST##status text#> and trailing separator.

Next do the same for URL's:

This is LINK  with file URL only LINK<#./path/name>,
LINK with               file URL LINK<#./path/name#> and separator,
followed by file URL + link text LINK<#./path/name#path text> then
file             URL + link text LINK<#./path/name#path text#> with separator,
then file    URL + link + status LINK<#./file/path/name#path text#and status>
with no separator. 

If all this works, try a couple of long URL's:

This is LINK with    web URL LINK<!http://www.somewhere.com/> no separator,
LINK with            web URL LINK<!http://www.somewhere.com/!> with separator,
LINK with web URL + url text LINK<!http://www.somewhere.com/!SOMEWHERE>
LINK with web URL + url text + status 
                             LINK<!http://www.somewhere.com/!SOMEWHERE!somewhere good>, all done!
|;

## test 2
my $page = $dir .'/test.page';
unless (open F, '>'. $page) {
  print "Bail out! could not open '$page'\nnot ";
}
&ok;

print F $htmltext;
close F;

my $exp = q|Gotta line up the LINK's for inspection.
Here are all the varients for LINK's:

This is LINK with page only <a class="B" title="TEST" onMouseOver="self.status='TEST';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">TEST</a> no trailing separator,
LINK with          trailing <a class="B" title="TEST" onMouseOver="self.status='TEST';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">TEST</a> separator,
LINK with         link text <a class="B" title="some link text" onMouseOver="self.status='some link text';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">some link text</a> no trailing separator,
then LINK with    link text <a class="B" title="more link text" onMouseOver="self.status='more link text';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">more link text</a> and trailing separator,
then LINK with 
         link text + status <a class="B" title="status text" onMouseOver="self.status='status text';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">link text</a> no
separator, then LINK 
with          link + status <a class="B" title="status text" onMouseOver="self.status='status text';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">link text</a>
separator, then LINK without 
link but        with status <a class="B" title="status text" onMouseOver="self.status='status text';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">TEST</a>
but no separator, then LINK without 
link        but with status <a class="B" title="status text" onMouseOver="self.status='status text';return true;" onMouseOut="self.status='';return true;" onClick="return(npg('TEST'));" href="./">TEST</a> and trailing separator.

Next do the same for URL's:

This is LINK  with file URL only <a class="B" title="./path/name" onMouseOver="self.status='./path/name';return true;" onMouseOut="self.status='';return true;" href="./path/name">./path/name</a>,
LINK with               file URL <a class="B" title="./path/name" onMouseOver="self.status='./path/name';return true;" onMouseOut="self.status='';return true;" href="./path/name">./path/name</a> and separator,
followed by file URL + link text <a class="B" title="path text" onMouseOver="self.status='path text';return true;" onMouseOut="self.status='';return true;" href="./path/name">path text</a> then
file             URL + link text <a class="B" title="path text" onMouseOver="self.status='path text';return true;" onMouseOut="self.status='';return true;" href="./path/name">path text</a> with separator,
then file    URL + link + status <a class="B" title="and status" onMouseOver="self.status='and status';return true;" onMouseOut="self.status='';return true;" href="./file/path/name">path text</a>
with no separator. 

If all this works, try a couple of long URL's:

This is LINK with    web URL <a class="B" title="http://www.somewhere.com/" onMouseOver="self.status='http://www.somewhere.com/';return true;" onMouseOut="self.status='';return true;" href="http://www.somewhere.com/">http://www.somewhere.com/</a> no separator,
LINK with            web URL <a class="B" title="http://www.somewhere.com/" onMouseOver="self.status='http://www.somewhere.com/';return true;" onMouseOut="self.status='';return true;" href="http://www.somewhere.com/">http://www.somewhere.com/</a> with separator,
LINK with web URL + url text <a class="B" title="SOMEWHERE" onMouseOver="self.status='SOMEWHERE';return true;" onMouseOut="self.status='';return true;" href="http://www.somewhere.com/">SOMEWHERE</a>
LINK with web URL + url text + status 
                             <a class="B" title="somewhere good" onMouseOver="self.status='somewhere good';return true;" onMouseOut="self.status='';return true;" href="http://www.somewhere.com/">SOMEWHERE</a>, all done!
|;

## test 3
my $got = file2text($pages,$page);
gotexp($got,$exp);
