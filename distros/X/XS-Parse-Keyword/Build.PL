use strict;
use warnings;

use lib 'inc';
use ExtUtils::CChecker 0.11;
use Module::Build::with::XSTests;

my $MIN_PERL = '5.014'; # PL_keyword_plugin

# MSWin32 needs at least perl 5.22
#   https://rt.cpan.org/Ticket/Display.html?id=136577
$MIN_PERL = '5.022' if $^O eq "MSWin32";

my $cc = ExtUtils::CChecker->new( quiet => 1 );

$cc->try_find_cflags_for(
   cflags => [
      # Most systems will need no extra cflags
      [],
      # HPUX may need to be told +std=gnu in order to accept anon inner unions
      ( $^O eq "hpux" ) ? [ "+std=gnu" ] : (),
   ],
   source => <<'EOF'
struct Named {
   union { int a, b; };
   int c;
};
int main(void) { struct Named n; n.a = 0; return n.a; }
EOF
) or die "OS unsupported - C compiler does not support anonymous inner unions\n";

{
   print "Checking for PL_infix_plugin...\n";

   my $have_pl_infix_plugin = 0;

   # No released version of perl (yet) has PL_infix_plugin. This commandline
   # argument allows it to build if patched correctly.
   $have_pl_infix_plugin = 1 if grep { $_ eq "--have-pl_infix_plugin" } @ARGV;

   $have_pl_infix_plugin ||= $cc->try_compile_run(
      source => <<'EOF'
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main(void) { struct Perl_custom_infix def; return 0; }
EOF
   ) if $] >= 5.035005;

   if( $have_pl_infix_plugin ) {
      print "Including support for core perl PL_infix_plugin\n";
      # ->define isn't currently documented but it will be in next version; it
      # has been present since v0.04, basically forever
      $cc->define( "HAVE_PL_INFIX_PLUGIN" )
   }
}

my $build = Module::Build::with::XSTests->new(
   module_name => 'XS::Parse::Keyword',
   requires => {
      'perl' => $MIN_PERL,
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'ExtUtils::CChecker' => '0.11',
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => [qw( -I. -Ihax )],
   c_source => [ "src/" ],
);

$cc->extend_module_build( $build );
$build->notes( builder_cflags => $cc->extra_compiler_flags );

$build->create_build_script;
