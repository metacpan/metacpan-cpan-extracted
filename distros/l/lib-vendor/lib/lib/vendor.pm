use v5.10;

package lib::vendor;
# ABSTRACT: add vendor libraries to the module search path (@INC)
our $VERSION = '0.14.163'; # VERSION

use strict;

use FindBin     ();
use File::Spec  ();

# File layout could be:
# .
# +- bin
# +- lib
# +- vendor
# +- ...
#
# Or:
#
# .
# +- lib
# +- vendor
# +- ...

our $APPDIR;
BEGIN {
    if ( not $APPDIR ) {
        $APPDIR = $FindBin::RealBin;
        while ( $APPDIR ne '/' && !-d File::Spec->catdir( $APPDIR, 'lib' ) ) {
            # Search upwards in the directory structure
            # until we find a subdirectory named 'lib'.
            my @appdir = File::Spec->splitdir($APPDIR);
            pop @appdir;
            $APPDIR = File::Spec->catdir(@appdir);
        }
    }
}

our $VENDOR //= 'vendor';
sub import {
    my ( $package, @vendors ) = @_;

    if ( @vendors ) {
        if ( defined $vendors[0] && $vendors[0] eq '-vendor' ) {
            ( undef, my $vendor, @vendors ) = @vendors;
            $VENDOR = $vendor if defined $vendor;
        }

        for my $vendor (@vendors) {
            $vendor = File::Spec->catdir( $APPDIR, $VENDOR, $vendor, 'lib' );
        }
    }
    unshift @vendors, File::Spec->catdir( $APPDIR, "lib" );

    shrink_INC(@vendors);
}

sub shrink_INC {
    local $_;
    my %seen = ();
    @INC = grep {
        my $key;
        if ( ref($_) ) {
            # If it's a ref, key on the memory address.
            $key = int $_;
        } elsif ( $^O ne 'MSWin32' and my ($dev, $inode) = stat($_) ) {
            # If it's on the filesystem, key on the combo of dev and inode,
            # which is not valid on MSWin32.
            $key = join( _ => $dev, $inode );
        } else {
            # Otherwise, key on the element.
            $key = $_;
        }
        $key && !$seen{$key}++;
    } @_, @INC;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::vendor - add vendor libraries to the module search path (@INC)

=head1 VERSION

version 0.14.163

=head1 SYNOPSIS

  # Include only $FindBin::RealBin/../lib in module search path (@INC).
  use lib::vendor;

or

  # Include in module search path (@INC):
  # $FindBin::RealBin/../lib,
  # $FindBin::RealBin/../vendor/core/lib 
  use lib::vendor qw(core);

or

  # Include in module search path (@INC):
  # $FindBin::RealBin/../lib,
  # $FindBin::RealBin/../vendor/core/lib,
  # $FindBin::RealBin/../vendor/common/lib,
  # $FindBin::RealBin/../vendor/mongodb/lib,
  # $FindBin::RealBin/../vendor/rabbitmq/lib
  use lib::vendor qw(core common mongodb rabbitmq);

or

  # Do nothing
  use lib::vendor ();

=head1 DESCRIPTION

Locates the full path to the script home and adds its lib directory to the
library search path, plus any vendor library directories specified.

The script home is the directory closest to the original script which has
a C<lib> subdirectory.  It first searches the directory that the script
was executed from, then upwards until it finds a directory containing a
C<lib> subdirectory.

There is an optional configuration value of C<-vendor>, which will configure
what the vendor directory is.

  use lib::vendor -vendor => 'include', qw( this that );
  # Include in module search path (@INC):
  # $FindBin::RealBin/../lib,
  # $FindBin::RealBin/../include/this,
  # $FindBin::RealBin/../include/that

  use lib::vendor -vendor => '', qw( this that );
  # Include in module search path (@INC):
  # $FindBin::RealBin/../lib,
  # $FindBin::RealBin/../this,
  # $FindBin::RealBin/../that

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/rkleemann/lib-vendor/issues or by email to
bug-lib-vendor@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib>, L<mylib>, L<FindBin>

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
