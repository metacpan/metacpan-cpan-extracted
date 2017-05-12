use ExtUtils::MakeMaker;
use Config;

my $pkg = 'Web::Scaffold';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';

# this is for the example web site
# comment it out if it bothers you
chmod 0777, 'example_website/ws_sitemap';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %makeparms = (
    NAME		=> $pkg,
    VERSION_FROM	=> $module, # finds $VERSION
    clean		=> { FILES    => "*~ tmp* example_website/pages/manpage.c1 example_website/pages/pages.c2 example_website/pages/specs.c2"},
    dist		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
    
);

# if html conversion has been removed in this perl version then work around here
#
sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s|(pure_all\s+::.+)|$1 README example_website/pages/manpage.c1|;
  $inherited;
}

sub MY::post_constants {
  my $post_constants = q|
MY_ITEM_EXTRACT = ./item_extract
MY_POD2HTML = |. $Config{scriptdirexp} .'/pod2html' .q|
MY_POD2TEXT = |. $Config{scriptdirexp} .'/pod2text' .q|   
|;
} 

sub MY::postamble {
  package MY;
  my $postamble = q|
README  : |. $module .q|
	@$(MY_POD2TEXT) |. $module .q| > README

example_website/pages/manpage.c1 :|. $module .q|
	@$(MY_POD2HTML) |. $module .q| > example_website/pages/manpage.c1
	@$(MY_ITEM_EXTRACT) example_website/pages/manpage.c1 specs > example_website/pages/specs.c2
	@$(MY_ITEM_EXTRACT) example_website/pages/manpage.c1 pages > example_website/pages/pages.c2
|;
}

WriteMakefile(%makeparms);
