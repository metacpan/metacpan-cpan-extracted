package inc::dtRdrBuilder;
our $VERSION = '0.01';

# Copyright (C) 2006, 2007 by Eric Wilhelm and OSoft, Inc.
# License: GPL

use warnings;
use strict;
use Carp;

use base (
  #'inc::MBwishlist', # 0.2807 got it
  'inc::MBwishlist::trees',
  qw(
    inc::dtRdrBuilder::PodCoverage
    Module::Build
    inc::dtRdrBuilder::Accessory
    inc::dtRdrBuilder::DepCheck
    inc::dtRdrBuilder::Distribute
  ),
);

my $perl = $^X;
if($^O eq 'darwin') {
  $perl =~ m/wxPerl/ or
    warn "'$perl' may not work for you on the GUI\n",
      "do 'wxPerl Build.PL' for best results\n\n";
}
BEGIN {
  if($^O eq 'darwin') {
    eval { require Module::Build::Plugins::MacBundle };
    $@ and warn "features missing -- $@";
    #Module::Build::Plugins::MacBundle->import('ACTION_appbundle')
    #  unless($@);
  }
} # end BEGIN

=head1 NAME

dtRdrBuilder -  Custom build methods for dotReader

=head1 SYNOPSIS

  Build Build Build Build Build Build
        Build Build Build Build Build Build
  Build Build Build             Build       Build Build
        Build       Build Build       Build Build Build
              Build             Build
        Build Build Build Build
                                                  Build
              Build Build
                                Build Build Build
  Build Build Build
  Build

  Build


  Build

=head1 General Notes

The build system has occassionally been a catch-all for stuff that
should maybe be a standalone utility, etc.  Thus, it is subject to the
same laws of chaos as the rest of the codebase, except that it has no
tests.

Therefore, code with the goal of making this package smaller.

=head2 Avoid Static Dependencies

Not only do they break CPAN-based builds/tests, they also make it harder
to yank-out the code and put it where it should be.

=cut

=head1 ACTIONS

=over

=item testgui

Run the gui tests.

=cut

sub ACTION_testgui {
  my $self = shift;
  $self->generic_test(type => 'gui');
}

=item testsync

Run the sync tests.

=cut

sub ACTION_testsync {
  my $self = shift;
  $self->generic_test(type => 'sync');
}

=item testbinary

Test the built binary.  This runs (mostly) in the same context as a
distributed .par/.app bundle.

Requires a graphical display, but (hopefully) no interaction.

=cut

sub ACTION_testbinary {
  my $self = shift;

  # setup
  my $token = time;
  local $ENV{DOTREADER_TEST} = qq(print "ok $token\n";);

  # disable gui errors
  local $ENV{JUST_DIE} = 1;

  # zero-out @INC on mac
  local $ENV{PW_NO_INC} = 1;

  my ($out, $err) = $self->run_binary;

  # check
  $out or die "not ok\n";
  ($out =~ m/^ok $token/) or die "not ok\n";

  # woot
  print "ok\n";
} # end subroutine ACTION_testbinary definition
########################################################################

=item runbinary

Runs the binary interactively.

=cut

sub ACTION_runbinary {
  my $self = shift;

  # TODO should we put all of this stuff in the run_binary() method?
  # disable gui errors
  local $ENV{JUST_DIE} = 1;

  # XXX hmm, some way to just run it on stderr/stdout?
  my ($out, $err) = $self->run_binary;
  $out and print $out;
  $err and warn $err;
} # end subroutine ACTION_runbinary definition
########################################################################

=item par

This is now deprecated in favor of the mini.  Still need the --mini
option to get there though.

Build a binfilename() (e.g. 'binary_build/dotreader.exe') par.

By default, this has no console on windows.  Use the "--nogui" option to
enable console output (only matters on windows.)

  build par --nogui 

=cut

sub ACTION_par {
  my $self = shift;

  my %args = $self->args;

  # just switch to mini mode
  return($self->depends_on('par_parts')) if($args{mini});

  my $use_gui = $args{gui};
  $use_gui or warn "building with console";

  my $parfile = $self->binfilename;
  { # do we need to do anything?
    my @sources = (
      keys(%{$self->find_pm_files}), 
      __FILE__, # XXX to thisfile or not to thisfile?
      );
    if($self->up_to_date(\@sources, $parfile)) {
      $self->log_info("Skip (up-to-date) building $parfile\n");
      return;
    }
  }
  $self->depends_on('code');
  $self->depends_on('datadir');

  use Config;

  if($^O eq 'linux') {
    $ENV{$Config{ldlibpthname}} =
      join($Config{path_sep}, qw(
        /usr/lib
        /usr/local/lib
        /usr/lib/mozilla
      ));
  }
  
  my @add_mods = ($self->additional_deps);

  my @modules =
    grep({$_ !~ m/^dtRdr::HTMLShim/} keys(%{{$self->_module_map()}}));

  push(@modules,
    ($^O eq 'linux') ? (
      'dtRdr::HTMLShim::WxMozilla',
    ) : (),
    ($^O eq 'MSWin32') ? (
      'dtRdr::HTMLShim::ActiveXIE',
      'Win32',
      'Wx::ActiveX::IE',
      'Wx::DocView',
      map({'Win32::OLE::'.$_} qw(
        Const Enum Lite NLS TypeInfo Variant
      )),
    ) : (),
    'dtRdr::HTMLShim::WxHTML'
  );
  
  require File::Path;
  $args{clean} and File::Path::rmtree($self->binary_build_dir);
  File::Path::mkpath($self->binary_build_dir);

  # Try to grab a cache of dependencies
  my $parmanifest = $self->parmanifest;
  my @cached_deps;
  if(-e $parmanifest) {
    warn "got $parmanifest -- skipping dependency-check compilation\n";
    open(my $fh, '<', $parmanifest);
    @cached_deps = grep(
      {
        $_ !~ m#^auto/# and
        $_ !~ m#^unicore/#
      }
      map({chomp;s#^lib/##;$_} 
        grep({m#^lib/# and m/\.pm$/} <$fh>)
      )
    );
    for(@cached_deps) { s#/+#::#g; s/\.pm$//;}
  }
  else {
    if(1) {
      # way faster compile
      warn "pre-compiling dependencies\n";
      @cached_deps = $self->scan_deps(
        modules => [@add_mods, @modules],
        string => $self->dependency_hints,
      );
    }
    else {
      push(@add_mods,
        $self->scan_deps(string => $self->dependency_hints));
    }
  }

  # got to have this because Module::ScanDeps thru ~0.71 doesn't pass
  # the -I opts into the subprocess which does the compile
  local $ENV{PERL5LIB} =
    (defined($ENV{PERL5LIB}) ? $ENV{PERL5LIB} . $Config{path_sep} : '') .
      $self->blib . '/lib';

  require File::Spec;
  my @command = (
    $self->which_pp,
    '-o', $parfile,
    ( # if we know what we need, let's quit checking for it
      scalar(@cached_deps) ?
      map({('-M', $_)} @cached_deps) :
      '--compile'
    ),
    #'-n', # seems to lose a lot of stuff
    qw(-z 9),
    ($use_gui ? '--gui' : ()), # only have console if requested
    '-a',  $self->datadir . ';data',
    '--icon',
      File::Spec->rel2abs(
        'client/data/gui_default/icons/dotreader.ico'
      ),
    '-I', $self->blib . '/lib',
    map({('-l', $_)} $self->external_libs),
    map({('-M', $_)} @add_mods, @modules),
    'client/app.pl',
  );
  warn "running pp",
    (0 ?
      ("\n  ", join(" ", @command)) :
      (scalar(@cached_deps) ?
        '' :
        ' (no cached dependencies)'
      )
    ),
    "\n";
  my ($in, $out, $err);
  0 and (@command = (qw(strace -o /tmp/stracefile), @command));
  IPC::Run::run(\@command, \$in, \*STDOUT, \*STDERR) or die "$! $^E $? $err";
  warn "built $parfile\n";
} # end subroutine ACTION_par definition
########################################################################

=item par_parts

Build the par_mini and then bundle it into an executable.

=cut

sub ACTION_par_parts {
  my $self = shift;

  my %args = $self->args;

  my $use_gui = $args{gui};

  $self->depends_on('par_mini');

  my $par_mini = $self->par_mini;

  # set this so the filename comes out right
  local $self->{args}{mini} = 1;
  my $exe_file = $self->binfilename;

  # TODO any reason to not skip?
  if($self->up_to_date($par_mini, $exe_file)) {
    $self->log_info("Skip (up-to-date) building $exe_file\n");
    return;
  }

  my @command = (
    $self->which_pp,
    '-o', $exe_file,
    qw(-z 9),
    ($use_gui ? '--gui' : ()), # only have console if requested
    '--icon',
      File::Spec->rel2abs(
        'client/data/gui_default/icons/dotreader.ico'
      ),
    $par_mini
  );
  warn "pp for $exe_file\n";
  system(@command) and die "$!";
  warn "par_parts done\n";
} # end subroutine ACTION_par_parts definition
########################################################################

=item par_mini

Build a '.par' archive with all of the project code.

The dependencies for this build the par_core, which builds par_deps,
which builds par_wx.

These four files (the deps, plus the main archive) are all that is
needed to construct a brand new executable binary on the client.  More
on this later.

=cut

sub ACTION_par_mini {
  my $self = shift;
  $self->depends_on('par_core');

  # egg, meet chicken
  $self->depends_on('par_pl');

  my $par_mini = $self->par_mini;
  my $par_seed = $self->par_seed;

  if($self->up_to_date([$par_seed, $self->parmain_pl], $par_mini)) {
    $self->log_info("Skip (up-to-date) building $par_mini\n");
    return;
  }

  $self->log_info("Zip $par_mini...");
  require Archive::Zip;
  my $zip = Archive::Zip->new();
  $zip->read($par_seed) == Archive::Zip::AZ_OK or
    die("'$par_seed' is not a valid zip file.");
  $zip->updateMember('script/dotReader.pl', $self->parmain_pl) or
    die "failed to add script";
  $zip->overwriteAs($par_mini) == Archive::Zip::AZ_OK or die 'write error';
  $self->log_info("done\n");

  # build the yaml file
  {
    require File::Basename;
    require YAML::Syck;

    my %yml_data = (
      name => File::Basename::basename($par_mini),
      requires => [ map({File::Basename::basename($self->$_)}
          qw(par_core par_deps par_wx)),
      ],
    );
    YAML::Syck::DumpFile($self->par_mini . '.yml', \%yml_data);
  }

} # end subroutine ACTION_par_mini definition
########################################################################

=item par_seed

=cut

sub ACTION_par_seed {
  my $self = shift;

  File::Path::mkpath($self->par_deps_dir);

  my $parfile = $self->par_seed;
  my @our_mods = map({s#^lib/+##; $_} keys(%{$self->find_pm_files}));

  # XXX this should probably check more of the contents of the datadir,
  # such as release_file
  if($self->up_to_date([map({'lib/' . $_} @our_mods)], $parfile)) {
    $self->log_info("Skip (up-to-date) building $parfile\n");
    return;
  }

  $self->depends_on('code');
  $self->depends_on('datadir');

  # TODO get the deplist from cache or scandeps on the bootstrap file?
  my @deps = $self->scan_deps(
    modules => [qw(dtRdr::0 warnings strict File::Spec Cwd Config version)],
    files => [qw(client/build_info/par_bootstrap.pl)],
  );
  0 and warn join("\n  ", "got deps:", @deps);

  # build it by including all of blib/lib
  my @command = (
    $self->which_pp,
    '-p', # plain par
    '-o', $parfile,
    qw(-z 9),
    '-n', # no scanning, no compiling, no executing
    '-a',  $self->datadir . ';data',
    '-I', $self->blib . '/lib',
    '-B', # need early core stuff in here
    map({('-M', $_)} @deps, @our_mods),
    'client/build_info/dotReader.pl'
  );

  warn "pp for $parfile\n";
  0 and warn "# @command\n";
  require Config_m if($^O eq 'MSWin32');
  local $ENV{PERL5LIB} = join($Config{path_sep}, $self->blib . '/lib',
    split($Config{path_sep}, $ENV{PERL5LIB} || ''));
  system(@command) and die "$! $^E $?";
  warn "par_seed done\n";

} # end subroutine ACTION_par_seed definition
########################################################################

=item par_pl

Build the blib/dotReader.pl file.

This contains hardcoded version numbers for the dependency bits.  It
gets built into the par_mini file using the seed.par, which solves the
chicken/egg problem.

=cut

sub ACTION_par_pl {
  my $self = shift;

  my $main_pl = $self->parmain_pl;

  my @depfiles = (__FILE__,
    map({$self->$_} qw(par_deps par_core par_wx)),
  );

  if($self->up_to_date([@depfiles], $main_pl)) {
    $self->log_info("Skip (up-to-date) $main_pl\n");
    return;
  }

  my ($boot, $app_pl) = map(
    { open(my $fh, '<', $_) or die "cannot open $_"; local $/; <$fh> }
    'client/build_info/par_bootstrap.pl', 'client/app.pl'
  );

  my $prelude_class = 'dtRdr::par_bootstrap';
  my $import_deps = "BEGIN {$prelude_class->post_bootstrap;}\n";
  $app_pl =~ s/^#### PAR_LOADS_DEPS_HERE.*$/$import_deps/m or die;

  my ($wx_par, $deps_par, $core_par) =
    map({$self->par_dep_file($_)} qw(wx deps core));

  # TODO get names for deps.par, etc
  my $prelude = <<"  ---";
    BEGIN {
      \$${prelude_class}::shared_par = '$wx_par';
      \$${prelude_class}::core_par = '$core_par';
      \$${prelude_class}::deps_par = '$deps_par';
    }
    BEGIN {
      package $prelude_class;
      \n$boot
    }
  ---

  open(my $fh, '>', $main_pl) or die "cannot write $main_pl";
  print $fh "$prelude\n$app_pl";
  close($fh) or die "write $main_pl failed";
} # end subroutine ACTION_par_pl definition
########################################################################

=item par_wx

=cut

sub ACTION_par_wx {
  my $self = shift;

  $self->depends_on('par_seed');

  my $parfile = $self->par_wx;
  if(-e $parfile) { # if you have it, I'll say that's enough
    $self->log_info("Skip (up-to-date) building $parfile\n");
    return;
  }

  # get all of the wx mods and libs
  #   compile to get -M list
  my @deps = $self->scan_deps(
    string => qq(use Wx qw(:everything :allclasses);),
  );
  0 and warn join("\n  ", "got deps:", @deps);

  use Config;

  $ENV{$Config{ldlibpthname}} = join($Config{path_sep},
    qw(/usr/lib /usr/local/lib)) if($^O eq 'linux');

  my @command = (
    $self->which_pp,
    '-o', $parfile,
    qw(-z 9),
    '-p', # plain par
    '-n', # no scanning, no compiling, no executing
    map({('-M', $_)} @deps),
    map({('-l', $_)} $self->external_libs),
    '-e', ';'
  );
  warn "pp for $parfile\n";
  0 and warn "# @command\n";
  system(@command) and die "$!";
  warn "par_wx done\n";
  $self->update_dep_version('wx');
} # end subroutine ACTION_par_wx definition
########################################################################

=head2 par_blacklist

Module::ScanDeps gets a bit too agressive

  $self->par_blacklist;

=cut

sub par_blacklist {
  my $self = shift;
  my @blacklist = qw(
    Log::Log4perl::Appender::DBI
    Log::Log4perl::Appender::RRDs
    Log::Log4perl::Appender::ScreenColoredLevels
    Log::Log4perl::Appender::Socket
    Log::Log4perl::Appender::Synchronized
    Log::Log4perl::Appender::TestArrayBuffer
    Log::Log4perl::Appender::TestBuffer
    Log::Log4perl::Appender::TestFileCreeper
  );
  return(@blacklist);
} # end subroutine par_blacklist definition
########################################################################

=item par_deps

Bundle all of the non-core, non-wx dependencies.

=cut

sub ACTION_par_deps {
  my $self = shift;

  my @req = keys(%{$self->requires});
  0 and warn join("\n  ", 'requires', @req);

  # TODO put those in a file somewhere for caching?
  # TODO versioning in client/build_info/par_versions/deps-v0.0.10.yml?
  $self->depends_on('par_wx');

  my $parfile = $self->par_deps;
  if(-e $parfile) { # if you have it, I'll say that's enough (for now)
    $self->log_info("Skip (up-to-date) building $parfile\n");
    return;
  }

  my $seed_par = $self->par_seed;
  my $wx_par = $self->par_wx;

  # to compile a list or not to compile a list?
  my @deps = $self->scan_deps(string => $self->dependency_hints);

  my @modlist = do {my %s; map({$s{$_} ? () : ($s{$_} = $_)} @deps, @req)};
  0 and warn join("\n  ", "modlist", @modlist);

  my @command = (
    $self->which_pp,
    '-o', $parfile,
    qw(-z 9),
    '-p', # plain par
    #'-n', # allow scanning (for now)
    map({('-M', $_)} @modlist),
    '-X', $seed_par,
    '-X', $wx_par,
    map({('-X', $_)} $self->par_blacklist),
    '-e', ';'
  );
  warn "pp for $parfile\n";
  0 and warn "# @command\n";
  system(@command) and die "$!";
  warn "par_deps done\n";
  $self->update_dep_version('deps');
} # end subroutine ACTION_par_deps definition
########################################################################

=item par_core


=cut

sub ACTION_par_core {
  my $self = shift;

  $self->depends_on('par_deps');
  my $parfile = $self->par_core;
  if(-e $parfile) { # if you have it, I'll say that's enough (for now)
    $self->log_info("Skip (up-to-date) building $parfile\n");
    return;
  }

  my $seed_par = $self->par_seed;
  my $wx_par = $self->par_wx;
  my $deps_par = $self->par_deps;

  my @our_mods = map({s#^lib/+##; $_} keys(%{$self->find_pm_files}));
  my @req = keys(%{$self->requires});

  # get the deplist from cache or scandeps on allmods+the hints file
  my @deps = $self->scan_deps(
    files => [@our_mods],
    modules => [@req],
    string => $self->dependency_hints,
  );
  0 and warn join("\n  ", 'deps are', @deps, '');

  my @command = (
    $self->which_pp,
    '-o', $parfile,
    qw(-z 9),
    '-I', $self->blib . '/lib',
    '-p', # plain par
    #'-n', # allow scanning (for now)
    map({('-M', $_)} @deps),
    '-X', $seed_par,
    '-X', $wx_par,
    '-X', $deps_par,
    map({('-X', $_)} $self->par_blacklist),
    '-B', # bundle core modules
    '-e', ';'
  );
  warn "pp for $parfile\n";
  0 and warn "# @command\n";
  local $ENV{PERL5LIB} = join($Config{path_sep}, $self->blib . '/lib',
    split($Config{path_sep}, $ENV{PERL5LIB} || ''));
  system(@command) and die "$!";
  warn "par_core done\n";
  $self->update_dep_version('core');
} # end subroutine ACTION_par_core definition
########################################################################

=item restore_par_cache

Assumes ~/.dotreader_dep_cache/

=cut

sub ACTION_restore_par_cache {
  my $self = shift;

  require File::Basename;
  require File::Path;
  require File::Copy;

  my @files = map({$self->$_} qw(par_core par_deps par_wx));
  my $dir = File::Basename::dirname($files[0]);
  File::Path::mkpath($dir) unless(-d $dir);

  foreach my $file (@files) {
    my $base = File::Basename::basename($file);
    if(-e $file) {
      warn "already have $base\n";
      next;
    }
    my $cached = $ENV{HOME} . '/.dotreader_dep_cache/' . $base;
    unless(-e $cached) {
      warn "no cache for $base\n";
      next;
    }
    1 and warn "$cached -> $file";
    File::Copy::copy($cached, $file);
  }
} # end subroutine ACTION_restore_par_cache definition
########################################################################

=item repar

Build and repackage the 'data/' directory for the par.

  ./Build repar

  ./Build repar nodata

=cut

sub ACTION_repar {
  my $self = shift;

  my @args = @{$self->{args}{ARGV}};
  my %args = map({ $_ => 1 } @args);

  if($args{nodata}) {
    warn "skipping datadir generation";
  }
  else {
    $self->depends_on('datadir');
  }

  require Archive::Zip;

  my $filename = $self->binfilename;

  my $src_dir = $self->datadir;
  (-e $src_dir) or
    die "you need to unset NO_DATA or manually build $src_dir";

  my $zip = Archive::Zip->new();
  $zip->read($filename) == Archive::Zip::AZ_OK or
    die("'$filename' is not a valid zip file.");
  $zip->updateTree($src_dir, 'data', sub {-f });
  $zip->overwrite( $filename ) == Archive::Zip::AZ_OK or die 'write error';
  undef($zip);

  rename($filename, "$filename.par") or die;
  system($self->which_pp, '-o', $filename, "$filename.par") and die;
  unlink("$filename.par") or warn "cannot remove '$filename.par' $!";
  warn "ok\n";
} # end subroutine ACTION_repar definition
########################################################################

=item datadir

Build the embedded par 'data/' directory in blib/pardata/.

=cut

sub ACTION_datadir {
  my $self = shift;

  # TODO up_to_date check?
  my $dest_dir = $self->datadir;
  $self->delete_filetree($dest_dir);
  File::Path::mkpath([$dest_dir]);

  warn "populating $dest_dir\n";
  require File::Find;

  require Cwd;
  my $ret_dir = Cwd::getcwd;
  chdir($self->clientdata) or die;
  File::Find::find({
    no_chdir => 1,
    wanted => sub {
    (-d $_) and return;
    #warn $_;
    m/\..*\.swp/ and return;
    if(-d $_ and m/\.svn/) {
      $File::Find::prune = 1;
      return;
    }
    $self->copy_if_modified(
      from    => $_,
      to      => "$ret_dir/$dest_dir/$_",
      verbose => 0,
    );
  }}, '.');
  chdir($ret_dir) or die;

  if(-e "$dest_dir/" . $self->release_file) {
    unlink("$dest_dir/" . $self->release_file) or die;
  }
  $self->write_release_file($dest_dir);

  require File::Copy;
  for (qw(log.conf.tmpl log.conf)) {
    unlink("$dest_dir/$_") or die $_;
    File::Copy::copy("$dest_dir/log.conf.par", "$dest_dir/$_");
  }

  foreach my $file (qw(LICENSE COPYING)) {
    $self->copy_if_modified(
      from    => $file,
      to      => "$dest_dir/$file",
      verbose => 1,
    );
  }

} # end subroutine ACTION_datadir definition
########################################################################


sub ACTION_appbundle {
  my $self = shift;

  $self->depends_on('datadir');
  local $self->{args}{deps} = 1;
  my $libs = $self->find_pm_files;
  local $self->{properties}{mm_also_scan} = [keys(%$libs)];
  local $self->{properties}{mm_add} = [
    $self->additional_deps,
    map({s#/+#::#g; s/\.pm//; $_} grep({m/\.pm$/}
      $self->scan_deps(string => $self->dependency_hints)
    )),
  ];
  my $mm = # TODO some way to do that with SUPER::
    Module::Build::Plugins::MacBundle::ACTION_appbundle($self, @_);

  # XXX ugh, bit of thrashing-about involved here
  # copy
  my $dest = $self->binfilename;
  #if(-e $dest) {
  #  File::Path::rmtree($dest) or die $!;
  #}
  unless(-d $dest) {
    File::Path::mkpath($dest) or die "$dest $!";
  }
  warn "copy to $dest";
  system('rsync', '-a', '--delete',
    $mm->built_dir . '/', $dest . '/') and die;

  # datadir
  system('rsync', '-a', '--delete',
    $self->datadir . '/', "$dest/Contents/Resources/data/") and die;

} # end subroutine ACTION_appbundle definition
########################################################################

=item parmanifest

Extract the MANIFEST file from the current par (saves compilation time
on the next BUILD par)

=cut

sub ACTION_parmanifest {
  my $self = shift;

  my $filename = $self->binfilename;
  my $parmanifest = $self->parmanifest;
  open(my $fh, '>', $parmanifest) or
    die "cannot write to $parmanifest $!";
  print $fh $self->grab_manifest($filename);
} # end subroutine ACTION_parmanifest definition
########################################################################

=item starter_data

Assemble a default config, library, and some free books in
"binary_build/dotreader-data/"

=cut

sub ACTION_starter_data {
  my $self = shift;

  my %args = $self->args;

  my $data_dir = $self->starter_data_dir . '/';

  $self->want_path($data_dir, clean => $args{clean});

  { # touch this
    open(my $fh, '>', $data_dir . 'first_time') or
      die "cannot touch first_time $!";
  }

  $self->copy_files(
    'client/setup/default_drconfig.yml',
    $data_dir . 'drconfig.yml',
    verbose => 1,
  );

  my @books = $self->default_booklist;
  foreach my $book (@books) {
    (-e $book) or die "need '$book' to build starter_data";
  }

  my $libfile = $data_dir . 'default_library.yml';
  my $libdir = $libfile;
  $libdir =~ s/\.yml//;
  require File::Basename;
  my @destbooks = map({
    $libdir . '/' . File::Basename::basename($_)
  } @books);
  if($self->up_to_date(\@books, \@destbooks)) { # Already fresh
    $self->log_info("Skip (up-to-date) $libfile\n");
  }
  else {
    $self->log_info("Create $libfile...");
    {
      local $self->{properties}{quiet} = 1;
      $self->run_perl_script(
        'util/mk_library', [],
        [
          '-f',
          $libfile,
          @books
        ],
      );
    }
    $self->log_info("done\n");
  }

  # standard plugins
  my @plugins = $self->default_plugins;
  require File::Path;
  my $pdir = $data_dir . 'plugins/';
  $self->want_path($pdir, clean => $args{clean});
  foreach my $dir (@plugins) {
    $dir =~ s#/+$##;
    my $mfile = File::Spec->catfile($dir,
      File::Basename::basename($dir) . '.MANIFEST'
    );
    $self->copy_from_manifest($mfile, $dir, $pdir);
  }

  # TODO add some annotation data, bells, whistles, etc

} # end subroutine ACTION_starter_data definition
########################################################################

=item binary

Builds the binary and starter data for the current platform.

=cut

sub ACTION_binary {
  my $self = shift;
  my %args = $self->args;
  $self->depends_on( ($^O eq 'darwin') ?  'appbundle' : 'par' );
  $args{bare} or $self->depends_on('starter_data');
} # end subroutine ACTION_binary definition
########################################################################

=item binary_package

Build the binary, starter data, and wrap it up.

Also takes a --bare argument

=cut

sub ACTION_binary_package {
  my $self = shift;
  $self->depends_on('binary');
  my %choice = map({$_ => $_} qw(darwin MSWin32));
  my $method = 'binary_package_' . ($choice{$^O} || 'linux');
  $self->$method;
} # end subroutine ACTION_binary_package definition
########################################################################

=back

=cut

########################################################################
# NO MORE ACTIONS
########################################################################

=head1 Helpers and Such

=head2 binary_package_name

Assembles platform, modifiers, version (and previewness) values into a
name (without .extension)

  my $packname = $self->binary_package_name;

=cut

sub binary_package_name {
  my $self = shift;

  my %args = $self->args;

  my %choice = (
    darwin => 'mac',
    MSWin32 => 'win32',
  );

  # maybe TODO ignore the --mini option on mac
    # my %nomini = map({$_ => 1} qw(mac));
    #((! $nomini{$platform} and $args{mini}) ? 'mini' : ()),

  my $platform = $choice{$^O} || $^O;
  my @special = (
    ($args{mini} ? 'mini' : ()),
    ($args{bare} ? 'bare' : ()),
  );
  my @extra; # ppc, dev, etc (not currently used)
  my $bump; # e.g. pre
  my $name = join('-',
    lc($self->dist_name),
    @special,
    $platform,
    @extra,
    $self->bin_version
  );
  return($name);
} # end subroutine binary_package_name definition
########################################################################

=head2 binary_package_linux

Linux and others.

  $self->binary_package_linux;

=cut

sub binary_package_linux {
  my $self = shift;

  my $packname = $self->binary_package_name;
  warn "package name $packname";

  require File::Path;
  if(-e $packname) {
    File::Path::rmtree($packname);
  }
  mkdir($packname) or die "cannot create directory '$packname'";
  $self->copy_package_files($packname);
  my $tarball = $self->distfilename;
  if(-e $tarball) {
    unlink($tarball) or die "cannot delete $tarball -- $!";
  }
  system('tar', '-czhvf', $tarball, $packname) and
    die "tarball failed $!";
  # cleanup
  File::Path::rmtree($packname);
} # end subroutine binary_package_linux definition
########################################################################

=head2 binary_package_darwin

  $self->binary_package_darwin;

=cut

sub binary_package_darwin {
  my $self = shift;

  my %args = $self->args;
  my $packname = $self->binary_package_name;

  warn "package name $packname";
  my $size = 0;
  {
    require IPC::Run;
    my ($in, $out, $err);
    IPC::Run::run(['du', '-ks', $self->binfilename,
      ($args{bare} ? () : $self->starter_data_dir)],
    \$in, \$out, \$err) or die "failed $err";
    $size += $_ for(map({s/\s.*//; $_} split(/\n/, $out)));
    $size = int($size / 1024) + 5;
  }

  # XXX this is pretty slow at 45MB
  my $tmpdmg = '/tmp/tmp.dmg';
  unlink($tmpdmg);
  warn "create dmg at $size MB\n";
  system(qw(hdiutil create -size), $size . 'm',
    qw(-fs HFS+ -volname), $packname, $tmpdmg) and die $!;
  # TODO check for failed umount
  system(qw(hdiutil attach), $tmpdmg) and die $!;

  warn "copy to image\n";
  system('rsync', '-a', $self->binfilename, '/Volumes/' . $packname)
    and die "$!";
  unless($args{bare}) {
    system('rsync', '-a',
      $self->starter_data_dir, '/Volumes/' . $packname) and die "$!";
  }

  # only on recent osx
  system(qw(hdiutil detach), '/Volumes/' . $packname) and die $!;

  my $outdmg = $self->distfilename;
  unlink($outdmg);
  warn "convert dmg\n";
  system(qw(hdiutil convert), $tmpdmg, qw(-format UDZO), '-o', $outdmg)
    and die $!;


} # end subroutine binary_package_darwin definition
########################################################################

=head2 binary_package_MSWin32

  $self->binary_package_MSWin32;

=cut

sub binary_package_MSWin32 {
  my $self = shift;

  my $packname = $self->binary_package_name;
  warn "package name $packname";

  require File::Path;
  if(-e $packname) {
    File::Path::rmtree($packname);
  }
  mkdir($packname) or die "cannot create directory '$packname'";
  $self->copy_package_files($packname);
  my $zipfile = $self->distfilename;
  if(-e $zipfile) {
    unlink($zipfile) or die "cannot delete $zipfile -- $!";
  }
  my $zipname = 'dotreader.zip';
  if(-e $zipname) {
    unlink($zipname) or die "cannot delete $zipname -- $!";
  }
  system('zip', '-r', $zipname, $packname) and die $!;
  require File::Which;
  my $unzipsfx = File::Which::which('unzipsfx');
  $unzipsfx or die "you need unzipsfx";
  my $zip;
  foreach my $file ($unzipsfx, $zipname) {
    open(my $fh, '<', $file) or die "$file $!";
    binmode($fh);
    local $/;
    $zip .= <$fh>;
  }
  {
    open(my $ofh, '>', $self->distfilename) or die $!;
    binmode($ofh);
    print $ofh $zip;
    close($ofh) or die $!;
  }

  system('zip', '-A', $self->distfilename);
  # cleanup
  File::Path::rmtree($packname);
} # end subroutine binary_package_MSWin32 definition
########################################################################

=head2 copy_package_files

  $self->copy_package_files($dir); # useful for mac too

=cut

sub copy_package_files {
  my $self = shift;
  my ($dir) = @_;

  my %args = $self->args;

  require File::NCopy;
  my $copy = sub {
    my ($file) = @_;
    File::NCopy->new(
      recursive      => 1,
      #set_permission => sub {chmod(0700, $_[1]) or die $!},
      )->copy($file, $dir . '/') or die "copy failed $!";
    };
  $copy->($self->binfilename);
  if($args{mini}) {
    # don't ship the cache dir
    my $depdir = $dir . '/' . $self->par_deps_base;
    mkdir($depdir) or die;
    $depdir .= '/';
    for(map({$self->$_} qw(par_wx par_core par_deps))) {
      File::NCopy->new->copy($_, $depdir) or die;
    }
  }
  $args{bare} or $copy->($self->starter_data_dir);
} # end subroutine copy_package_files definition
########################################################################

=head2 _module_map

  my %map = _module_map()

=cut

sub _module_map {
  # /me shakes fist at Module::Build, pokes around in guts...
  # my $pm = $self->find_pm_files;
  # die join("\n", map({"$_ => $pm->{$_}"} keys(%$pm)));
  require File::Find;
  my @files;
  File::Find::find(sub {
    /\.pm$/ or return;
    push(@files, $File::Find::name);
    }, 'lib/');
  my %modmap = map({
    my $mod = $_;
    $mod =~ s#lib/##;
    $mod =~ s#\\|/#::#g;
    $mod =~ s/\.pm$// or die;
    $mod => $_;
    }
    @files
  );
  return(%modmap);
} # end subroutine _module_map definition
########################################################################

=head2 run_binary

Run the binary, returns stdout and stderr strings, replaces the
first_time file (if it didn't crash.)

  my ($out, $err) = $self->run_binary;

=cut

sub run_binary {
  my $self = shift;

  # build it
  $self->depends_on('binary');
  $self->depends_on('starter_data');

  my $ft_file = $self->starter_data_dir . '/first_time';
  (-e $ft_file) or die "first_time file did not get created";

  my $file = $self->binfilename_sys;
  warn "launch $file\n";
  require IPC::Run;
  my ($out, $err);
  IPC::Run::run([$file], \*STDIN, \$out, \$err) # TODO tee stderr
    or die "bad exit status $! $? ($err)";

  # check
  (-e $ft_file) and die "first_time file did not get deleted";
  open(my $fh, '>', $ft_file); # putback

  return($out, $err)
} # end subroutine run_binary definition
########################################################################

=head2 binfilename

A filename for the binary.

=cut

sub binfilename {
  my $self = shift;

  my %args = $self->args;
  return($self->binary_build_dir . '/' . $self->dist_name . '.app')
    if($^O eq 'darwin');

  return(
    $self->binary_build_dir .
      '/' . $self->dist_name .
      ($args{mini} ? '-mini' : '') .
      ($^O eq 'MSWin32' ? '.exe' : '')
  );
} # end subroutine binfilename definition
########################################################################

=head2 binfilename_sys

The mac binfilename is a directory.  This gets an actual binary
filename.  On windows and linux it is exactly binfilename().

=cut

sub binfilename_sys {
  my $self = shift;
  return( 
    $self->binfilename . 
    (($^O eq 'darwin') ? ('/Contents/MacOS/' . $self->dist_name) : '')
  );
} # end subroutine binfilename_sys definition
########################################################################

=head2 bin_version

Same as dist_version I<iff> C<--release V>

  $self->bin_version;

=cut

sub bin_version {
  my $self = shift;

  my %args = $self->args;
  my $v = '' . $self->dist_version;

  my $r = lc($args{release});

  if($r eq 'v') {
  }
  elsif($args{release} eq 'p') {
    $v =~ s/^v/p/ or die "oops";
    my $preview = uc($args{preview});
    $preview =~ m/^[A-Z0-9]+$/ or
      die "invalid preview value: '$args{preview}'";
    $v .= '.' . $preview;
  }
  else { # there was a 't' for 'tag', but I don't like it so...
    die "invalid release arg '$r'";
  }

  return($v);
} # end subroutine bin_version definition
########################################################################

# the distribution file (depends on current options)
sub distfilename {
  my $self = shift;
  my $packname =
    $self->binary_build_dir . '/' .
    $self->binary_package_name . $self->distfile_extension;
  return($packname);
}
sub distfile_extension {
  my $self = shift;
  my %choice = (
    darwin => '.dmg',
    MSWin32 => '.exe',
  );
  return($choice{$^O} || '.tar.gz');
}

sub starter_data_dir {
  my $self = shift;
  return($self->binary_build_dir . '/' . lc($self->dist_name) . '-data');
}

use constant {
  clientdata       => 'client/data',
  binary_build_dir => 'binary_build',
};
{ # some 'constants' conditional on blib()
  my %blibdefs = (
    datadir          => 'pardata',
    parmanifest      => 'parmanifest',
    parmain_pl       => 'dotReader.pl',
  );
  foreach my $key (keys(%blibdefs)) {
    my $sub = sub {
      my $self = shift;
      return $self->blib . '/' . $blibdefs{$key};
    };
    no strict 'refs';
    *{$key} = $sub;
  }
}

sub par_deps_dir {
  my $self = shift;
  return($self->binary_build_dir . '/' . $self->par_deps_base);
}
sub par_deps_base { return lc(shift->dist_name) . '-deps'; }

sub par_seed { shift->binary_build_dir . '/seed.par', };
sub par_mini {
  my $self = shift;
  return($self->binary_build_dir . '/' .
    join('-',
      $self->dist_name . '-mini',
      $self->bin_version,
      $self->short_archname,
      $Config{version}
    ) .'.par');
}
foreach my $tag (qw(wx deps core)) {
  my $sub = sub {
    my $self = shift;
    $self->par_deps_dir . '/' . $self->par_dep_file($tag)
  };
  my $subname = 'par_' . $tag;
  no strict 'refs';
  *{$subname} = $sub;
}

sub version_file {
  my $self = shift;
  my $tag = shift;
  use Config;
  my $file = "client/build_info/deplist.$tag-" .
    $self->short_archname . "-$Config{version}.yml";
}

=head2 par_dep_file

Returns the basename for the par dependency file.

  $file = $self->par_dep_file($tag);

=cut

sub par_dep_file {
  my $self = shift;
  my ($tag) = @_;
  my $version = $self->dep_version($tag);
  return(
    join('-', $tag, $version, $self->short_archname, $Config{version}) .
    '.par'
  );
} # end subroutine par_dep_file definition
########################################################################
use constant {
  short_archname => sub {
    my $n = shift;
    $n =~ s/-(.*)$//;
    return($n . '.' . join('',
      map({m/^(.*\d+)/ ? $1 : substr($_, 0, 1)} split(/-/, $1))
      ));
  }->($Config{archname})
};

=head2 update_dep_version

Returns a new version number for the dependency tag or undef if it has
not changed.

  $version = $self->update_dep_version($tag);

=cut

sub update_dep_version {
  my $self = shift;
  my ($tag) = @_;

  my $checkfile = $self->deplist_file($tag);
  # read the existing data
  my ($version, $old_deps);
  if(open(my $fh, '<', $checkfile)) {
    chomp($version = <$fh>);
    local $/;
    $old_deps = <$fh>;
    $old_deps =~ s/\n+$//;
  }
  # get the manifest from the archive
  my $depmethod = 'par_' . $tag;
  my $archive = $self->$depmethod;
  my $new_deps;
  { # bunch of details here
    my $man = $self->grab_manifest($archive);
    my @mods = split(/\n/, $man);
    if($^O eq 'MSWin32') { # grr, scandeps problem?
      foreach my $mod (@mods) {
        if($mod =~ s#^lib/+([a-z]:/)#$1#i) {
          warn "mod fix $mod\n";
          my $kill_inc = join("|", map({quotemeta($_)}
            sort({length($b) <=> length($a)} @INC))
          );
          warn "kill inc $kill_inc";
          $mod =~ s/^(?:$kill_inc)/lib\//i;
        }
      }
    }
    my @deps = grep(
      {
        $_ !~ m#^auto/# and
        $_ !~ m#^unicore/#
      }
      map({chomp;s#^lib/+##;$_} 
        grep({m#^lib/# and m/\.pm$/} @mods)
      )
    );
    for(@deps) { s#/+#::#g; s/\.pm$//;}

    warn "get versions\n";
    my %depv;
    foreach my $mod (@deps) {
      my $v = Module::Build::ModuleInfo->new_from_module(
        $mod, collect_pod => 0
      );
      defined($v) or die "cannot create ModuleInfo for $mod";
      $v = $v->version;
      $v = $v->stringify if(defined($v) and ref($v));
      $depv{$mod} = defined($v) ? $v : '~';
    }
    $new_deps = join("\n", map({"$_ $depv{$_}"} sort(keys(%depv))));
  } # end dep-details

  0 and warn "new deps:\n$new_deps\n";

  return if($new_deps eq (defined($old_deps) ? $old_deps : ''));

  # make dep versions vX.Y.Q, where Q is independent, but vX.Y stays
  # roughly in-sync with the main dist
  my $dist_version = $self->dist_version;
  my $dist_XY = $dist_version;
  $dist_XY =~ s/\.\d+$//;
  if($version =~ m/^$dist_XY\.(\d+)/) {
    $version = $dist_XY . '.' . ($1 + 1);
  }
  else {
    $version = $dist_version;
  }

  warn "$tag version changed to $version\n";

  # save the data
  open(my $fh, '>', $checkfile) or die "cannot write $checkfile";
  print $fh join("\n", $version, $new_deps, '');
  close($fh) or die "write $checkfile failed";
  # rename the archive
  rename($archive, $self->$depmethod) or die "cannot rename $archive";
  # and return the new version
  return($version);
} # end subroutine update_dep_version definition
########################################################################

=head2 dep_version

Returns the current version number for the dependency tag.  This will be
the dotReader version number at which it was last changed.

  $version = $self->dep_version($tag);

=cut

sub dep_version {
  my $self = shift;
  my ($tag) = @_;

  my $version;

  my $checkfile = $self->deplist_file($tag);
  if(-e $checkfile) {
    open(my $fh, '<', $checkfile);
    my $v = <$fh>;
    chomp($v);
    length($v) or die "bad $checkfile";
    $v =~ m/^v\d+\.\d+\.\d+$/ or die "bad version '$v' in $checkfile";
    $version = $v;
  }
  return($version || $self->dist_version);
} # end subroutine dep_version definition
########################################################################

# just to debug option parser
sub ACTION_argv {my $self = shift;
  my %args = $self->args;
  warn "actual \@ARGV: ", join(',', @ARGV), "\n";
  warn "ARGV: ", join(',', @{delete($args{ARGV})}), "\n";
  warn join("\n  ", 'args:', map({"$_ => $args{$_}"} keys %args)), "\n";
  if(my $do = $args{do}) {
    eval($do);
    $@ and die "oops $@";
  }
}
sub get_options {
  my $self = shift;
  my $specs = $self->SUPER::get_options;
  my %own_specs = (
    #'foo' => {}, # a simple boolean
    #'bar' => {type => '=s'}
    mini    => {},
    bare    => {},
    clean   => {},
    release => {type => '=s', default => 'p'},
    preview => {type => '=s', default => 'A'},
    nolink  => {}, # not really sure whether that should even exist
    gui     => {type => '!', default => 1},
    do      => {type => '=s'},
  );
  #warn "specs: ", %$specs;
  return({%$specs, %own_specs});
}

=head2 deplist_file

  my $checkfile = $self->deplist_file($tag);

=cut

sub deplist_file {
  my $self = shift;
  my ($tag) = @_;

  my $checkfile = 'client/build_info/' . 'deplist.' .
    join('-', $tag, $self->short_archname, $Config{version});
} # end subroutine deplist_file definition
########################################################################

sub _my_args {
  my $self = shift;

  # XXX quit using this

  my %args = $self->args;
  # TODO index this by the calling subroutine?
  my @bin_opts = qw(
    clean
    nolink
    bare
    mini
  );
  foreach my $opt (@bin_opts) {
    $args{$opt} = 1 if(exists($args{$opt}));
  }
  return(%args);
}

# for par (TODO put this elsewhere)
sub additional_deps {
  qw(
    Log::Log4perl::Appender::File
    Log::Log4perl::Appender::Screen
  );
}

=head2 dependency_hints

  my $string = $self->dependency_hints;

=cut

sub dependency_hints {
  my $self = shift;
  open(my $fh, '<', 'client/build_info/runtime_deps.pm') or die;
  local $/ = undef;
  return(<$fh>);
} # end subroutine dependency_hints definition
########################################################################

=head2 external_libs

  @libs = $self->external_libs;

=cut

sub external_libs {
  my $self = shift;

  my @wxlibs;
  my @other_dll;
  if($^O eq 'linux') {
    require IPC::Run;
    my $prefix;
    {
      my ($in, $out, $err);
      IPC::Run::run([qw(wx-config --prefix)], \$in, \$out, \$err) or die;
      $out or die;
      chomp($out);
      $prefix = $out;
    }
    {
      my ($in, $out, $err);
      IPC::Run::run([qw(wx-config --libs)], \$in, \$out, \$err) or die;
      $out or die;
      @wxlibs = map({s/^-l//; "$prefix/lib/lib$_.so"} # glob?
        grep(/^-l/, split(/ /, $out)));
      0 and warn "wx libs: @wxlibs";
    }
    push(@wxlibs, qw(
      tiff
      wxmozilla_gtk2u-2.6
      ),
      # I'm really getting tired of trying to bundle mozilla
      (0 ? qw(
        gtkembedmoz
        xpcom
        nspr4
        libmozjs
        jsj
        libmozz
      ) : () ),
    );
    push(@other_dll, qw(
      /usr/lib/libstdc++.so.6
      /usr/lib/libexpat.so.1
    ));
  }
  elsif($^O eq 'MSWin32') {
    @wxlibs = map({'C:/Perl/site/lib/auto/Wx/' . $_}
      qw(
        mingwm10.dll
        wxbase26_gcc_custom.dll
        wxbase26_net_gcc_custom.dll
        wxbase26_xml_gcc_custom.dll
        wxmsw26_adv_gcc_custom.dll
        wxmsw26_core_gcc_custom.dll
        wxmsw26_gl_gcc_custom.dll
        wxmsw26_html_gcc_custom.dll
        wxmsw26_media_gcc_custom.dll
        wxmsw26_stc_gcc_custom.dll
        wxmsw26_xrc_gcc_custom.dll
      ),
    );
    if(0) { # make that unicode
      s/26_/26u_/ for(@wxlibs);
    }

  }
  else {
    # mac gets an appbundle
    die "building a par for VMS now, eh?";
  }
  return(@wxlibs, @other_dll);
} # end subroutine external_libs definition
########################################################################

=head2 which_pp

The pp command

=cut

sub which_pp {
  my $self = shift;
  return(($^O eq 'MSWin32') ? ($self->perl, 'c:/perl/bin/pp') : ('pp'));
} # end subroutine which_pp definition
########################################################################

=head2 grab_manifest

  $string = $self->grab_manifest($zipfile);

=cut

sub grab_manifest {
  my $self = shift;
  my ($filename) = @_;

  require Archive::Zip;
  my $zip = Archive::Zip->new;
  $zip->read($filename);
  my $member = $zip->memberNamed('MANIFEST');
  return($zip->contents($member));
} # end subroutine grab_manifest definition
########################################################################

# TODO put this in dtRdr.pm?
use constant {release_file => 'dotreader_release'};
sub write_release_file {
  my $self = shift;
  my ($location) = @_;

  # let this get a different value from somewhere
  my %args = $self->args;
  my $release = uc($args{'release'});
  if($release) {
    if($release eq 'T') { # don't know if I'll use this, but here
      $release = svn_tag() or die "not in a tag";
    }
    elsif($release eq 'V') {
      $release = $self->bin_version;
    }
    elsif($release eq 'P') {
      $release = 'pre-release ' . $self->bin_version . '';
    }
  }

  $release .= ' (' . svn_rev() . ') built ' . scalar(localtime);

  my $file = "$location/" . $self->release_file;
  open(my $fh, '>', $file) or die "cannot write $file ($!)";
  print $fh $release;
}
sub svn_rev {
  require IPC::Run;
  unless(-e '.svn') {
    my ($in, $out, $err);
    my @command = ('svk', 'info');
    ($^O eq 'MSWin32') and return('notsvn'); # bah
    eval {IPC::Run::run(\@command, \$in, \$out, \$err)}
      or return("notsvn-" . time());
    my ($rev) = grep(/^Revision/, split(/\n/, $out));
    $rev or die "can't find revision in output >>>$out<<<";
    $rev =~ s/Revision: *//;
    return('svk' . $rev);
  }
  my ($in, $out, $err);
  my @command = ('svn', 'info');
  IPC::Run::run(\@command, \$in, \$out, \$err) or die "eek $err";
  my ($rev) = grep(/^Revision/, split(/\n/, $out));
  $rev or die "can't find revision in output >>>$out<<<";
  $rev =~ s/Revision: *//;
  return('svn' . $rev);
}
sub svn_tag {
  (-e '.svn') or return();
  my ($in, $out, $err);
  my @command = ('svn', 'info');
  require IPC::Run;
  IPC::Run::run(\@command, \$in, \$out, \$err) or die "eek $err";
  my ($url) = grep(/^URL/, split(/\n/, $out));
  $url or die "can't find URL in output >>>$out<<<";
  $url =~ s/URL: *//;
  if($url =~ m#/tags/([^/]+)(?:/|$)#) {
    return($1);
  }
  return();
}

=head2 scan_deps

  $self->scan_deps(
    modules => \@mods,
    files => \@files,
    string => \$string
  );

=cut

sub scan_deps {
  my $self = shift;
  my %args = @_;

  require Module::ScanDeps;
  require File::Temp;
  require File::Spec;
  require Config;
  my ($fh, $tmpfile) = File::Temp::tempfile('dtRdrBuilder-XXXXXXXX',
    UNLINK => 1, DIR => File::Spec->tmpdir,
  );
  0 and warn "writing to $tmpfile";
  print $fh "BEGIN {\n";

  foreach my $mod (@{$args{modules} || []}) {
    print $fh qq(require $mod;\n);
  }
  foreach my $file (@{$args{files} || []}) {
    print $fh qq(require("$file");\n);
  }
  defined($args{string}) and print $fh $args{string}, "\n";

  print $fh "} # close begin\n1;\n";
  close($fh) or die "out of space?";

  local $ENV{PERL5LIB} = join($Config{path_sep}, $self->blib . '/lib',
    split($Config{path_sep}, $ENV{PERL5LIB} || ''));
  my $hash_ref = Module::ScanDeps::scan_deps_runtime(
    files => [$tmpfile], compile => 1, recurse => 0,
  );
  #unlink($tmpfile) or die "cannot remove $tmpfile";
  my @files =
    grep({$_ !~ m/\.$Config{dlext}$/}
    grep({$_ !~ m/\.bs$/}
      keys(%$hash_ref)
    ));
  return(@files);
} # end subroutine scan_deps definition
########################################################################

=head2 copy_from_manifest

  $self->copy_from_manifest($mfile, $srcdir, $destdir);

=cut

sub copy_from_manifest {
  my $self = shift;
  my ($mfile, $srcdir, $dstdir) = @_;

  (-e $mfile) or die "cannot copy_from_manifest without $mfile";

  # hmm, should we be able to do this?
  #my ($mfile, @and) = glob("$srcdir/*MANIFEST");
  #$mfile or die "no *MANIFEST found";
  #@and and die "too many *MANIFEST files in $srcdir";

  # XXX it's not really a manifest without comments, but I doubt that we
  # want a cannot-have-spaces ExtUtils::Manifest either
  my @manifest = do {
    open(my $fh, '<', $mfile) or die $!;
    map({chomp; $_} <$fh>);
  };

  foreach my $file (@manifest) {
    $self->copy_files(
      File::Spec->catfile($srcdir, $file),
      File::Spec->catfile($dstdir, $file),
      verbose => 1
    );
  }
} # end subroutine copy_from_manifest definition
########################################################################

# TODO have a manifest for shippable books?
use constant default_booklist => map({"books/default/$_.jar"} qw(
  dotReader_beta_QSG
  Alienation_Victim
  publication_556
  rebel-w-o-car
  seventy_five_times
  Reflections
  dpp_reader
));

use constant default_plugins => qw(
  example_plugins/InfoButton/
);

=head1 Overridden Methods

=head2 find_pm_files

Overridden to eliminate platform-specific deps.

Also, fixes QDOS problems.

  $self->find_pm_files;

=cut

sub find_pm_files {
  my $self = shift;
  my $files = $self->SUPER::find_pm_files;

  if($^O eq 'MSWin32') {
    %$files = map({my $v = $files->{$_}; s#\\#/#g; ($_ => $v)}
      keys(%$files)
    );
  }

  my @deletes;
  unless($^O eq 'MSWin32') {
    push(@deletes,
      'dtRdr::HTMLShim::ActiveXIE',
      'dtRdr::HTMLShim::ActiveXMozilla',
    );
  }
  unless($^O eq 'darwin') {
    push(@deletes,
      'dtRdr::HTMLShim::WebKit'
    );
  }
  unless($^O eq 'linux') {
    push(@deletes,
      'dtRdr::HTMLShim::WxMozilla'
    );
  }
  for(@deletes) {
    s#::#/#g;
    $_ = 'lib/' . $_ . '.pm';
  }
  delete($files->{$_}) for(@deletes);
  return($files);
} # end subroutine find_pm_files definition
########################################################################

sub ACTION_build {
  my $self = shift;
  $self->depends_on('books'); # XXX ick -- needed for disttest to pass
  $self->SUPER::ACTION_build;
} # end subroutine ACTION_build definition
########################################################################

sub ACTION_manifest {
  my $self = shift;
  $self->SUPER::ACTION_manifest;
  open(my $afh, '<', 'MANIFEST.add') or die;
  open(my $mfh, '>>', 'MANIFEST') or die;
  print $mfh join('', <$afh>);
} # end subroutine ACTION_manifest definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, neither Eric Wilhelm, nor anyone else, owes you anything
whatseover.  You have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
