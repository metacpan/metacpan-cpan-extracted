package Versionify::Dispatch;

use Moose;
use MooseX::FollowPBP;
use Carp;
use Sort::Versions;

use version; our $VERSION = qv('0.2.4');

has 'default_version' => (
    is  => 'rw',
    isa => 'Str',
);

has 'function' => (
    is  => 'rw',
    isa => 'HashRef[CodeRef]',
    reader  => '_get_function',
    writer  => 'set_function',
);

sub get_function {
    my $self = shift;
    my $version = shift;
    
    $version ||= $self->get_default_version;
    
    my $function_lookup_ref = $self->_get_function;
    if($version)
    {
        my $matching_function = $function_lookup_ref->{$version};
        return $matching_function if $matching_function;
    }
    my @available_versions = keys %$function_lookup_ref;
    @available_versions = grep {versioncmp($version, $_) > 0} @available_versions if $version;
    @available_versions = sort {versioncmp($a, $b)} @available_versions;
    croak 'No valid functions stored' unless @available_versions;
    
    return $function_lookup_ref->{$available_versions[-1]};
}

sub register{
    my $self = shift;
    my %functions_to_register = @_;
    
    my $function_lookup_ref = $self->_get_function;
    my %function_lookup = $function_lookup_ref ? %$function_lookup_ref : ();
    my @new_function_versions = keys %functions_to_register;
    
    @function_lookup{@new_function_versions} = @functions_to_register{@new_function_versions};
    $self->set_function(\%function_lookup);
}

no Moose;
__PACKAGE__->meta->make_immutable;


1; # Magic true value required at end of module
__END__

=head1 NAME

Versionify::Dispatch - A function dispatcher that respects versions, with fallback.


=head1 VERSION

This document describes Versionify::Dispatch version 0.2.4


=head1 SYNOPSIS

    use Versionify::Dispatch;
    
    my $dispatcher = Versionify::Dispatch->new(
        function => {
            1.0 => \&some_function,
            1.6 => \$sub_ref,
        }
    );
    
    $dispatcher->register(
        1.8 => sub {
            ...
        }
    );
    
    $dispatcher->get_function($desired_version)->(@args);


=head1 DESCRIPTION

This module is designed to allow a version friendly approach to dispatching
function calls. One possible use of this is in an API situation, where the
behaviour of functionality with a similar purpose may change over time.

When the function of a specific version is requested, the reference to the
function with the highest version equal to or less than the requested version
is returned by the C<get_function> method. If no specific version is supplied,
the default version is used (if set), otherwise the maximum version is used.


=head1 INTERFACE 

=over

=item new

    $dispatcher = Versionify::Dispatch->new(default_version => $some_version, function => \%function_mapping);

The constructor, which has two named parameters - the default version, and a
hashref of the version to function mapping. Both parameters are optional, but
calling C<get_function> without having initialised the function mapping
(either in the constructor, or in C<set_function>) will not work well.

=item set_function

    $dispatcher->set_function(\%function_mapping);

Used to set the version -> function mapping inside the dispatcher object. B<This
will remove any existing mapping.>

=item set_default_version

    $dispatcher->set_default_version($some_version);

Sets the default version to be used when no version is explicitly set in
the C<get_function> call.

=item register

    $dispatcher->register(%function_mapping)

Registers additional version -> function mappings. This does not remove existing
mappings, except when a version conflict arises - the newly registered function
takes precedence.

=item get_function

    $return = $dispatcher->get_function($version)->(@args);
    # or
    $sub_ref = $dispatcher->get_function($version);

Returns the appropriate function. If the version string is not supplied
the default version is used. The highest versioned function reference
that is less than or equal to the version (or highest in general if no
version was supplied and no default is set) is returned.

The version comparisons are done by the L<Sort::Versions> module.

=back


=head1 DIAGNOSTICS

=over

=item C<< No valid functions stored >>

There are no functions of a version less than or equal to the desired
version (possibly no functions at all).

=back


=head1 CONFIGURATION AND ENVIRONMENT

Versionify::Dispatch requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item L<Moose>

=item L<MooseX::FollowPBP>

=item L<Sort::Versions>

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-versionify-dispatch@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Glenn Fowler  C<< <cebjyre@cpan.org> >>

Thanks to L<http://www.hiivesystems.com>.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Glenn Fowler C<< <cebjyre@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
