package Win32::SqlServer::DTS::Assignment::Destination;

=head1 NAME

Win32::SqlServer::DTS::Assignment::Destination - abstract class to represent a destination string of a DTS DynamicPropertiesTaskAssignment object.

=head1 SYNOPSIS

    use warnings;
    use strict;
    use Win32::SqlServer::DTS::Application;
    my $xml = XML::Simple->new();
    my $config = $xml->XMLin('test-config.xml');

    my $app = Win32::SqlServer::DTS::Application->new($config->{credential});

    my $package =
      $app->get_db_package(
        { id => '', version_id => '', name => $config->{package}, package_password => '' } );

	# checking out all destination string from all assignments from 
	# all Dynamic Property tasks of a package
	my $iterator = $package->get_dynamic_props();

    while ( my $dyn_prop = $iterator->() ) {

		my $assign_iterator = $dyn_props->get_assignments;

		while ( my $assignment = $assign_iterator->() ) {

			print $assignment->get_string(), "\n";

		}

    }

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Assignment::Destination> represents the destination string of a DTS DynamicPropertiesTaskAssignment object.
The Destination string is usually something like 

C<Object;Name of object;Properties;Name of the property> 

but this will change depending on the type of object which is mean to be the target of the assignment. 
C<Win32::SqlServer::DTS::Assignment::Destination> is a "syntatic sugar" to allow the different types of Destination string to be 
used with a set of methods, hidding the complexity and hardwork to deal with this string.

C<Win32::SqlServer::DTS::Assignment::Destination> is a abstract class and it's not meant to be used directly: to instantiate objects, look
for the subclasses of it.

Although is part of the package, C<Win32::SqlServer::DTS::Assignment::Destination> is B<not> a subclass of C<Win32::SqlServer::DTS::Assignment>, so no 
method from is inherited. Besides that, the package is not part of the original MS SQL Server API.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use base qw(Class::Accessor Class::Publisher);
use Carp qw(confess);
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=cut

=head3 new

The object constructor method of the class. C<new> is implemented to setup de object with two basic attributes: 
I<string> and I<destination>.

Expects as an argument the Destination string as a parameter. Subclasses of C<Win32::SqlServer::DTS::Assignment::Destination> must 
implement the C<initialize> method that parses the string and define the I<destination> property correctly.

=cut

sub new {

    my $class = shift;
    my $self;
    my $string = shift;

	$self->{string} = undef;

    # assuming that the last part of Class name is always the target object
    $self->{who} = ( split( /\:{2}/, $class ) )[-1];

    bless $self, $class;

    $self->set_string($string);

    lock_keys( %{$self} );

    return $self;

}

=head3 initialize

This method must be overrided by subclasses of C<Win32::SqlServer::DTS::Assignment::Destination>.
It should parse the I<string> attribute and define the I<destination> attribute with the proper value.

C<initialize> is invoked automatically by the C<new> method during object creation.

=cut

sub initialize {

    confess "'initialize' method must be overrided by subclasses of Win32::SqlServer::DTS::Assignment::Destination.\n";

}

=head3 get_destination

Returns the target of the Destination object, in other words, what will be modified by the related Assignment.

=cut

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(destination));

=head3 get_string

Returns a formatted destination string where all "'" (single quotes) are stripped.

=cut

sub get_string {

    my $self = shift;

    my $fmt_string = $self->{string};

    $fmt_string =~ tr/\'//d;

    return $fmt_string;

}

=head3 get_raw_string

Returns the destination string without any formating, as it's defined by the DTS API.

=cut

sub get_raw_string {

    my $self = shift;

    return $self->{string};

}

=head3 set_string

Modifies the destination string in the object. The string is validated against a regular expression before starting
changing the property. The regex is "C<^(\'[\w\s\(\)]+\'\;\'[\w\s\(\)]+\')(\'[\w\s\(\)]+\')*>" and it's based on the destination 
string specification in MSDN. If the regex does not match, the method will abort program execution.

The programmer must be aware that invoking C<set_string> will automatically execute the C<initialize> method (to setup 
other attributes related to the destination) and notify the related C<Win32::SqlServer::DTS::Assignment>t object to modify the property 
in it's C<_sibling> attribute, to keep all values syncronized.

=cut

sub set_string {

    my $self   = shift;
    my $string = shift;

    confess "'string' attribute cannot be undefined"
      unless ( defined($string) );

    confess "invalid value of destination string: $string"
      unless ( $string =~ /^(\'[\w\s\(\)]+\'\;\'[\w\s\(\)]+\')(\'[\w\s\(\)]+\')*/ );

    $self->{string} = $string;
    $self->initialize();
    $self->notify_subscribers('changed');

}

=head3 changes

This method tests which object is being changed by the C<Win32::SqlServer::DTS::Assignment::Destination> object.
Expects a object name as a parameter; returns true if it changes the same object name, false if not.

An valid object name is equal to one of the subclasses of C<Win32::SqlServer::DTS::Assignment::Destination>.

Since a Dynamic Property task can hold several assignments, this method is usefull for testing if an assignment is
the one that you want to deal with. It's also possible to test that using the C<isa> method, like this:

	if ( $destination->isa('Win32::SqlServer::DTS::Assignment::Destination::Connection') ) {

		#do something

	}

But that is a lot of typing. Instead, use:

	if ( $destination->changes('Connection') ) {

		#do something

	}

The result will be the same.

=cut

sub changes {

    my $self   = shift;
    my $target = shift;

    if ( $target eq $self->{who} ) {

        return 1;

    }
    else {

        return 0;

    }

}

1;
__END__

=head1 SEE ALSO

=over

=item *
L<Win32::SqlServer::DTS::Assignment> at C<perldoc>.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=item *
C<Class::Publisher> at C<perldoc>. This package is a subclass of C<Class::Publisher>.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
