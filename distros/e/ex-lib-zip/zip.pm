package ex::lib::zip;

use 5.007001;
use strict;
use warnings;

use XSLoader ();
use PerlIO::gzip 0.07;
use PerlIO::subfile 0.02; # Now passing a UV arg

our $VERSION = '0.04';
our @ORIG_INC = @INC;	# take a handy copy of 'original' value

XSLoader::load "ex::lib::zip", $VERSION;

sub import {
  my $package = shift;

  my %names;
  foreach (reverse @_) {
    if ($_ eq '') {
      require Carp;
      Carp::carp("Empty compile time value given to use lib::zip");
    }
    if (-e && ! -f _) {
      require Carp;
      Carp::carp("Parameter to use lib::zip must be file, not directory");
    }
    unshift(@INC, new ($package, $_));
  }

  # Add any previous version directories we found at configure time
  # remove trailing duplicates
  return;
}

1;
__END__

=head1 NAME

ex::lib::zip - Perl extension to let you C<use> things direct from zip files.

=head1 SYNOPSIS

  use ex::lib::zip 'library.zip'; # A zip file that contains a file Foo.pm
  use Foo; # And perl will get Foo.pm from library.zip.

=head1 DESCRIPTION

An extension to let you C<use> things direct from zip files direct.
No temporary files.  No subprocesses.

=head2 EXPORT

Nothing.

=head1 BUGS

no "no ex::lib::zip" to remove things yet.
no code to remove trailing duplicates from @INC yet.

=head1 AUTHOR

Nicholas Clark, E<lt>nick@talking.bollo.cxE<gt>

=head1 SEE ALSO

L<perl>.

=cut
