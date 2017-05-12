#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::IgnoreChecker;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::IgnoreChecker - Ask it if a file should be ignored.

=head1 SYNOPSIS

  my $ignorer = VCS::LibCVS::IgnoreChecker->new($repository);
  if ( $ignorer->ignore_check("dir1/file1") ) {

=head1 DESCRIPTION

CVS has an involved way of deciding which files should be ignored, and which
shouldn't.  Create an IgnoreChecker, and ask it if a file should be ignored.

The CVSROOT directory in the repository contains some information about what to
ignore, so you'll need a Repository to create an IgnoreChecker.

See the CVS info page for which files are ignored.

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/IgnoreChecker.pm,v 1.9 2005/10/10 12:52:11 dissent Exp $ ';

use constant DEFAULT_IGNORE_LIST =>
  ( 'RCS', 'SCCS', 'CVS', 'CVS.adm',
    'RCSLOG', 'cvslog.*',
    'tags', 'TAGS',
    '.make.state', '.nse_depinfo',
    '*~', '#*', '.#*', ',*', '_$*', '*$',
    '*.old', '*.bak', '*.BAK', '*.orig', '*.rej', '.del-*',
    '*.a', '*.olb', '*.o', '*.obj', '*.so', '*.exe',
    '*.Z', '*.elc', '*.ln',
    'core',
  );

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Repository}    VCS::LibCVS::Repository
# $self->{GlobalList}    @list ref of perl regexps.  Checked for all files

###############################################################################
# Class routines
###############################################################################

=head1 CLASS ROUTINES

=head2 B<new()>

$ignorer = VCS::LibCVS::IgnoreChecker->new($repository)

=over 4

=item return type: VCS::LibCVS::IgnoreChecker

=item argument 1 type: VCS::LibCVS::Repository

The repository from which to retrieve global information.

=back

Creates a new IgnoreChecker, for a specific repository.

=cut

sub new {
  my $class = shift;
  my $that = bless {}, $class;

  $that->{Repository} = shift;
  $that->{GlobalList} = [];

  # Build up the global ignore list

  # Start with the default ignore list
  $that->_append_patterns($that->{GlobalList}, DEFAULT_IGNORE_LIST);

  # Get CVSROOT/cvsignore from the repository
  # if it's not there, we catch the exception
  eval {
    my $r_ig = VCS::LibCVS::RepositoryFile->new($that->{Repository}, "CVSROOT/cvsignore");
    my $r_ig_file_rev = $r_ig->get_revision("HEAD");
    my $r_patterns = $r_ig_file_rev->get_contents()->as_string();
    $that->_append_patterns($that->{GlobalList}, split(/\s/,$r_patterns));
  };

  # Home directory
  $that->_append_patterns_file($that->{GlobalList}, "$ENV{HOME}/.cvsignore");

  # Environment
  if ($ENV{CVSIGNORE}) {
    $that->_append_patterns($that->{GlobalList}, split(/\s/,$ENV{CVSIGNORE}));
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<ignore_check()>

if ($ignorer->ignore_check("module/file1")) {

=over 4

=item return type: boolean scalar

Returns true if the file is ignored by CVS

=item argument 1 type: scalar string

Filename to check.  The filename must be qualified with its directory name so
that the .cvsignore in that directory may be checked.  The path may be relative
or absolute.

=back

Checks if the file should be ignored.  See CVS info page for how this is done.

=cut

sub ignore_check {
  my $self = shift;
  my $qual_filename = shift;

  # Look for a .cvsignore in the same directory as the file
  my ($dirname, $filename) = $qual_filename =~ /^(.*?)([^\/]*)$/;
  my $cvsignore_filename = $dirname . ".cvsignore";

  # Duplicate the GlobalList so that we can add the local things to it
  my $local_list = [ @{$self->{GlobalList}} ];
  $self->_append_patterns_file($local_list, $cvsignore_filename);

  foreach my $pat (@$local_list) {
    return 1 if $filename =~ /$pat/;
  }
}

###############################################################################
# Private routines
###############################################################################

# Append a list of patterns to the global list
sub _append_patterns {
  my $self = shift;
  my $list = shift;

  foreach my $next (@_) {
    if ($next eq "-I") {
      @$list = ();
    } else {
      push (@$list, _sh_pattern_2_perl_re($next));
    }
  }
}

# Append a list of patterns found in the named file, (if it exists) to the
# global list
sub _append_patterns_file {
  my $self = shift;
  my $list = shift;
  my $filename = shift;

  if (-f $filename) {
    open FDHOME, $filename;
    my @more_patterns = <FDHOME>;
    $self->_append_patterns($list, map { split(/\s/,$_) } @more_patterns);
  }
}

########################################
# Convert a CVS / sh(1) filematch pattern into a perl regexp
# Differences:
#   + sh(1) allows any character to be escaped.  In Perl, only alphas should
#     not be escaped.  Also true inside [..]
#   + sh(1) interprets a leading ! or ^ in a character class as negation
#     Perl only interprets for this ^

# Note also that CVS differs from sh(1) in that it doesn't require a leading
# . to be specified explicitly

# Perl and sh/CVS appear to use character classes ([:class:]) in the same way.

sub _sh_pattern_2_perl_re {
  my $sh_pattern = shift;
  my $perl_re = "^";

  # Traverse the sh pattern with regexp matches.  Find special characters
  # (*, ?, [) not escaped by a slash
  while ($sh_pattern) {
    $sh_pattern =~ /^(([^[*?\\]|\\.)*)([[*?\\])?(.*)/;
    my $non_special_bit = $1;
    my $optional_special = $3;
    $sh_pattern = $4;

    # Transform the non-special bit by changing escaping schemes
    $perl_re .= _sh_pattern_escapes_2_perl_re_escapes($non_special_bit);

    # Act on the special bit:
    next unless $optional_special;

    # matched a trailing \.  Ignore it like CVS.
    next if $optional_special eq "\\";

    # replace ? with .
    $perl_re .= "." if $optional_special eq "?";

    # replace * with .*
    $perl_re .= ".*" if $optional_special eq "*";

    # classes are a bit more work
    if ($optional_special eq "[") {
      # Grab the whole class, consists of:
      # Optional ^ or !; optional ]; non-] characters or [:class:]'es; final ]
      $sh_pattern =~ /^([\!\^]?\]?(\[:[^:]*:\]|[^]]*?)*)\](.*)/;
      my $class = $1;
      $sh_pattern = $3;

      # Replace leading ! with ^
      $class =~ s/^!/^/;

      # Remove escapes on alphas (count odd number of \)
      $class =~ s/((^|[^\\])(\\\\)*)\\([[:alpha:]])/$1$4/g;

      # Append to perl_re
      $perl_re .= "[$class]";
    }
  }
  $perl_re .= "\$";
  return $perl_re;
}

# Change the slash escape scheme being used

# Trailing slashes are ignored by CVS.  To copy this behaviour they are removed
# before quoting with quotemeta

sub _sh_pattern_escapes_2_perl_re_escapes {
  my $sh_pattern = shift;
  # Remove all backslashes that are escaping something
  $sh_pattern =~ s/\\(.)/$1/g;
  # Remove a trailing backslash
  $sh_pattern =~ s/\\$//;
  return quotemeta($sh_pattern);
}

=head1 SEE ALSO

  VCS::LibCVS

=cut

1;
