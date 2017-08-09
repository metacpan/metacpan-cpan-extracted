# $Id: Gcc.pm,v 1.41 2016/09/06 19:59:45 pfeiffer Exp $

=head1 NAME

Mpp::CommandParser::Gcc - makepp command parser for gcc or cc

=head1 DESCRIPTION

Parses a gcc compile command for implicit dependencies.

This class is readily subclassed for similar things, such as the
Embedded SQL preprocessor/compiler.

=cut

use strict;
package Mpp::CommandParser::Gcc;

use Mpp::CommandParser;
our @ISA = 'Mpp::CommandParser';

use Mpp::Text;
use Mpp::File;

*factory = \&Mpp::Subs::p_gcc_compilation;

sub new {
  my $self = &Mpp::CommandParser::new;
  require Mpp::Scanner::C;
  $self->{SCANNER} = new Mpp::Scanner::C($self->rule, $self->dir);
  $self;
}

sub new_no_gcc {
  my $self = &new;
  undef $self->{xNO_GCC};
  $self;
}

sub set_default_signature_method {
  my( $self, $leave_comments ) = @_;
  $self->rule->set_signature_class( $leave_comments ? 'md5' : 'C', 1 );
}

# The subclass can override these. Don't start doing any actual scanning here,
# because the signature method isn't necessarily set yet.
*parse_opt = $Mpp::Text::N[0]; # Ignore unknown option.
sub parse_arg {
  #my( undef, $arg, undef, $files ) = @_;

  push @{$_[3]}, $_[1]
    if is_cpp_source_name $_[1];
}


my( $no_link, $leave_comments, $nostdinc, $static );


my %opt =
  (c => \$no_link,
   E => \$no_link,
   S => \$no_link,
   C => \$leave_comments,
   nostdinc => \$nostdinc,
   static => \$static);

my %info_string = (user => 'INCLUDES',
		   sys => 'SYSTEM_INCLUDES',
		   lib => 'LIBS');
my @static_suffix_list = qw(.a);
my @suffix_list = qw(.la .so .sa .a .sl);
sub tags {
  my $scanner = $_[0]{SCANNER};
  $scanner->should_find( 'user' );
  $scanner->info_string( \%info_string );
  $scanner->add_include_suffix_list( lib => $_[1] == 1 ? \@static_suffix_list : \@suffix_list )
    if $_[1];
}
sub xparse_command {
  my( $self, $command, $setenv ) = @_;

  my $dir = $self->dir;
  my $scanner = $self->{SCANNER};
  my $conditional = $scanner->{CONDITIONAL};

  my @prefiles;
  my @files;
  my $idash; # saw -I-
  my @incdirs;
  my @idirafter;
  my $iprefix = '';
  my @libs;
  my @obj_files;
  my @cpp_opts;
  my $file_regexp = $self->input_filename_regexp($command->[0]);
  my $real_lib;

  $no_link = $leave_comments = $nostdinc = $static = 0;
  my( $cmd, @words ) = @$command;
  $cmd =~ s@.*/@@ || Mpp::is_windows > 1 && $cmd =~ s/.*\\//;
  my $icc = $cmd =~ /^ic[cl](?:\.exe)?$/;
  local $_;
  while( defined( $_ = shift @words )) {
    if( !s/^-// ) {
      if( /\.(?:[ls]?[oa]|s(?:l|o\.[\d.]+)|obj|dll)$/ ) { # object file?
	if( /[\*\?\[]/ ) {		# wildcard?
 # TBD: Why is this disabled?  Probably because zglob finds more than the Shell will.  Need chdir & glob.
 if(0) {
	  require Mpp::Glob;
	  push @obj_files,
	    Mpp::Glob::zglob($_, $self->dirinfo);
 }
	} else {
	  push @obj_files, $_;
	}
      } elsif($file_regexp && /$file_regexp/) {
        push @files, $_;
      } else {
	$self->parse_arg( $_, \@words, \@files );
      }
    } elsif( $opt{$_} ) {
      ${$opt{$_}} = 1;
    } elsif( s/^I// ) {
      $_ ||= shift @words;
      if( $_ eq '-' ) {
	$idash = 1;
	$scanner->add_include_dir( user => $_ )
	  for splice @incdirs;
      } else {
	push @incdirs, $_;
      }
    } elsif( s/^i(?:quot(e)|syste(m)|dirafte(r)|(nclude|macros)|prefi(x)|withprefix(before)?)// ) {
      my $val = $_ || shift @words; # yes, value can be glued :-{
      if( $1 || $2 ) {		# -iquote, -isystem
	$scanner->add_include_dir( $2 ? 'sys' : 'user', $val );
      } elsif( $3 ) { 		# -idirafter
	push @idirafter, $val;
      } elsif( $4 ) {		# -include or -imacros
	push @prefiles, $val;
      } elsif( $5 ) { 		# -iprefix
	$iprefix = $val;
      } elsif( $6 ) { 		# -iwithprefixbefore
	push @incdirs, $iprefix . $val;
      } else {			# -iwithprefix
	push @idirafter, $iprefix . $val;
      }
    } elsif( s/^L// ) {
      $scanner->add_include_dir( lib => $_ || shift @words );
    } elsif( s/^l// ) {
      $_ ||= shift @words;
      if( s/^:// ) {		# colon means actual lib name follows
	$real_lib = 1;
	push @libs, $_;
      } else {
	push @libs, "lib$_";
      }
    } elsif( s/^D// ) {
      $_ ||= shift @words;
      if( /^(\w+)=(.*)/ ) {
	$scanner->set_var( $1, $2 );
      } else {
	$scanner->set_var( $_, 1 );
      }
    } elsif( s/^U// ) {
      $scanner->set_var( $_ || shift @words, undef );
    } elsif( $icc && /^op(?:t-|enmp)/ ) {
    } elsif( s/^o// ) {
      $self->add_target( $_ || shift @words );
    } else {
      push @cpp_opts, "-$_" if $conditional;	# collect non parsed options for preprocessor
      $self->parse_opt( $_, \@words, \@files );
    }
  }

  $self->set_default_signature_method( $leave_comments );

  $scanner->add_include_dir( user => undef ) unless $idash;

  $self->tags( $no_link ? 0 : $static ? 1 : 2 );

  $scanner->add_include_dir( user => 'in CPATH' ) unless exists $self->{xNO_GCC};
  $scanner->add_include_dir( user => 'in :sys' );
  $scanner->add_include_dir( sys => $_ )
    for @incdirs;
  if( $nostdinc ) {
    $scanner->should_find( 'sys' );
  } else {
    require Mpp::Subs;
    $scanner->add_include_dir( sys => $_ )
      for @Mpp::Subs::system_include_dirs;
  }
  $scanner->add_include_dir( sys => absolute_filename file_info $_, $self->{RULE}{MAKEFILE}{CWD} )
    for @idirafter;
  my $context = $scanner->get_context if @files > 1;
  my $var;
  for( @files ) {
    my $file_end = case_sensitive_filenames ? lc substr $_, -4 : substr $_, -4;
    my $cplusplus = $file_end =~ /\.(?:c(?:c|xx|pp|\+\+)|C)$/;
    $scanner->reset( $context, $cplusplus ) if $context;
    unless( $var ) {
      $var = exists $self->{xNO_GCC} ?
	Mpp::is_windows && $cmd =~ /\bcl(?:.cl)?$/i && 'in ;INCLUDE' :
	$cplusplus ? 'in CPLUS_INCLUDE_PATH' : 'in C_INCLUDE_PATH';
      $scanner->add_include_dir( sys => $var, 1 ) if $var;
    }

    $self->xset_preproc_vars( $cmd, \@cpp_opts, $cplusplus ) if $conditional;
    # scan each file included on command line with  set of preproc. vars
    $scanner->scan_file( $self, c => $_ ) or return undef
      for @prefiles, $_;
  }

  unless( $no_link ) {
    $scanner->add_include_suffix( lib => '' )
      if $real_lib;
    $scanner->add_include_dir( lib => $_ )
      for @Mpp::Subs::system_lib_dirs;
    my $var = exists $self->{xNO_GCC} ?
      Mpp::is_windows && $cmd =~ /\bcl(?:.cl)?$/i && 'in ;LIB' :
      'in LIBRARY_PATH';
    $scanner->add_include_dir( lib => $var ) if $var;

    $self->add_simple_dependency( $_ )
      for @obj_files;
    return 1 unless @libs;
    my $tag = $scanner->get_tagname( 'lib' );
    $self->add_simple_dependency( $scanner->find( undef, 'lib', $_ ), $tag, undef, $_ )
      for @libs;
  }
  return 1;
}

sub _set_def {
  my ($self, $key, $value) = @_;
  $self->{SCANNER}->set_var( $key => $value )
    unless exists $self->{SCANNER}{VARS}{$key};
}
my %var_cache;
sub xset_preproc_vars {
  my( $self, $cmd, $opts, $cplusplus ) = @_;

  my $ran;
  unless( exists $self->{xNO_GCC} ) {
    #use preprocessor
    $cmd = Mpp::Text::join_with_protection $cmd,
      '-E', '-dM', '-x', $cplusplus ? 'c++' : 'c', '/dev/null',
      @$opts;
    if( $var_cache{$cmd} ) {
      my %copy = %{$var_cache{$cmd}};
      $self->{SCANNER}{VARS} = \%copy;
      return;
    }
#now call preprocessor to get rest of variables, but do not
#override variables which were already set up via -D and -U
    local $_;
    open my $cpp, '-|', $cmd or die;
    while( <$cpp> ) {
      next if(/^\#\s+\d/);	# gcc 3.4 reports an explicit line number
      # The second space is optional, because gcc doesn't always print it
      # for certain built-in macros such as __FILE__, and when that happens
      # the value is the empty string.
      if( /^\#define (\S+) ?(.*)/ ) {
	my ($name, $val)=($1, $2);
	_set_def $self, $name, $val;
      } else {
	chomp;
	warn "$cmd produced unparsable `$_'";
      }
    }
    $ran = close $cpp or
      warn "Preprocessor exited with status $? from opts: $cmd\n";
  }
  unless( $ran ) { # very basic setup any compiler/OS
    _set_def $self, __STDC__ => 1 unless grep { $_ eq '-traditional' } @$opts;
    _set_def $self, __GNUC__ => 1 unless exists $self->{xNO_GCC} || grep { $_ eq '-no-gcc' } @$opts;
    _set_def $self, __cplusplus => 1 if $cplusplus;
  }
  unless( exists $self->{xNO_GCC} ) {
    my %copy = %{$self->{SCANNER}{VARS}};
    $var_cache{$cmd} = \%copy;
  }
  return;
}
1;
