# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Distlinks.

# Distlinks is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::Documentation::PodLinkCheck;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 11;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  my $str = $elem->serialize;

  my $parser = Perl::Critic::Policy::Documentation::PodLinkCheck::LinkParser->new
    (policy => $self,
     elem => $elem,
     str => $str);
  $parser->parse_from_string ($str);
  return @{$parser->{'violations'}};
}

#------------------------------------------------------------------------------
package Perl::Critic::Policy::Documentation::PodLinkCheck::LinkParser;
use strict;
use warnings;
use base 'Pod::Parser';
use File::Spec;
use List::Util;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (@_,
                                 violations => []);
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

sub command {
  return '';
}

sub verbatim {
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### LinkParser textblock
  return $self->interpolate ($text, $linenum);
}

sub interior_sequence {
  my ($self, $command, $arg, $seq_obj) = @_;
  ### LinkParser interior: $command
  ### $arg
  ### $seq_obj
  ### seq raw_text: $seq_obj->raw_text
  ($command eq 'L') or return '';

  require Pod::ParseLink;
  my $L = $arg;
  $L =~ s/^L<//;
  $L =~ s/>$//;
  my ($text, $inferred, $name, $section, $type)
    = Pod::ParseLink::parselink($L);
  ### parselink: $text, $inferred, $name, $section, $type
  ($type eq 'pod') or return '';

  my $error;
  my $podfile;
  if (defined $name) {
    $podfile = _module_to_podfile ($name);
    if (! defined $podfile) {
      $error = "L<> link to unknown POD or module \"$name\""
    }
  }

  if (defined $section && ! defined $error) {
    my $sections;
    if (defined $podfile) {
      my $parser = Perl::Critic::Policy::Documentation::PodLinkCheck::SectionParser->new;
      $parser->parse_from_file ($podfile);
      ### file sections: $parser->{'sections'}
      $sections = $parser->{'sections'};
    } else {
      my $elem = $self->{'elem'};
      $sections = ($elem->{__PACKAGE__.'.sections'} ||= do {
        my $parser = Perl::Critic::Policy::Documentation::PodLinkCheck::SectionParser->new;
        $parser->parse_from_string ($elem->serialize);
        ### own sections: $parser->{'sections'}
        $parser->{'sections'};
      });
    }

    if (! $sections->{$section}) {
      $error = "L<> link to unknown section \"$section\"";
      if (defined $name) {
        $error .= " in \"$name\" (file $podfile)";
      } else {
        $error .= " in this document";
      }
    }
  }

  if (defined $error) {
    my ($filename, $linenum) = $seq_obj->file_line;
    my $policy = $self->{'policy'};
    my $elem   = $self->{'elem'};
    my $str    = $self->{'str'};
    my $violation = $policy->violation
      ($error,
       '',
       $elem);
    require Perl::Critic::Policy::Compatibility::PodMinimumVersion;
    Perl::Critic::Policy::Compatibility::PodMinimumVersion::_violation_override_linenum ($violation, $str, $linenum);
    push @{$self->{'violations'}}, $violation;

  }
  return '';
}

sub _module_to_podfile {
  my ($module) = @_;

  my @moduleparts = split /::/, $module;
  foreach my $suffix ('.pod', '.pm') {
    foreach my $dir (@INC) {
      foreach my $poddir ([], ['pod']) {
        my $filename = File::Spec->catdir($dir,@$poddir,@moduleparts) . $suffix;
        #### $filename
        if (-e $filename) {
          return $filename;
        }
      }
    }
  }
  return undef;
}

#------------------------------------------------------------------------------
package Perl::Critic::Policy::Documentation::PodLinkCheck::SectionParser;
use strict;
use warnings;
use base 'Pod::Parser';
use File::Spec;

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

sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  ### $text
  if ($command =~ /^(head|item)/) {
    $text = $self->interpolate ($text, $linenum);
    $text =~ tr/\n//d;
    ### text interpolated: $text
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

my %empty_interpolates = (L => 1,
                          X => 1);
sub interior_sequence {
  my ($self, $command, $arg, $seq_obj) = @_;
  ### SectionParser interior: $command
  if ($empty_interpolates{$command}) {
    return '';
  }
  ### return arg: $arg
  return $arg;
}


1;
__END__

=for stopwords addon builtin Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::PodLinkCheck - check LE<lt>E<gt> link targets

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It checks LE<lt>E<gt> links to verify the target module or POD
referred to exists, including any section given in the LE<lt>E<gt>.

    L<No::Such::Module>             # bad, external
    L<perlfaq4/"no such section">   # bad, external
    L</"no such section">           # bad, own document

Bad links are considered documentation bugs and on that basis this policy is
under the "bugs" theme (see L<Perl::Critic/POLICY THEMES>), but low priority.

External documents are sought in the C<@INC> path.  Section targets are
C<=head> and C<=item> directives.  Markup like C<LE<lt>E<gt>> etc in the
target or the LE<lt>E<gt> is stripped.

Most of the time if you cross-reference an external module then you'll have
it installed.  For obscure things it can be annoying to get a violation when
not installed.  Perhaps in the future there'll be a configuration option
with modules to consider available (and sections within them).

As always if you don't care about this you can disable C<PodLinkCheck> from
your F<.perlcriticrc> in the usual way,

    [-Documentation::PodLinkCheck]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

L<Pod::Checker>, which checks internal links, but not external

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013 Kevin Ryde

Distlinks is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Distlinks is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Distlinks.  If not, see <http://www.gnu.org/licenses/>.

=cut
