package Tie::Select;

use strict;
use warnings;

our $VERSION = 0.01;
$VERSION = eval $VERSION;

use Exporter;
our @ISA = qw/ Exporter /;
our @EXPORT = qw/ $SELECT /;

tie our $SELECT, __PACKAGE__ 
  or die q/Can't tie $SELECT/;

sub TIESCALAR { return bless [], $_[0] }
sub FETCH { return select }
sub STORE { select $_[1] }

1;

__END__
__POD__

=head1 NAME

Tie::Select - Provides a localized interface to the C<select> function

=head1 SYNOPSIS

 use strict; use warnings;
 use Tie::Select;

 {
   local $SELECT = *STDERR;
   print "This goes to STDERR";
 }

 print "This goes to STDOUT";

=head1 DESCRIPTION

The Perl builtin C<print>, when not called with an explicit file handle, will print to the file handle designated by the C<select> command. This is a global action, which is bad. Further, it has an awkward interface for restoring a previous handle; on a call to C<select> a reference to the old handle is returned, which has to itself be C<select>-ed to restore the old handle. Better to see an example.

 my $stdin = select *STDERR;
 print "To STDERR";
 select $stdin;

L<Tie::Select> offers a localizable interface to C<select>. Simply assign a handle to the C<$SELECT> variable this module to change the C<select>-ed handle. If this is done with C<local> the change is dynamically bound to the enclosing scope.

The inspiration for this type of interface is L<File::chdir> which provides a similar localizable interface to the current working directory.

=head1 SEE ALSO

=over

=item *

L<File::chdir> - Allow localized working directory, inspiration for this module

=item * 

L<Lexical::select> - As the name implies, it provides a lexically scoped interface to the C<select> function rather than dynamically scoped

=item *

L<IO::Select> - This time its an Object-Oriented interface to C<select>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Tie-Select>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

