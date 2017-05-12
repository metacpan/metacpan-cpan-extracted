use strict;
use warnings;

use Module::Build;

eval { require ExtUtils::CChecker; 1 } or
   die "OS unsupported - missing ExtUtils::CChecker";

my $cc = ExtUtils::CChecker->new;

$cc->try_compile_run(
   define => "HAVE_TIMEGM",
   source => <<'EOF' );
      #include <time.h>
      int main(int argc, char *argv[]) {
        struct tm tm;
        time_t t = timegm(&tm);
        return 0;
      }
EOF

# Windows calls this _mkgmtime instead
$cc->try_compile_run(
   define => "HAVE_MKGMTIME",
   source => <<'EOF' );
      #include <time.h>
      int main(int argc, char *argv[]) {
        struct tm tm;
        time_t t = _mkgmtime(&tm);
        return 0;
      }
EOF

my $build = $cc->new_module_build(
   module_name => 'Time::timegm',
   requires => {
      'POSIX' => 0,
   },
   configure_requires => {
      'ExtUtils::CChecker' => 0,
   },
   build_requires => {
      'Test::More' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
