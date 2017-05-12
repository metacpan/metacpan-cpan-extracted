package Web::ComposableRequest::Config;

use namespace::autoclean;

use Class::Inspector;
use File::Spec::Functions        qw( tmpdir );
use Unexpected::Types            qw( NonEmptySimpleStr PositiveInt Str );
use Web::ComposableRequest::Util qw( merge_attributes is_member );
use Moo;

my $_list_attr_of = sub {
   my $class = shift; my @except = qw( BUILDARGS BUILD DOES does new );

   return map  { $_->[1] }
          grep { $_->[0] ne 'Moo::Object' and not is_member $_->[1], @except }
          map  { m{ \A (.+) \:\: ([^:]+) \z }mx; [ $1, $2 ] }
              @{ Class::Inspector->methods( $class, 'full', 'public' ) };
};

# Public attributes
has 'encoding'       => is => 'ro', isa => NonEmptySimpleStr,
   default           => 'UTF-8';

has 'max_asset_size' => is => 'ro', isa => PositiveInt,
   default           => 4_194_304;

has 'scrubber'       => is => 'ro', isa => Str,
   default           => '[^ +\-\./0-9@A-Z\\_a-z~]';

has 'tempdir'        => is => 'ro', isa => Str, coerce => sub { $_[ 0 ].q() },
   default           => sub { tmpdir };

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, $config) = @_; my $attr = {};

   defined $config
       and merge_attributes $attr, $config, [ $_list_attr_of->( $self ) ];

   return $attr;
};

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Config - Base class for the request configuration

=head1 Synopsis

   package Web::ComposableRequest;

   use Moo;

   my $_build_config_class = sub {
      my $base  = __PACKAGE__.'::Config';
      my @roles = list_config_roles; @roles > 0 or return $base;

      return Moo::Role->create_class_with_roles( $base, @roles );
   };

   has 'config'        => is => 'lazy', isa => Object, builder => sub {
      $_[ 0 ]->config_class->new( $_[ 0 ]->config_attr ) }, init_arg => undef;

   has 'config_attr'   => is => 'ro',   isa => HashRef | Object | Undef,
      builder          => sub {},  init_arg => 'config';

   has 'config_class'  => is => 'lazy', isa => NonEmptySimpleStr,
      builder          => $_build_config_class;

=head1 Description

Base class for the request configuration

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<encoding>

The encoding used to decode all inputs, defaults to C<UTF-8>

=item C<max_asset_size>

Integer defaults to 4Mb. Maximum size in bytes of the file upload

=item C<scrubber>

A string used as a character class in a regular expression. These character
are scrubber from user input so they cannot appear in any user supplied
pathnames or query terms. Defaults to C<[;\$\`&\r\n]>

=item C<tempdir>

Directory used to store temporary files

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Lists the attributes of the composed class and initialises their
values from supplied configuration

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Inspector>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-ComposableRequest.
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
