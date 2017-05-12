use strict;
use Module::Build;

require Win32;
unless (Win32::IsWinNT) {
  die "Windows NT (2000/XP/2003/etc) is required!\n";
}

my $build = Module::Build->new
    (
     module_name => 'Win32::EventLog::Carp',
     license => 'perl',
     requires => {
       'perl'                     => '5.005',
       'Carp'                     => 0, # standard module
       'Carp::Heavy'              => 0, # & part of Carp
       'File::Basename'           => 0, # standard module
       'File::Spec'               => 0, # standard module
       'Win32'                    => 0,
       'Win32::EventLog'          => 0,
     },
# requires_os: MSWin32
     recommends => {
       'Win32::EventLog::Message' => 0, # from www.roth.net
     },
     build_requires => {
       'Test::More'               => 0,
     },
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org> and David Landgren <dland at cpan.org>',
);

$build->create_build_script;
