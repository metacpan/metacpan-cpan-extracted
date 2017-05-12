package Yakuake::Sessions::TraitFor::Management;

use namespace::autoclean;

use Class::Usul::Constants qw( EXCEPTION_CLASS FAILED OK SPC TRUE );
use Class::Usul::Functions qw( emit throw );
use File::DataClass::Types qw( NonEmptySimpleStr );
use Unexpected::Functions  qw( PathNotFound );
use Moo::Role;
use Class::Usul::Options;

requires qw( dump dumper extra_argv file load loc
             profile_dir profile_path run_cmd );

# Object attributes (public)
option 'editor'  => is => 'lazy', isa => NonEmptySimpleStr,
   documentation => 'Which text editor to use',
   default       => sub { $_[ 0 ]->config->editor }, format => 's';

# Public methods
sub create : method {
   my $self = shift;

   unshift @{ $self->extra_argv }, $self->profile_path->assert_filepath;

   return $self->dump;
}

sub delete : method {
   my $self = shift; my $path = $self->profile_path;

   $path->exists or throw class => PathNotFound, args => [ $path ];
   $path->unlink;
   return OK;
}

sub edit : method {
   my $self = shift; my $path = $self->profile_path;

   $self->run_cmd( $self->editor.SPC.$path, { async => TRUE, } );
   return OK;
}

sub list : method {
   my $self = shift; my @suffixes = @{ $self->extensions };

   emit map { $_->basename( @suffixes ) } $self->profile_dir->all_files;
   return OK;
}

sub select : method {
   my $self     = shift;
   my @profiles = map { $_->basename( @{ $self->extensions } ) }
                      $self->profile_dir->all_files;
   my @options  = map { ucfirst $_ } @profiles;
   my $prompt   = 'Select a profile from the following list';
   my $index    = $self->get_option( $prompt, undef, TRUE, undef, \@options );

   $index < 0 and return FAILED;
   $self->unshift_argv( $profiles[ $index ] ); $self->load;
   return OK;
}

sub show : method {
   my $self = shift; $self->dumper( $self->load( TRUE ) ); return OK;
}

1;

__END__

=pod

=encoding utf8

=head1 Name

Yakuake::Sessions::TraitFor::Management - CRUD methods for session profiles

=head1 Synopsis

   use Moo;

   extends 'Yakuake::Sessions::Base';
   with    'Yakuake::Sessions::TraitFor::Management';

=head1 Description

Create, retrieve, update, and delete methods for session profiles

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<editor>

The editor used to edit profiles. Can be set from the configuration
file. Defaults to the environment variable C<EDITOR> or if unset
C<emacs>

=back

=head1 Subroutines/Methods

=head2 create - Create a new session profile

   $exit_code = $self->create;

New session profiles are created in the C<profile_dir> directory

=head2 delete - Delete a session profile

   $exit_code = $self->delete;

The session profile is specified on the command line

=head2 edit - Edit a session profile

   $exit_code = $self->edit;

Uses the C<editor> attribute to select the editor

=head2 list - List the names of the stored profiles

   $exit_code = $self->list;

List the session profiles stored in the C<profile_dir>

=head2 select - Select the profile to load from a list

   $exit_code = $self->select;

Displays a list of the available profiles and loads the one that
is selected

=head2 show - Display the contents of a session profile

   $exit_code = $self->show;

The session profile is specified on the command line

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<File::DataClass>

=item L<Moo::Role>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2014 Peter Flanigan. All rights reserved

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
