use strict;
use warnings;

use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib "$Bin/lib";
use Test::More;
use Test::FitNesse::Slim::InstallDocumentation qw(
  installed_manpage_paths render_installed_pod
);

my $private = tempdir('test-slim-private-pod-XXXXXX', TMPDIR => 1, CLEANUP => 1);
chmod 0700, $private or die "chmod private POD root: $!";
my $module_dir = "$private/lib/perl5/Test/FitNesse";
make_path($module_dir);
my $installed_pod = "$module_dir/Slim.pm";
copy("$Bin/../lib/Test/FitNesse/Slim.pm", $installed_pod)
  or die "copy POD into private installation prefix: $!";
chmod 0644, $installed_pod or die "chmod installed POD: $!";

my $rendered = eval { render_installed_pod($installed_pod) };
ok(defined $rendered, 'Pod::Text renders documentation in a private install prefix')
  or diag $@;
like($rendered, qr/FitNesse/, 'rendered text comes from installed Test::FitNesse::Slim POD');

my $missing = "$module_dir/Missing.pm";
my $ok = eval { render_installed_pod($missing); 1 };
ok(!$ok, 'missing installed documentation is rejected');
like($@, qr/installed POD file is missing/, 'missing documentation has a distinct diagnostic');

my ($enabled_paths, $enabled_disabled) = installed_manpage_paths('/prefix', {
  man1dir => '/usr/share/man/man1', man3dir => '/usr/share/man/man3',
  installman1dir => '/usr/share/man/man1', installman3dir => '/usr/share/man/man3',
  man1ext => '1p', man3ext => '3pm',
}, ['Test::FitNesse::Slim', 'Test::FitNesse::Slim::Server']);
is_deeply($enabled_paths, {
  bindoc => [File::Spec->catfile('/prefix', 'man', 'man1', 'perl-slim.1p')],
  libdoc => [
    File::Spec->catfile('/prefix', 'man', 'man3', 'Test::FitNesse::Slim.3pm'),
    File::Spec->catfile('/prefix', 'man', 'man3', 'Test::FitNesse::Slim::Server.3pm'),
  ],
}, 'enabled Module::Build targets map executable and each module manual to install_base');
is_deeply($enabled_disabled, [], 'enabled manpage targets are not reported disabled');

my ($disabled_paths, $disabled_types) = installed_manpage_paths('/prefix', {
  man1dir => 'none', man3dir => 'none',
  installman1dir => 'none', installman3dir => 'none',
  man1ext => '', man3ext => '',
});
is_deeply($disabled_paths, {}, 'Perl configurations without manpage support expect no generated pages');
is_deeply($disabled_types, [qw(bindoc libdoc)],
  'disabled executable and library documentation targets are identified separately');

my ($partial_paths, $partial_disabled) = installed_manpage_paths('/prefix', {
  man1dir => '/usr/share/man/man1', man3dir => 'none',
  installman1dir => '/usr/share/man/man1', installman3dir => 'none',
  man1ext => '1p', man3ext => '',
}, ['Test::FitNesse::Slim']);
is_deeply($partial_paths, {
  bindoc => [File::Spec->catfile('/prefix', 'man', 'man1', 'perl-slim.1p')],
},
  'each configured documentation destination remains strictly checked');
is_deeply($partial_disabled, ['libdoc'], 'only the unavailable library-manual target is disabled');

done_testing;
