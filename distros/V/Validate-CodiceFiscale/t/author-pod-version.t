
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use Test::More tests => 1;

my $module = 'Validate::CodiceFiscale';

(my $packfile = "$module.pm") =~ s{::}{/}gmxs;
require $packfile;

(my $filename = $INC{$packfile}) =~ s{pm$}{pod};

my $pod_version;
{
   open my $fh, '<', $filename
     or BAIL_OUT "can't open '$filename'";
   binmode $fh, ':raw';
   local $/;
   my $module_text = <$fh>;
   ($pod_version) = $module_text =~ m{
      ^This\ document\ describes\ $module\ version\ (.*?)\.$
   }mxs;
}

my $version;
{
   no strict 'refs';
   $version = ${$module . '::VERSION'};
}

is $pod_version, $version, 'version in POD';
