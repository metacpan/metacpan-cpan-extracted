package import;
# I have chosen a lowercase name, as the intent is a pragma

# SCCS INFO: @(#) import.pm 1.01 99/10/10
#  RCS INFO: $Id: import.pm,v 1.01 1999/10/10 mak Exp $
#
# Copyright (C) 1997,1998 Michael King (mike808@mo.net)
# Saint Louis, MO USA.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

import - import all modules with a package prefix, aliasing it away.

'import' acts as a pragma that performs a 'use' on all modules that can be 
found with the given package prefix. Any modules found have a 'use' statement 
performed, and the fully qualified package name is aliased to one without the 
given prefix. The functionality is similar to Java's 'import' statement.

See import.pod for details.

=head1 HISTORY

 import.pm
 v1.01 10/10/99 mak

=head1 COPYRIGHT

 Copyright (C) 1999 Michael King ( mike808@mo.net )
 Saint Louis, MO USA.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This module is copyright (c) 1997,1998 by Michael King ( mike808@mo.net ) and is
made available to the Perl public under terms of the Artistic License used to
cover Perl itself. See the file Artistic in the distribution  of Perl 5.002 or
later for details of copy and distribution terms.

=head1 AVAILABILITY

The latest version of this module is likely to be available from:

 http://walden.mo.net/~mike808/import_pm

The best place to discuss this code is via email with the author.

=cut

# --- END OF PAGE ---.#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;

# CORE module usage
use Carp;
use DirHandle;

# Declare our own version
$import::VERSION = 1.01;
sub VERSION { $import::VERSION };

# Use a custom import
sub import {
  my $selfpkg = shift;
  my $callpkg = caller;
  my @dir = @_;
  foreach my $pkg (@dir) {
    my $dir = $pkg;
    $dir =~ s|::|/|g;      # Convert :: to /
    $dir =~ s{(^/|/$)}{}g; # Strip leading trailing slashes

    my %PKG; # Holds lists of modules found keyed to their package name
    my @PKG; # Preserves the order of packages inserted into %PKG

    # Look in each of the @INC dirs
    foreach my $inc_dir (@INC) {
      my $dirpath = "$inc_dir/$dir";

      # Try for a module file first
      my $pm = "${dirpath}.pm";
      if ( -f $pm ) {               # Found a module file!
        $pm =~ s|.*/||;             # strip path prefix
        $pm =~ s|\.pm$||;           # strip .pm suffix

        # Save the module
        %PKG = (                    # Assign the package list
          $inc_dir => [ $pm ],      # %PKG holds array refs
        );
        @PKG = ( $inc_dir );        # Preserve order in %PKG
        $dir =~ s|/$pm$||;          # Drop our package name portion
        last;                       # We're done since we found a module
      }

      next unless -d $dirpath;      # Found a directory!

      # Get ready to read it
      my $dh = DirHandle->new($dirpath)
        or croak "Could not opendir '$dirpath': $!";

      # Grab all the .pms
      my @pm = sort                  # sort them
        grep { -f }                  # only plain files
        map { "$dirpath/$_" }        # full path
        grep { !/^\./ }              # filter out dot files
        grep { /\.pm$/ }             # filter in pm files
        $dh->read;                   # read all entries in the dir
        
      map { s|^$dirpath/|| } @pm;    # strip dirpath prefix
      map { s|\.pm$|| } @pm;         # strip .pm suffix

      # Save the list
      $PKG{$inc_dir} = \@pm;
      push @PKG, $inc_dir;           # Preserve order in %PKG
    }

    # Alias the symbol tables
    foreach (@PKG) {
      foreach my $alias (@{$PKG{$_}}) {
        my $fq_pkg = $dir . "/" . $alias . ".pm";
        # Do a 'use' - dups are ignored by require so we don't have to
        require $fq_pkg && $fq_pkg->import();
        no strict qw( refs );
        *{$alias . "::"} = *{$pkg . "::" . $alias . "::"};
      }
    }
  }
  # Kaboom!

  # Hunt ourselves down in the %INC - we are a pragma
  foreach my $key (sort keys %INC) {
	  next unless $key =~ m|/?${selfpkg}.pm$|;
  	$INC{$key} =~ m|/?${selfpkg}.pm$|;
  	my $self = $`;
  	use Cwd qw();
  	if ($self) {
  		$self = Cwd::cwd() . "/" . $self unless $self =~ m/^\//;
  	} else {
  		$self = Cwd::cwd();
  	}
  	delete $INC{$key}; # Remove ourselves from the %INC
  	last;
  }
}

1;
