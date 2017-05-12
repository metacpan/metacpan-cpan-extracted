# $Id: 0_config.t,v 1.1.1.1 2002/06/14 20:39:50 grantm Exp $

use Test::More tests => 1;

use strict;
use File::Spec;

eval {
  # Build up a list of installed modules

  my @mod_list = qw(
    XML::SAX XML::SAX::Writer XML::SAX::Machines XML::NamespaceSupport
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

  printf STDERR "\r%-30s %s\n", 'Package', 'Version';
  foreach my $module (@mod_list) {
    $version{$module} = 'Not Installed' unless(defined($version{$module}));
    $version{$module} .= " (default parser)" if($module eq $default_parser);
    printf STDERR " %-30s %s\n", $module, $version{$module};
  }

};

ok(1);
