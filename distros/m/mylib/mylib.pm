package mylib;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $Prefix $Bin $Lib $Etc);

$VERSION = "1.02";

require Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw($Prefix $Bin $Lib $Etc);

use FindBin qw($RealBin);

$Prefix = $Bin = $RealBin;
$Lib = "$Prefix/lib";

unless (-d $Lib) {
    require File::Basename;
    $Prefix = File::Basename::dirname($Prefix);
    $Lib = "$Prefix/lib";
    unless (-d $Lib) {
        die "Can't find lib in either $Bin or $Prefix, stopped";
    }
}

$Etc = "$Prefix/etc";

require lib;
lib->import($Lib);

1;

__END__

=head1 NAME

mylib - add private lib to the module search path

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use mylib;

  use Private::Module;

=head1 DESCRIPTION

This is just a convenient wrapper around L<FindBin> and L<lib> that
will prepend to perl's search path the F<lib> directory either found
in the directory of the script or its parent directory.  If neither of
these locations contain a F<lib> directory it will die.

This makes it easy to create a collection of scripts that share private
modules (not to be installed with perl) using the traditional Unix
layout of sibling F<bin>, F<lib>, F<man>, F<etc>,... directories.

The following variables can be imported:

=over

=item C<$Prefix>

This is the directory where the F<lib> directory is found.

=item C<$Lib>

This is the same as C<"$Prefix/lib">.

=item C<$Etc>

This is the same as C<"$Prefix/etc">.

=item C<$Bin>

This will normally either be C<$Prefix> or C<"$Prefix/bin">.  It is
the same as C<$FindBin::RealBin>.

=back

=head1 COPYRIGHT

Copyright 2008 Gisle Aas.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<rlib>, L<FindBin>, L<lib>
