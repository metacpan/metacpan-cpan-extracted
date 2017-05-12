#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of PodLinkCheck.

# PodLinkCheck is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;

use FindBin;
my $progfile = "$FindBin::Bin/$FindBin::Script";
print $progfile,"\n";

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $plc = App::PodLinkCheck->new;
  $plc->command_line;
  exit 0;
}

{
  my $plc = App::PodLinkCheck->new;
  $plc->check_file ($progfile);
  exit 0;
}

{
  my $parser = App::PodLinkCheck::SectionParser->new;
   $parser->parse_from_file ($progfile);
  # $parser->parse_from_file ('/usr/share/perl/5.10/pod/perlsyn.pod');

  my $sections = $parser->{'sections'};
  require Data::Dumper;
  print Data::Dumper->new([$sections],['args'])->Sortkeys(1)->Dump;
  exit 0;
}


#------------------------------------------------------------------------------
{
  package App::PodLinkCheck;
  use strict;
  use warnings;

  sub new {
    my ($class, @options) = @_;
    return bless { verbose => 0,
                   module_path => \@INC,
                   executable_path => [ split /:/, $ENV{'PATH'} ],
                   @options }, $class;
  }

  sub command_line {
    my ($self) = @_;
    my @files = @ARGV;
    while (@files) {
      my $filename = shift @files;
      if (-d $filename) {
        ### recurse dir: $filename
        my @morefiles;
        require File::Find;
        File::Find::find ({ wanted => sub {
                              #### file: $_
                              if (! -d && /\.p(m|od)$/) {
                                push @morefiles, $_;
                              }
                            },
                            follow_fast => 1,
                            no_chdir => 1,
                          },
                          $filename);
        unshift @files, @morefiles;
      } else {
        print "$filename:\n";
        $self->check_file ($filename);
      }
    }
  }

  sub check_file {
    my ($self, $filename) = @_;
    my $parser = App::PodLinkCheck::LinkParser->new
      (verbose => $self->{'verbose'});
    $parser->parse_from_file ($filename);
  }
}

#------------------------------------------------------------------------------
{
  package App::PodLinkCheck::LinkParser;
  use strict;
  use warnings;
  use File::Spec;
  use List::Util;
  BEGIN { our @ISA = ('App::PodLinkCheck::SectionParser'); }

  sub new {
    my $class = shift;
    return $class->SUPER::new (@_,
                               pending_links => []);
  }

#   sub command {
#     my ($self, $command, $text, $linenum, $paraobj) = @_;
#     ### command: $command
#     ### $text
#     if ($command =~ /^(head|item)/) {
#       $text = $self->interpolate ($text, $linenum);
#       $text =~ tr/\n//d;
#       ### text interpolated: $text
#       $self->{'sections'}->{$text} = 1;
# 
#       # like Pod::Checker take the first word as a section name too, which is
#       # much used for cross-references to perlfunc
#       if ($text =~ s/\s.*//) {
#         ### text one word: $text
#         $self->{'sections'}->{$text} = 1;
#       }
#     }
#     return '';
#   }

#   sub verbatim {
#     return '';
#   }

  sub textblock {
    my ($self, $text, $linenum, $paraobj) = @_;
    ### LinkParser textblock
    return $self->interpolate ($text, $linenum);
  }

  sub interior_sequence {
    my ($self, $command, $arg, $seq_obj) = @_;
    ### LinkParser interior: $command
    ### $arg
    ### seq raw_text: $seq_obj->raw_text
    #    ### $seq_obj

    if ($command eq 'L') {
      $self->check_L ($seq_obj->raw_text, $seq_obj);
    }
    return shift->SUPER::interior_sequence (@_);
  }

  sub check_L {
    my ($self, $arg, $seq_obj) = @_;
    require Pod::ParseLink;
    my ($text, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($arg);
    ### parselink: $text, $inferred, $name, $section, $type

    my $linenum = ($seq_obj->file_line)[1];
    if (defined $name) {
      $name = $self->interpolate ($name, $linenum);
    }

    if ($type eq 'man') {
      if (! _manpage_is_known($name)) {
        $self->link_error ($seq_obj,
                           "unknown man page \"$name\"");
      }
      return;
    }
    ($type eq 'pod') or return;

    if (! defined $name) {
      if (defined $section) {
        push @{$self->{'pending_links'}}, [ $section, $seq_obj ];
      }
      return;
    }

    my $podfile = ($self->_module_to_podfile($name)
                   || $self->_find_executable($name));
    if (! defined $podfile) {
      if (! _manpage_is_known($name)) {
        $self->link_error ($seq_obj,
                           "unknown module/program/pod \"$name\"");
      }
      return;
    }

    (defined $section) or return;
    $section = $self->interpolate ($section, ($seq_obj->file_line)[1]);
    ### interpolated section: $section

    my $sections = _filename_to_sections ($podfile);
    if (! exists $sections->{$section}) {
      $self->link_error
        ($seq_obj,
         "unknown section \"$section\" in \"$name\" (file $podfile)");
    }
  }

  sub end_pod {
    my ($self) = @_;
    my $sections = $self->{'sections'};
    foreach my $pending (@{$self->{'pending_links'}}) {
      my ($section, $seq_obj) = @$pending;

      if (! exists $sections->{$section}) {
        $self->link_error ($seq_obj, "unknown section \"$section\"");
      }
    }
    return '';
  }

  sub link_error {
    my ($self, $seq_obj, $msg) = @_;
    my ($filename, $linenum) = $seq_obj->file_line();
    print "$filename:$linenum: $msg\n";
  }

  sub _module_to_podfile {
    my ($self, $module) = @_;
    my @moduleparts = split /::/, $module;
    foreach my $suffix ('.pod', '.pm') {
      foreach my $dir (@{$self->{'module_path'}}) {
        foreach my $poddir ([], ['pod']) {
          my $filename = (File::Spec->catfile($dir,@$poddir,@moduleparts)
                          . $suffix);
          #### $filename
          if (-e $filename) {
            return $filename;
          }
        }
      }
    }
    return undef;
  }

  sub _find_executable {
    my ($self, $name) = @_;
    foreach my $dir (@{$self->{'executable_path'}}) {
      my $filename = File::Spec->catfile($dir,$name);
      #### $filename
      if (-e $filename) {
        return $filename;
      }
    }
    return undef;
  }

  my %sections_cache;
  sub _filename_to_sections {
    my ($filename) = @_;
    return ($sections_cache{$filename} ||= do {
      my $parser = App::PodLinkCheck::SectionParser->new;
      $parser->parse_from_file ($filename);
      ### file sections: $parser->sections_hashref
      $parser->sections_hashref;
    });
  }

  my %manpage_is_known;
  sub _manpage_is_known {
    my ($name) = @_;
    if (! exists $manpage_is_known{$name}) {
      my $path;
      require IPC::Run;
      IPC::Run::run (['man', '--location', $name],
                     \undef,  # stdin
                     \$path,  # stdout
                     sub{});  # stderr
      $manpage_is_known{$name} = ($path ne '');
    }
    return $manpage_is_known{$name};
  }
}

#------------------------------------------------------------------------------
{
  package App::PodLinkCheck::SectionParser;
  use strict;
  use warnings;
  use Pod::Escapes;
  use base 'Pod::Parser';

  sub new {
    my $class = shift;
    my $self = $class->SUPER::new (@_,
                                   sections => {});
    $self->errorsub ('error_handler'); # method name
    return $self;
  }
  sub error_handler {
    my ($self, $errmsg) = @_;
    return 1;  # error handled
  }

  sub parse_from_string {
    my ($self, $str) = @_;
    require IO::String;
    my $fh = IO::String->new ($str);
    $self->parse_from_filehandle ($fh);
  }

  sub sections_hashref {
    my ($self) = @_;
    return $self->{'sections'};
  }

  sub command {
    my ($self, $command, $text, $linenum, $paraobj) = @_;
    ### SectionParser command: $command
    ### $text
    if ($command =~ /^(head|item)/) {
      $text = $self->interpolate ($text, $linenum);
      $text =~ tr/\n//d;
      ### text interpolated: $text
      $text =~ s/^\s+//;
      $text =~ s/\s+$//;
      $self->{'sections'}->{$text} = 1;

      # like Pod::Checker take the first word as a section name too, which is
      # much used for cross-references to perlfunc
      if ($text =~ s/\s.*//) {
        ### text one word: $text
        $self->{'sections'}->{$text} = 1;
      }
    }
    return '';
  }

  sub verbatim {
    return '';
  }
  sub textblock {
    return '';
  }

  BEGIN {
    my %empty_interior = (L => 1,
                          X => 1);
    sub interior_sequence {
      my ($self, $command, $arg, $seq_obj) = @_;
      ### SectionParser interior_sequence: $command
      if ($command eq 'E') {
        return Pod::Escapes::e2char($arg);
      }
      if ($empty_interior{$command}) {
        ### empty
        return '';
      }
      ### return arg: $arg
      return $arg;
    }
  }
}

# =over 4
# 
# L<coE<sol>de>
# 
# =cut

# =item PERL_HASH_SEED
# X<PERL_HASH_SEED>
# 
# =item E<gt>
# 
# =item blah Z<>
# 
# =item C<code>
# 
# L</C<code>>
# 
# L</blah>
# 
# L</no such target>
# 
# L</PERL_HASH_SEED>
# 
# L<AutoLoader/foo>
# 
# L<AutoLoader/"foo bar">
# 
# =back
# 
# Pod::Man
