use strict;
use inc::Module::Install;
use ExtUtils::Install;
use File::Spec;
use Cwd;
name 'smokeinabox';
author 'Chris Williams <chris@bingosnet.co.uk>';
version_from 'lib/App/Smoke/In/A/Box.pm';
readme_from 'lib/App/Smoke/In/A/Box.pm';
#abstract 'CPAN Tester smoke environment boxed';
abstract_from 'bin/smokeinabox';
install_script 'bin/smokeinabox';
configure_requires 'ExtUtils::Install' => 1.52;
perl_version '5.006';
license 'perl';
auto_license holder => 'Chris Williams';
githubmeta;
no_index directory => 'cpansmokebox';
no_auto_test;
auto_provides;

unless ( $Module::Install::AUTHOR ) {
##########################################################################################
print qq[
===

Smoke In A Box Installer
========================

Smoke In A Box requires a location to put the
boxed smoke environment.

As soon as you enter a location we will attempt
to copy the relevant files there.

===
    \n
];

my $defloc = _find_dir();
my $install_dir = prompt("Where do you want to install the cpansmokebox directory?", $defloc );
die "That location isn't a directory, quitting\n" unless -d $install_dir;

print qq[

Okay installing into "$install_dir"

];

my $proceed = prompt("Do you really wish to proceed? [y/N]",'N');

exit if $proceed =~ /^N/i;

$install_dir = File::Spec->catdir( $install_dir, 'cpansmokebox' );

install({ 'cpansmokebox' => $install_dir });
install({ 'README' => $install_dir });

print qq[Done\n\n];

my $email = prompt("Please supply the email address you will submit reports from");

unless ( $email ) {
  print qq[Okay, I will not configure the installation now, quitting\n];
  exit 0;
}

my $mx = prompt("Please supply a mail gateway to use (optional hit return to skip)");

my $orig_cwd = getcwd;

chdir $install_dir or die "$!\n";

system "$^X bin/cpanp-boxed -q";
system "$^X bin/cpconf-boxed --email '$email'" . ( $mx ? " --mx '$mx'" : '' );

chdir $orig_cwd or die "$!\n";

print qq[

Your Smoke In A Box is now installed and configured at

   $install_dir

You may change to that location and run

   $^X bin/yactest-boxed

to start CPAN Testing

Have a nice day >:)

===
    \n
];

exit 0;
##########################################################################################
}

WriteAll();

sub _find_dir() {
  my @os_home_envs = qw( APPDATA HOME USERPROFILE WINDIR SYS$LOGIN );

  for my $env ( @os_home_envs ) {
      next unless exists $ENV{ $env };
      next unless defined $ENV{ $env } && length $ENV{ $env };
      return $ENV{ $env } if -d $ENV{ $env };
  }

  return '..';
}
