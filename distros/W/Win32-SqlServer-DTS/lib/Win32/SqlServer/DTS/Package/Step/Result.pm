package Win32::SqlServer::DTS::Package::Step::Result;

=head1 NAME

Win32::SqlServer::DTS::Package::Step::Result - a Perl class to represent a DTS Package Step execution result.

=head1 SYNOPSIS

    use Win32::SqlServer::DTS::Package::Step::Result;

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Package::Step::Result> does not exists in the regular MS SQL Server DTS 2000 API. 

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use base qw(Class::Accessor);
use Carp qw(confess);
use XML::Simple 2.18;
use Params::Validate 1.24 qw(validate :types);
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_ro_accessors(
    qw(exec_status step_name error_code source description));

=head2 METHODS

=head3 new

Instantiates a new C<Win32::SqlServer::DTS::Package::Step::Result>. Expects as a parameter a hash reference with the following keys:

=over

=item *
error_code: scalar value.

=item *
source: scalar value.

=item *
description: scalar value.

=item *
step_name: scalar value.

=item *
is_success: "boolean". Accepts 0 or 1.

=item *
exec_status: scalar value.

=back

=cut

sub new {

    my $class = shift;

    validate(
        @_,
        {
            error_code  => { type => SCALAR },
            source      => { type => SCALAR },
            description => { type => SCALAR },
            step_name   => { type => SCALAR },
            is_success  => { type => SCALAR, regex => qr/[10]{1}/ },
            exec_status => { type => SCALAR }
        }
    );

    my $self = shift;

    bless $self, $class;

    lock_keys( %{$self} );

    return $self;

}

=head3 to_string

Returns the C<DTS:Package::Step::Result> as a pure text content. Useful for simple reports.

=cut

sub to_string {

    my $self = shift;

    my @attrib_names = keys( %{$self} );

	my $string;

    foreach my $attrib_name (@attrib_names) {

        $string .= "$attrib_name => $self->{$attrib_name}\n";

    }

	return $string;

}

=head3 to_xml

Returns the C<DTS:Package::Step::Result> as an XML content.

=cut

sub to_xml {

    my $self = shift;

    my $xs = XML::Simple->new();

    return $xs->XMLout($self);

}

=head3 is_success

Returns true if the step was executed successfully.

=cut

sub is_success {

    my $self = shift;

    return $self->{is_success};

}

1;

__END__

=head1 SEE ALSO

=over

=item *
C<Win32::SqlServer::DTS::Package::Step> documentation.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
