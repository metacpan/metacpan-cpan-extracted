package Web::Components::Role::ConfigLoader;

use Web::ComposableRequest::Constants qw( FALSE TRUE );
use File::DataClass::Types qw( Directory File Path );
use Web::Components::Util  qw( ns_environment );
use File::DataClass::IO    qw( io );
use File::DataClass::Schema;
use Moo::Role;

=encoding utf-8

=head1 Name

Web::Components::Role::ConfigLoader - Configuration file loading role

=head1 Synopsis

   use Moo;

   with 'Web::Components::Role::ConfigLoader';

=head1 Description

Finds and loads the configuration file(s)

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<config_file>

The configuration file is discovered by the loader once the 'home' attribute
has been established

=cut

has 'config_file' => is => 'ro', isa => File, predicate => 'has_config_file';

=item C<config_home>

The directory containing the configuration file(s)

=cut

has 'config_home' =>
   is        => 'ro',
   isa       => Directory,
   predicate => 'has_config_home';

=item C<home>

This is the directory that the loader has chosen to call 'home'

=cut

has 'home' => is => 'ro', isa => Directory;

=item C<local_config_file>

The name of the local configuration file which is optionally set in the
main configuration file

=cut

has 'local_config_file' =>
   is        => 'ro',
   isa       => File|Path,
   coerce    => TRUE,
   predicate => 'has_local_config_file';

sub _config_file_list ($) {
   my $attr = shift;
   (my $name = lc $attr->{appclass}) =~ s{ :: }{-}gmx;
   my $file = $attr->{config_file}
      // ns_environment($attr->{appclass}, 'config')
      // $name;
   my $extensions = $attr->{config_extensions} // 'json yaml';

   return map { "${file}.${_}" } split m{ \s }mx, $extensions;
}

sub _home_indicator_dirs () {
   return qw( var );
}

sub _dist_indicator_files () {
   return qw( Makefile.PL Build.PL dist.ini cpanfile );
}

sub _find_config ($) {
   my $attr = shift;
   my $home = $attr->{home};

   my ($config_home, $config_file);

   for my $dir ($home->catdir('var', 'etc'), $home->catdir('etc'), $home) {
      for my $file (_config_file_list $attr) {
         if ($dir->catfile($file)->exists) {
            $config_home = $dir;
            $config_file = $dir->catfile($file);
            last;
         }
      }

      last if $config_file;
   }

   return ($config_home, $config_file);
}

sub _find_home ($) {
   my $attr  = shift;
   my $class = $attr->{appclass};
   (my $file = "$class.pm") =~ s{::}{/}g;
   my $inc_entry = $INC{$file} or return;
   (my $path = $inc_entry) =~ s{ $file \z }{}mx;

   $path ||= io->cwd if !defined $path || !length $path;

   my $home = io($path)->absolute;

   $home = $home->parent while $home =~ m{ b?lib \z }mx;

   return $home if $home =~ m{ xt \z }mx;

   return $home if grep { $home->catfile($_)->exists } _dist_indicator_files;

   return $home if grep { $home->catdir($_)->exists } _home_indicator_dirs;

   ($path = $inc_entry) =~ s{ \.pm \z }{}mx;
   $home = io($path)->absolute;

   return $home if $home->exists;

   return;
}

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<BUILDARGS>

Modifies the method in the base class. Starting with C<appclass> it discovers
C<home>, then it discovers C<config_home> and C<config_file>, then it loads the
configuration file. If this defines C<local_config_file> that to is loaded

=cut

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr = $orig->($self, @args);

   if ($attr->{appclass}) {
      my $home = io $attr->{home} if defined $attr->{home} and -d $attr->{home};
      my $env_var = ns_environment $attr->{appclass}, 'home';

      $home = io $env_var      if !$home and $env_var and -d $env_var;
      $home = _find_home $attr if !$home;
      $attr->{home} = $home    if  $home;
   }

   if ($attr->{appclass} && $attr->{home}) {
      my ($config_home, $config_file) = _find_config $attr;

      $attr->{config_home} = $config_home if $config_home;
      $attr->{config_file} = $config_file if $config_file;
   }

   my $schema = File::DataClass::Schema->new( storage_class => 'Any' );

   if ($attr->{config_file}) {
      $attr = { %{$attr}, %{$schema->load($attr->{config_file})} };
   }

   if (my $file = $attr->{local_config_file}) {
      my $config_file = $attr->{config_home}->catfile($file);

      if ($config_file->exists) {
         $attr->{local_config_file} = $config_file;
         $attr = { %{$attr}, %{$schema->load($config_file)} };
      }
   }

   if ($attr->{home} && $attr->{home}->catdir('var')->exists) {
      $attr->{vardir} = $attr->{home}->catdir('var');
   }

   return $attr;
};

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass>

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

Copyright (c) 2024 Peter Flanigan. All rights reserved

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
