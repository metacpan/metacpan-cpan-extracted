package Win32::SqlServer::DTS;

=head1 NAME

Win32::SqlServer::DTS - Perl classes to access Microsoft SQL Server 2000 DTS Packages

=head1 DESCRIPTION

Although it's possible to use all features here by using only C<Win32::OLE> module, C<Win32::SqlServer::DTS> (being more specific, it's 
childs classes) provides a much easier interface (pure Perl) and (hopefully) a better documentation.

The API for this class will give only read access to a package attributes. No write methods are available are 
directly available at this time, but could be executed since at each DTS object created a related object is 
passed as an reference to new object. This related object is a MS SQL Server DTS object and has all methods and
properties as defined by the MS API. This object reference is kept as an "private" property called C<_sibling>
and generally can be obtained with a C<get_sibling> method call. Once the reference is recovered, all methods from it
are available.

The C<Win32::SqlServer::DTS> class does not much: it will server only as an interface class, since it cannot be instancied or the
available methods be called directly (as an abstracted class). The inheritance will help only to make available
easier (and globally) access to the methods C<kill_sibling> and C<get_sibling>.

=head2 Why having all this trouble?

You may be asking yourself why having all this trouble to write such API as an layer to access data thought C<Win32::OLE>
module.

The very simple reason is: MS SQL Server 2000 API is terrible to work with (lots and lots of indirection), the 
documentation is not as good as it should be and one has to convert examples from it of VBScript code to Perl.

C<Win32::SqlServer::DTS> API was created to provide an easier (and more "perlish") way to fetch data from a DTS package. 
One can use this API to easily create reports or implement automatic tests using a module 
as L<Test::More|Test::More> (see EXAMPLES directory in the tarball distribution of this module).

Current development state should be considered BETA, despite the API is already usable. There is a high chance that the
interface changes during next releases, so be careful when updating.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use Data::Dumper;
use Carp qw(confess);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=head3 get_sibling 

Returns the relationed DTS object. All objects holds an reference to the original DTS object once is instantiated, 
unless the C<kill_sibling> is executed.

If the reference is not available, it will abort program execution with an error.

=cut

sub get_sibling {

    my $self = shift;

    if ( exists( $self->{_sibling} ) ) {

        return $self->{_sibling};

    }
    else {

        confess
          "The reference to the original DTS object is not more available\n";

    }

}

=head3 is_sibling_ok

Validates if the attribute _sibling is defined and has a valid value. Returns true if it's ok, false otherwise.

=cut

sub is_sibling_ok {
    my $self = shift;

    if (    ( exists( $self->{_sibling} ) )
        and ( $self->{_sibling}->isa('Win32::OLE') ) )
    {
        return 1;
    }
    else {
        return 0;
    }

}

=head3 kill_sibling

This method will simple delete the key (or attribute, if you prefer) C<_sibling> from the hash reference used by all classes that inherints from
DTS class. Once the key is removed, the Perl garbage collector will remove the related object created using the MS SQL 
Server 2000.

The reasons of why doing such thing is described in L<CAVEATS|/CAVEATS>.

=cut

sub kill_sibling {
    my $self = shift;
    delete $self->{_sibling};
}

=head3 debug

Uses the L<Data::Dumper|Data::Dumper> C<Dumper> function to print to C<STDOUT> the properties of a given object
that inherints from C<Win32::SqlServer::DTS> (almost of all classes in the API).

The way this is implemented is to do a dirty I<clone> of the original object, but without the C<_sibling> 
attribute. This allows to quickly check the object state. This is not as good as it could be, but sometimes
the Perl debugger dies while checking DTS objects, so it's better than nothing.

Maybe in the future this method is replaced to turn on debug mode for all methods calls using C<Log::Log4perl> module.

=cut

sub debug {

    my $self = shift;
    my $clone;

    foreach my $key ( keys( %{$self} ) ) {

        next if ( $key eq '_sibling' );

        $clone->{$key} = $self->{$key};

    }

    bless $clone, ref($self);

    print Dumper($clone);

}

1;
__END__

=head1 CAVEATS

All objects under DTS distribution cannot be created without a reference to the original DTS object they mimic: at
the current development state, object can only be recovered from a MS SQL Server database. Some classes may have methods
to change their inner attributes, other classes don't. Check the POD for each class to be sure,  but future releases 
should have write methods for all classes implemented.

DTS distribuition replicates several DTS classes, but it is still INCOMPLETE. There are many classes there were not 
replicated, like Bulk Insert Task or Transformation. Check the UML in the project website for an overview of which
classes are implemented.

The I<sibling> object, kept as an reference, sometimes is quite annoying. This because the MS SQL Server API uses
a lot of indirection. Using L<Data::Dumper|Data::Dumper>, for example, seems impossible. Using the C<x> (eval) 
command in the debugger sometimes also shows a interesting visual effect, but is equally useless (setting 
C<maxdepth> should help).

There are serious problems using the Perl debugger, since it seems to crash everytime there is more than an object
instantied (if there is a C<_sibling> attribute involved). The solution until now is use the C<debug> method 
or using a module like C<Log4Perl> to detect issues in the code.

If you need to persist any object created, first remove the I<sibling> object using the C<kill_sibling> 
method. As said before, it was detected issues with the L<Data::Dumper|Data::Dumper> C<Dumper> function, but there
are no garantees that invoking C<kill_sibling> will solve the issue, since this probably also depends on Perl 
garbage collector. Anyway, persisting a DTS object will do no good if you need to execute methods that depends on the
I<sibling> attribute since those methods are based on remote requests with COM.

C<kill_sibling> probably will help also regarding memory using, althought this was not tested formally.

Once this API is built over L<Win32::OLE|Win32::OLE> module, one will only be able to use C<Win32::SqlServer::DTS> modules in a 
MS Windows operational system that also supports the installation of the MS SQL Server Enterprise Manager, at 
least the client part of the application, to be able to use the original DTS API that comes with the MS SQL 
Server client. All issues from L<Win32::OLE|Win32::OLE> applies too. Since release 0.04, DTS distribution will die if
used in any other operational system. See L<Devel::AssertOS|Devel::AssertOS> for more implementation details.

C<Win32::SqlServer::DTS> modules were tested with MS SQL Server 8 (or 2000, if you prefer) so maybe some methods will fail if tried 
on previous versions of MS SQL Server.

=head1 SEE ALSO

=over

=item *
L<Win32::OLE> at C<perldoc>.

=item *
L<Data::Dumper> at C<perldoc>.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=item *
README file in the module distribuition about how to enable extended tests for the API.

=item *
Project website at L<http://code.google.com/p/perldts> for more information, including 
UML diagrams and Subversion repository.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
