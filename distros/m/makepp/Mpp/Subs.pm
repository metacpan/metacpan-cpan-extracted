# $Id: Subs.pm,v 1.201 2012/10/25 21:10:27 pfeiffer Exp $

=head1 NAME

Mpp::Subs - Functions and statements for makefiles

=head1 DESCRIPTION

This package contains subroutines which can be called from a makefile.
Subroutines in this package are called in two ways:

=over

=item 1)

Any line which isn't a rule or an assignment and has at the left margin a word
is interpreted as a subroutine call to a subroutine in the makefile package,
or if not in the makefile package, in this package.  "s_" is prefixed to the
name before the Perl function is looked up.

=item 2)

Any function that is in a make expression (e.g., $(xyz abc)) attempts to call
a Perl function in the make package, and failing that, in this package.  "f_"
is prefixed to the name first.

=back

All official subroutine names in this package are automatically exported to
each makefile package by Mpp::Makefile::load.  See the regexps in import, for
which ones are official.

=cut

package Mpp::Subs;

use strict qw(vars subs);

use Mpp::Text qw(index_ignoring_quotes split_on_whitespace requote
		unquote unquote_split_on_whitespace format_exec_args);
use Mpp::File;
use Mpp::FileOpt;
use Mpp::Event qw(wait_for when_done read_wait);
use Mpp::Glob qw(zglob zglob_fileinfo);
use Mpp::CommandParser;
use Mpp::CommandParser::Gcc;

# eval successfully or die with a fixed error message
our( $makefile, $makefile_line );
sub eval_or_die($$$) {
  my $code = $_[0];
  # Make $makefile and $makefile_line available to the Perl code, so that it
  # can call f_* and s_* subroutines.
  local( undef, $makefile, $makefile_line ) = @_; # Name the arguments.

  (my $line = $makefile_line) =~ s/(.+):(\d+)(?:\(.+\))?$/#line $2 "$1"/;
  &touched_filesystem;
  $code = qq{
    no strict; package $makefile->{PACKAGE};
    \@Cxt=(\$Mpp::Subs::makefile, \$Mpp::Subs::makefile_line);
$line
$code};
  if( wantarray ) {
    my @result = eval $code;
    &touched_filesystem;
    die $@ if $@;
    @result;
  } elsif( defined wantarray ) {
    my $result = eval $code;
    &touched_filesystem;
    die $@ if $@;
    $result;
  } else {
    eval $code;
    &touched_filesystem;
    die $@ if $@;
  }
}

our $rule;

###############################################################################
#
# Command parsers included with makepp:
#
# Parse C command, looking for sources and includes and libraries.
#
# TODO: is $ENV{INCLUDE} a reliable alternative on native Windows?  And if
# ActiveState is to call MinGW gcc, must makepp translate directory names?
our @system_include_dirs = grep -d, qw(/usr/local/include /usr/include);
our @system_lib_dirs = grep -d, qw(/usr/local/lib /usr/lib /lib);

sub p_gcc_compilation {
  shift;
  Mpp::CommandParser::Gcc->new( @_ );
}
# TODO: remove the deprecated backwards compatibility scanner_ variants.
*scanner_gcc_compilation = \&p_gcc_compilation;

sub p_c_compilation {
  shift;
  Mpp::CommandParser::Gcc->new_no_gcc( @_ );
}
*scanner_c_compilation = \&p_c_compilation;

sub p_esql_compilation {
  shift;
  require Mpp::CommandParser::Esql;
  Mpp::CommandParser::Esql->new( @_ );
}
*scanner_esql_compilation = \&p_esql_compilation;

sub p_vcs_compilation {
  shift;
  require Mpp::CommandParser::Vcs;
  Mpp::CommandParser::Vcs->new( @_ );
}
*scanner_vcs_compilation = \&p_vcs_compilation;

sub p_swig {
  shift;
  require Mpp::CommandParser::Swig;
  Mpp::CommandParser::Swig->new( @_ );
}
*scanner_swig = \&p_swig;

#
# This parser exists only to allow the user to say ":parser none" to suppress
# the default parser.
#
sub scanner_none {
  $_[1]{SCANNER_NONE} = 1;
  shift;
  Mpp::CommandParser->new( @_ );
}

#
# This parser simply moves to the next word that doesn't begin with
# - and parses again.
#
sub scanner_skip_word {
  #my ($action, $myrule, $dir) = @_;
  my ($action) = @_;		# Name the arguments.

  $action =~ s/^\s+//;		# Leading whitespace messes up the regular
				# expression below.
  while ($action =~ s/^\S+\s+//) { # Strip off another word.
    $action =~ s/^([\"\'\(])//;	# Strip off leading quotes in case it's
				# something like sh -c "cc ...".
    if( defined $1 ) {
      my $compl = ${{qw!" " ' ' ( \)!}}{$1};
      $action =~ s/$compl//;
    }
    next if $action =~ /^-/;	# Word that doesn't look like an option?
    local $_[1]{LEXER} if $_[1]{LEXER}; # Don't skip next word on recursion.
    local $_[1]{LEXER_OBJ} if $_[1]{LEXER_OBJ}; # ditto
    my $lexer = new Mpp::Lexer;
    $_[1]{SCANNER_NONE} = 1
      if Mpp::Lexer::parse_command( $lexer, $action, $_[1], $_[2], $_[1]{MAKEFILE}{ENVIRONMENT} );
    last;			# Don't go any further.
  }
  new Mpp::Lexer;
}

# These are implemented in Mpp::Lexer::find_command_parser
(*p_none, *p_skip_word, *p_shell) = @Mpp::Text::N;

#
# This array contains the list of the default parsers used for various
# command words.
#
our %parsers =
  (
   # These words usually introduce another command
   # which actually is the real compilation command:
   ash		=> \&p_shell,
   bash		=> \&p_shell,
   csh		=> \&p_shell,
   ksh		=> \&p_shell,
   sh		=> \&p_shell,
   tcsh		=> \&p_shell,
   zsh		=> \&p_shell,
   eval		=> \&p_shell,

   ccache	=> \&p_skip_word,
   condor_compile => \&p_skip_word,
   cpptestscan	=> \&p_skip_word, # Parasoft c++test
   diet		=> \&p_skip_word, # dietlibc
   distcc	=> \&p_skip_word,
   fast_cc	=> \&p_skip_word,
   libtool	=> \&p_skip_word,
   purecov	=> \&p_skip_word,
   purify	=> \&p_skip_word,
   quantify	=> \&p_skip_word,
   time		=> \&p_skip_word,

   # All the C/C++ compilers we have run into so far:
   aCC		=> \&p_c_compilation, # HP C++.
   bcc32	=> \&p_c_compilation, # Borland C++
   c89		=> \&p_c_compilation,
   c99		=> \&p_c_compilation,
   cc		=> \&p_c_compilation,
   CC		=> \&p_c_compilation,
   ccppc	=> \&p_c_compilation, # Green Hills compilers.
   clang	=> \&p_c_compilation, # LLVM
   cl		=> \&p_c_compilation, # MS Visual C/C++
  'c++'		=> \&p_c_compilation,
   cpp		=> \&p_c_compilation, # The C/C++ preprocessor.
   cxppc	=> \&p_c_compilation,
   cxx		=> \&p_c_compilation,
   icc		=> \&p_c_compilation, # Intel
   icl		=> \&p_c_compilation, # Intel?
   ingcc	=> \&p_c_compilation, # Ingres wrapper
   insure	=> \&p_c_compilation, # Parasoft Insure++
   kcc		=> \&p_c_compilation, # KAI C++.
   lsbcc	=> \&p_c_compilation, # LSB wrapper around cc.
  'lsbc++'	=> \&p_c_compilation,
   pcc		=> \&p_c_compilation,
   xlC		=> \&p_c_compilation,
   xlc		=> \&p_c_compilation, # AIX
   xlc_r	=> \&p_c_compilation,
   xlC_r	=> \&p_c_compilation,

   vcs		=> \&p_vcs_compilation,

   apre		=> \&p_esql_compilation, # Altibase APRE*C/C++
   db2		=> \&p_esql_compilation, # IBM DB2
   dmppcc	=> \&p_esql_compilation, # CASEMaker DBMaker
   ecpg		=> \&p_esql_compilation, # PostgreSQL
   esql		=> \&p_esql_compilation, # IBM Informix ESQL/C / Mimer
   esqlc	=> \&p_esql_compilation, # Ingres
   gpre		=> \&p_esql_compilation, # InterBase / Firebird
   proc		=> \&p_esql_compilation, # Oracle
   yardpc	=> \&p_esql_compilation, # YARD

   swig         => \&p_swig
);

@parsers{ map "$_.exe", keys %parsers } = values %parsers
  if Mpp::is_windows;


#
# An internal subroutine that converts Mpp::File structures to printable
# names.  Takes either a single Mpp::File structure, an array of Mpp::File
# structures, or a reference to an array of Mpp::File structures.
#
sub relative_filenames {
  my @ret_vals;

  my $cwd = $rule->build_cwd;
  foreach (@_) {
    next unless defined;	# Skip undef things--results in a blank.
    push @ret_vals, (ref() eq 'ARRAY') ? relative_filenames(@$_) : relative_filename $_, $cwd;
  }

  @ret_vals;
}

###############################################################################
#
# Functions that are intended to be invoked by make expressions.  These
# all begin with the prefix "f_", which is added before we look up the
# name of the function.	 These functions are called with the following
# arguments:
# a) The text after the function name in the makefile (with other macros
#    already expanded).
# b) The makefile.
# c) The line number in the makefile that this expression occurred in.
#

#
# Define all the cryptic one-character symbols, and anything else that isn't a
# valid subroutine name:
#
our %perl_unfriendly_symbols =
  ('@' => \&f_target,
   '<' => \&f_dependency,
   '^' => \&f_dependencies,
   '?' => \&f_changed_dependencies,
   '+' => \&f_sorted_dependencies,
   '*' => \&f_stem,
   '&' => '',			# Perl makefiles use this for some reason, but
				# $& is a perl pattern match variable.
   '/' => Mpp::is_windows > 1 ? '\\' : '/',

   '@D' => \&f_target,		# Special handling in expand_variable for /^.[DF]$/.
   '@F' => \&f_target,
   '*D' => \&f_stem,
   '*F' => \&f_stem,
   '<D' => \&f_dependency,
   '<F' => \&f_dependency,
   '^D' => \&f_dependencies,
   '^F' => \&f_dependencies
  );

#
# Obtain the single arg of a makefile f_function.
# This utility takes the same 3 parameters as f_* functions, so call it as: &arg
#
# It gives you the expanded value of the calling f_function's single arg, if the
# first parameter is a ref to a string, else just the unexpanded string.
# If the 2nd arg is false it also doesn't expand.
#
# If the f_function doesn't take an arg, there is no need to call this.
#
sub arg { $_[1] && ref $_[0] ? $_[1]->expand_text( ${$_[0]}, $_[2] ) : $_[0] }

#
# Obtain multiple args of a makefile f_function.
# This utility takes the same 3 parameters as arg
#
# Additional parameters:
# max: number of args (default 2): give ~0 (maxint) for endless
# min: number of args (default 0 if max is ~0, else same as max)
# only_comma: don't eat space around commas
#
sub args {
  local $_ = ref $_[0] ? ${$_[0]} : $_[0]; # Make a modifiable copy
  my $max = $_[3] || 2;
  my $min = ($_[4] or $max == ~0 ? 1 : $max) - 1;
  pos = 0;
  while( length() > pos ) {
    /\G[^,\$]+/gc;
    if( /\G,/gc ) {
      --$min if $min;
      last unless --$max;
      my $pos = pos;
      substr $_, $pos - 1, 1, "\01";
      pos = $pos;
    } elsif( /\G\$/gc ) {
      &Mpp::Text::skip_over_make_expression;
    }
  }
  tr/\01/,/,
  die $_[2] || 'somewhere', ': $(', (caller 1)[3], " $_) $min more arguments expected\n" if $min;
  $_ = $_[1]->expand_text( $_, $_[2] ) if $_[1] && ref $_[0] && /\$/;
  $_[5] ? split "\01", $_, -1 : split /\s*\01\s*/, $_, -1;
}

#
# Return the absolute filename of all the arguments.
#
sub f_absolute_filename {
  my $cwd = $_[1] && $_[1]{CWD};
  join ' ',
    map absolute_filename( file_info unquote(), $cwd ),
      split_on_whitespace &arg;
}
*f_abspath = \&f_absolute_filename;

sub f_absolute_filename_nolink {
  my $cwd = $_[1]{CWD};
  join ' ',
    map absolute_filename_nolink( file_info unquote(), $cwd ),
      split_on_whitespace &arg;
}
*f_realpath = \&f_absolute_filename_nolink;

sub f_addprefix {
  my( $prefix, $text ) = args $_[0], $_[1], $_[2], 2, 2, 1; # Get the prefix.
  join ' ', map "$prefix$_", split ' ', $text;
}

sub f_addsuffix {
  my( $suffix, $text ) = args $_[0], $_[1], $_[2], 2, 2, 1; # Get the suffix.
  join ' ', map "$_$suffix", split ' ', $text;
}

sub f_and {
  my $ret = '';
  for my $cond ( args $_[0], undef, $_[2], ~0 ) {
    $ret = $_[1] && ref $_[0] ? $_[1]->expand_text( $cond, $_[2] ) : $cond;
    return '' unless length $ret;
  }
  $ret;
}

sub f_or {
  for my $cond ( args $_[0], undef, $_[2], ~0 ) {
    $cond = $_[1]->expand_text( $cond, $_[2] )
      if $_[1] && ref $_[0];
    return $cond if length $cond;
  }
  '';
}

sub f_basename {
  join ' ', map { s!\.[^./,]*$!!; $_ } split ' ', &arg;
}

our $call_args = 1;		# In nested call, don't inherit outer extra args.
sub f_call {
  my @args= args $_[0], $_[1], $_[2], ~0, 1, 1;
  local @perl_unfriendly_symbols{0..($#args>$call_args ? $#args : $call_args)} = @args; # assign to $0, $1, $2...
  local $call_args = $#args;
  local $Mpp::Makefile::expand_bracket;
  $_[1]->expand_variable( $args[0], $_[2] );
}

sub f_dir {
  join ' ', map { m@^(.*/)@ ? $1 : './' } split ' ', &arg;
}

sub f_dir_noslash {		# An internal routine that does the same
				# thing but doesn't return a trailing slash.
  join ' ', map { m@^(.*)/@ ? $1 : '.'} split ' ', &arg;
}

sub f_error {
  die "$_[2]: *** ".&arg."\n";	# Throw the text.
}

#
# Perform a pattern substitution on file names.	 This differs from patsubst
# in that it will perform correctly when alternate names for directories are
# given (as long as they precede the percent sign).  For example,
#
#  $(filesubst ./src/%.c, %.o, $(wildcard src/*.c))
#
# will work with filesubst but not with patsubst.
#
sub f_filesubst {
  my( $src, $dest, $words, $set_stem ) = args $_[0], $_[1], $_[2], 4, 3;
				# Get the patterns.
  die "$_[2]: filesubst has extra argument `$set_stem'\n" if defined $set_stem && $set_stem ne '_';
  my $cwd = $_[1]{CWD};
#
# First we eat away at the directories on the source until we find the
# percent sign.	 We remember where this directory is.  Then we consider each
# of the words and strip off leading directories until we reach that
# directory.  Then we run through patsubst.
#
  my $startdir = ($src =~ s@^/+@@) ? $Mpp::File::root : $cwd;
				# The directory we're in if there are no
				# other directories specified.

  while ($src =~ s@([^%/]+)/+@@) { # Strip off a leading directory that
				# doesn't contain the % sign.
    $startdir = dereference file_info $1, $startdir;
				# Move to that directory.
  }

#
# Now eat away at the directories in the words until we reach the starting
# directory.
#
  my @words;
  foreach( split ' ', $words ) {
    my $thisdir = (s@^/+@@) ? $Mpp::File::root : $cwd;
    $thisdir = dereference file_info $1, $thisdir
      while $thisdir != $startdir && s@([^/]+)/+@@;	# Another directory?
    push @words, case_sensitive_filenames ? $_ : lc;
				# What's left is the filename relative to that
				# directory.
  }

  local $Mpp::Text::set_stem = 1 if $set_stem;
  join ' ', Mpp::Text::pattern_substitution
    case_sensitive_filenames ? $src : lc $src,
					    $dest,
    @words;
}

sub f_filter {
  my( $filters, $words ) = args $_[0], $_[1], $_[2];
  my @filters = split ' ', $filters; # Can be more than one filter.
  foreach (@filters) {		# Convert these into regular expressions.
    s/([.+()])/\\$1/g;		# Protect all the periods and other special chars.
    s/[*%]/\.\*/g;		# Replace '*' and '%' with '.*'.
    $_ = qr/^$_$/;		# Anchor the pattern.
  }

  my @ret_words;
 wordloop:
  foreach( split ' ', $words ) { # Now look at each word.
    foreach my $filter (@filters) {
      if (/$filter/) {		# Does it match this filter?
	push @ret_words, $_;
	next wordloop;
      }
    }
  }

  join ' ', @ret_words;
}


sub f_filter_out {
  my ($filters, $words) = args $_[0], $_[1], $_[2];
  my @filters = split ' ', $filters; # Can be more than one filter.
  foreach (@filters) {		# Convert these into regular expressions.
    s/([.+()])/\\$1/g;		# Protect all the periods and other special chars.
    s/[*%]/\.\*/g;		# Replace '*' and '%' with '.*'.
    $_ = qr/^$_$/;		# Anchor the pattern.
  }

  my @ret_words;
 wordloop:
  foreach( split ' ', $words ) { # Now look at each word.
    foreach my $filter (@filters) {
      next wordloop if /$filter/; # Skip if it matches this filter.
    }
    push @ret_words, $_;
  }

  join ' ', @ret_words;
}

sub f_filter_out_dirs {
  #my ($text, $mkfile) = @_; # Name the arguments.
  join ' ', grep { !is_or_will_be_dir file_info $_, $_[1]{CWD} } split ' ', &arg;
}

#
# Find one of several executables in PATH.  Optional 4th arg means to return found path.
# Does not consider last chance rules or autoloads if PATH is used.
#
# On Windows this is ugly, because an executable xyz is usually not present,
# instead there is xyz.exe.  If we want the full path with the builtin rules
# we need to depend on xyz as long as xyz.exe hasn't been built, because
# that's where Unix makefiles put the dependencies.  To make matters worse,
# stat may lie about xyz when only xyz.exe exists.
#
sub f_find_program {
  my $mkfile = $_[1];		# Access the other arguments.

  my @pathdirs;			# Remember the list of directories to search.
  my $first_round = 1;
  foreach my $name ( split ' ', &arg) {
    if( $name =~ /\// || Mpp::is_windows > 1 && $name =~ /\\/ ) { # Either relative or absolute?
      my $finfo = path_file_info $name, $mkfile->{CWD};
      my $exists = Mpp::File::exists_or_can_be_built $finfo;
      if( Mpp::is_windows && $name !~ /\.exe$/ ) {
	my( $exists_exe, $finfo_exe );
	$exists_exe = Mpp::File::exists_or_can_be_built $finfo_exe = Mpp::File::path_file_info "$name.exe", $mkfile->{CWD}
	  if !$exists ||
	    $_[3] && Mpp::File::stat_exe_separate ? !exists $finfo->{xEXISTS} : !open my $fh, '<', absolute_filename $finfo;
				# Check for exe, but don't bother returning it, unless full path wanted.
				# If stat has .exe magic, xEXISTS is meaningless.
	return $_[3] ? absolute_filename( $finfo_exe ) : $name if $exists_exe;
      }
      return $_[3] ? absolute_filename( $finfo ) : $name if $exists;
      next;
    }
    @pathdirs = Mpp::Text::split_path( $mkfile->{EXPORTS} ) unless @pathdirs;
    foreach my $dir (@pathdirs) { # Find the programs to look for in the path:
      # Avoid publishing nonexistent dirs in the path.  This works around
      # having unquoted drive letters in the path looking like relative
      # directories.
      if( $first_round ) {
	$dir = path_file_info $dir, $mkfile->{CWD};
	undef $dir unless is_or_will_be_dir $dir;
      }
      next unless $dir;
      my $finfo = file_info $name, $dir;
      my $exists = Mpp::File::exists_or_can_be_built $finfo, undef, undef, 1;
      if( Mpp::is_windows && $name !~ /\.exe$/ ) {
	my( $exists_exe, $finfo_exe );
	$exists_exe = Mpp::File::exists_or_can_be_built $finfo_exe = file_info( "$name.exe", $dir ), undef, undef, 1
	  if !$exists ||
	    $_[3] && Mpp::File::stat_exe_separate ? !exists $finfo->{xEXISTS} : !open my $fh, '<', absolute_filename $finfo;
				# Check for exe, but don't bother returning it, unless full path wanted.
	return $_[3] ? absolute_filename( $finfo_exe ) : $name if $exists_exe;
      }
      return $_[3] ? absolute_filename( $finfo ) : $name if $exists;
    }
    $first_round = 0;
  }

  Mpp::log NOT_FOUND => ref $_[0] ? ${$_[0]} : $_[0], $_[2];
  'not-found';			# None of the programs were executable.
}

#
# Find a file in a specified path, or in the environment variable PATH if
# nothing is specified.
#
sub f_findfile {
  my ($name, $path) = args $_[0], $_[1], $_[2]; # Get what to look for, and where
				# to look for it.
  my $mkfile = $_[1]; # Access the other arguments.
  my @pathdirnames = $path ? split( /\s+|:/, $path ) :
    Mpp::Text::split_path( $mkfile->{EXPORTS} );
				# Get a separate list of directories.
  my @names = split ' ', $name; # Get a list of names to find.
  foreach $name (@names) {	# Look for each one in the path:
    foreach my $dir (@pathdirnames) {
      my $finfo = file_info $name, file_info $dir, $mkfile->{CWD};
				# Get the finfo structure.
      if( file_exists $finfo ) { # Found it?
	$name = absolute_filename $finfo; # Replace it with the full name.
	last;			# Skip to the next thing to look for.
      }
    }
  }

  join ' ', @names;
}

#
# Find a file by searching for it in the current directory, then in ., ..,
# etc.
# Modified from function contributed by Matthew Lovell.
#
# Two versions are supplied: $(find_upwards ...) is the original function:
# its behavior, when given multiple filenames, it attempts to find all
# the requested files
#
sub f_find_upwards {
  my $cwd = $_[1] && $_[1]{CWD};
  my @ret_names;
  my $cwd_devid;		# Remember what device this is mounted on
				# so we can avoid crossing file system boundaries.
  for( split_on_whitespace &arg ) {
    $_ = unquote;
    my $found;
    my $dirinfo = $cwd;
    while( 1 ) {
      my $finfo = file_info $_, $dirinfo;
      if( Mpp::File::exists_or_can_be_built $finfo ) { # Found file in the path?
	$found = 1;
	push @ret_names, relative_filename $finfo, $cwd;
	last;			# done searching
      }
      last unless $dirinfo = $dirinfo->{'..'}; # Look in all directories above us.
      last if (stat_array $dirinfo)->[Mpp::File::STAT_DEV] !=
	($cwd_devid ||= (stat_array $cwd)->[Mpp::File::STAT_DEV]);
				# Don't cross device boundaries.  This is
				# intended to avoid trouble with automounters
				# or dead network file systems.
    }
    $found or die "find_upwards: cannot find file $_\n";
  }

  join ' ', @ret_names;
}

#
# $(find_first_upwards ...) is similar, but reverses the order of the loop.
# It looks for any of the named files at one directory-level, before going
# to "..", where it then also looks for any of the filenames. It returns the
# first file that it finds.  With a 4th true arg, returns a Mpp::File instead.
# If the 4th arg is a ref, only returns files that already exist.
#
sub f_find_first_upwards {
  my @fnames = unquote_split_on_whitespace &arg;
  my $cwd = $_[1] && $_[1]{CWD};

  my $cwd_devid;		# Remember what device this is mounted on
				# so we can avoid crossing file system boundaries.
  my $dirinfo = $cwd;
  while( 1 ) {
    for( @fnames ) {
      my $finfo = file_info $_, $dirinfo;
      return $_[3] ? $finfo : relative_filename $finfo, $cwd
	if ref $_[3] ?
	  file_exists $finfo :
	  Mpp::File::exists_or_can_be_built $finfo; # Found file in the path?
    }
    last unless $dirinfo = $dirinfo->{'..'}; # Look in all directories above us.
    last if (stat_array $dirinfo)->[Mpp::File::STAT_DEV] !=
      ($cwd_devid ||= (stat_array $cwd)->[Mpp::File::STAT_DEV]);
				# Don't cross device boundaries.  This is
				# intended to avoid trouble with automounters
				# or dead network file systems.
  }
  return if $_[3];
  die "find_first_upwards cannot find any of the requested files: @fnames\n";
}

sub f_findstring {
  my( $find, $in ) = args $_[0], $_[1], $_[2], 2, 2, 1;

  (index($in, $find) >= 0) ? $find : '';
}

sub f_firstword {
  (split ' ', &arg, 2)[0] || '';
}

#
# Return the first available file of a list of possible candidates.
# This can be used to make your makefiles work in several different
# environments.
#
sub f_first_available {
  foreach my $fname (split ' ', &arg) {
    Mpp::File::exists_or_can_be_built( file_info $fname, $_[1]->{CWD} ) and return $fname;
  }
  '';
}

#
# The if function is unusual, because its arguments have not
# been expanded before we call it.  The if function is defined so that
# only the expression that is actually used is expanded.  E.g., if the
# if statement is true, then only the then expression is expanded, and
# any side effects of the else expression do not happen.
#
sub f_if {
  my( $cond, $then, $else ) = args $_[0], undef, $_[2], 3, 2, 1;
  my( undef, $mkfile, $mkfile_line, $iftrue ) = @_; # Name the arguments.
  $cond = ref $_[0] ? $mkfile->expand_text( $cond, $mkfile_line ) : $cond; # Evaluate the condition.
  $cond =~ s/^\s+//;		# Strip out whitespace on the response.
  $cond =~ s/\s+$//;
  if( $cond || !$iftrue && $cond ne "" ) {
    ref $_[0] ? $mkfile->expand_text( $then, $mkfile_line ) : $then;
  } elsif( defined $else ) {
    ref $_[0] ? $mkfile->expand_text( $else, $mkfile_line ) : $else;
  } else {
    '';
  }
}
sub f_iftrue {
  $_[3] = 1;
  goto &f_if;
}

#
# Infer the linker command from a list of objects.  If any of the objects
# is Fortran, we use $(FC) as a linker; if any of the objects is C++, we
# use $(CXX); otherwise, we use $(CC).
#
# This function is mostly used by the default link rules (see
# makepp_builtin_rules.mk).
#
sub f_infer_linker {
  my @objs = split ' ', &arg;	# Get a list of objects.
  my( undef, $mkfile, $mkfile_line ) = @_; # Name the arguments.
#
# First build all the objs.  Until we build them, we don't actually know what
# source files went into them.	They've probably been built, but we must
# make sure.
#
  my @build_handles;
  &Mpp::maybe_stop;
  foreach my $obj (@objs) {
    $obj = file_info($obj, $mkfile->{CWD}); # Replace the name with the
				# fileinfo.
    my $bh = prebuild( $obj, $mkfile, $mkfile_line );
				# Build this one.
    $bh and push @build_handles, $bh;
  }

  my $status = wait_for @build_handles;	# Wait for them all to build.
  $status and die "Error while compiling\n"; # Maybe I'll come up with a better
				# error message later.

#
# Now see what source files these were built from.  Unfortunately, the
# dependencies have been sorted, so we can't just look at the first one.
#
  my $linker;
  foreach my $obj (@objs) {
    foreach my $source_name( split /\01/, Mpp::File::build_info_string($obj, 'SORTED_DEPS') || '' ) {
      # TODO: Why is $(FC) only Fortran 77?  What about .f90 files?
      $source_name =~ /\.f(?:77)?$/ and $linker = '$(FC)';
      $source_name =~ /\.(?:c\+\+|cc|cxx|C|cpp|moc)$/ and $linker ||= '$(CXX)';
    }
  }
  $linker ||= '$(CC)';	# Assume we can use the ordinary C linker.

  $mkfile->expand_text($linker, $mkfile_line);
				# Figure out what those things expand to.
}

#
# Usage:
#    target : $(infer_objs seed-list, list of possible objs)
#
sub f_infer_objects {
  my ($seed_objs, $candidate_list) = args $_[0], $_[1], $_[2];
  my (undef, $mkfile, $mkfile_line) = @_; # Name the arguments.

  my $build_cwd = $rule ? $rule->build_cwd : $mkfile->{CWD};

#
# Build up a list of all the possibilities:
#
  my %candidate_objs;
  foreach my $candidate_obj (map Mpp::Glob::zglob_fileinfo_atleastone($_, $build_cwd), split ' ', $candidate_list) {
				# Get a list of all the possible objs.
    my $objname = $candidate_obj->{NAME};
    $objname =~ s/\.[^\.]+$//;	# Strip off the extension.
    if ($candidate_objs{$objname}) { # Already something by this name?
      ref($candidate_objs{$objname}) eq 'ARRAY' or
	$candidate_objs{$objname} = [ $candidate_objs{$objname} ];
				# Make into an array as appropriate.
      push @{$candidate_objs{$objname}}, $candidate_obj;
    }
    else {			# Just one obj?
      $candidate_objs{$objname} = $candidate_obj;
    }
  }
#
# Now look at the list of all the include files.  This is a little tricky
# because we don't know the include files until we've actually built the
# dependencies.
#
  my %source_names;		# These are the names of include files for
				# which are look for the corresponding objects.

  my @build_handles;		# Where we put the handles for building objects.
  my @deps = map zglob_fileinfo($_, $build_cwd), split ' ', $seed_objs;
				# Start with the seed files themselves.
  @deps or die "infer_objects called with no seed objects that exist or can be built\n";
  Mpp::log INFER_SEED => \@deps
    if $Mpp::log_level;

  foreach (@deps) {
    my $name = $_->{NAME};
    $name =~ s/\.[^\.]+$//;	# Strip off the extension.
    $source_names{$name}++;	# Indicate that we already have this as a
				# source file.
  }


  my $dep_idx = 0;

  &Mpp::maybe_stop;
#
# Build everything, so we know what everything's dependencies are.  Initially,
# we'll only have a few objects to start from, so we build all of those, in
# parallel if possible.	 (That's why the loop structure is so complicated
# here.)  Then we infer additional objects, build those in parallel, and
# so on.
#
  for (;;) {
    while ($dep_idx < @deps) {	# Look at each dependency currently available.
      my $o_info = $deps[$dep_idx]; # Access the Mpp::File for this object.
      my $bh = prebuild( $o_info, $mkfile, $mkfile_line );
				# Start building it.
      my $handle = when_done $bh, # Build this dependency.
      sub {			# Called when the build is finished:
	defined($bh) && $bh->status and return $bh->status;
				# Skip if an error occurred.
	my @this_sources = split /\01/, Mpp::File::build_info_string($o_info,'SORTED_DEPS') || '';
				# Get the list of source files that went into
				# it.
	foreach (@this_sources) {
	  my $name = $_;	# Make a copy of the file.
	  $name =~ s@.*/@@;	# Strip off the path.
	  $name =~ s/\.[^\.]+$//; # Strip off the extension.
	  unless ($source_names{$name}++) { # Did we already know about that source?
	    if (ref($candidate_objs{$name}) eq 'Mpp::File') { # Found a file?
	      Mpp::log INFER_DEP => $candidate_objs{$name}, $_
		if $Mpp::log_level;
	      push @deps, $candidate_objs{$name}; # Scan for its dependencies.
	    }
	    elsif (ref($candidate_objs{$name}) eq 'ARRAY') { # More than 1 match?
	      Mpp::print_error('`', $mkfile_line, "' in infer_objects: more than one possible object for include file $_:\n  ",
			    join("\n  ", map absolute_filename( $_ ), @{$candidate_objs{$name}}),
			    "\n");
	    }
	  }
	}
      };

      if (defined($handle)) {   # Something we need to wait for?
        $handle->{STATUS} && !$Mpp::keep_going and
          die "$mkfile_line: infer_objects failed because dependencies could not be built\n";
        push @build_handles, $handle;
      }
      ++$dep_idx;
    }

    last unless @build_handles;	# Quit if nothing to wait for.
    my $status = wait_for @build_handles; # Wait for them all to build, and
				# try again.
    @build_handles = ();	# We're done with those handles.
    $status and last;		# Quit if there was an error.
  }

#
# At this point, we have built all the dependencies, and we also have a
# complete list of all the objects.
#
  join ' ', map relative_filename( $_, $build_cwd ), @deps;
}

sub f_info {
  print &arg."\n";		# Print the text.
  '';
}

sub f_join {
  my ($words1, $words2) = args $_[0], $_[1], $_[2], 2, 2, 1;
				# Get the two lists of words.
  my @words1 = split ' ', $words1;
  my @words2 = split ' ', $words2;

  for my $word ( @words1 ) {
    last unless @words2;
    $word .= shift @words2;
  }
  push @words1, @words2;
  join ' ', @words1;
}

#
# map Perl code to variable values
#
sub f_makemap {
  my( $list, $code ) = args $_[0], $_[1], $_[2];
  $code = eval_or_die "sub {$code\n;defined}", $_[1], $_[2];
  $_[1]->cd;			# Make sure we're in the correct directory
  join ' ', grep &$code, split_on_whitespace $list;
}
sub f_map {
  my( $list, $code ) = args $_[0], undef, $_[2];
  $code = eval_or_die "sub {$code\n;defined}", $_[1], $_[2];
  $_[1]->cd;			# Make sure we're in the correct directory
  join ' ', grep &$code, split_on_whitespace ref $_[0] ? $_[1]->expand_text( $list, $_[2] ) : $list;
}

#
# make a temporary file name, similarly to the like named Unix command
#
our @temp_files;
END { Mpp::File::unlink $_ for @temp_files }
sub f_mktemp {
  my $template = &arg;
  my $mkfile = $_[1];
  $mkfile ||= \%Mpp::Subs::;	# Any old hash for default LAST_TEMP_FILE & CWD
  return $mkfile->{LAST_TEMP_FILE} || die "No previous call to \$(mktemp)\n" if $template eq '/';
  $template ||= 'tmp.';
  my $Xmax = 9;
  $Xmax = length( $1 ) - 1 if $template =~ s/(X+)$//;
  my $finfo;
  for( 0..999 ) {		# Should not normally loop at all.
    my $X = '';
    for( 0..$Xmax ) {
      my $chr = (!$_ && $Xmax) ? $$ % (26 + 26 + 10) : int rand 26 + 26 + 10;
				# First is from pid, if at least two given.
      $X .= $chr < 10 ?
	$chr :
	chr $chr - 10 + ($chr < 26 + 10 ?
			 ord 'a' :
			 -26 + ord 'A');
    }
    $mkfile->{LAST_TEMP_FILE} = $template . $X;
    $finfo = file_info $mkfile->{LAST_TEMP_FILE}, $mkfile->{CWD};
				# Default to global CWD, to make this easier to use without makefile.
    unless( $finfo->{MKTEMP}++ || file_exists $finfo ) {
      push @temp_files, $finfo;
      return $mkfile->{LAST_TEMP_FILE};
    }
  }
  die "$_[2]: too many tries necessary to make unique filename for $_[0]\n";
}

#
# Force all the targets to be made.
#
sub f_prebuild {
  my $names = &arg;
  my( undef, $mkfile, $mkfile_line ) = @_;

  my @build_handles;
  &Mpp::maybe_stop;
  for( split_on_whitespace $names ) {
    push @build_handles, prebuild( file_info( unquote(), $mkfile->{CWD} ),
				   $mkfile, $mkfile_line  );
                                # Start building this target.
  }
  my $status = wait_for @build_handles; # Wait for them all to complete before
                                # we continue.
  $status and die "\$(prebuild $names) failed\n";

  $names;			# Return arguments verbatim now that we have
                                # built them.
}
*f_make = \&f_prebuild;

sub f_notdir {
  join ' ', map { m@^.*/([^/]+)@ ? $1 : $_ } split ' ', &arg;
}

#
# Return only the files in the list that are actually targets of some rule:
#
sub f_only_targets {
  my $phony = $_[3];
  my $cwd = $_[1] && $_[1]{CWD};
  my @ret_files;

  foreach (split ' ', &arg) {
    foreach my $finfo (zglob_fileinfo($_, $cwd, 0, $phony)) {
      $phony || exists($finfo->{RULE}) and
	push @ret_files, relative_filename $finfo, $cwd;
    }
  }

  join ' ', @ret_files;
}

#
# Return only the targets in the list that are phony:
#
sub f_only_phony_targets {
  $_[3] = \1;
  goto &f_only_targets;
}

#
# Return only the files in the list that are not targets of some rule:
#
sub f_only_nontargets {
  my $cwd = $_[1] && $_[1]{CWD};
  my @ret_files;

  foreach (split ' ', &arg) {
    foreach my $finfo (Mpp::Glob::zglob_fileinfo_atleastone($_, $cwd)) {
      exists($finfo->{RULE}) or
	push @ret_files, relative_filename $finfo, $cwd;
    }
  }

  join ' ', @ret_files;
}

#
# Returns only the existing files that were generated by makepp, according
# to the build info.
#
sub f_only_generated {
  #my ($text, $mkfile) = @_;	# Name the arguments.
  my $cwd = $_[1] && $_[1]{CWD};
  my @ret_files;

  foreach (split ' ', &arg) {
    foreach my $finfo (Mpp::Glob::zglob_fileinfo_atleastone($_, $cwd, 0,0,1)) {
      Mpp::File::was_built_by_makepp( $finfo ) and
	push @ret_files, relative_filename $finfo, $cwd;
    }
  }

  join ' ', @ret_files;
}

#
# Returns only the existing files that were generated by makepp, according
# to the build info, but are no longer targets.
#
sub f_only_stale {
  my $cwd = $_[1] && $_[1]{CWD};
  my @ret_files;

  foreach (split ' ', &arg) {
    foreach my $finfo (Mpp::Glob::zglob_fileinfo_atleastone($_, $cwd, 0,0,1)) {
      Mpp::File::is_stale( $finfo ) and
	push @ret_files, relative_filename $finfo, $cwd;
    }
  }

  join ' ', @ret_files;
}

#
# Figure out where a variable came from:
#
sub f_origin {
  my $varname = &arg;
  my $mkfile = $_[1];
  $perl_unfriendly_symbols{$varname} ? 'automatic' :
  $Mpp::Makefile::private && defined $Mpp::Makefile::private->{PRIVATE_VARS}{$varname} ? 'file' :
  defined ${$mkfile->{PACKAGE} . "::$varname"} ? 'file' :
  defined ${"Mpp::global::$varname"} ? 'global' :
  $mkfile->{COMMAND_LINE_VARS}{$varname} ? 'command line' :
  $mkfile->{ENVIRONMENT}{$varname} ? 'environment' :
  !defined( *{$mkfile->{PACKAGE} . "::f_$varname"}{CODE} ) ? 'undefined' :
  $varname =~ /^(?:foreach|targets?|dependenc(?:y|ies)|inputs?|outputs?)$/ ? 'automatic' :
    'default';	# Must be a variable like "CC".
}

#
# Perform a pattern substitution:
#
sub f_patsubst {
  my ($src, $dest, $words) = args $_[0], $_[1], $_[2], 3;
				# Get the arguments.
  join ' ', Mpp::Text::pattern_substitution( $src, $dest,
					     split_on_whitespace $words );
}

#
# evaluate Perl code as a function
#
sub f_makeperl {
  $_[1]->cd;			# Make sure we're in the correct directory
  join ' ', grep { defined } eval_or_die &arg, $_[1], $_[2];
}
sub f_perl {
  if( ref $_[0] ) {
    f_makeperl ${$_[0]}, $_[1], $_[2]; # deref to avoid expansion
  } else {
    goto &f_makeperl
  }
}

#
# Mark targets as phony:
#
sub f_phony {
  my $text = &arg;
  undef file_info( unquote(), $_[1]{CWD} )->{xPHONY}
    for split_on_whitespace $text;
  $text;			# Just return our argument.
}

sub f_print {
  my $text = &arg;
  print "$text\n";		# Print the text.
  $text;			# Just return it verbatim.
}

#
# Return a filename for a given file relative to the current directory.
# (Modified from Matthew Lovell's contribution.)
#
sub f_relative_filename {
  my( $files, $slash ) = args $_[0], $_[1], $_[2], 2, 1;
  my $cwd = $_[1]{CWD};
  join ' ',
    map {
      $_ = relative_filename file_info( unquote(), $cwd ), $cwd;
      !$slash || m@/@ ? $_ : "./$_"
    } split_on_whitespace $files;
}

#
# Return a filename relative to a given directory.
# Syntax: $(relative_to file1 file2, path/to/other/directory)
#
sub f_relative_to {
  my ($files, $dir, $slash) = args $_[0], $_[1], $_[2], 3, 2;
  my $cwd = $_[1]{CWD};
  defined $dir or die "wrong number of arguments to \$(relative_to file, dir)\n";
  $dir =~ s/^\s+//;		# Trim whitespace.
  $dir =~ s/\s+$//;
  my $dirinfo = file_info unquote( $dir ), $cwd;
				# Directory this is relative to.
  join ' ',
    map {
      $_ = relative_filename file_info( unquote(), $cwd ), $dirinfo;
      !$slash || m@/@ ? $_ : "./$_"
    } split_on_whitespace $files;
}

sub f_shell {
  my $str = &arg;
  my( undef, $mkfile, $mkfile_line ) = @_; # Name the arguments.
  Mpp::log SHELL => $str, $mkfile_line
    if $Mpp::log_level;

  local %ENV;			# Pass all exports to the subshell.
  $mkfile->setup_environment;

  $mkfile->cd;	# Make sure we're in the correct directory.
  my $shell_output = '';
  if( Mpp::is_windows ) {	# Doesn't support forking well?
    if( Mpp::is_windows != 1 ) {
      $shell_output = `$str`;	# Run the shell command.
    } else {			# ActiveState not using command.com, but `` still does
      my @cmd = format_exec_args $str;
      if( @cmd == 3 ) {		# sh -c
	substr $cmd[2], 0, 0, '"';
	$cmd[2] .= '"';
      }
      $shell_output = `@cmd`;
    }
    $? == 0 or
      warn "shell command `$str' returned `$?' at `$mkfile_line'\n";
  } else {
#
# We used to use Perl's backquotes operators but these seem to have trouble,
# especially when doing parallel builds.  The backquote operator doesn't seem
# to capture all of the output.	 Every once in a while (sometimes more often,
# depending on system load and whether it's a parallel build) the backquote
# operator returns without giving any output, even though the shell command
# is actually executed; evidently it's finishing before it's captured all
# the output.  So we try a different approach here.
# This is about the third different technique that I've tried, and this one
# (finally) seems to work.  I'm still not 100% clear on why some of the
# other ones didn't.
#
    pipe my $pin, my $pout or die "can't make pipe--$!\n";
    my $proc_handle = new Mpp::Event::Process sub { # Wait for process to finish.
      #
      # This is the child process.  Redirect our standard output to the pipe.
      #
      close $pin;		# Don't read from the handle any more.
      close STDOUT;
      open STDOUT,'>&', $pout or die "can't redirect stdout--$!\n";
      exec format_exec_args $str;
      die "exec $str failed--$!\n";
    }, ERROR => sub {
      warn "shell command `$str' returned `$_[0]' at `$mkfile_line'\n";
    };

    close $pout;		# In parent, get rid of the output handle.
    my $n_errors_remaining = 3;
    for (;;) {
      my $n_chars = sysread $pin, my( $blk ), 8192; # Try to read.
      unless( defined $n_chars ) { # An error on the read?
	--$n_errors_remaining > 0 and next; # Probably "Interrupted system call".
	die "read error--$!\n";
      }
      last if $n_chars == 0;	# No characters read--other process closed pipe.
      $shell_output .= $blk;
    }
    wait_for $proc_handle; 	# Should not really be necessary.
    close $pin;
  }
  $shell_output =~ s/\r?\n/ /g	# Get rid of newlines.
    unless $Mpp::Makefile::s_define;
  $shell_output =~ s/\s+$//s;	# Strip out trailing whitespace.
  $shell_output;
}

sub f_sort {
#
# Sort is documented to remove duplicates as well as to sort the string.
#
  my $last = '';
  join ' ', map { $last eq $_ ? () : ($last = $_) }
    sort split ' ', &arg;
}

sub f_stem {
  unless( defined $rule ) {
    warn "\$(stem) or \$* used outside of rule at `$_[2]'\n";
    return '';
  }
  defined $rule->{PATTERN_STEM} and
    return $rule->{PATTERN_STEM};

  f_basename &f_target;		# If there's no stem, just strip off the
				# target's suffix.  This is what GNU make
				# does.
}

sub f_strip {
  join ' ', split ' ', &arg;
}

sub f_subst {
  my( $from, $to, $text ) = args $_[0], $_[1], $_[2], 3, 3, 1;
  $from = quotemeta($from);
  join ' ', map { s/$from/$to/g; $_ } split ' ', $text;
}

sub f_suffix {
  join ' ', map { m@(\.[^\./]*)$@ ? $1 : () } split ' ', &arg;
}

#
# Mark targets as temporary:
#
sub f_temporary {
  my $text = &arg;
  undef file_info( unquote(), $_[1]{CWD} )->{xTEMP}
    for split_on_whitespace $text;
  $text;			# Just return our argument.
}


sub f_wildcard {
  my $cwd = $rule ? $rule->build_cwd : $_[1]{CWD};
				# Get the default directory.

  join ' ', map zglob($_, $cwd), split ' ', &arg;
}

sub f_wordlist {
  my ($startidx, $endidx, $text) = args $_[0], $_[1], $_[2], 3, 2;
  if( defined $text ) {
    my @wordlist = split ' ', $text;
    $_ < 0 and $_ += @wordlist + 1 for $startidx, $endidx;

    # These are defined behaviors in GNU make, so we generate no warnings:
    return '' if $startidx > $endidx;
    $endidx = @wordlist if $endidx > @wordlist;

    join ' ', @wordlist[$startidx-1 .. $endidx-1];
  } else {			# 2nd arg is the text
    join ' ', (split ' ', $endidx)[map { $_ > 0 ? $_ - 1 : $_ } split ' ', $startidx];
  }
}
*f_word = \&f_wordlist;		# It's a special case of the index-list form.

sub f_words {
  # Must map split result, or implicit assignment to @_ takes place
  scalar map undef, split ' ', &arg;
}

###############################################################################
#
# Define special automatic variables:
#
sub f_target {
  unless( defined $rule ) {
    warn "\$(output), \$(target) or \$\@ used outside of rule at `$_[2]'\n";
    return '';
  }
  my $arg = defined $_[0] ? &arg : 0;
  relative_filename $rule->{EXPLICIT_TARGETS}[$arg ? ($arg > 0 ? $arg - 1 : $arg) : 0],
    $rule->build_cwd;
}
*f_output = \&f_target;

sub f_targets {
  unless( defined $rule ) {
    warn "\$(outputs) or \$(targets) used outside of rule at `$_[2]'\n";
    return '';
  }
  my $arg = defined $_[0] ? &arg : 0;
  join ' ', relative_filenames
    $arg ?
      [@{$rule->{EXPLICIT_TARGETS}}[map { $_ > 0 ? $_ - 1 : $_ } split ' ', $arg]] :
      $rule->{EXPLICIT_TARGETS};
}
*f_outputs = *f_targets;

sub f_dependency {
  unless( defined $rule ) {
    warn "\$(dependency) or \$(input) or \$< used outside of rule at `$_[2]'\n";
    return '';
  }
  my $arg = defined $_[0] ? &arg : 0;
  my $finfo = $rule->{EXPLICIT_DEPENDENCIES}[$arg ? ($arg > 0 ? $arg - 1 : $arg) : 0];
  $finfo or return '';		# No dependencies.

  relative_filename $finfo, $rule->build_cwd;
}
*f_input = *f_dependency;

sub f_dependencies {
  unless( defined $rule ) {
    warn "\$(dependencies) or \$(inputs) or \$^ used outside of rule at `$_[2]'\n";
    return '';
  }
  my $arg = defined $_[0] ? &arg : 0;
  join ' ', relative_filenames
    $arg ?
      [@{$rule->{EXPLICIT_DEPENDENCIES}}[map { $_ > 0 ? $_ - 1 : $_ } split ' ', $arg]] :
      $rule->{EXPLICIT_DEPENDENCIES};
}
*f_inputs = *f_dependencies;

#
# Return the list of inputs that have changed.  Note that this function
# should only be called in the action of a rule, which means that we're
# only called from find_all_targets_dependencies.
#
sub f_changed_inputs {
  unless( defined $rule && defined $rule->{EXPLICIT_TARGETS} ) {
    warn "\$(changed_dependencies) or \$(changed_inputs) or \$? used outside of rule at `$_[2]'\n";
    return '';
  }
  my @changed_dependencies =
    $rule->build_check_method->changed_dependencies
      ($rule->{EXPLICIT_TARGETS}[0],
       $rule->signature_method,
       $rule->build_cwd,
       @{$rule->{EXPLICIT_DEPENDENCIES}});

  # Somehow we can't pass this to sort directly
  my @filenames = relative_filenames @changed_dependencies;
  join ' ', sort @filenames;
}
*f_changed_dependencies = \&f_changed_inputs;

sub f_sorted_dependencies {
  unless( defined $rule ) {
    warn "\$(sorted_dependencies) or \$(sorted_inputs) or \$+ used outside of rule at `$_[2]'\n";
    return '';
  }
  Mpp::Subs::f_sort join ' ', relative_filenames $rule->{EXPLICIT_DEPENDENCIES};
}
*f_sorted_inputs = *f_sorted_dependencies;

#
# Foreach is a little bit tricky, since we have to support the new
# $(foreach) automatic variable, but also the old GNU make function
# foreach.  We can tell the difference pretty easily by whether we have
# any arguments.
#
sub f_foreach {
  my( undef, $mkfile, $mkfile_line ) = @_; # Name the arguments.
  unless( $_[0] ) {		# No argument?
    defined $rule && defined $rule->{FOREACH} or
      die "\$(foreach) used outside of rule, or in a rule that has no :foreach clause at `$_[2]'\n";
    return relative_filename $rule->{FOREACH}, $rule->build_cwd;
  }

#
# At this point we know we're trying to expand the old GNU make foreach
# function.  The syntax is $(foreach VAR,LIST,TEXT), where TEXT is
# expanded once with VAR set to each value in LIST.  When we get here,
# because of some special code in expand_text, VAR,LIST,TEXT has not yet
# been expanded.
#
  my( $var, $list, $text ) = args $_[0], undef, $_[2], 3, 3, 1;
				# Get the arguments.
  $var = ref $_[0] ? $mkfile->expand_text( $var, $mkfile_line ) : $var;
  my $ret_str = '';
  my $sep = '';
  $Mpp::Makefile::private ?
    (local $Mpp::Makefile::private->{PRIVATE_VARS}{$var}) :
    (local $Mpp::Makefile::private);
  local $Mpp::Makefile::private->{VAR_REEXPAND}{$var} = 0 if $Mpp::Makefile::private->{VAR_REEXPAND};
				# We're going to expand ourselves.  No need to
				# override this if there are no values,
				# leading to a false lookup anyway.
  for( split ' ', ref $_[0] ? $mkfile->expand_text( $list, $mkfile_line ) : $list ) { # Expand text
    $Mpp::Makefile::private->{PRIVATE_VARS}{$var} = $_;
				# Make it a private variable so that it
				# overrides even any other variable.
				# The local makes it so it goes away at the
				# end of the loop.
    $ret_str .= $sep . (ref $_[0] ? $mkfile->expand_text( $text, $mkfile_line ) : $text);
    $sep = ' ';			# Next time add a space
  }

  $ret_str;
}

sub f_warning {
  warn &arg." at `$_[2]'\n";	# Print the text.
  '';
}

sub f_xargs {
  my( $command, $list, $postfix, $max_length ) = args $_[0], $_[1], $_[2], 3, 2;
  $postfix = '' unless defined $postfix;
  $max_length ||= 1000;
  $max_length -= length $postfix;

  my( $piece, @pieces ) = $command;
  for my $elt ( split ' ', $list ) {
    if( length( $piece ) + length( $elt ) < $max_length ) {
      $piece .= " $elt";
    } else {
      push @pieces, "$piece $postfix";
      $piece = $command;
      redo;
    }
  }
  push @pieces, "$piece $postfix"
    if $piece ne $command;
  join "\n", @pieces;
}

#
# Internal function for builtin rule on Windows.  This is a hack to make a
# phony target xyz that depends on xyz.exe.  set_rule marks xyz as a phony
# target *after* it has associated a rule with the target, because it
# specifically rejects builtin rules for phony targets (to prevent disasters).
#
*f__exe_phony_ = sub {
  my $cwd = $rule->build_cwd;
  my $phony = substr relative_filename( $rule->{FOREACH}, $cwd ), 0, -4; # strip .exe
  file_info( $phony, $cwd )->{_IS_EXE_PHONY_} = 1;
  $phony;
} if Mpp::is_windows;

#
# $(MAKE) needs to expand to the name of the program we use to replace a
# recursive make invocation.  We pretend it's a function with no arguments.
#
sub f_MAKE {
  require Mpp::Recursive;
  goto &f_MAKE;			# Redefined.
}
*f_MAKE_COMMAND = \&f_MAKE;

###############################################################################
#
# Makefile statements.	These are all called with the following arguments:
# a) The whole line of text (with the statement word removed).
# b) The makefile this is associated with.
# c) A printable string describing which line of the makefile the statement
#    was on.
#

#
# Define a build cache for this makefile.
#
sub s_build_cache {#_
  my ($fname, $mkfile, $mkfile_line) = @_;
  my $var = delete $_[3]{global} ? \$Mpp::BuildCache::global : \$mkfile->{BUILD_CACHE};

  $fname = $mkfile->expand_text( $fname, $mkfile_line )
    if $mkfile;
  $fname =~ s/^\s+//;
  $fname =~ s/\s+$//; # Strip whitespace.

  if ($fname eq 'none') { # Turn off build cache?
    undef $$var;
  } else {
    $fname = absolute_filename file_info $fname, $mkfile->{CWD}
      if $mkfile;		# Make sure we work even if cwd is wrong.

    require Mpp::BuildCache;	# Load the build cache mechanism.
    warn "$mkfile_line: Setting another build cache.\n"
      if $$var;
    $$var = new Mpp::BuildCache( $fname );
  }
}

#
# Build_check statement.
#
sub s_build_check {#_
  my( $name, $mkfile, $mkfile_line ) = @_;
  my $global = delete $_[3]{global};
  my $var = $global ? \$Mpp::BuildCheck::default : \$mkfile->{DEFAULT_BUILD_CHECK_METHOD};

  $name = $mkfile->expand_text( $name, $mkfile_line )
    if $mkfile;
  $name =~ s/^\s*(\w+)\s*$/$1/ or
    die "$mkfile_line: invalid build_check statement\n";
  if( $name ne 'default' ) {
    $$var = eval "use Mpp::BuildCheck::$name; \$Mpp::BuildCheck::${name}::$name" ||
      eval "use BuildCheck::$name; warn qq!$mkfile_line: name BuildCheck::$name is deprecated, rename to Mpp::BuildCheck::$name\n!; \$BuildCheck::${name}::$name"
      or die "$mkfile_line: invalid build_check method $name\n";
  } elsif( $global ) {		# Return to the default method?
    $$var = $Mpp::BuildCheck::exact_match::exact_match;
  } else {
    undef $$var;
  }
}

#
# Handle the no_implicit_load statement.  This statement marks some
# directories not to be loaded by the implicit load mechanism, in case
# there are makefiles there that you really don't want to load.
#
sub s_no_implicit_load {
  my ($text_line, $mkfile, $mkfile_line) = @_; # Name the arguments.

  $text_line = $mkfile->expand_text($text_line, $mkfile_line);
  my $cwd = $rule ? $rule->build_cwd : $mkfile->{CWD};
				# Get the default directory.

  local $Mpp::implicitly_load_makefiles; # Temporarily turn off makefile
				# loading for the expansion of this wildcard.

  my @dirs = map zglob_fileinfo($_, $cwd),
    split ' ', $mkfile->expand_text($text_line, $mkfile_line);
				# Get a list of things matching the wildcard.
  foreach my $dir (@dirs) {
    undef $dir->{xNO_IMPLICIT_LOAD} if is_or_will_be_dir $dir;
				# Tag them so they don't load later.
  }
}

#
# Include statement:
#
our( $defer_include, @defer_include ); # gmake cludge
sub s_include {#__
  my( undef, $mkfile, $mkfile_line, $keyword ) = @_;
				# Name the arguments.
  if( $defer_include ) {
    push @defer_include, $keyword->{ignore} ? \&s__include : \&s_include, @_[0..2];
    return;
  }

  for my $file ( split ' ', $mkfile->expand_text( $_[0], $mkfile_line )) { # Get a list of files.
    my $finfo = f_find_first_upwards $Mpp::Makefile::c_preprocess ? $file : "$file.makepp $file",
      $mkfile, $mkfile_line, 1;	# Search for special makepp versions of files as well.
    if( $Mpp::Makefile::c_preprocess ) {
      eval { $mkfile->read_makefile($finfo) };
      die $@ if
	$@ and $keyword->{ignore} ? !/^can't read makefile/ : 1;
    } else {
      $finfo and
	wait_for prebuild( $finfo, $mkfile, $mkfile_line ) and
				# Build it if necessary, or link it from a repository.
	die "can't build " . absolute_filename( $finfo ) . ", needed at $mkfile_line\n";
				# Quit if the build failed.
#
# If it wasn't found anywhere in the directory tree, search the standard
# include files supplied with makepp.  We don't try to build these files or
# link them from a repository.
#
      unless( $finfo ) { # Not found anywhere in directory tree?
	foreach (@{$mkfile->{INCLUDE_PATH}}) {
	  $finfo = file_info($file, $_); # See if it's here.
	  last if file_exists $finfo;
	}
	unless( file_exists $finfo ) {
	  next if $keyword->{ignore};
	  die "makepp: can't find include file `$file'\n";
	}
      }

      Mpp::log LOAD_INCL => $finfo, $mkfile_line
	if $Mpp::log_level;
      $mkfile->read_makefile($finfo); # Read the file.
    }
  }
}

#
# This subroutine does exactly the same thing as include, except that it
# doesn't die with an error message if the file doesn't exist.
#
sub s__include {#_
  s_include @_[0..2], {ignore => 1};#__
}

#
# Load one or several makefiles.
#
sub s_load_makefile {#_
  my ($text_line, $mkfile, $mkfile_line) = @_; # Name the arguments.

  my @words = split_on_whitespace $mkfile->expand_text($text_line, $mkfile_line);

  $mkfile->cleanup_vars;
  my %command_line_vars = %{$mkfile->{COMMAND_LINE_VARS}};
				# Extra command line variables.	 Start out
				# with a copy of the current command line
				# variables.
  my @include_path = @{$mkfile->{INCLUDE_PATH}};
				# Make a copy of the include path (so we can
				# modify it with -I).
#
# First pull out the variable assignments.
#
  my @makefiles;
  while (defined($_ = shift @words)) { # Any words left?
    if (/^(\w+)=(.*)/) {	# Found a variable?
      $command_line_vars{$1} = unquote($2);
    }
    elsif (/^-I(\S*)/) {	# Specification of the include path?
      unshift @include_path, ($1 || shift @words);
				# Grab the next word if it wasn't specified in
				# the same word.
    }
    else {			# Unrecognized.	 Must be name of a makefile.
      push @makefiles, $_;
    }
  }

  my $set_do_build = $Mpp::File::root->{DONT_BUILD} &&
    $Mpp::File::root->{DONT_BUILD} == 2 && # Was set implicitly through root makefile.
    !Mpp::File::dont_build( $mkfile->{CWD} );
				# Our dir is to be built, so propagate that to
				# loaded makefiles' dirs.
#
# Now process the makefiles:
#
  foreach (@makefiles) {
    s/^-F//;			# Support the archaic syntax that put -F
				# before the filename.
    my $mfile = file_info $_, $mkfile->{CWD};
				# Get info on the file.
    my $mdir = $mfile;		# Assume it is actually a directory.
    is_or_will_be_dir $mfile or $mdir = $mfile->{'..'};
				# Default directory is the directory the
				# makefile is in.
    if( $set_do_build && Mpp::File::dont_build( $mdir ) && $mdir->{DONT_BUILD} == 2 ) {
				# Inherited from '/'.
      my @descend = $mdir;
      while( @descend ) {
	my $finfo = shift @descend;
	next unless $finfo->{DONT_BUILD} && $finfo->{DONT_BUILD} == 2;
				# Not yet propagated from '/' or manually set?
	undef $finfo->{DONT_BUILD};
	push @descend, values %{$finfo->{DIRCONTENTS}} if $finfo->{DIRCONTENTS};
      }
    }
    Mpp::Makefile::load( $mfile, $mdir, \%command_line_vars, '', \@include_path,
		    $mkfile->{ENVIRONMENT} ); # Load the makefile.
  }
}

#
# This function allows the user to do something in the makefile like:
# makeperl {
#   ... perl code
# }
#
sub s_makeperl { s_perl( @_[0..2], {make => 1} ) }

#
# This function allows the user to do something in the makefile like:
# makesub subname {
#   ... perl code
# }
#
sub s_makesub { s_sub( @_[0..2], {make => 1} ) }

#
# Begin a whole block of perl { } code.
#
sub s_perl {#__
  my ($perl_code, $mkfile, $mkfile_line, $keyword) = @_;
				# Name the arguments.
  $perl_code = Mpp::Makefile::read_block( $keyword->{make} ? 'makeperl' : 'perl', $perl_code );
  $perl_code = $mkfile->expand_text($perl_code, $mkfile_line) if $keyword->{make};
  $mkfile->cd;			# Make sure we're in the correct directory
				# because some Perl code will expect this.
  eval_or_die $perl_code, $mkfile, $mkfile_line;
}


#
# Begin a whole block of Perl code.
#
sub s_perl_begin {#_
  my ($perl_code, $mkfile, $mkfile_line) = @_;
				# Name the arguments.
  warn "$mkfile_line: trailing cruft after statement: `$perl_code'\n"
    if $perl_code;
  $perl_code = Mpp::Makefile::read_block( perl_begin => $perl_code, qr/perl[-_]end/ );
  $mkfile->cd;			# Make sure we're in the correct directory
				# because some Perl code will expect this.
  eval_or_die $perl_code, $mkfile, $mkfile_line;
}

#
# Build targets immediately.
# Useful when the list of targets depends on files that might be generated.
#
sub s_prebuild {#__
  my ($text_line, $mkfile, $mkfile_line) = @_;
  my (@words) = split_on_whitespace $mkfile->expand_text($text_line, $mkfile_line);

  &Mpp::maybe_stop;
  for my $target (@words) {
    my $finfo = file_info $target, $mkfile->{CWD};
    # TBD: If prebuild returns undef, then that could mean that the file
    # didn't need to be built, but it could also means that there was a
    # dependency loop. We ought to generate an error in the latter case.
    wait_for prebuild( $finfo, $mkfile, $mkfile_line ) and
      die "failed to prebuild $target\n";
  }
}
*s_make = \&s_prebuild;
sub prebuild {
  my ($finfo, $mkfile, $mkfile_line ) = @_;
  Mpp::log PREBUILD => $finfo, $mkfile_line
    if $Mpp::log_level;
  if( my $myrule = Mpp::File::get_rule $finfo ) {
    # If the file to be built is governed by the present Makefile, then
    # just initialize the Mpp::Makefile and build it based on what we know so far,
    # because then the file will *always* be built with the same limited
    # knowledge (unless there are multiple rules for it, in which case a
    # warning will be issued anyway). On the other hand, if the file is
    # governed by another Makefile that isn't fully loaded yet, then issue
    # a warning, because then you could get weird dependencies on the order in
    # which Makefiles were loaded. Note that this warning isn't guaranteed to
    # show up when it's called for, because targets that are built via direct
    # calls to Mpp::build() don't undergo this check.
    warn 'Attempting to build ' . &absolute_filename . " before its makefile is completely loaded\n"
      unless ref( $myrule ) eq 'Mpp::DefaultRule' ||
	exists $finfo->{BUILD_HANDLE} ||
	$myrule->makefile == $mkfile ||
	exists $myrule->makefile->{xINITIALIZED};
  }
  Mpp::build($finfo);
}

#
# Register an autoload.
# Usage from the makefile:
#    autoload filename ...
#
sub s_autoload {#__
  my ($text_line, $mkfile, $mkfile_line) = @_; # Name the arguments.

  ++$Mpp::File::n_last_chance_rules;
  my (@fields) = split_on_whitespace $mkfile->expand_text($text_line, $mkfile_line);
  push @{$mkfile->{AUTOLOAD} ||= []}, @fields;
}

#
# Register an action scanner.
# Usage from the makefile:
#    register_scanner command_word scanner_subroutine_name
#
#
sub s_register_scanner {#_
  my( undef, $mkfile, $mkfile_line ) = @_; # Name the arguments.
  warn "$mkfile_line: register-scanner deprecated, please use register-parser at `$_[2]'\n";

  my( @fields ) = split_on_whitespace $mkfile->expand_text( $_[0], $mkfile_line );
				# Get the words.
  @fields == 2 or die "$mkfile_line: register_scanner needs 2 arguments\n";
  my $command_word = unquote $fields[0]; # Remove quotes, etc.
  $fields[1] =~ tr/-/_/;
  my $scanner_sub = $fields[1] =~ /^(?:scanner_)?none$/ ?
    undef : (*{"$mkfile->{PACKAGE}::$fields[1]"}{CODE} || *{"$mkfile->{PACKAGE}::scanner_$fields[1]"}{CODE});
				# Get a reference to the subroutine.
  $mkfile->register_parser($command_word, $scanner_sub);
}

#
# Register a command parser. Usage from the makefile:
#    register_command_parser command_word command_parser_class_name
#
#
sub s_register_parser {#_
  my( undef, $mkfile, $mkfile_line ) = @_; # Name the arguments.

  my( @fields ) = unquote_split_on_whitespace $mkfile->expand_text( $_[0], $mkfile_line );
				# Get the words.
  @fields == 2 or die "$mkfile_line: register_command_parser needs 2 arguments at `$_[2]'\n";
  $fields[1] =~ tr/-/_/;
  $fields[1] =
    *{"$mkfile->{PACKAGE}::p_$fields[1]"}{CODE} ||
    *{"$fields[1]::factory"}{CODE} ||
    *{"Mpp::CommandParser::$fields[1]::factory"}{CODE} ||
    *{"$fields[1]::factory"}{CODE} ||
    die "$mkfile_line: invalid command parser $fields[1]\n";
  $mkfile->register_parser( @fields );
}
*s_register_command_parser = \&s_register_parser;

#
# Register an input filename suffix for a particular command.
# Usage from the makefile:
#    register_input_suffix command_word suffix ...
#
sub s_register_input_suffix {
  my ($text_line, $mkfile, $mkfile_line) = @_; # Name the arguments.

  my( $command_word, @fields ) = # Get the words.
    unquote_split_on_whitespace($mkfile->expand_text($text_line, $mkfile_line));

  no strict 'refs';
  my $hashref = \%{$mkfile->{PACKAGE} . '::input_suffix_hash'};
  push @{$hashref->{$command_word} ||= []}, @fields;
}

#
# Load from repositories:
#
sub s_repository {#__
  require Mpp::Repository;
  goto &s_repository;		# Redefined.
}
sub s_vpath {#__
  require Mpp::Repository;
  goto &s_vpath;		# Redefined.
}

#
# Add runtime dependencies for an executable.
#
sub s_runtime {#__
  my ($text, $mkfile, $mkfile_line) = @_; # Name the arguments.

  (my $comma = index_ignoring_quotes $text, ',') >= 0 or # Find the command
    die "$mkfile_line: runtime EXE,LIST called with only one argument\n";
  my $exelist = $mkfile->expand_text(substr($text, 0, $comma), $mkfile_line);
  substr $text, 0, $comma+1, ''; # Get rid of the variable name.
  my @deps = map file_info($_, $mkfile->{CWD}), split_on_whitespace $mkfile->expand_text($text, $mkfile_line);
  for my $exe ( map file_info($_, $mkfile->{CWD}), split_on_whitespace $exelist) {
    for my $dep (@deps) {
      $exe->{RUNTIME_DEPS}{$dep} = $dep;
    }
  }
}

#
# Set the default signature method for all rules in this makefile or globally:
#
sub s_signature {#__
  my( $name, $mkfile, $mkfile_line ) = @_;
  my $global = delete $_[3]{global};
  my $override = delete $_[3]{override};
  my $var = $global ? \$Mpp::Signature::default : \$mkfile->{DEFAULT_SIGNATURE_METHOD};
  my $name_var = $global ? \$Mpp::Signature::default_name : \$mkfile->{DEFAULT_SIG_METHOD_NAME};
  my $override_var = $global ? \$Mpp::Signature::override : \$mkfile->{DEFAULT_SIG_OVERRIDE};
  $name = $mkfile->expand_text( $name, $mkfile_line )
    if $mkfile;
  $name =~ s/^\s*(.*?)\s*$/$1/;
  if( $name ne 'default' ) {
    $$var = Mpp::Signature::get( $name, $mkfile_line );
    if( defined $$var ) {
      $$name_var = $name;
      $$override_var = $override;
    } else {
#
# The signature methods and build check methods used to be the same thing,
# so for backward compatibility, see if this is actually a build check
# method.
#
      $var = eval "use Mpp::BuildCheck::$name; \$Mpp::BuildCheck::${name}::$name" ||
	eval "use BuildCheck::$name; warn qq!$mkfile_line: name BuildCheck::$name is deprecated, rename to Mpp::BuildCheck::$name\n!; \$BuildCheck::${name}::$name";
      if( defined $var ) {
	warn "$mkfile_line: requesting build check method $name via signature is deprecated.\n";
	if( $global ) {
	  $Mpp::BuildCheck::default = $var;
	} else {
	  $mkfile->{DEFAULT_BUILD_CHECK_METHOD} = $var;
	}
      } else {
	die "$mkfile_line: invalid signature method $name\n";
      }
    }
  } else {		# Return to the default method?
    undef $$name_var;
    undef $$var;
    $$override_var = $override;
  }
}

#
# This function allows the user to do something in the makefile like:
# sub subname {
#   ... perl code
# }
#
sub s_sub {#__
  my ($subr_text, $mkfile, $mkfile_line, $keyword) = @_; # Name the arguments.
  $subr_text = Mpp::Makefile::read_block( $keyword->{make} ? 'makesub' : 'sub', $subr_text );
  $subr_text = $mkfile->expand_text($subr_text, $mkfile_line) if defined $keyword->{make};
  eval_or_die "sub $subr_text", $mkfile, $mkfile_line;
}

#
# Don't export a variable to child processes.
#
sub s_unexport {#__
  my ($text_line, $mkfile, $mkfile_line) = @_; # Name the arguments.
  delete @{$mkfile->{EXPORTS}}{split ' ', $mkfile->expand_text($text_line, $mkfile_line)}
    if $mkfile->{EXPORTS};	# Look at each variable listed.
}


#
# Execute an external Perl script within the running interpreter.
#
sub run(@) {
  local( $0, @ARGV ) = @_;		# Name the arguments.
  $0 = f_find_program $0,
    $rule ? $rule->{MAKEFILE} : $makefile,
    $rule ? $rule->{RULE_SOURCE} : $makefile_line
    unless -f $0;		# not relative or absolute
  local $SIG{__WARN__} = local $SIG{__DIE__} = 'DEFAULT';
  die $@ || "$0 failed--$!\n"
    if !defined do $0 and $@ || $!;
}

###############################################################################
#
# Default values of various variables.	These are implemented as functions
# with no arguments so that:
# a) They are visible to all makefiles, yet are easily overridden.
#    (If we just put them in makepp_builtin_rules.mk, then they are not
#    visible in the makefile except in rules, because makepp_builtin_rules.mk
#    is loaded after the makefile.  That's where they were for a while but
#    that was discovered not to work well.)
# b) The $(origin ) function can work with them.
#
sub f_AR()	{ 'ar' }
sub f_ARFLAGS()	{ 'rv' }
sub f_AS()	{ 'as' }
my $CC;
sub f_CC	{ $CC ||= f_find_program 'gcc egcc pgcc c89 cc' . (Mpp::is_windows?' cl bcc32':''), $_[1], $_[2] }
sub f_CFLAGS	{ f_if \('$(filter %gcc, $(CC)), -g -Wall, ' . (Mpp::is_windows?' $(if $(filter %cl %cl.exe %bcc32 %bcc32.exe, $(CC)), , -g)':'-g')), $_[1], $_[2] }
sub f_CURDIR	{ absolute_filename $_[1]{CWD} }
my $CXX;
sub f_CXX	{ $CXX ||= f_find_program 'g++ c++ pg++ cxx ' . (Mpp::is_windows?'cl bcc32':'CC aCC'), $_[1], $_[2] }
sub f_CXXFLAGS	{ f_if \('$(filter %g++ %c++, $(CXX)), -g -Wall, ' . (Mpp::is_windows?'$(if $(filter %cl %cl.exe %bcc32 %bcc32.exe, $(CXX)), , -g)':'-g')), $_[1], $_[2] }
my $F77;
sub f_F77	{ $F77 ||= f_find_program 'f77 g77 fort77', $_[1], $_[2] }
sub f_FC	{ $_[1]->expand_variable('F77', $_[2]) }
my $LEX;
sub f_LEX	{ $LEX ||= f_find_program 'lex flex', $_[1], $_[2] }
sub f_LIBTOOL()	{ 'libtool' }
sub f_LD()	{ 'ld' }
sub f_MAKEINFO() { 'makeinfo' }
*f_PWD = \&f_CURDIR;
# Can't use &rm -f, because it might get used in a complex Shell construct.
sub f_RM()	{ 'rm -f' }
my $YACC;
sub f_YACC	{ $YACC ||= f_if \'$(filter bison, $(find_program yacc bison)), bison -y, yacc', $_[1], $_[2] }

sub f_ROOT	{ $_[1]{CWD}{ROOT} ? relative_filename( $_[1]{CWD}{ROOT}, $_[1]{CWD} ) : '' }

# Don't use Exporter so we don't have to keep a huge list.
sub import() {
  my $package = caller;
  no warnings 'redefine';	# In case we are reimporting this
  for( keys %Mpp::Subs:: ) {
    $_[1] ? /^(?:$_[1])/ : /^[fps]_/ or # functions, parsers and statements only
      /^args?$/ or
      /^run/ or
      /^scanner_/ or
      next;
    my $coderef = *{"Mpp::Subs::$_"}{CODE};
    *{$package . "::$_"} = $coderef if $coderef;
  }
}

1;
