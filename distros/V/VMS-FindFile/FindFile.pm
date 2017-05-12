## VMS::FindFile - Implements some simple hooks to give VMS perl
## a function similar to DCL's f$search().
##
## Copyright (C) 2002 Forrest Cahoon
##
## This source code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.


package VMS::FindFile;

use 5.004;
use strict;
require DynaLoader;
use vars qw($VERSION @ISA);
@ISA = qw(DynaLoader);

$VERSION = '0.92';

bootstrap VMS::FindFile $VERSION;

use VMS::FindFile;

sub new {
   my $class = $_[0];
   my $objref = {_filespec  => $_[1]};
   ($objref->{"_resultant"},$objref->{"_context"}) =
     VMS::FindFile::_find_file($objref->{"_filespec"}, 0);
   bless $objref, $class;
   return $objref;
}

sub search {
   my ($self) = @_;
   my $fname = $self->{"_resultant"};
   if ($fname) {
      ($self->{"_resultant"}, $self->{"_context"}) =
	VMS::FindFile::_find_file($self->{"_filespec"}, $self->{"_context"});
   }
   return $fname;
}

sub DESTROY {
   my ($self) = @_;
   if ($self->{"_context"}) {
      VMS::FindFile::_find_file_end($self->{"_context"});
   }
}

1;

__END__

=head1 NAME

VMS::FindFile - Returns all file names matching a VMS wildcard specification.

=head1 SYNOPSIS

  use VMS::FindFile;

  my $ff=VMS::FindFile->new($wildcard_spec);

  while (my $filename = $ff->search()) {
     # ... do whatever with $filename ...
  }

=head1 DESCRIPTION

VMS::FindFile is a VMS-specific module which returns all file names
matching a VMS-style wildcard specification.  It acts almost exactly
like the f$search() function in DCL, except that instead of using
context numbers to do multiple concurrent searches, you create
multiple VMS::FindFile objects.

While it is VMS-specific, it's a lot faster than the system-
independent File::Find.

=head1 AUTHOR

Forrest Cahoon (forrest@cpan.org)

=head1 SEE ALSO

perl(1).

=cut
