use v5;
use strict;
use warnings;

use lib 'inc';
use ExtUtils::CChecker 0.11;
use Module::Build::with::XSTests;

my @extra_compiler_flags = qw( -Ishare-keyword/include -Ishare-infix/include -Ihax );

# Perl 5.36 made -std=c99 standard; before then we'll have to request it specially
push @extra_compiler_flags, qw( -std=c99 ) if $^V lt v5.36.0;

push @extra_compiler_flags, qw( -DDEBUGGING=-g ) if $^X =~ m|/debugperl|;

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

my $build = Module::Build::with::XSTests->new(
   module_name => 'XS::Parse::Keyword',
   requires => {
      'perl' => $MIN_PERL,
   },
   build_requires => {
      # We have multiple t/*.xs files, which requires a new enough version of
      # ExtUtils::ParseXS to cope with.
      # Unsure the exact version required. perl 5.14 normally ships with version
      # 2.2210 but that fails. perl 5.16's version 3.16 works fine.
      'ExtUtils::ParseXS' => '3.16',
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'ExtUtils::CChecker' => '0.11',
      'Module::Build' => '0.4004', # test_requires
   },
   share_dir => {
      module => {
         "XS::Parse::Infix"   => [ 'share-infix' ],
         "XS::Parse::Keyword" => [ 'share-keyword' ],
      },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,

   extra_compiler_flags => \@extra_compiler_flags,
   c_source => [ "src/" ],
);

$cc->extend_module_build( $build );
$build->notes( builder_cflags => $cc->extra_compiler_flags );

$build->create_build_script;
