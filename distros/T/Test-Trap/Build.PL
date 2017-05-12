use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass( code => do { local $/; <DATA> } );

my $builder = $class->new
  ( module_name         => 'Test::Trap',
    license             => 'perl',
    create_makefile_pl  => 'traditional',
    dist_author         => 'Eirik Berg Hanssen <ebhanssen@cpan.org>',
    dist_version_from   => 'lib/Test/Trap.pm',
    configure_requires  =>
    { 'Module::Build'     => 0,
    },
    requires =>
    { 'base'              => 0, # core ...
      'constant'          => 0, # core ...
      'Carp'              => 0,
      'Data::Dump'        => 0,
      'Exporter'          => 0,
      'File::Temp'        => 0,
      'IO::Handle'        => 0,
      'lib'               => 0, # core ...
      'strict'            => 0, # now _that's_ core!
      'Test::Builder'     => 0,
      'Test::More'        => 0,
      'Test::Tester'      => 0.107,   # fails with at least some earlier ones
      'perl'              => '5.6.2',
      'version'           => 0,
      'warnings'          => 0,
    },
    PL_files =>
    { 't/08-fork.PL'             => 't/08-fork.t',
      't/11-systemsafe-basic.PL' => 't/11-systemsafe-basic.t',
    },
    add_to_cleanup =>
    [ 'Test-Trap-*',
      'MYMETA.yml',
      't/08-fork.t',
      't/11-systemsafe-basic.t',
    ],
  );

$builder->create_build_script();

__DATA__

=head1 ACTIONS

=head2 authortest

This runs all the C<xt/author> tests, as well as the ordinary tests,
after making sure that the build, manifest, and distmeta actions have
been taken.

=cut

sub ACTION_authortest {
  my ($self) = @_;

  $self->depends_on('build');
  $self->depends_on('manifest');
  $self->depends_on('distmeta');

  $self->test_files( qw< t xt/author > );
  $self->recursive_test_files(1);

  $self->depends_on('test');

  return;
}

sub ACTION_distdir {
  my ($self) = @_;

  $self->depends_on('authortest');

  return $self->SUPER::ACTION_distdir();
}

sub ACTION_distmeta {
  my ($self) = @_;

  require Module::Build::Compat;
  unless (Module::Build::Compat->VERSION gt 0.31 or eval { Module::Build::Compat->PL_FILES_PATCH }) {
    die <<'DIE'
Too old Module::Build::Compat to Build distmeta.
Upgrade if possible or apply the following hack patch:
--- Compat.pm   2008-10-04 02:14:02.000000000 +0200
+++ Compat.pm   2008-10-04 02:15:10.000000000 +0200
@@ -139,7 +139,7 @@
     
     $MM_Args{EXE_FILES} = [ sort keys %{$build->script_files} ] if $build->script_files;
     
-    $MM_Args{PL_FILES} = {};
+    $MM_Args{PL_FILES} = $build->PL_files;
     
     local $Data::Dumper::Terse = 1;
     my $args = Data::Dumper::Dumper(\%MM_Args);
@@ -153,6 +153,7 @@
   }
 }
 
+sub PL_FILES_PATCH { 1 }
 
 sub subclass_dir {
   my ($self, $build) = @_;
DIE
  }

  return $self->SUPER::ACTION_distmeta();
}
