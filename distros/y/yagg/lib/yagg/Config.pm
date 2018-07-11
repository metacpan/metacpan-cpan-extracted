package yagg::Config;

use strict;
use yagg::Grammar;

use vars qw( $VERSION %Config );

$VERSION = 0.01;

%yagg::Config = (
  'programs' => {
    'ar' => '/usr/bin/ar',
    'c++' => '/usr/bin/c++',
    'chmod' => '/usr/local/opt/coreutils/libexec/gnubin/chmod',
    'cp' => '/usr/local/opt/coreutils/libexec/gnubin/cp',
    'cpp' => '/usr/bin/cpp',
    'date' => '/usr/local/opt/coreutils/libexec/gnubin/date',
    'dirname' => '/usr/local/opt/coreutils/libexec/gnubin/dirname',
    'expr' => '/usr/local/opt/coreutils/libexec/gnubin/expr',
    'find' => '/usr/local/bin/find',
    'grep' => '/usr/bin/grep',
    'ln' => '/usr/local/opt/coreutils/libexec/gnubin/ln',
    'make' => '/usr/bin/make',
    'mkdir' => '/usr/local/opt/coreutils/libexec/gnubin/mkdir',
    'mv' => '/usr/local/opt/coreutils/libexec/gnubin/mv',
    'perl' => '/Users/coppit/perl5/perlbrew/perls/perl-5.8.8/bin/perl',
    'rm' => '/usr/local/opt/coreutils/libexec/gnubin/rm',
    'rsync' => '/usr/local/bin/rsync',
    'ssh' => '/usr/bin/ssh',
    'yapp' => '/Users/coppit/perl5/perlbrew/perls/perl-5.8.8/bin/yapp',
  },
);

# Same directory as yagg::Grammar.
$yagg::Config{'template_path'} =
  $INC{'yagg/Grammar.pm'};
$yagg::Config{'template_path'} =~ s/\/Grammar.pm//;
$yagg::Config{'template_path'} .= '/input_generator_code';

1;

__END__

# --------------------------------------------------------------------------

=head1 NAME

yagg::Config - An internal configuration class

=cut
