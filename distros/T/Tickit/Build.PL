use strict;
use warnings;

use Module::Build::Using::PkgConfig;

my $build = Module::Build::Using::PkgConfig->new(
   module_name => 'Tickit',
   requires => {
      'Exporter' => '5.57',
      'perl' => '5.010', # //
      'Struct::Dumb' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   test_requires => {
      'Test::Builder::Tester' => 0,
      'Test::Fatal' => 0,
      'Test::HexString' => 0,
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

if( $build->try_pkgconfig( "tickit", atleast_version => "0.2" ) ) {
   # libtickit installed; just use it
}
else {
   # libtickit not installed; use bundled source code instead
   print "Using bundled libtickit source\n";

   $build->c_source( "src" );
   $build->include_dirs( [ "include" ] );

   $build->push_extra_compiler_flags( qw( -std=c99 ) );

   # bundled source still needs libtermkey and unibilium
   $build->use_pkgconfig( "termkey", atleast_version => "0.16",
      alien => "Alien::libtermkey",
      alien_version => "0.19", # latest
   );

   $build->use_pkgconfig( "unibilium", atleast_version => "1.1.0",
      alien => "Alien::unibilium",
      alien_version => "0.13",
   );
   $build->push_extra_compiler_flags( qw( -DHAVE_UNIBILIUM ) );
}

{
   # Scan extra_linker_flags to try to emulate what libtool does:
   #   For each -lfoo see if we can find libfoo.la in any of the linker paths
   #   If we find one extract the libdir out of it and append it to rpath
   my @system_libdirs = my @libdirs = qw( /lib /usr/lib );
   my @rpaths;
   FLAG: foreach my $flag ( @{ $build->extra_linker_flags } ) {
      if( $flag =~ m/^-L(.*)$/ ) {
         push @libdirs, $1;
         next FLAG;
      }

      if( $flag =~ m/^-l(.*)$/ ) {
         my $lafile = "lib$1.la";
         my $libdir;
         -f "$_/$lafile" and $libdir = $_ and last for @libdirs;
         defined $libdir or next FLAG;

         # TODO: libtool will `source` the actual .la file here and check if
         #   the stored `libdir` really matches the dirname it was found in,
         #   printing a warning if not. We won't bother here and just presume
         #   it is

         $_ eq $libdir and next FLAG for @system_libdirs, @rpaths;

         print STDERR "Accumulated extra -rpath=$libdir\n";
         push @rpaths, $libdir;
         next FLAG;
      }
   }

   foreach my $rpath ( @rpaths ) {
      $build->push_extra_linker_flags( "-Wl,-rpath", "-Wl,$rpath" );
   }
}

$build->create_build_script;
