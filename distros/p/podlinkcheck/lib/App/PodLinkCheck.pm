# Copyright 2010, 2011, 2012, 2013, 2016, 2017 Kevin Ryde

# This file is part of PodLinkCheck.

# PodLinkCheck is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

package App::PodLinkCheck;
use 5.006;
use strict;
use warnings;
use Carp;
use File::Spec;
use Locale::TextDomain ('App-PodLinkCheck');

use vars '$VERSION';
$VERSION = 15;

# uncomment this to run the ### lines
# use Smart::Comments;

sub command_line {
  my ($self) = @_;
  ### command_line(): @ARGV
  ref $self or $self = $self->new;

  require Getopt::Long;
  Getopt::Long::Configure ('permute',  # options with args, callback '<>'
                           'no_ignore_case',
                           'bundling');
  Getopt::Long::GetOptions
      ('version'   => sub { $self->action_version },
       'help'      => sub { $self->action_help },
       'verbose:i' => \$self->{'verbose'},
       'V+'        => \$self->{'verbose'},
       'I=s'       => $self->{'extra_INC'}, # push onto arrayref
       '<>' => sub {
         my ($value) = @_;
         # stringize to avoid Getopt::Long object
         $self->check_tree ("$value");
       },
      );
  ### final ARGV: @ARGV
  $self->check_tree (@ARGV);
  return ($self->{'report_count'} ? 1 : 0);
}

sub action_version {
  my ($self) = @_;
  print __x("PodLinkCheck version {version}\n", version => $self->VERSION);
  if ($self->{'verbose'} >= 2) {
    require Pod::Simple;
    print __x("  Perl        version {version}\n", version => $]);
    print __x("  Pod::Simple version {version}\n", version => Pod::Simple->VERSION);
  }
  return 0;
}

sub action_help {
  my ($self) = @_;
  require FindBin;
  no warnings 'once';
  my $progname = $FindBin::Script;
  print __x("Usage: $progname [--options] file-or-dir...\n");
  print __x("  --help         print this message\n");
  print __x("  --version      print version number (and module versions if --verbose=2)\n");
  print __x("  --verbose      print diagnostic details\n");
  print __x("  --verbose=2    print even more diagnostics\n");
  return 0;
}


#------------------------------------------------------------------------------

sub new {
  my ($class, @options) = @_;
  return bless { verbose => 0,
                 cpan_methods => ['CPAN_SQLite','cpanminus','CPAN','CPANPLUS'],
                 extra_INC => [],
                 report_count => 0,
                 @options }, $class;
}

sub check_tree {
  my ($self, @files_or_directories) = @_;
  ### check_tree(): \@files_or_directories

  foreach my $filename (@files_or_directories) {
    if (-d $filename) {
      require File::Find::Iterator;
      my $finder = File::Find::Iterator->create (dir => [$filename],
                                                 order => \&_find_order,
                                                 filter => \&_is_perlfile);
      while ($filename = $finder->next) {
        print "$filename:\n";
        $self->check_file ($filename);
      }
    } else {
      print "$filename:\n";
      $self->check_file ($filename);
    }
  }

  #         ### recurse dir: $filename
  #         require File::Find;
  #         File::Find::find ({ wanted => sub {
  #                               #### file: $_
  #                               if (_is_perlfile()) {
  #                                 print "$_:\n";
  #                                 $self->check_file ($_);
  #                               }
  #                             },
  #                             follow_fast => 1,
  #                             preprocess => \&_find_sort,
  #                             no_chdir => 1,
  #                           },
  #                           $filename);
  #       } else {
  #         print "$filename:\n";
  #         $self->check_file ($filename);
  #       }
  #     }
}

# $_ is a filename.
# Return true if $_ looks like a Perl .pl .pm .pod filename.
# Any emacs .#foo.pm etc lockfile is excluded.
# (Emacs auto-saves and backups change the suffix so don't have
# to be excluded.)
#
sub _is_perlfile {
  ### _is_perlfile(): $_
  return (! -d
          && ! m{/\.#}   # not emacs lockfile
          && /\.p([lm]|od)$/);
}

use constant::defer _HAVE_SORT_KEY_NATURAL => sub {
  eval { require Sort::Key::Natural; 1 };
};

# _find_order($x,$y) compares filenames $x,$y
# Return spaceship style 1,false,-1 order.
# File::Find::Iterator 0.4 wants a reverse order since it pop()s off its
# pending filenames, hence the nasty hack to swap here.
#
# File::Find::Iterator also sorts with a mixture of current directory and
# subdirectory.  Not sure if the result is a strict pre-order traversal if
# some directory names have chars before or after "/".  Would like to ask it
# for pre-order.
#
sub _find_order {
  my ($x, $y) = @_;
  ($x,$y) = ($y,$x);
  return (_cmp_file_before_directory($x,$y)
          || do {
            if (_HAVE_SORT_KEY_NATURAL) {
              $x = Sort::Key::Natural::mkkey_natural($x);
              $y = Sort::Key::Natural::mkkey_natural($y);
            }
            lc($x) cmp lc($y)  || $x cmp $y
          });
}

# $x,$y are filenames.
# Return spaceship style <=> comparision 1,false,-1 which reckons
# file < directory.
sub _cmp_file_before_directory {
  my ($x, $y) = @_;
  # If $x or $y is a dangling symlink then -d is undef rather than '' false,
  # hence "||0" for the compare.
  return (-d $x || 0) <=> (-d $y || 0);
}

sub check_file {
  my ($self, $filename) = @_;
  require App::PodLinkCheck::ParseLinks;
  my $parser = App::PodLinkCheck::ParseLinks->new ($self);
  $parser->parse_from_file ($filename);

  my $own_sections = $parser->sections_hashref;
  ### $own_sections

  foreach my $link (@{$parser->links_arrayref}) {
    my ($type, $to, $section, $linenum, $column) = @$link;

    if ($self->{'verbose'}) {
      print "Link: $type ",(defined $to ? $to : '[undef]'),
        (defined $section ? " / $section" : ""), "\n";
    }

    if ($type eq 'man') {
      if (! $self->manpage_is_known($to)) {
        $self->report ($filename, $linenum, $column,
                       __x('no man page "{name}"', name => $to));
      }
      next;
    }

    if (! defined $to) {
      if (defined $section
          && ! $own_sections->{$section}) {
        if (my $approximations
            = _section_approximations($section,$own_sections)) {
          $self->report ($filename, $linenum, $column,
                         __x("no section \"{section}\"\n    perhaps it should be {approximations}",
                             section => $section,
                             approximations => $approximations));
        } else {
          $self->report ($filename, $linenum, $column,
                         __x('no section "{section}"',
                             section => $section));
        }
        if ($self->{'verbose'} >= 2) {
          print __("    available sections:\n");
          foreach my $section (sort keys %$own_sections) {
            print "    $section\n";
          }
        }
      }
      next;
    }

    my $podfile = ($self->module_to_podfile($to)
                   || $self->find_script($to));
    ### $podfile
    if (! defined $podfile) {
      if (my $method = $self->_module_known_cpan($to)) {
        if (defined $section && $section ne '') {
          $self->report ($filename, $linenum, $column,
                         __x('target "{name}" on cpan ({method}) but no local copy to check section "{section}"',
                             name => $to,
                             method => $method,
                             section => $section));
        }
        next;
      }
    }

    if (! defined $podfile
        && ! defined $section
        && $self->manpage_is_known($to)) {
      # perhaps a script or something we can't find the source but does
      # have a manpage -- take that as good enough
      next;
    }
    if (! defined $section
        && _is_one_word($to)
        && $own_sections->{$to}) {
      # one-word internal section
      if (defined $podfile) {
        # print "$filename:$linenum:$column: target \"$to\" is both external module/program and internal section\n";
      } else {
        $self->report ($filename, $linenum, $column,
                       __x('internal one-word link recommend guard against ambiguity with {slash} or {quote}',
                           slash => "L</"._escape_angles($to).">",
                           quote => "L<\""._escape_angles($to)."\">"));
      }
      next;
    }
    if (! defined $podfile) {
      if ($own_sections->{$to}) {
        # multi-word internal section
        return;
      }
      $self->report ($filename, $linenum, $column,
                     "no module/program/pod \"$to\"");
      next;
    }

    if (defined $section && $section ne '') {
      my $podfile_sections = $self->filename_to_sections ($podfile);
      if (! $podfile_sections->{$section}) {
        if (my $approximations
            = _section_approximations($section,$podfile_sections)) {
          $self->report ($filename, $linenum, $column,
                         __x("no section \"{section}\" in \"{name}\" (file {filename})\n    perhaps it should be {approximations}",
                             name => $to,
                             section => $section,
                             filename => $podfile,
                             approximations => $approximations));
        } else {
          $self->report ($filename, $linenum, $column,
                         __x('no section "{section}" in "{name}" (file {filename})',
                             name => $to,
                             section => $section,
                             filename => $podfile));
        }
        if ($self->{'verbose'} >= 2) {
          print __("    available sections:\n");
          foreach my $section (keys %$podfile_sections) {
            print "    $section\n";
          }
        }
      }
    }
  }
}

sub report {
  my ($self, $filename, $linenum, $column, $message) = @_;
  print "$filename:$linenum:$column: $message\n";
  $self->{'report_count'}++;
}

# return a string of close matches of $section in the keys of %$hashref
sub _section_approximations {
  my ($section, $hashref) = @_;
  $section = _section_approximation_crunch($section);
  return join(' or ',
              map {"\"$_\""}
              grep {_section_approximation_crunch($_) eq $section}
              keys %$hashref);
}
sub _section_approximation_crunch {
  my ($section) = @_;
  $section =~ s/(\W|_)+//g;
  return lc($section);
}

sub _is_one_word {
  my ($link) = @_;
  return ($link !~ /\W/);
}

# change all < and > in $str to pod style E<lt> and E<gt>
sub _escape_angles {
  my ($str) = @_;
  $str =~ s{([<>])}
    { 'E<'.($1 eq '<' ? 'lt' : 'gt').'>' }ge;
  return $str;
}

sub module_to_podfile {
  my ($self, $module) = @_;
  ### module_to_podfile(): $module
  ### dirs: $self->{'extra_INC'}
  require Pod::Find;
  return Pod::Find::pod_where ({ '-dirs' => $self->{'extra_INC'},
                                 '-inc' => 1,
                               },
                               $module);
}

# return hashref
sub filename_to_sections {
  my ($self, $filename) = @_;
  return ($self->{'sections_cache'}->{$filename} ||= do {
    ### parse file for sections: $filename
    my $parser = App::PodLinkCheck::ParseSections->new;
    $parser->parse_file ($filename);
    ### file sections: $parser->sections_hashref
    $parser->sections_hashref;
  });
}

#------------------------------------------------------------------------------
# CPAN
#
# cf CPAN::API::HOWTO

# look for $module in the cpan indexes
# if found return the name of the cpan method it was found in
# if not found return false
sub _module_known_cpan {
  my ($self, $module) = @_;
  foreach my $method (@{$self->{'cpan_methods'}}) {
    my $fullmethod = "_module_known_$method";
    if ($self->$fullmethod ($module)) {
      return $method;
    }
  }
  return 0;
}

{
  # a bit of a hack to suppress CPAN.pm messages, unless our verbose
  package App::PodLinkCheck::CPANquiet;
  our @ISA;
  sub print_ornamented { }
}
use constant::defer _CPAN_config => sub {
  my ($self) = @_;
  ### _CPAN_config() ...

  my $result = 0;
  eval {
    require CPAN;
    if (! $self->{'verbose'}) {
      # usually $CPAN::Frontend is CPAN::Shell
      @App::PodLinkCheck::CPANquiet::ISA = ($CPAN::Frontend);
      $CPAN::Frontend = 'App::PodLinkCheck::CPANquiet::ISA';
    }
    # not sure how far back this will work, maybe only 5.8.0 up
    if (! $CPAN::Config_loaded
        && CPAN::HandleConfig->can('load')) {
      # fake $loading to avoid running the CPAN::FirstTime dialog -- is
      # this the right way to do that?
      local $CPAN::HandleConfig::loading = 1;
      if ($self->{'verbose'}) {
        print __x("PodLinkCheck: {module} configs\n",
                  module => 'CPAN');
      }
      CPAN::HandleConfig->load;
    }
    $result = 1;
  }
    or do {
      if ($self->{'verbose'}) {
        print "CPAN.pm config error: $@\n";
      }
    };
  return $result;
};

sub _module_known_CPAN_SQLite {
  my ($self, $module) = @_;

  if (! defined $self->{'cpan_sqlite'}) {
    $self->{'cpan_sqlite'} = 0;  # no sqlite, unless we succeed below

    if ($self->_CPAN_config($self->{'verbose'})) {
      # configs loaded

      if ($self->{'verbose'}) {
        print __x("PodLinkCheck: loading {module} for module existence checking\n",
                  module => 'CPAN::SQLite');
      }
      if (! eval { require CPAN::SQLite }) {
        if ($self->{'verbose'}) {
          print __x("Cannot load {module}, skipping -- {error}\n",
                    module => 'CPAN::SQLite',
                    error => $@);
        }
        return 0;
      }

      # Quieten warning messags from CPAN::SQLite apparently when never yet run
      local $SIG{'__WARN__'} = sub {
        if ($self->{'verbose'}) {
          warn @_;
        }
      };
      if (! eval {
        # fake $loading to avoid running the CPAN::FirstTime dialog -- is
        # this the right way to do that?
        local $CPAN::HandleConfig::loading = 1;
        $self->{'cpan_sqlite'} = CPAN::SQLite->new (update_indices => 0);
      }) {
        if ($self->{'verbose'}) {
          print __x("{module} error: {error}\n",
                    module => 'CPAN::SQLite',
                    error => $@);
        }
      }
    }
  }

  my $cpan_sqlite = $self->{'cpan_sqlite'} || return 0;

  # Have struck errors from cpantesters creating db tables.  Not sure if it
  # might happen in a real run.  Guard with an eval.
  #
  my $result;
  if (! eval { $result = $cpan_sqlite->query (mode => 'module',
                                              name => $module);
               1 }) {
    if ($self->{'verbose'}) {
      print __x("{module} error, disabling -- {error}\n",
                module => 'CPAN::SQLite',
                error  => $@);
    }
    $self->{'cpan_sqlite'} = 0;
    return 0;
  }
  return $result;
}

my $use_CPAN;
sub _module_known_CPAN {
  my ($self, $module) = @_;
  ### _module_known_CPAN(): $module

  if (! defined $use_CPAN) {
    $use_CPAN = 0;

    if ($self->_CPAN_config($self->{'verbose'})) {
      eval {
        if ($self->{'verbose'}) {
          print __x("PodLinkCheck: load {module} for module existence checking\n",
                    module => 'CPAN');
        }

        if (defined $CPAN::META && %$CPAN::META) {
          $use_CPAN = 1;
        } elsif (! CPAN::Index->can('read_metadata_cache')) {
          if ($self->{'verbose'}) {
            print __("PodLinkCheck: no Metadata cache in this CPAN.pm\n");
          }
        } else {
          # try the .cpan/Metadata even if CPAN::SQLite is installed, just in
          # case the SQLite is not up-to-date or has not been used yet
          local $CPAN::Config->{use_sqlite} = 0;
          CPAN::Index->read_metadata_cache;
          if (defined $CPAN::META && %$CPAN::META) {
            $use_CPAN = 1;
          } else {
            if ($self->{'verbose'}) {
              print __("PodLinkCheck: empty Metadata cache\n");
            }
          }
        }
        1;
      }
        or do {
          if ($self->{'verbose'}) {
            print "CPAN.pm error: $@\n";
          }
        };
    }
  }

  return ($use_CPAN
          && exists($CPAN::META->{'readwrite'}->{'CPAN::Module'}->{$module}));
}

sub _module_known_CPANPLUS {
  my ($self, $module) = @_;
  ### _module_known_CPANPLUS(): $module

  if (! defined $self->{'cpanplus'}) {
    if ($self->{'verbose'}) {
      print __x("PodLinkCheck: load {module} for module existence checking\n",
                module => 'CPANPLUS');
    }
    if (! eval { require CPANPLUS::Backend;
                 require CPANPLUS::Configure;
               }) {
      $self->{'cpanplus'} = 0;
      if ($self->{'verbose'}) {
        print __x("Cannot load {module}, skipping -- {error}\n",
                  module => 'CPANPLUS',
                  error => $@);
      }
      return 0;
    }
    my $conf = CPANPLUS::Configure->new;
    $conf->set_conf (verbose => 1);
    $conf->set_conf (no_update => 1);
    $self->{'cpanplus'} = CPANPLUS::Backend->new ($conf);
  }

  my $cpanplus = $self->{'cpanplus'} || return 0;

  # module_tree() returns false '' for not found.
  #
  # Struck an error from module_tree() somehow relating to
  # CPANPLUS::Internals::Source::SQLite on cpantesters at one time, so guard
  # with an eval.
  #
  my $result;
  if (! eval { $result = $cpanplus->module_tree($module); 1 }) {
    if ($self->{'verbose'}) {
      print __x("{module} error, disabling -- {error}\n",
                module => 'CPANPLUS',
                error  => $@);
    }
    $self->{'cpanplus'} = 0;
    return 0;
  }
  return $result;
}

sub _module_known_cpanminus {
  my ($self, $module) = @_;
  ### _module_known_cpanminus(): $module

  foreach my $filename ($self->_cpanminus_packages_details_filenames()) {
    my $fh;
    unless (open $fh, '<', $filename) {
      unless ($self->{'cpanminus-warned'}->{$filename}++) {
        if ($self->{'verbose'}) {
          print __x("PodLinkCheck: cannot open {filename}: {error}\n",
                    filename => $filename,
                    error => "$!");
        }
      }
      next;
    }
    unless ($self->{'cpanminus'}->{$filename}++) {
      if ($self->{'verbose'}) {
        print __x("PodLinkCheck: module existence checking in {filename}\n",
                  filename => $filename);
      }
    }

    # binary search
    if (_packages_details_bsearch($fh, $module)) {
      return 1;
    }

    # Plain search.
    # while (defined(my $line = readline $fh)) {
    #   if ($line =~ /^\Q$module\E /) {
    #     return 1;
    #   }
    # }
  }
  return 0;
}

# Return a list of all the 02packages.details.txt files in App::cpanminus.
# eg. "/home/foo/.cpanm/sources/http%www.cpan.org/02packages.details.txt".
# ENHANCE-ME: Only one of the filenames returned will be its configured
# mirror.  Will it tell us which?
sub _cpanminus_packages_details_filenames {
  # my ($self) = @_;
  require File::HomeDir;
  my $home = File::HomeDir->my_home;
  if (! defined $home) { return; }  # undef if no $HOME

  my $wildcard = File::Spec->catfile($home, '.cpanm', 'sources',
                                     '*', '02packages.details.txt');
  return glob $wildcard;
}

# $fh is a file handle open on an 02packages.details.txt file.
# Return true if $module exists in the file (any version, any author).
#
# 02packages header lines are first field with trailing colon like
#     File: 02packages.details.txt
# and a blank line before first module.
#
# Sort order is lc($a) cmp lc($a) per PAUSE::mldistwatch rewrite02().
#   https://github.com/andk/pause/raw/master/lib/PAUSE/mldistwatch.pm
# This means modules differing only in upper/lower case are ordered by
# version number and author, which will be semi-random.  Hence linear search
# after the bsearch finds the first.  This doesn't happen often so the
# result is still good speed-wise.
#
sub _packages_details_bsearch {
  my ($fh, $module) = @_;

  require Search::Dict;
  my $lc_module = lc($module);
  ### $lc_module
  my $pos = Search::Dict::look ($fh, $lc_module,
                                { xfrm => \&_packages_details_line_to_module });
  ### $pos
  next if ! defined $pos;

  while (defined(my $line = readline $fh)) {
    return 1 if $line =~ /^\Q$module\E /;
    last     if $line !~ /^\Q$module\E /i;
  }
  return 0;
}

# $line is a line from an 02packages.details.txt file.
# Return the module name on the line, or empty string "" if not a module line.
sub _packages_details_line_to_module {
  my ($line) = @_;
  if ($line =~ /^([^ ]*[^ :]) /) {
    ### at: lc($1)
    return lc($1);
  } else {
    return '';
  }
}

#------------------------------------------------------------------------------
# PATH

sub find_script {
  my ($self, $name) = @_;
  foreach my $dir ($self->PATH_list) {
    my $filename = File::Spec->catfile($dir,$name);
    #### $filename
    if (-e $filename) {
      return $filename;
    }
  }
  return undef;
}

# return list of directories
sub PATH_list {
  my ($self) = @_;
  require Config;
  return split /\Q$Config::Config{'path_sep'}/o, $self->PATH;
}

# return string
sub PATH {
  my ($self) = @_;
  if (defined $self->{'PATH'}) {
    return $self->{'PATH'};
  } else {
    return $ENV{'PATH'};
  }
}

#------------------------------------------------------------------------------
# man

# return bool
sub manpage_is_known {
  my ($self, $name) = @_;
  my @manargs;
  my $section = '';
  if ($name =~ s/\s*\((.+)\)$//) {
    $section = $1;
    @manargs = ($section);
  }

  my $r = \$self->{'manpage_is_known'}->{$section}->{$name};
  if (defined $$r) {
    return $$r;
  }
  push @manargs, $name;
  ### man: \@manargs

  return ($$r = ($self->_man_has_location_option()
                 ? $self->_manpage_is_known_by_location(@manargs)
                 : $self->_manpage_is_known_by_output(@manargs)));
}

# --location is not in posix,
# http://www.opengroup.org/onlinepubs/009695399/utilities/man.html
# Is it man-db specific, or does it have a chance of working elsewhere?
#
use constant::defer _man_has_location_option => sub {
  my ($self) = @_;
  ### _man_has_location_option() ...
  require IPC::Run;
  my $str = '';
  eval {
    IPC::Run::run (['man','--help'],
                   '<', \undef,
                   '>', \$str,
                   '2>', File::Spec->devnull);
  };
  my $ret = ($str =~ /--location\b/);
  if ($self->{'verbose'} >= 2) {
    if ($ret) {
      print __("man \"--location\" option is available\n");
    } else {
      print __("man \"--location\" option not available (not in its \"--help\")\n");
    }
  }
  ### $ret
  return $ret;
};

sub _manpage_is_known_by_location {
  my ($self, @manargs) = @_;
  ### _manpage_is_known_by_location() run: \@manargs
  require IPC::Run;
  my $str;
  if (! eval {
    IPC::Run::run (['man', '--location', @manargs],
                   '<', \undef,  # stdin
                   '>', \$str,  # stdout
                   '2>', File::Spec->devnull);
    1;
  }) {
    my $err = $@;
    $err =~ s/\s+$//;
    print __x("PodLinkCheck: error running 'man': {error}\n", error => $err);
    return 0;
  }
  ### _manpage_is_known_by_location() output: $str
  return ($str =~ /\n/ ? 1 : 0);
}

sub _manpage_is_known_by_output {
  my ($self, @manargs) = @_;
  ### _manpage_is_known_by_output() run: \@manargs
  require IPC::Run;
  require File::Temp;
  my $fh = File::Temp->new (TEMPLATE => 'PodLinkCheck-man-XXXXXX',
                            TMPDIR => 1);
  if (! eval {
    IPC::Run::run (['man', @manargs],
                   '<', \undef,  # stdin
                   '>', $fh,     # stdout
                   '2>', File::Spec->devnull);
    1;
  }) {
    my $err = $@;
    $err =~ s/\s+$//;
    print __x("PodLinkCheck: error running 'man': {error}\n", error => $err);
    return 0;
  }

  seek $fh, 0, 0;
  foreach (1 .. 5) {
    if (! defined (readline $fh)) {
      return 0;
    }
  }
  return 1;
}

1;
__END__

=for stopwords PodLinkCheck Ryde stdout lockfiles symlinks

=head1 NAME

App::PodLinkCheck -- check Perl pod LE<lt>E<gt> link references

=head1 SYNOPSIS

 use App::PodLinkCheck;
 exit App::PodLinkCheck->command_line;

=head1 FUNCTIONS

=over 4

=item C<$plc = App::PodLinkCheck-E<gt>new (key =E<gt> value, ...)>

Create and return a PodLinkCheck object.  The optional key/value parameters
are

=over

=item C<verbose =E<gt> $integer> (default 0)

Print some diagnostics about checking.  Currently C<verbose=E<gt>1> shows
all the links checked, or C<verbose=E<gt>2> shows that and also available
targets detected in destination files etc.

=back

=item C<$exitcode = $plc-E<gt>command_line>

Run a PodLinkCheck as from the command line.  Arguments are taken from
C<@ARGV> and the return is an exit status code suitable for C<exit>, so 0
for success.

=item C<$plc-E<gt>check_file ($filename)>

Run checks on a single file C<$filename> and print reports to stdout.

=item C<$plc-E<gt>check_tree ($file_or_dir, ...)>

Run checks on all the files or directories given and print reports to
stdout.  Directories are traversed recursively, checking all Perl files.
A Perl file is F<.pm>, F<.pl> or F<.pod>.  Emacs F<.#foo.pm> etc lockfiles
(dangling symlinks) are ignored.

=back

=head1 SEE ALSO

L<podlinkcheck>

L<App::PodLinkCheck::ParseLinks>,
L<App::PodLinkCheck::ParseSections>

=head1 HOME PAGE

http://user42.tuxfamily.org/podlinkcheck/index.html

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2016, 2017 Kevin Ryde

PodLinkCheck is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

PodLinkCheck is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

=cut

