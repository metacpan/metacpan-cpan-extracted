use strict;
use warnings;

use Module::Build;
use ExtUtils::PkgConfig;

my %build_args;

sub eu_pc_atleast_version
{
   my ( $module, $ver ) = @_;

   print "Checking pkg-config $module --atleast_version $ver... ";

   # Silence its scary errors
   open OLDERR, ">&", \*STDERR or die "Cannot dup STDERR: $!";
   open STDERR, ">>", "/dev/null" or die "Cannot reopen STDERR - $!";

   my $ret = eval { ExtUtils::PkgConfig->atleast_version( $module, $ver ) };

   open STDERR, ">&", OLDERR;
   close OLDERR;

   print $ret ? "yes\n" : "no\n";

   return $ret;
}

sub add_cflags_libs
{
   my ( $modname ) = @_;

   my $cflags = ExtUtils::PkgConfig->cflags( $modname );
   my $libs   = ExtUtils::PkgConfig->libs( $modname );

   push @{ $build_args{extra_compiler_flags} }, split( m/ +/, $cflags );

   push @{ $build_args{extra_linker_flags} }, split( m/ +/, $libs );
}

if( eu_pc_atleast_version( "tickit", "0.2" ) ) {
   # libtickit installed; just use it
   print "Using installed libtickit\n";

   add_cflags_libs "tickit";
}
else {
   # libtickit not installed; use bundled source code instead
   print "Using bundled libtickit source\n";

   $build_args{c_source}     = "src";
   $build_args{include_dirs} = "include";

   $build_args{extra_compiler_flags} = [qw( -std=c99 )];

   # bundled source still needs libtermkey and optionally can use
   # unibilium
   if( eu_pc_atleast_version( "termkey", "0.16" ) ) {
      print "Using installed libtermkey\n";

      add_cflags_libs "termkey";
   }
   elsif( eval { require Alien::libtermkey } ) {
      print "Using Alien::libtermkey\n";

      push @{ $build_args{extra_compiler_flags} },
         split m/ +/, Alien::libtermkey->cflags;

      push @{ $build_args{extra_linker_flags} },
         split m/ +/, Alien::libtermkey->libs;
   }
   else {
      die "OS unsupported - need libtermkey";
   }

   if( eu_pc_atleast_version( "unibilium", "1.1.0" ) ) {
      print "Using installed unibilium\n";

      push @{ $build_args{extra_compiler_flags} }, qw( -DHAVE_UNIBILIUM );

      add_cflags_libs "unibilium";
   }
   elsif( eval { require Alien::unibilium and Alien::unibilium->VERSION( '0.09' ) } ) {
      print "Using Alien::unibilium\n";

      push @{ $build_args{extra_compiler_flags} }, qw( -DHAVE_UNIBILIUM ),
         split m/ +/, Alien::unibilium->cflags;

      push @{ $build_args{extra_linker_flags} },
         split m/ +/, Alien::unibilium->libs;
   }
   elsif( eu_pc_atleast_version( "ncursesw", 0 ) ) {
      print "Using installed ncursesw\n";

      add_cflags_libs "ncursesw";
   }
   else {
      print "Using installed ncurses\n";

      push @{ $build_args{extra_linker_flags} }, qw( -lncurses );
   }
}

my $build = Module::Build->new(
   module_name => 'Tickit',
   %build_args,
   requires => {
      'Exporter' => '5.57',
      'perl' => '5.010', # //
      'Struct::Dumb' => 0,
   },
   configure_requires => {
      # Note to downstream package maintainers:
      # We don't -actually- depend directly on these Alien modules but it's far
      # easier to get CPAN smoketest machines to install them this way than
      # anything else.
      # These dependencies can be omitted if libtermkey/unibilium are installed
      # by some other mechanism
      'Alien::libtermkey' => '0.16',
      'Alien::unibilium' => '0.11',
      'ExtUtils::PkgConfig' => 0,
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
   build_requires => {
      'Alien::libtermkey' => '0.16',
      'Alien::unibilium' => '0.11',
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
