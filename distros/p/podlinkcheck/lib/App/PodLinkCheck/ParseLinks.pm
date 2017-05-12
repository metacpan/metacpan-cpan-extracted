# Copyright 2010, 2011, 2012, 2013, 2016 Kevin Ryde

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


package App::PodLinkCheck::ParseLinks;
use 5.006;
use strict;
use warnings;
use File::Spec;
use List::Util;
use Text::Tabs;
use base 'App::PodLinkCheck::ParseSections';

use vars '$VERSION';
$VERSION = 15;

# uncomment this to run the ### lines
# use Smart::Comments;

sub new {
  my ($class, $plc) = @_;
  my $self = $class->SUPER::new ($plc);
  $self->{(__PACKAGE__)}->{'links'} = [];
  $self->{(__PACKAGE__)}->{'linenum'} = 1;
  $self->{(__PACKAGE__)}->{'column'} = 1;
  return $self;
}

sub links_arrayref {
  my ($self) = @_;
  return $self->{(__PACKAGE__)}->{'links'};
}

sub _handle_text {
  my ($self, $text) = @_;
  shift->SUPER::_handle_text (@_);

  ### $text
  $self->{(__PACKAGE__)}->{'linenum'} += ($text =~ tr/\n/\n/);
  #### linenum: $self->{(__PACKAGE__)}->{'linenum'}

  my $pos = 1 + rindex ($text, "\n");
  if ($pos) {
    $self->{(__PACKAGE__)}->{'column'} = 1;
  }
  substr ($text, 0, $pos, '');
  $text = Text::Tabs::expand ($text);
  $self->{(__PACKAGE__)}->{'column'} += length($text);
}

sub _handle_element_start {
  my ($self, $ename, $attr) = @_;
  shift->SUPER::_handle_element_start (@_);
  ### $ename
  ### $attr

  if (defined $attr->{'start_line'}) {
    $self->{(__PACKAGE__)}->{'linenum'} = $attr->{'start_line'};
    $self->{(__PACKAGE__)}->{'column'} = 1;
  }
  if ($ename eq 'item-bullet') {
    $self->{(__PACKAGE__)}->{'linenum'} += 2;
  }

  if ($ename eq 'L') {
    my $type = "$attr->{'type'}";
    if ($type eq 'man' || $type eq 'pod') {
      my $to = $attr->{'to'};
      if (defined $to) {
        $to = App::PodLinkCheck::ParseSections::_collapse_whitespace("$to");
      }
      my $section = $attr->{'section'};
      if (defined $section) {
        $section = App::PodLinkCheck::ParseSections::_collapse_whitespace("$section");
      }
      ### $to
      ### $section

      push @{$self->{(__PACKAGE__)}->{'links'}},
        [ $type,
          $to,
          $section,
          $self->{(__PACKAGE__)}->{'linenum'},
          $self->{(__PACKAGE__)}->{'column'} ];
    }
  }
}

#   sub _str_last_line {
#     my ($str) = @_;
#     return substr ($str, 1+rindex ($str, "\n"));
#   }

1;
__END__

=for stopwords PodLinkCheck Ryde superclass boolean arrayref whitespace formatters subclassing

=head1 NAME

App::PodLinkCheck::ParseLinks -- parse out POD LE<lt>E<gt> links

=head1 SYNOPSIS

 use App::PodLinkCheck::ParseLinks;

=head1 CLASS HIERARCHY

    Pod::Simple
      App::PodLinkCheck::ParseSections
        App::PodLinkCheck::ParseLinks

=head1 DESCRIPTION

This is a POD parser used by C<App::PodLinkCheck> to find C<LE<lt>E<gt>>
links and section names in a document.  Its behaviour is specific to
PodLinkCheck but might have other use.

Section names are recorded as per the superclass
C<App::PodLinkCheck::ParseSections>.  This subclass records C<LE<lt>E<gt>>
links too.

Links are recorded in an array (and sections in a hash) rather than
callbacks or similar because PodLinkCheck does its analysis at the end of a
document.  This is since internal links will be satisfied by section names
which might be late in the document, and the full list of section names is
used to suggest likely candidates for a broken link.

=head1 FUNCTIONS

=over

=item C<$parser = App::PodLinkCheck::ParseLinks-E<gt>new($options_hashref)>

Create and return a new parser object.

(See superclass L<App::PodLinkCheck::ParseSections> on POD whining options.)

=item C<$parser-E<gt>parse_file($filename)>

Parse the pod from C<$filename>.  All the various C<Pod::Simple> parse input
styles can be used too.

=item C<$aref = $parser-E<gt>links_arrayref()>

Return an arrayref of C<LE<lt>E<gt>> links seen by C<$parser>.  Each array
element is a 5-element arrayref

        [ $type,       # L<> attribute, eg. 'pod' or 'man'
          $to,         # L<> attribute, whitespace collapsed, or undef
          $section,    # L<> attribute or undef
          $linenum,    # integer, first line 1
          $column      # integer, first column 1
        ]

So for example

    my $links_arrayref = $parser->links_arrayref;
    foreach my $link (@$links_arrayref) {
      my ($type, $to, $section, $linenum, $column) = @$link;
      ...

C<$type>, C<$to> and C<$section> are the C<type>, C<to> and C<section>
attributes from C<Pod::Simple>.  An internal link has C<$to = undef>.  An
external link with no section has C<$section = undef>.

C<$to> and C<$section> are mildly normalized by collapsing whitespace to a
single space each and removing leading and trailing whitespace.  Believe
that's mostly how the pod formatters end up treating target names for
linking purposes.  (That sort of treatment being the intention here.)
Usually C<$to> won't have any whitespace (being a module name etc).

C<$linenum> and C<$column> are the location of the C<LE<lt>E<gt>> in the
input file.  C<Pod::Simple> normally only gives the paragraph start line.
Some gambits here give more resolution since it's helpful to show the exact
place in a paragraph with several links.

The links accumulate everything seen by C<$parser>.  No attention is paid to
any "Document" start etc.  Usually a new C<App::PodLinkCheck::ParseLinks>
will be used for each file.

The accuracy of C<$linenum> and C<$column> presently depend on seeing
C<XE<lt>E<gt>> codes, so if subclassing or similar don't C<nix_X_codes()>.

=back

=head1 SEE ALSO

L<App::PodLinkCheck>,
L<App::PodLinkCheck::ParseSections>

=head1 HOME PAGE

http://user42.tuxfamily.org/podlinkcheck/index.html

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2016 Kevin Ryde

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
