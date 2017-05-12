package App::Rgit::Utils;

use strict;
use warnings;

use Cwd        (); # abs_path
use File::Spec (); # file_name_is_absolute, updir, splitdir, splitpath

=head1 NAME

App::Rgit::Utils - Miscellaneous utilities for App::Rgit classes.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

Miscellaneous utilities for L<App::Rgit> classes.

This is an internal module to L<rgit>.

=head1 FUNCTIONS

=head2 C<abs_path $path>

Forcefully make a path C<$path> absolute (in L<Cwd/abs_path>'s meaning of the term) when it isn't already absolute or when it contains C<'..'>.

=cut

sub abs_path {
 my ($path) = @_;

 if (File::Spec->file_name_is_absolute($path)) {
  my $updir  = File::Spec->updir;
  my @chunks = File::Spec->splitdir((File::Spec->splitpath($path))[1]);

  unless (grep $_ eq $updir, @chunks) {
   return $path;
  }
 }

 return Cwd::abs_path($path);
}

=head1 CONSTANTS

=head2 C<NEXT>, C<REDO>, C<LAST>, C<SAVE>

Codes to return from the C<report> callback to respectively proceed to the next repository, retry the current one, end it all, and save the return code.

=cut

use constant {
 SAVE => 0x1,
 NEXT => 0x2,
 REDO => 0x4,
 LAST => 0x8,
};

=head2 C<DIAG>, C<INFO>, C<WARN>, C<ERR> and C<CRIT>

Message levels.

=cut

use constant {
 INFO => 3,
 WARN => 2,
 ERR  => 1,
 CRIT => 0,
};

=head1 EXPORT

L<abs_path> is only exported on request.

C<NEXT> C<REDO>, C<LAST> and C<SAVE> are only exported on request, either by their name or by the C<'codes'> tags.

C<INFO>, C<WARN>, C<ERR> and C<CRIT> are only exported on request, either by their name or by the C<'levels'> tags.

=cut

use base qw/Exporter/;

our @EXPORT         = ();
our %EXPORT_TAGS    = (
 funcs  => [ qw/abs_path/ ],
 codes  => [ qw/SAVE NEXT REDO LAST/ ],
 levels => [ qw/INFO WARN ERR CRIT/ ],
);
our @EXPORT_OK      = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

=head1 SEE ALSO

L<rgit>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-rgit at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=rgit>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rgit::Utils

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of App::Rgit::Utils
