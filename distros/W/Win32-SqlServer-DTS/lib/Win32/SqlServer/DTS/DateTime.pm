package Win32::SqlServer::DTS::DateTime;

=head1 NAME

Win32::SqlServer::DTS::DateTime - DateTime Perl object built from Win32::OLE Variant values

=head1 SYNOPSIS

    use Win32::SqlServer::DTS::DateTime;
	use Win32::OLE::Variant;

	my $variant = Variant( VT_DATE, "April 1 99" );

	my $date = Win32::SqlServer::DTS::DateTime->new($variant);

=head1 DESCRIPTION

Extends the DateTime class constructor (new method) to create a DateTime object that is equal to a 
C<Win32::OLE::Variant> object.

Some classes in C<DTS> distribution have methods that returns date/time values, but as Variants. C<Win32::SqlServer::DTS::DateTime> objects
are used as substitutes.

Most attributes returned as date/time variants from DTS API original classes are read-only, so beware that changing a
C<Win32::SqlServer::DTS::DateTime> object attribute because, as long as it seems to work,  it will not save the state in the DTS package: the C<Win32::SqlServer::DTS::DateTime>
is "disconnected" from the original date/time variant.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use base qw(DateTime);
use Params::Validate 1.24 qw(validate_pos);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=head3 new

Expects a C<Win32::OLE::Variant> date object as a parameter.

=cut

sub new {
    my $class = shift;
    validate_pos( @_, { isa => 'Win32::OLE::Variant' } );
    my $variant_timestamp = shift;
    my $self = $class->SUPER::new(
        year   => $variant_timestamp->Date('yyyy'),
        month  => $variant_timestamp->Date('M'),
        day    => $variant_timestamp->Date('d'),
        hour   => $variant_timestamp->Time('H'),
        minute => $variant_timestamp->Time('m'),
        second => $variant_timestamp->Time('s'),
    );
    return $self;
}

1;

__END__

=head1 SEE ALSO

=over

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but you will need to convert examples written in VBScript to Perl code.

=item *
L<DateTime>.

=item *
L<Win32::OLE::Variant>.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
