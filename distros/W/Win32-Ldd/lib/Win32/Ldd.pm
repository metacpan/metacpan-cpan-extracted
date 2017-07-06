package Win32::Ldd;

our $VERSION = '0.02';

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(pe_dependencies);
our @EXPORT = qw();

require XSLoader;
XSLoader::load('Win32::Ldd', $VERSION);

use File::Spec;

sub pe_dependencies {
    my ($pe_file, %opts) = @_;
    build_dep_tree(File::Spec->canonpath($pe_file),
                   $opts{search_paths} // [split /;/, $ENV{PATH}],
                   $opts{recursive} // 1,
                   $opts{data_relocs} // 0,
                   $opts{function_relocs} // 0);
}

1;
__END__

=head1 NAME

Win32::Ldd - Track dependencies for Windows EXE and DLL PE-files

=head1 SYNOPSIS

  use Win32::Ldd qw(pe_dependencies);

  my $dep_tree = pe_dependencies('c:\\strawberry\\perl\\bin\\perl.exe');

=head1 DESCRIPTION

This module is an XS wrapper for the
L<ntldd|https://github.com/LRN/ntldd> library.

It can inspect Windows PE files and extract information about its
dependencies.

=head2 FUNCTIONS

The following function can be imported from the module:

=over 4

=item $dep_tree = pe_dependencies($filename, %opts);

This function returns a tree of hashes representing the dependencies
of the module.

The options accepted by the function are as follows:

=over 4

=item search_paths => \@path

Where to look for DLLs. Defaults to the directories in C<$ENV{PATH}>.

=item recursive => $bool

Indicates whether resolved dependencies should also be inspected for
its own dependencies. Defaults to true.

=item data_reloc => $bool

unknown!

=item function_reloc => $bool

unknown!

=back

=back

=head1 SEE ALSO

The L<ntldd|https://github.com/LRN/ntldd> project.

Other tools providing similar features are the Freeware
L<DependencyWalker|http://dependencywalker.com/> (aka C<depends.exe>),
or the C<objdump.exe> utility (included with Strawberry Perl).

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>.

Copyright (C) 2010-2016 LRN E<lt>lrn1986@gmail.comE<gt>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
