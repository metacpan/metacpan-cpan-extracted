# autogenerated by /home/rlauer/bin/make-cpan-dist.pl on Tue Feb  4 09:00:48 2025

use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'Workflow::Inotify',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rlauer6@comcast.net>',
  VERSION_FROM     => 'lib/Workflow/Inotify.pm',
  ABSTRACT         => 'Linux::Inotify2 wrapper',
  LICENSE          => 'perl',
  PL_FILES         => {},
  EXE_FILES        => ['bin/inotify.pl'],
  PREREQ_PM        => {
    'Class::Accessor::Fast' => '0',
    'Config::IniFiles'      => '0',
    'Linux::Inotify2'       => '0',
    'List::Util'            => '0',
    'Proc::Daemon'          => '0',
    'Proc::PID::File'       => '0',
    'Readonly'              => '0'
  },
  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
  },
  TEST_REQUIRES => {},
  META_MERGE    => {
    'meta-spec' => { 'version' => 2 },
    'provides'  => {
      'Workflow::Inotify' => {
        'file'    => 'lib/Workflow/Inotify.pm',
        'version' => '1.0.7'
      },
      'Workflow::Inotify::Handler' => {
        'file'    => 'lib/Workflow/Inotify/Handler.pm',
        'version' => '1.0.7'
      }
    },
    'resources' => {
      'bugtracker' => {
        'mailto' => 'rlauer6@comcast.net',
        'web'    => 'http://github.com/rlauer6/perl-Workflow-Inotify/issues'
      },
      'homepage'   => 'http://github.com/rlauer6/perl-Workflow-Inotify',
      'repository' => {
        'type' => 'git',
        'url'  => 'git://github.com/rlauer6/perl-Workflow-Inotify.git',
        'web'  => 'http://github.com/rlauer6/perl-Workflow-Inotify'
      }
    }
  }

);

package MY;

use File::ShareDir::Install;
use English qw(-no_match_vars);

sub postamble {
  my $self = shift;

  my @ret = File::ShareDir::Install::postamble($self);

  my $postamble = join "\n", @ret;

  if ( -e 'postamble' ) {

    local $RS = undef;

    open my $fh, '<', 'postamble'
      or die "could not open postamble\n";

    $postamble .= <$fh>;

    close $fh;
  }

  return $postamble;
}

1;
