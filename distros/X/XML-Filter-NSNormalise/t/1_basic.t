# $Id: 1_basic.t,v 1.3 2002/10/11 02:00:46 grantm Exp $
##############################################################################
# Very basic tests that do not rely on XML::SAX being installed correctly.
#

use strict;
use Test::More tests => 6;

$^W = 1;


##############################################################################
# Print out a list of installed modules and their version numbers
#

eval {

  my @mod_list = qw(
    XML::SAX XML::SAX::Writer XML::NamespaceSupport
  );


  # If XML::SAX is installed, add a list of installed SAX parsers

  eval { require XML::SAX; };
  my $default_parser = '';
  unless($@) {
    push @mod_list, map { $_->{Name} } @{XML::SAX->parsers()};
    $default_parser = ref(XML::SAX::ParserFactory->parser());
  }


  # Extract the version number from each module

  my(%version);
  foreach my $module (@mod_list) {
    eval " require $module; ";
    unless($@) {
      no strict 'refs';
      $version{$module} = ${$module . '::VERSION'} || "Unknown";
    }
  }


  # Add version number of the Perl binary

  eval ' use Config; $version{perl} = $Config{version} ';  # Should never fail
  if($@) {
    $version{perl} = $];
  }
  unshift @mod_list, 'perl';


  # Print details of installed modules on STDERR

  diag(sprintf("\r%-30s %s", 'Package', 'Version'));
  foreach my $module (@mod_list) {
    $version{$module} = 'Not Installed' unless(defined($version{$module}));
    $version{$module} .= " (default parser)" if($module eq $default_parser);
    printf STDERR " %-30s %s\n", $module, $version{$module};
  }

};


##############################################################################
# Confirm that the module compiles

use XML::Filter::NSNormalise

ok(1, 'XML::Filter::NSNormalise compiled OK');


##############################################################################
# Try creating a filter object.
#

my $filter = XML::Filter::NSNormalise->new(
  Map => {
    'http://purl.org/dc/elements/1.1/' => 'dc',
    'http://purl.org/rss/1.0/modules/syndication/' => 'syn'
  }
);

ok(ref($filter), 'Created a filter object');
isa_ok($filter, 'XML::Filter::NSNormalise');
isa_ok($filter, 'XML::SAX::Base');


##############################################################################
# Try specifying an invalid mapping.
#

$filter = eval {
  XML::Filter::NSNormalise->new(
    Map => {
      'http://purl.org/dc/elements/1.1/' => 'dc',
      'http://purl.org/rss/1.0/modules/syndication/' => 'dc'
    }
  );
};

like($@, qr/Multiple URIs mapped to prefix 'dc'/, "Caught many to one mapping");


##############################################################################
# Try specifying no mapping.
#

$filter = eval {
  XML::Filter::NSNormalise->new();
};

like($@, qr/No 'Map' option in call to XML::Filter::NSNormalise->new/,
  "Caught missing 'Map' option");

