package Win32::SqlServer::DTS::Assignment::Constant;

=head1 NAME

Win32::SqlServer::DTS::Assignment::Constant - a class to represent a DynamicPropertiesTaskAssignment object

=head1 SYNOPSIS

    use warnings;
    use strict;
    use Win32::SqlServer::DTS::Application;
    use Test::More;
    use XML::Simple;

    my $xml = XML::Simple->new();
    my $config = $xml->XMLin('test-config.xml');

    my $app = Win32::SqlServer::DTS::Application->new($config->{credential});

    my $package =
      $app->get_db_package(
        { id => '', version_id => '', namne => $config->{package}, package_password => '' } );

	my $iterator = $package->get_dynamic_props();

    while ( my $dyn_prop = $iterator->() ) {

        foreach my $assignment_prop ( @{ $dyn_prop->get_properties() } ) {

            if ( $assignment_prop->get_type() eq 'Constant' ) {

			    print $assignment_prop->to_string(), "\n";

            }

        }
    }

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Assignment::Constant> represents a Constant Assignment from a Dynamic Property Task of DTS API. Such
element will add a constant value to a desired destination once the Dynamic Property task, which is associated with,
is executed.

Unless you're developing a new API is quite probably that one is going to use C<Win32::SqlServer::DTS::Assignment::Constant> returned
by the C<get_properties> method from C<Win32::SqlServer::DTS::Task::DynamicProperty> class.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use base qw(Win32::SqlServer::DTS::Assignment);
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

Inherits all methods from C<Win32::SqlServer::DTS::Assignment>.

=head3 new

Overrides C<new> method from superclass by modifying the attribute C<source>.

=cut

sub new {

    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{source} = $self->get_sibling()->SourceConstantValue();
    lock_keys( %{$self} );
    return $self;

}

=head3 get_source

Overrided method from L<Win32::SqlServer::DTS::Assignment|Win32::SqlServer::DTS::Assignment> superclass.

Returns a string that represents the C<SourceConstantValue> property, in other words, the value that will be assigned
to the destination everytime the C<Win32::SqlServer::DTS::Task::DynamicProperty> associated object is executed.

=cut

sub get_source {

    my $self = shift;
    return $self->{source};

}

1;

__END__

=head1 SEE ALSO

=over

=item *
L<Win32::SqlServer::DTS::Assignment> is the superclass of C<Win32::SqlServer::DTS::Assignment::Constant>.

=item *
L<Win32::OLE> at C<perldoc>.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but the documentation one will need to convert examples written in VBScript to Perl code.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
