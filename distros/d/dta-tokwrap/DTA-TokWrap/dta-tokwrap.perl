#!/usr/bin/perl -w
use lib ('.');
use DTA::TokWrap;
use DTA::TokWrap::Version;
use DTA::TokWrap::Utils qw(:si);
use File::Basename qw(basename);
use IO::File;

use Getopt::Long (':config' => 'no_ignore_case');
use Pod::Usage;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------

##-- general
our $prog = basename($0);
our ($help,$man,$version);
our $verbose = 1;      ##-- verbosity

##-- DTA::TokWrap options
my %bx0opts = DTA::TokWrap::Processor::mkbx0->defaults();
our %twopts = (
	       inplacePrograms=>1,
	       keeptmp => 0,
	       procOpts => {
			    #traceLevel => 'trace',
			    hint_sb_xpaths => $bx0opts{hint_sb_xpaths},
			    hint_wb_xpaths => $bx0opts{hint_wb_xpaths},
			    nohints => 0,        ##-- don't generate any hints in output .txt file
			    abbrevLex => undef,  ##-- abbrev "lexicon"; see SVN 'dev/dta-resources' or 'dev/moot-models/dtiger' project
			    stopLex => undef,    ##-- stopword "lexicon" (waste tokenizer only)
			    conjLex => undef,    ##-- conjunction "lexicon" (waste tokenizer only)
			    wasteHmm => undef,   ##-- waste model (waste tokenizer only)
			    mweLex   => undef,   ##-- mwe "lexicon"; see SVN 'dev/dta-resources' project
			   },
	      );
our %docopts = (
		##-- Document class options
		class => 'DTA::TokWrap::Document',
		#class => 'DTA::TokWrap::Document::Maker',

		##-- DTA::TokWrap::Document options
		#traceOpen => 'trace',
		#traceClose => 'trace',
		#traceLoad   => 'trace',
		#traceSave   => 'trace',
		#traceProc => 'trace',
		format => 1,

		##-- DTA::TokWrap::Document::Maker options
		#traceMake => 'trace',
		#traceGen  => 'trace',
		#genDummy => 0,
		#force => 0,  ##-- propagated from DTA::TokWrap $doc->{tw}
	       );

##-- Logging options
our $logConfFile = undef;
our ($logConf);            ##-- default log configuration string; see below
our $logToStderr = 1;      ##-- log to stderr?
our $logFile     = undef;  ##-- log to file?
our $logProfile  = 'info'; ##-- log-level for profiling information?

##-- make/generate options
our $makeKeyAct = 'make';   ##-- one of 'make', 'gen', 'list'
our @targets = qw();
our @defaultTargets = qw(all);

##-- debugging options
our $listTargets = 0;
our $dump_xsl_prefix = undef;
our $traceLevel = 'trace'; ##-- trace level for '-trace' options
our @traceOptions = (
		     {opt=>'traceOpen',ref=>\$docopts{traceOpen},vlevel=>1},
		     {opt=>'traceFrag',ref=>\$twopts{procOpts}{addwsInfo},vlevel=>2},
		     {opt=>'traceClose',ref=>\$docopts{traceClose},vlevel=>3},
		     {opt=>'traceProc',ref=>\$docopts{traceProc},vlevel=>2},
		     {opt=>'traceLoad',ref=>\$docopts{traceLoad},vlevel=>3},
		     {opt=>'traceSave',ref=>\$docopts{traceSave},vlevel=>3},
		     {opt=>'traceMake',ref=>\$docopts{traceMake},vlevel=>4},
		     {opt=>'traceGen',ref=>\$docopts{traceGen},vlevel=>5},
		     {opt=>'traceSubproc',ref=>\$twopts{procOpts}{traceLevel},vlevel=>6},
		     {opt=>'traceRun', ref=>\$DTA::TokWrap::Utils::TRACE_RUNCMD,vlevel=>7},
		    );
our $verbose_max = 255;

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------

## undef = setVerboseTrace($bool)
## undef = setVerboseTrace($bool,$verbose,$clearToo)
##  + set trace options by verbosity level
sub setVerboseTrace {
  my $_verbose = defined($_[1]) ? $_[1] : $verbose;
  ${$_->{ref}} = ($_[0] ? $traceLevel : undef) foreach (grep {$_verbose>=$_->{vlevel}} @traceOptions);
  if ($_[2]) {
    ##-- clear flags, too
    ${$_->{ref}} = undef foreach (grep {$_verbose<$_->{vlevel}} @traceOptions);
  }
  if ($verbose <= 0) { $logProfile=0; }
}
setVerboseTrace(1,$verbose,1); ##-- default

GetOptions(
	   ##-- General
	   'help|h' => \$help,
	   'man' => \$man,
	   'verbose|v=i' => sub { $verbose=$_[1]; setVerboseTrace(1,$verbose,1); },
	   'verbion|V' => \$version,

	   ##-- pseudo-make
	   'make|m' => sub { $docopts{class}='DTA::TokWrap::Document::Maker'; $makeKeyAct='make'; },
	   'nomake|M' => sub { $docopts{class}='DTA::TokWrap::Document'; },
	   'remake|r!' => sub { $docopts{class}='DTA::TokWrap::Document::Maker'; $makeKeyAct='remake'; },
	   'targets|target|t=s' => \@targets,
	   'list-targets|list|lt!' => \$listTargets,
	   'force-target|ft=s' => sub { push(@{$twopts{force}},$_[1]) },
	   'force|f' => sub { push(@{$twopts{force}},'all') },
	   'noforce|nof' => sub { $twopts{force} = [] },

	   ##-- DTA::TokWrap::Processor options
	   'resource-directory|rcdir|rcd|rd=s' => \$DTA::TokWrap::Version::RCDIR,
	   'inplacePrograms|inplace|i!' => \$twopts{inplacePrograms},
	   'sentence-break-xpath|sb-xpath|sbx|sb=s@' => $twopts{procOpts}{hint_sb_xpaths},
	   'word-break-xpath|wb-xpath|wbx|wb=s@' => $twopts{procOpts}{hint_wb_xpaths},
	   'weak-hints|weakhints|whitespace-hints|wh' => sub { $twopts{procOpts}{wbStr}=$twopts{procOpts}{sbStr}="\n\n"; },
	   'strong-hints|sh' => sub { delete(@{$twopts{procopts}}{qw(wbStr sbStr)}); },
	   'hints!' => sub { $twopts{procOpts}{nohints} = !$_[1]; },
	   'abbrev-lex|to-abbrev-lex|al=s' => \$twopts{procOpts}{abbrevLex},
	   'mwe-lex|to-mwe-lex|ml=s' => \$twopts{procOpts}{mweLex},
	   'stop-lex|to-stop-lex|sl=s' => \$twopts{procOpts}{stopLex},
	   'conj-lex|to-conj-lex|cl=s' => \$twopts{procOpts}{conjLex},
	   'waste-model|to-waste-model|wm=s' => \$twopts{procOpts}{wasteHmm},
	   'waste-dir|wd=s' => \$twopts{procOpts}{wasteDir},
	   'processor-option|procopt|po|pO=s%' => $twopts{procOpts},

	   ##-- DTA::TokWrap options: I/O
	   'outdir|od|d=s' => \$twopts{outdir},
	   'tmpdir|tmp|T=s' => \$twopts{tmpdir},
	   'keeptmp|keep|k!' => \$twopts{keeptmp},
	   'format-xml|format|fmt|pretty-xml|pretty|fx|px:i'  => sub { $docopts{format} = $_[1]||1; },
	   'noformat-xml|noformat|nofmt|nopretty-xml|nopretty|nofx|nopx'  => sub { $docopts{format} = 0; },
	   'document-option|docopt|do|dO|O=s%' => \%docopts,

	   ##-- Log options
	   'log-config|logconfig|logconf|log-rc|logrc|lc=s' => \$logConfFile,
	   'log-level|loglevel|ll=s' => sub { $DTA::TokWrap::Logger::DEFAULT_LOGLEVEL=uc($_[1]); },
	   'log-file|logfile|lf=s' => \$logFile,
	   'log-stderr|stderr|le!' => \$logToStderr,
	   'log-profile|profile|p!' => sub { $logProfile = $_[1] ? 'info' : undef; },
	   'silent|quiet|q' => sub {
	     $verbose=0;
	     setVerboseTrace(0,$verbose_max,1);
	     $DTA::TokWrap::Logger::DEFAULT_LOGLEVEL='FATAL';
	   },

	   ##-- Debugging options
	   (map {
	     my ($opt,$ref) = @$_{qw(opt ref)};
	     ("${opt}" => sub { $$ref = $traceLevel },
	      "${opt}Level=s" => sub { $$ref = $_[1] },
	      (map { ("no$_" => sub { $$ref=undef }) } split(/\|/, $opt))
	     )
	   } @traceOptions),
	   "traceLevel|trace-level=s" => \$traceLevel,
	   "trace!" => sub { setVerboseTrace($_[1],$verbose,1); },
	   "traceAll|trace-all!" => sub { setVerboseTrace($_[1],$verbose_max,1); },
	   "dummy|no-act|n!" => \$docopts{dummy},
	   ##
	   "tokenizer-class|tokclass|tc=s" => \$DTA::TokWrap::Document::TOKENIZE_CLASS,
	   "dummy-tokenizer|dummytok|dt!" => sub {
	     $DTA::TokWrap::Document::TOKENIZE_CLASS = ($_[1] ? 'dummy' : 'auto');
	   },
	   "http-tokenizer|httptok|ht!" => sub {
	     $DTA::TokWrap::Document::TOKENIZE_CLASS = ($_[1] ? 'http' : 'auto');
	   },

	   'dump-xsl-stylesheets|dump-xsl:s' => \$dump_xsl_prefix,
	  );

if ($version) {
  print
    ("$prog version $VERSION\n",
     "  + DTA::TokWrap version $DTA::TokWrap::Version::VERSION\n",
     "  + SVN $DTA::TokWrap::Version::SVNID\n",
    );
  exit(0);
}

pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-exitval=>0, -verbose=>1}) if ($man);
pod2usage({-exitval=>1, -verbose=>0, -message=>'No XML source file(s) specified!'})
  if (@ARGV < 1 && !$dump_xsl_prefix && !$listTargets);


##==============================================================================
## Subs
##==============================================================================

##--------------------------------------------------------------
## Subs: Messaging

sub vmsg {
  my ($vlevel,@msg) = @_;
  if ($verbose >= $vlevel) {
    print STDERR @msg;
  }
}

sub vmsg1 {
  vmsg($_[0],"$prog: ", @_[1..$#_], "\n");
}


##--------------------------------------------------------------
## Subs: File processing

## $bool = processFile($argvFile)
##  + process a single file
sub processFile {
  my $f = shift;
  my $rc = 1;
  eval {
    $rc &&= ($doc = $tw->open($f,%docopts));
    foreach $target (@targets) {
      last if (!$rc);
      $rc &&= defined($makeKeySub->($doc,$target));
    }
    $rc &&= $doc->close();
  };
  return $rc;
}


##==============================================================================
## MAIN
##==============================================================================

##-- init logger
if (defined($logConfFile)) {
  DTA::TokWrap->logInit($logConfFile);
} else {
  $logConf ="
##-- Loggers
#log4perl.rootLogger = WARN, AppStderr
log4perl.oneMessagePerAppender = 1     ##-- suppress duplicate messages to the same appender
log4perl.logger.DTA.TokWrap = ". join(', ',
				      '__DTA_TOKWRAP_DEFAULT_LOGLEVEL__',
				      ($logToStderr ? 'AppStderr' : qw()),
				      ($logFile     ? 'AppFile'   : qw()),
				     ) . "

##-- Appenders: Utilities
log4perl.PatternLayout.cspec.G = sub { return '$prog'; }
"
				       .($logToStderr ? "
##-- Appender: AppStderr
log4perl.appender.AppStderr = Log::Log4perl::Appender::Screen
log4perl.appender.AppStderr.stderr = 1
log4perl.appender.AppStderr.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.AppStderr.layout.ConversionPattern = %G[%P] %X{xmlbase}: %p %c: %m%n
" : '')
					 .($logFile ? ("
##-- Appender: AppFile
log4perl.appender.AppFile = Log::Log4perl::Appender::File
log4perl.appender.AppFile.filename = $logFile
log4perl.appender.AppFile.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.AppFile.layout.ConversionPattern = %d{yyyy-mm-dd hh:mm:ss} %G[%P] %X{xmlbase}: %p %c: %m%n

") : '');

  DTA::TokWrap->logInit(\$logConf);
}

##-- defaults: targets
if (!@targets) {
  @targets = @defaultTargets;
} else {
 @targets = map { split(/[\,\;\s]+/,$_) } @targets;
}

##-- create $tw
our $tw = DTA::TokWrap->new(%twopts)
  or die("$prog: could not create DTA::TokWrap object");

##-- debug: dump XSL?
if (defined($dump_xsl_prefix)) {
  $tw->{mkbx0}->dump_chain_stylesheet($dump_xsl_prefix."mkbx0_chain.xsl");
  $tw->{mkbx0}->dump_hint_stylesheet($dump_xsl_prefix."mkbx0_hint.xsl");
  $tw->{mkbx0}->dump_sort_stylesheet($dump_xsl_prefix."mkbx0_sort.xsl");
  exit(0);
}

##-- debug: list targets
if ($listTargets) {
  my $gen = \%DTA::TokWrap::Document::KEYGEN;
  my ($key,$val, $type,$details);
  foreach $key (sort keys %$gen) {
    $val = $gen->{$key};
    $type    = 'UNKNOWN';
    $details = '';
    if (UNIVERSAL::isa($val,'CODE')) {
      ($type,$details) = ("CODE",$val);
    }
    elsif (UNIVERSAL::can('DTA::TokWrap::Document',$key)) {
      ($type,$details) = ("METHOD",$key);
    }
    elsif (!ref($val) && UNIVERSAL::can('DTA::TokWrap::Document',$val)) {
      ($type,$details) = ("METHOD",$val);
    }
    elsif (UNIVERSAL::isa($val,'ARRAY')) {
      ($type,$details) = ("CHAIN",join(' ',@$val));
    }
    printf("%-15s\t%s\t%s\n",$key,$type,$details);
  }
  exit 0;
}

##-- options: pseudo-make: make|gen
our $makeKeySub = $docopts{class}->can("${makeKeyAct}Key")
  or die("$prog: no method for $docopts{class}->${makeKeyAct}Key()");

##-- profiling
#our $tv_started = [gettimeofday];

##-- ye olde loope
our ($doc);
our $progrc=0;
our ($filerc,$target);
foreach $f (@ARGV) {
  $filerc = processFile($f);
  if ($@ || !$filerc) {
    vmsg1(0,"error processing XML file '$f': $@");
    ++$progrc;
  }
}

##-- profiling
$tw->logProfile($logProfile) if ($logProfile && $progrc==0);


exit($progrc); ##-- exit status

__END__

##===============================================================================
=pod

=head1 NAME

dta-tokwrap.perl - top-level tokenizer wrapper for DTA XML documents

=cut

##===============================================================================
=pod

=head1 SYNOPSIS

 dta-tokwrap.perl [OPTIONS] XMLFILE(s)...
 
 General Options:
  -help                  # show this help message
  -man                   # show complete manpage
  -verbose LEVEL         # set verbosity level (0<=level<=7; default=1)
 
 Make Emulation Options:
  -list-targets		 # just list known targets
  -targets TARGETS       # set build targets (default='all')
  -make , -nomake        # do/don't emulate make-style dependency tracking (default=don't)
  -remake                # force rebuilding of all targets (implies -make)
  -force-target TARGET   # for -make mode, force rebuilding of TARGET
  -force                 # alias for -force-target=all
  -noforce               # overrides all preceeding -force and -force-target flags
 
 Subprocessor Options:
  -rcdir RCDIR           # resource directory (default=$ENV{TOKWRAP_RCDIR} or /usr/local/share/dta-resources)
  -inplace , -noinplace  # do/don't use locally built programs if available (default=do)
  -sb-xpath XPATH        # add sentence-break hints on XPATH (element) open and close
  -wb-xpath XPATH        # add word-break hints on XPATH (element) open and close
  -hints, -nohints       # do/don't generate "hints" for the tokenizer (default=do)
  -weak-hints            # use whitespace-only hints rather than defaults ($WB$,$SB$)
  -strong-hints          # opposite of -weak-hints
  -abbrev-lex=FILE       # abbreviation lexicon for dwds_tomasotath or waste tokenizer
  -mwe-lex=FILE          # multiword-expression lexicon for dwds_tomasotath tokenizer
  -stop-lex=FILE         # stopword lexicon for waste tokenizer
  -conj-lex=FILE         # conjunction lexicon for waste tokenizer
  -waste-model=FILE      # HMM file for waste tokenizer
  -waste-dir=DIR         # waste base directory (defaults for -abbr-lex, -stop-lex, -conj-lex, -waste-model)
  -procopt OPT=VALUE     # set arbitrary subprocessor options
 
 I/O Options:
  -outdir OUTDIR         # set output directory (default=.)
  -tmpdir TMPDIR         # set temporary directory (default=$ENV{DTATW_TMP} or OUTDIR)
  -keep , -nokeep        # do/don't keep temporary files (default=don't)
  -format , -noformat    # do/don't pretty-print XML output (default=do)
  -docopt OPT=VALUE      # set arbitrary document options (e.g. filenames)
 
 Logging Options:
  -log-config RCFILE     # use Log::Log4perl configuration file RCFILE (default=internal)
  -log-level LEVEL       # set minimum log level
  -log-file LOGFILE      # log to file LOGFILE (default=none)
  -stderr  , -nostderr   # do/don't log to console (default=do)
  -profile , -noprofile  # do/don't log profiling information (default=do)
  -silent  , -quiet      # alias for -verbose=0 -log-level=FATAL -notrace
 
 Trace and Debugging Options:
  -dump-xsl PREFIX       # dump generated XSL stylesheets to PREFIX*.xsl and exit
  -dummy , -nodummy      # don't/do actually run any subprocessors (default=do)
  -tokenizer-class CLASS # specify tokenizer subclass (e.g. http, waste, dummy, tomasotath_04x, ...)
  -dummy-tokenizer       # alias for -tokenizer-class=dummy
  -http-tokenizer	 # alias for -tokenizer-class=http
  -trace , -notrace      # do/don't log trace messages (default: depends on -verbose)
  -traceAll              # enable logging of all possible trace messages
  -notraceAll            # disable logging of all possible trace messages
  -traceLevel LEVEL      # set trace logging level (default='trace')
  -traceX, -notraceX     # do/don't trace "X" (X={Open|Load|Save|Make|...})
  -traceXLevel LEVEL     # set log level for "X" traces (X={Open|...})

=cut

##===============================================================================
=pod

=head1 OPTIONS

=cut

##----------------------------------------------------------------------
=pod

=head2 General Options

=over 4

=item -help

Display a short help message and exit.

=item -man

Display the complete program manpage and exit.

=item -verbose LEVEL

Set verbosity level (0<=level<=7; default=0)

=back

=cut

##----------------------------------------------------------------------
=pod

=head2 Make Emulation Options

=over 4

=item -targets TARGETS

Set build targets (default=L</all>).
Multiple TARGETS may be separated by whitespace, commas, or
by passing multiple -targets options.
See L</"Known Targets"> for a list of currently defined targets.

=item -make , -nomake

Do/don't emulate experimental F<make>-style dependency tracking (default=don't).
Use of C<-make> mode may be faster (because it requires less file I/O).

=item -remake

Force rebuilding of all targets (implies L<-make|/"-make , -nomake">).

=item -force-target TARGET

For L<-make|/"-make , -nomake"> mode, force rebuilding of TARGET.

=item -force

Alias for L<-force-target|/"-force-target TARGET">C<=all>

=item -noforce

Overrides all preceeding L</-force> and L<-force-target|/"-force-target TARGET"> flags.

=back

=cut

##----------------------------------------------------------------------
=pod

=head2 Subprocessor Options:

=over 4

=item -inplace , -noinplace

Do/don't use locally built programs if available (default=do).
This is useful if you want to test a development version (C<-inplace>)
and an installed system version (C<-noinplace>) of this package
on the same machine.

=item -sb-xpath XPATH

Tells the C<mkbx0> subprocessor
to add sentence-break hints on XPATH (which should resolve only to element nodes) open and close.
XPATH is included in the generated F<hint.xsl> XSL stylesheet as a C<match>
item, so it can include e.g. top-level unions, but no nested unions.

This option may be specified more than once.

=item -wb-xpath XPATH

Tells the C<mkbx0> subprocessor
to add sentence-break hints on XPATH (which should resolve only to element nodes) open and close.
Same caveats as for L</"-sb-xpath XPATH">

This option may be specified more than once.

=item -hints , -nohints

Do/don't generate explicit sentence- and/or token-break "hints" for the tokenizer
in the temporary .txt file (default=do).  Explicit hint strings can be set
with
C<-procopt wbStr=WORDBREAK_HINT_STRING> and/or C<-procopt sbStr=SENTBREAK_HINT_STRING>;
see L<-procopt|/"-procopt OPT=VALUE"> below for details.

=item -weak-hints

If generating tokenizer "hints", use whitespace-only hints rather than defaults
"\n$WB$\n", "\n$SB$\n".
This can be useful if your low-level tokenizer doesn't understand the explicit
hints, but might be predisposed to break tokens and/or sentences on whitespace.

=item -strong-hints

Opposite of -weak-hints.

=item -abbrev-lex=FILE

Abbreviation lexicon for F<dwds_tomasotath> tokenizer.
Default is (usually)
F</usr/local/share/dta-resources/dta_abbrevs.lex>.

FILE may be specified as the empty string to avoid
use of an abbreviation lexicon altogether, although
this is likely to weak havoc with F<dwds_tomasotath>'s
sentence-boundary recognition.

=item -mwe-lex=FILE

Multiword-expression lexicon for F<dwds_tomasotath> tokenizer.
Default is (usually)
F</usr/local/share/dta-resources/dta_mwe.lex>.

FILE may be specified as the empty string to avoid
use of a multiword-expression lexicon altogether, although
this might cause problems with F<dwds_tomasotath>.

=item -procopt OPT=VALUE

Set a literal arbitrary subprocessor option OPT to VALUE.
See subprocessor module documentation for available options.

=back

=cut

##----------------------------------------------------------------------
=pod

=head2 I/O Options

=over 4

=item -outdir OUTDIR

Set output directory (default=.)

=item -tmpdir TMPDIR

Set directory for storing temporary files.  Default value is
taken from the environment variable C<$DTATW_TMP> if it is set,
otherwise the default is the value of OUTDIR (see L<-outdir|/"-outdir OUTDIR">).

=item -keep , -nokeep

Do/don't keep temporary files, rather than deleting them
when they are no longer needed (default=don't).

=item -format , -noformat

Do/don't pretty-print XML output when possible (default=do).

=item docopt OPT=VALUE

Set arbitrary DTA::TokWrap::Document options (e.g. filenames).
See L<DTA::TokWrap::Document(3pm)|DTA::TokWrap::Document> for details.

=back

=cut

##----------------------------------------------------------------------
=pod

=head2 Logging Options

=over 4

=item -log-config RCFILE

Use Log::Log4perl configuration file F<RCFILE>,
rather than the default internal configuration.
See L<Log::Log4perl(3pm)|Log::Log4perl> for details
on the syntax of F<RCFILE>.

=item -log-level LEVEL

Set minimum log level.
Only effective if the default (internal) log configuration is being used.

=item -log-file LOGFILE

Send log output to file F<LOGFILE> (default=none).
Only effective if the default (internal) log configuration is being used.

=item -stderr  , -nostderr

Do/don't log to console (default=do).
Only effective if the default (internal) log configuration is being used.

=item -profile , -noprofile

Do/don't log profiling information (default=do).

=item -silent  , -quiet

Alias for C<-verbose=0 -log-level=FATAL -notrace>.

=back

=cut

##----------------------------------------------------------------------
=pod

=head2 Trace and Debugging Options

=over 4

=item -dump-xsl PREFIX

Dumps generated XSL stylesheets to PREFIX*.xsl and exits.
Useful for debugging.
Causes the following files to be written:

 ${PREFIX}mkbx0_hint.xsl    # hint insertion
 ${PREFIX}mkbx0_sort.xsl    # serialization sort-key generation
 ${PREFIX}standoff_t2s.xsl  # master XML to sentence standoff
 ${PREFIX}standoff_t2w.xsl  # master XML to token standoff
 ${PREFIX}standoff_t2a.xsl  # master XML to analysis standoff

=item -dummy , -nodummy

Don't/do actually run any subprocessors (default=do)

=item -dummy-tokenizer , -nodummy-tokenizer

Do/don't use locally built dummy tokenizer instead of tomata2.

=item -trace , -notrace

Do/don't log trace messages (default: depends on the current C<-verbose>
level; see L<-verbose|/"-verbose LEVEL">).

=item -traceAll

Enable logging of all possible trace messages.
B<Warning>: this generates a lot of log output.

=item -notraceAll

Disable logging of all possible trace messages.

=item -traceLevel LEVEL

Set log level to use for trace messages (default='trace').
C<LEVEL> is one of the following: C<trace, debug, info, warn, error, fatal>.
Any other value for C<LEVEL> causes trace messages not to be logged.

=item -traceX , -notraceX

Do/don't log trace messages for the trace flavor I<X>,
where I<X> is one of the following:

 Open    # document object open() method
 Close   # document object close() method
 Proc    # document processing method calls
 Load    # load document data file
 Save    # save document data file
 Make    # document target (re-)making (including status-check)
 Gen     # document target (re-)generation
 Subproc # low-level subprocessor calls
 Run     # external system command

=item -traceXLevel LEVEL

Set log level for I<X>-type traces to LEVEL.
I<X> is a trace message flavor as described
in L<-traceX|/"-traceX , -notraceX">, and
LEVEL is as described in L<-traceLevel|/"-traceLevel LEVEL">.

=back

=cut

##===============================================================================
=pod

=head1 ARGUMENTS

All other command-line arguments are assumed to be filenames of
DTA "base-format" XML files,
which are simply (TEI-conformant) UTF-8 encoded XML files with
one (optional as of dta-tokwrap v0.38) C<E<lt>cE<gt>> element per character:

=over 4

=item *

the document B<MUST> be encoded in UTF-8,

=item *

all text nodes to be tokenized should be descendants of a C<E<lt>textE<gt>> element,
and may optionally be immediate daughters of a C<E<lt>cE<gt>> element
(XPath C<//text//text()|//text//c/text()>). C<E<lt>cE<gt>> elements may not be nested.

Prior to dta-tokwrap v0.38, C<E<lt>cE<gt>> elements were required.

=back

=cut


##===============================================================================
=pod

=head1 DESCRIPTION

This program is intended to provide a flexible high-level command-line interface
to the tokenization of DTA "base-format" XML documents, generating
I<e.g.> sentence-, token-, and analysis-level standoff XML annotations for
each input document.

The problem can be run in one of two main modes; see L</"Modes of Operation"> for details on these.
In either mode, it can be used either as a standalone batch-processor for
one or more input documents, or called by a superordinate build system, I<e.g.>
GNU C<make> (see C<make(1)>).  Program operation is controlled primarily
by the specification of one or more "targets" to build for each input document;
see L</"Known Targets"> for details.

=cut

##----------------------------------------------------------------------
=pod

=head2 Modes of Operation

The program can be run in one of two modes of operation,
L</"-make Mode"> and L</"-nomake Mode">.

=head3 -make Mode

B<(DEPRECATED)>

In this (deprecated) mode, the program attempts to emulate the dependency tracking
features of C<make> by (re-)building only those targets which either
do not yet exist, or which are older than one or more of their dependencies.
Since some dependencies are ephemeral, existing only in RAM during
a single program run, this can mean a lot of pain for comparatively little gain.

-make mode is enabled by specifying the L<-make|/"-make , -nomake"> option
on the command-line.

=head3 -nomake Mode

In this (experimental) mode, no implicit dependency tracking is
attempted, and all required data files (input, "temporary", and/or output)
must exist when the requested target is built; otherwise an error results.
-nomake mode can be somewhat slower than -make mode, since "temporary"
data (which in -make mode are RAM-only ephemera) may need to be bounced off
the filesystem.

-nomake mode is the default mode, and may be (re-)enabled (overriding
any preceding C<-make> option) 
by specifying the L<-nomake|/"-make , -nomake"> option
on the command-line.

=cut

##----------------------------------------------------------------------
=pod

=head2 Known Targets

=head3 -make Targets

The following targets are known values for the
L<-targets|/"-targets TARGETS"> option in L<-make Mode>:

=over 4

=item all

=item (not yet documented)

=back



=head3 -nomake Targets

The following targets are known values for the
L<-targets|/"-targets TARGETS"> option in L<-nomake Mode>:

=over 4

=item mkindex

B<Alias(es):> cx sx tx xx

B<Input(s):> FILE.xml

B<Output(s):> FILE.cx, FILE.sx, FILE.tx

Creates temporary
"character index" F<FILE.cx> (CSV),
"structure index" F<FILE.sx> (XML without C<E<lt>cE<gt>> elements),
and
"text index" F<FILE.tx> (raw text, unserialized)
for each input document F<FILE.xml>.

=item mkbx0

B<Alias(es):> bx0

B<Input(s):> FILE.sx

B<Output(s):> FILE.bx0

Creates temporary
hint- and serialization index F<FILE.bx0>
for each input document F<FILE.xml>

=item mkbx

B<Alias(es):> mktxt bx txt

B<Input(s):> FILE.bx0, FILE.tx

B<Output(s):> FILE.bx, FILE.txt

Creates temporary serialized block-index file F<FILE.bx>
and serialized text file F<FILE.txt>
for each input document F<FILE.xml>.

=item mktok0

B<Alias(es):> tokenize0 tok0 t0 tt0

B<Input(s):> FILE.txt

B<Output(s):> FILE.t0

Creates temporary CSV-format raw tokenizer output file F<FILE.t0>
for each input document F<FILE.xml>

=item mktok1

B<Alias(es):> tokenize1 tok1 t1 tt1

B<Input(s):> FILE.t0

B<Output(s):> FILE.t1

Creates temporary CSV-format post-processed tokenizer output file F<FILE.t1>
for each input document F<FILE.xml>

=item mktok

B<Alias(es):> tokenize tok t tt

B<Input(s):> FILE.txt

B<Output(s):> FILE.t0 FILE.t1

Wrapper for "mktok0 mktok1".

=item mktxml

B<Alias(es):> tok2xml xtok txml ttxml tokxml

B<Input(s):> FILE.t, FILE.bx, FILE.cx

B<Output(s):> FILE.t.xml

Creates master tokenized XML output file F<FILE.t.xml>
for each input document F<FILE.xml>

=item addws

B<Alias(es):> mkcws cwsxml cws

B<Input(s):> FILE.xml FILE.t.xml

B<Output(s):> FILE.cws.xml

Creates "spliced" XML output "Frankenfile" F<FILE.cws.xml>
for each input document F<FILE.xml> ;
see also L<dtatw-splice.perl(1)|dtatw-splice.perl>.

=item mksxml

B<Alias(es):> mksos sosxml sosfile sxml

B<Input(s):> FILE.t.xml

B<Output(s):> FILE.s.xml

B<DEPRECATED>

Creates sentence-level stand-off XML file FILE.s.xml
for each input document F<FILE.xml>

=item mkwxml

B<Alias(es):> mksow sowxml sowfile wxml

B<Input(s):> FILE.t.xml

B<Output(s):> FILE.w.xml

B<DEPRECATED>

Creates token-level stand-off XML file FILE.w.xml
for each input document F<FILE.xml>

=item mkaxml

B<Alias(es):> mksoa sowaml soafile axml

B<Input(s):> FILE.t.xml

B<Output(s):> FILE.a.xml

B<DEPRECATED>

Creates token-analysis-level stand-off XML file FILE.a.xml
for each input document F<FILE.xml>

=item mkstandoff

B<Alias(es):> standoff so mkso

B<DEPRECATED>

Alias for L<mksxml>, L<mkwxml>, L<mkaxml>.

=item all

B<Alias(es):> (none)

B<Input(s):> FILE.xml

B<Output(s):> FILE.t.xml, FILE.cws.xml

Alias for all targets required to generated
the target's output files (master tokenized file and spliced output)
from the input document, run in the proper order.

=item tei2t

B<Aliases:> (none)

B<Input(s):> FILE.xml

B<Output(s):> FILE.t

Alias for all targets required to generated
fixed tokenizer output F<FILE.t> from a TEI-XML file F<FILE.xml>,
run in the proper order.

=item tei2txml

B<Aliases:> (none)

B<Input(s):> FILE.xml

B<Output(s):> FILE.t.xml

Alias for all targets required to generated
a flat tokeized XML file F<FILE.t.xml> from a TEI-XML file F<FILE.xml>,
run in the proper order.

=back

=cut

##===============================================================================
=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dtatw-add-c.perl(1)|dtatw-add-c.perl>,
L<dtatw-add-w.perl(1)|dtatw-add-w.perl>,
L<dtatw-add-s.perl(1)|dtatw-add-s.perl>,
L<dtatw-rm-c.perl(1)|dtatw-rm-c.perl>,
L<dtatw-splice.perl(1)|dtatw-splice.perl>,
...

=cut

##===============================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
