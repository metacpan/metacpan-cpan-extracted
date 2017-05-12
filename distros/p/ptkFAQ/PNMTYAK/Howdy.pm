package Howdy;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

bootstrap Howdy $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Howdy - Perl extension for testing Xlib extensibility. 

=head1 SYNOPSIS

  use Howdy;
  blah blah blah

=head1 DESCRIPTION

This "module" is simply to test a _very_basic_ Xlib extension to perl.
If you can get this to build and work on your computer you should have
very little trouble getting the Tk extension to perl working on your
system.

Blah blah blah.

=head1 AUTHOR

Peter Prymmer, pvhp@lns62.lns.cornell.edu

=head1 SEE ALSO

perl(1).

=cut
