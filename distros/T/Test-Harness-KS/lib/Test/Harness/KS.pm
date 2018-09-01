package Test::Harness::KS;
# ABSTRACT: Harness the power of clover and junit in one easy to use wrapper.
#
# Copyright 2018 National Library of Finland
# Copyright 2017 KohaSuomi

=head1 NAME

Test::Harness::KS

=head1 SYNOPSIS

Runs given test files and generates clover, html and junit test reports to the given directory.

Automatically sorts given test files by directory and deduplicates them.

See

 test-harness-ks --help

for commandline usage

=head1 USAGE

  my $harness = Test::Harness->new($params);
  $harness->run();

=cut

##Pragmas
use Modern::Perl;
use Carp::Always;
use autodie;
use English; #Use verbose alternatives for perl's strange $0 and $\ etc.
use Try::Tiny;
use Scalar::Util qw(blessed);
use Cwd;

##Testing harness libraries
sub _loadJUnit() {
  require TAP::Harness::JUnit;
}
sub _loadCover() {
  require Devel::Cover; #Require coverage testing and extensions for it. These are not actually used in this package directly, but Dist::Zilla uses this data to autogenerate the dependencies
  require Devel::Cover::Report::Clover;
  require Template;
  require Perl::Tidy;
  require Pod::Coverage::CountParents;
  require Test::Differences;
}


##Remote modules
use IPC::Cmd;
use File::Basename;
use File::Path qw(make_path);
use Params::Validate qw(:all);
use Data::Dumper;
use Storable;

use Log::Log4perl qw(get_logger);
use Log::Log4perl::Level;

=head2 new

Creates a new Test runner

Configure log verbosity by initializing Log::Log4perl beforehand, otherwise the internal logging defaults to WARN

 @params HashRef: {
          resultsDir => String, directory, must be writable. Where the test deliverables are brought
          tar        => Boolean
          cover      => Boolean
          junit      => Boolean
          testFiles  => ARRAYRef, list of files to test
          dryRun     => Boolean
          lib        => ARRAYRef or undef, list of extra include directories for the test files
        }

=cut

my $validationTestFilesCallbacks = {
  'files exist' => sub {
    die "not an array" unless (ref($_[0]) eq 'ARRAY');
    die "is empty" unless (scalar(@{$_[0]}));

    my @errors;
    foreach my $file (@{$_[0]}) {
      push(@errors, "$file is not readable") unless (-r $file);
    }
    return 1 unless @errors;
    die "files are not readable:\n".join("\n",@errors);
  },
};
my $validationNew = {
  resultsDir => {
    callbacks => {
      'resultsDir is writable' => sub {
        if ($_[0]) {
          return (-w $_[0]);
        }
        else {
          return 1 if (-w File::Basename::dirname($0));
          die "No --results-dir was passed, so defaulting to the directory of the program used to call me '".File::Basename::dirname($0)."'. Unfortunately that directory is not writable by this process and I don't know where to save the test deliverables."
        }
      },
    },
  },
  tar => {default => 0},
  cover  => {default => 0},
  junit  => {default => 0},
  dryRun => {default => 0},
  lib     => {
    default => [],
    callbacks => {
      'lib is an array or undef' => sub {
        return 1 unless ($_[0]);
        if (ref($_[0]) eq 'ARRAY') {
          return 1;
        }
        else {
          die "param lib is not an array";
        }
      },
    },
  },
  testFiles => {
    callbacks => $validationTestFilesCallbacks,
  },
  dbDiff => {default => 0},
  dbUser => {default => undef},
  dbPass => {default => undef},
  dbHost => {default => undef},
  dbPort => {default => undef},
  dbDatabase => {default => undef},
  dbSocket => {default => undef},
  dbDiffIgnoreTables => {default => undef}
};

use fields qw(resultsDir tar cover junit dryRun lib testFiles testFilesByDir dbDiff dbUser dbPass dbHost dbPort dbDatabase dbSocket dbDiffIgnoreTables);

sub new {
  unless (Log::Log4perl->initialized()) { Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority( 'WARN' ) ); }

  my $class = shift;
  my $params = validate(@_, $validationNew);

  my $self = Storable::dclone($params);
  bless($self, $class);

  $self->{testFilesByDir} = _sortFilesByDir($self->{testFiles});

  _loadJUnit() if $self->{junit};
  _loadCover() if $self->{cover};

  return $self;
}

=head2 run

  $harness->run();

Executes the configured test harness.

=cut

sub run {
  my ($self) = @_;

#  $self->_changeWorkingDir();
  $self->_prepareTestResultDirectories();
  $self->clearCoverDb() if $self->{cover};
  $self->_runharness();
  $self->createCoverReport() if $self->{cover};
  $self->tar() if $self->{tar};
#  $self->_revertWorkingDir();
}

sub _changeWorkingDir {
  my ($self) = @_;

  $self->{oldWorkingDir} = Cwd::getcwd();
  chdir $self->{resultsDir} || File::Basename::dirname($0);
}

sub _revertWorkingDir {
  my ($self) = @_;

  die "\$self->{oldWorkingDir} is not known when reverting to the old working directory?? This should never happen!!" unless $self->{oldWorkingDir};
  chdir $self->{oldWorkingDir};
}

sub _prepareTestResultDirectories {
  my ($self) = @_;
  $self->getTestResultFileAndDirectoryPaths($self->{resultsDir});
  mkdir $self->{testResultsDir} unless -d $self->{testResultsDir};
  $self->_shell("rm", "-r $self->{junitDir}")  if -e $self->{junitDir};
  $self->_shell("rm", "-r $self->{coverDir}") if -e $self->{coverDir};
  $self->_shell("rm", "-r $self->{dbDiffDir}")  if -e $self->{dbDiffDir};
  mkdir $self->{junitDir} unless -d $self->{junitDir};
  mkdir $self->{coverDir} unless -d $self->{coverDir};
  mkdir $self->{dbDiffDir} unless -d $self->{dbDiffDir};
  unlink $self->{testResultsArchive} if -e $self->{testResultsArchive};
}

=head2 clearCoverDb

Empty previous coverage test results

=cut

sub clearCoverDb {
  my ($self) = @_;
  $self->_shell('cover', "-delete $self->{cover_dbDir}");
}

=head2 createCoverReport

Create Cover coverage reports

=cut

sub createCoverReport {
  my ($self) = @_;
  $self->_shell('cover', "-report clover -report html -outputdir $self->{coverDir} $self->{cover_dbDir}");
}

=head2 tar

Create a tar.gz-package out of test deliverables

Package contains

  testResults/cover/clover.xml
  testResults/cover/coverage.html
  testResults/cover/*
  testResults/junit/*.xml

=cut

sub tar {
  my ($self) = @_;
  my $baseDir = $self->{resultsDir};

  #Choose directories that need archiving
  my @archivable;
  push(@archivable, $self->{junitDir}) if $self->{junit};
  push(@archivable, $self->{coverDir}) if $self->{cover};
  my @dirs = map { my $a = $_; $a =~ s/\Q$baseDir\E\/?//; $a;} @archivable; #Change absolute path to relative
  my $cwd = Cwd::getcwd();
  chdir $baseDir;
  $self->_shell("tar", "-czf $self->{testResultsArchive} @dirs");
  chdir $cwd;
}

#
# Runs all given test files
#
sub _runharness {
  my ($self) = @_;

  if ($self->{isDbDiff}) {
    $self->databaseDiff(); # Initialize first mysqldump before running any tests
  }

  foreach my $dir (sort keys %{$self->{testFilesByDir}}) {
    my @tests = sort @{$self->{testFilesByDir}->{$dir}};
    unless (scalar(@tests)) {
        get_logger()->logdie("\@tests is empty?");
    }
    ##Prepare test harness params
    my $dirToPackage = $dir;
    $dirToPackage =~ s!^\./!!; #Drop leading "current"-dir chars
    $dirToPackage =~ s!/!\.!gsm; #Change directories to dot-separated packages
    my $xmlfile = $self->{testResultsDir}.'/junit'.'/'.$dirToPackage.'.xml';
    my @exec = (
        $EXECUTABLE_NAME,
        '-w',
    );
    push(@exec, "-MDevel::Cover=-db,$self->{cover_dbDir},-silent,1,-coverage,all") if $self->{cover};
    foreach my $lib (@{$self->{lib}}) {
      push(@exec, "-I$lib");
    }

    if ($self->{dryRun}) {
        print "TAP::Harness::JUnit would run tests with this config:\nxmlfile => $xmlfile\npackage => $dirToPackage\nexec => @exec\ntests => @tests\n";
    }
    else {
      my $harness;
      if ($self->{junit}) {
        $harness = TAP::Harness::JUnit->new({
            xmlfile => $xmlfile,
            package => "",
            verbosity => get_logger()->is_debug(),
            namemangle => 'perl',
            callbacks => {
              after_test => sub {
                $self->databaseDiff({
                  test => shift->[0], parser => shift
                }) if $self->{isDbDiff};
              },
            },
            exec       => \@exec,
        });
        $harness->runtests(@tests);
      }
      else {
        $harness = TAP::Harness->new({
            verbosity => get_logger()->is_debug(),
            callbacks => {
              after_test => sub {
                $self->databaseDiff({
                  test => shift->[0], parser => shift
                }) if $self->{isDbDiff}
              },
            },
            exec       => \@exec,
        });
        $harness->runtests(@tests);
      }
    }
  }
}

=head2 databaseDiff

Diffs two mysqldumps and finds changes to INSERT INTO queries. Collects names of
the tables that have new INSERTs.

=cut

sub databaseDiff {
    my ($self, $params) = @_;

    my $test   = $params->{test};

    my $user = $self->{dbUser};
    my $pass = $self->{dbPass};
    my $host = $self->{dbHost};
    my $port = $self->{dbPort};
    my $db   = $self->{dbDatabase};
    my $sock = $self->{dbSocket};

    unless (defined $user) {
        die 'KSTestHarness->databaseDiff(): Parameter dbUser undefined';
    }
    unless (defined $host) {
        die 'KSTestHarness->databaseDiff(): Parameter dbHost undefined';
    }
    unless (defined $port) {
        die 'KSTestHarness->databaseDiff(): Parameter dbPort undefined';
    }
    unless (defined $db) {
        die 'KSTestHarness->databaseDiff(): Parameter dbDatabase undefined';
    }

    $self->{tmpDbDiffDir} ||= '/tmp/KSTestHarness/dbDiff';
    my $path = $self->{tmpDbDiffDir};
    unless (-e $path) {
        make_path($path);
    }

    my @mysqldumpargs = (
        'mysqldump',
        '-u', $user,
        '-h', $host,
        '-P', $port
    );

    push @mysqldumpargs, "-p$pass" if defined $pass;

    if ($sock) {
        push @mysqldumpargs, '--protocol=socket';
        push @mysqldumpargs, '-S';
        push @mysqldumpargs, $sock;
    }
    push @mysqldumpargs, $db;

    unless ($test && -e "$path/previous.sql") {
        eval { $self->_shell(@mysqldumpargs, '>', "$path/previous.sql"); };
    }
    return 1 unless defined $test;

    eval { $self->_shell(@mysqldumpargs, '>', "$path/current.sql"); };

    my $diff;
    eval {
        $self->_shell(
            'git', 'diff', '--color-words', '--no-index', '-U0',
            "$path/previous.sql", "$path/current.sql"
        );
    };
    my @tables;
    if ($diff = $@) {
        # Remove everything else except INSERT INTO queries
        $diff =~ s/(?!^.*INSERT INTO .*$)^.+//mg;
        $diff =~ s/^\n*//mg;
        @tables = $diff =~ /^INSERT INTO `(.*)`/mg; # Collect names of tables
        if ($self->{dbDiffIgnoreTables}) {
          foreach my $table (@{$self->{dbDiffIgnoreTables}}) {
            if (grep(/$table/, @tables)) {
              @tables = grep { $_ ne $table } @tables;
            }
          }
        }
        if (@tables) {
            if ($params->{parser}) {
              $self->_add_failed_test_dynamically(
                  $params->{parser}, "Test $test leaking test data to following ".
                  "tables:\n". Data::Dumper::Dumper(@tables)
              );
            }
            get_logger()->info("New inserts at tables:\n" . Data::Dumper::Dumper(@tables));
            my $filename = dirname($test);
            make_path("$self->{dbDiffDir}/$filename");
            open my $fh, '>>', "$self->{dbDiffDir}/$test.out";
            print $fh $diff;
            close $fh;
        }
    }

    $self->_shell('mv', "$path/current.sql", "$path/previous.sql");

    return @tables;
}

sub _sortFilesByDir {
    my ($files) = @_;
    unless (ref($files) eq 'ARRAY') {
        get_config()->logdie("\$files is not an ARRAYRef");
    }
    unless (scalar(@$files)) {
        get_config()->logdie("\$files is an ampty array?");
    }

    #deduplicate files
    my (%seen, @files);
    @files = grep !$seen{$_}++, @$files;

    #Sort by dirs
    my %dirsWithFiles;
    foreach my $f (@files) {
        my $dir = File::Basename::dirname($f);
        $dirsWithFiles{$dir} = [] unless $dirsWithFiles{$dir};
        push (@{$dirsWithFiles{$dir}}, $f);
    }
    return \%dirsWithFiles;
}

#
# Dynamically generates a failed test and pushes the result to the end of
# TAP::Parser::Result->{__results} for JUnit.
#
# C<$parser> is an instance of TAP::Harness::JUnit::Parser
# C<$desc> is a custom description for the test
#
sub _add_failed_test_dynamically {
  my ($self, $parser, $desc) = @_;

  $desc ||= 'Dynamically failed test';
  my $test_num = $parser->tests_run+1;
  my @plan_split = split(/\.\./, $parser->{plan});
  my $plan = $plan_split[0].'..'.++$plan_split[1];
  $parser->{plan} = $plan;

  if (ref($parser) eq 'TAP::Harness::JUnit::Parser') {
    my $failed = {};
    $failed->{ok} = 'not ok';
    $failed->{test_num} = $test_num;
    $failed->{description} = $desc;
    $failed->{raw} = "not ok $test_num - $failed->{description}";
    $failed->{type} = 'test';
    $failed->{__end_time} = 0;
    $failed->{__start_time} = 0;
    $failed->{directive} = '';
    $failed->{explanation} = '';
    bless $failed, 'TAP::Parser::Result::Test';

    push @{$parser->{__results}}, $failed;
    $parser->{__results}->[0]->{raw} = $plan;
    $parser->{__results}->[0]->{tests_planned}++;
  }
  push @{$parser->{failed}}, $test_num;
  push @{$parser->{actual_failed}}, $test_num;
  
  $parser->{tests_planned}++;
  $parser->{tests_run}++;
  print "not ok $test_num - $desc";

  return $parser;
}

sub _shell {
  my ($self, $program, @params) = @_;
  my $programPath = IPC::Cmd::can_run($program) or die "$program is not installed!";
  my $cmd = "$programPath @params";

  if ($self->{dryRun}) {
    print "$cmd\n";
  }
  else {
    my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
        IPC::Cmd::run( command => $cmd, verbose => 0 );
    my $exitCode = ${^CHILD_ERROR_NATIVE} >> 8;
    my $killSignal = ${^CHILD_ERROR_NATIVE} & 127;
    my $coreDumpTriggered = ${^CHILD_ERROR_NATIVE} & 128;
    die "Shell command: $cmd\n  exited with code '$exitCode'. Killed by signal '$killSignal'.".(($coreDumpTriggered) ? ' Core dumped.' : '')."\nERROR MESSAGE: $error_message\nSTDOUT:\n@$stdout_buf\nSTDERR:\n@$stderr_buf\nCWD:".Cwd::getcwd()
        if $exitCode != 0;
    get_logger->info("CMD: $cmd\nERROR MESSAGE: ".($error_message // '')."\nSTDOUT:\n@$stdout_buf\nSTDERR:\n@$stderr_buf\nCWD:".Cwd::getcwd());
    return "@$full_buf";
  }
}

=head2 getTestResultFileAndDirectoryPaths
 @static

Injects paths to the given HASHRef.

Centers the relevant path calculation logic so the paths can be accessed from external tests as well.

=cut

sub getTestResultFileAndDirectoryPaths {
  my ($hash, $resultsDir) = @_;
  $hash->{testResultsDir} = $resultsDir.'/testResults';
  $hash->{testResultsArchive} = 'testResults.tar.gz';
  $hash->{junitDir} =  $hash->{testResultsDir}.'/junit';
  $hash->{coverDir} = $hash->{testResultsDir}.'/cover';
  $hash->{cover_dbDir} = $hash->{testResultsDir}.'/cover_db';
  $hash->{dbDiffDir} = $hash->{testResultsDir}.'/dbDiff';
}

=head2 parseOtherTests
 @static

Parses the given blob of file names and paths invoked from god-knows what ways of shell-magic.
Tries to normalize them into something the Test::Harness::* can understand.

 @param1 ARRAYRef of Strings, which might or might not contain separated textual lists of filepaths.
 @returns ARRAYRef of Strings, Normalized test file paths

=cut

sub parseOtherTests {
    my ($files) = @_;
    my @files = split(/(?:,|\s)+/, join(',', @$files));

    my @warnings;
    for (my $i=0 ; $i<@files ; $i++) {
        my $f = $files[$i];
        if ($f !~ /\.t\b/) {
            push(@warnings, "File '$f' doesn't look like a Perl test file, as it doesn't have .t ending, ignoring it.") unless (-d $f);
            $files[$i] = undef;
        }
    }
    if (@warnings) {
        get_logger->warn(join("\n", @warnings)) if @warnings;
        @files = grep { defined $_ } @files;
    }
    return \@files;
}

=head2 findfiles
 @static

Helper to the shell command 'find'

 @param1 String, Dir to look from
 @param2 String, selector used in the -name -parameter
 @param3 Integer, -maxdepth, the depth of directories 'find' keeps looking into
 @returns ARRAYRef of Strings, filepaths found

=cut

sub findFiles {
    my ($dir, $selector, $maxDepth) = @_;
    $maxDepth = 999 unless(defined($maxDepth));
    my $files = `/usr/bin/find $dir -maxdepth $maxDepth -name '$selector'`;
    my @files = split(/\n/, $files);
    return \@files;
}

1;
