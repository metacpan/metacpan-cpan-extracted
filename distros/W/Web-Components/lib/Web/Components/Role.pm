package Web::Components::Role;

use namespace::autoclean;

use Web::Components::Util             qw( deref );
use Web::ComposableRequest::Constants qw( TRUE );
use Unexpected::Types                 qw( HashRef NonEmptySimpleStr
                                          NonNumericSimpleStr Object );
use Moo::Role;

has 'components'  => is => 'ro',   isa => HashRef, default => sub { {} },
   weak_ref       => TRUE;

has 'config'      => is => 'ro',   isa => Object | HashRef, required => TRUE;

has 'encoding'    => is => 'lazy', isa => NonEmptySimpleStr,
   builder        => sub { deref $_[ 0 ]->config, 'encoding' };

has 'log'         => is => 'ro',   isa => Object, required => TRUE;

has 'moniker'     => is => 'ro',   isa => NonNumericSimpleStr, required => TRUE;

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args ); my $app;

   (exists $attr->{application} and $app = $attr->{application})
      or return $attr;

   $app->can( 'config' ) and $attr->{config} //= $app->config;
   $app->can( 'log'    ) and $attr->{log   } //= $app->log;

   return $attr;
};

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Role - Attributes used when instantiating a Web::Components object

=head1 Synopsis

   use Moo;

   with 'Web::Components::Role';

=head1 Description

Attributes used when instantiating a Web::Components object

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<components>

A hash reference of component object references. This is not fully populated
until all of the components have been loaded. It can be used by components to
discover other dependant components

=item C<config>

A required object or hash reference

=item C<encoding>

A non empty simple string that defaults to the value of the configuration
attribute of the same name. Used to set input and output decoding / encoding

=item C<log>

A required object reference of type C<Logger>. The log object should support
the C<log> call as well as the usual log level calls

=item C<moniker>

A required non numeric simple string. This is the component name. It is used
to uniquely identify a component in the component collections held by the role
L<Web::Components::Loader>

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

If supplied with an object reference called C<application> the C<config> and
C<log> attribute values will be set from it if they are otherwise undefined

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=item L<Web::ComposableRequest>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
