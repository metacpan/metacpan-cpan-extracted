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

package App::PodLinkCheck::ParseSections;
use 5.006;
use strict;
use warnings;
use base 'Pod::Simple';

use vars '$VERSION';
$VERSION = 15;

# uncomment this to run the ### lines
# use Smart::Comments;

sub new {
  my ($class, $plc) = @_;
  my $self = $class->SUPER::new;
  $self->{(__PACKAGE__)}->{'sections'} = {};
  $self->no_errata_section(1);
  $self->preserve_whitespace(1);
  if (! $plc->{'verbose'}) {
    $self->no_whining(1);
  }
  return $self;
}

sub sections_hashref {
  my ($self) = @_;
  return $self->{(__PACKAGE__)}->{'sections'};
}

sub _handle_element_start {
  my ($self, $ename, $attr) = @_;
  ### _handle_element_start(): $ename, $attr

  # Any of head1
  #        head2
  #        head3
  #        head4
  #        item-text
  #        item-bullet
  #        item-number
  if ($ename =~ /^(head|item)/) {
    $self->{(__PACKAGE__)}->{'item_text'} = '';
  }

  # in_X is true when within an X<>, possibly a nested X<a X<b> c>
  # although that's likely a mistake and probably meaningless
  $self->{(__PACKAGE__)}->{'in_X'} += ($ename eq 'X');
}
sub _handle_text {
  my ($self, $text) = @_;
  ### _handle_text(): $text
  if (exists $self->{(__PACKAGE__)}->{'item_text'}
     && ! $self->{(__PACKAGE__)}->{'in_X'}) {
    $self->{(__PACKAGE__)}->{'item_text'} .= $text;
  }
}
sub _handle_element_end {
  my ($self, $ename) = @_;
  ### _handle_element_end(): $ename

  $self->{(__PACKAGE__)}->{'in_X'} -= ($ename eq 'X');

  if ($ename =~ /^(head|item)/) {
    my $section = delete $self->{(__PACKAGE__)}->{'item_text'};
    ### section: $section

    $section = _collapse_whitespace ($section);
    $self->{(__PACKAGE__)}->{'sections'}->{$section} = 1;

    # Like Pod::Checker take the first word, meaning up to the first
    # whitespace, as a section name too, which is much used for
    # cross-references to perlfunc.
    #
    # THINK-ABOUT-ME: CHI.pm is better treated by taking the first \w word
    # so as to exclude parens etc.
    #
    if ($section =~ s/\s.*//) {
      ### section one word: $section
      $self->{(__PACKAGE__)}->{'sections'}->{$section} = 1;
    }
  }
}

sub _collapse_whitespace {
  my ($str) = @_;
  $str =~ s/\s+/ /g;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

1;
__END__

=for stopwords PodLinkCheck Ryde boolean hashref whitespace formatters

=head1 NAME

App::PodLinkCheck::ParseSections -- parse out section names from POD

=head1 SYNOPSIS

 use App::PodLinkCheck::ParseSections;

=head1 CLASS HIERARCHY

    Pod::Simple
      App::PodLinkCheck::ParseSections

=head1 DESCRIPTION

This is a POD parser used by C<App::PodLinkCheck> to find section names in a
document.  Its behaviour is specific to PodLinkCheck but might have other
use.

=head1 FUNCTIONS

=over

=item C<$parser = App::PodLinkCheck::ParseSections-E<gt>new($options_hashref)>

Create and return a new parser object.

The default is to disable C<Pod::Simple> whining about dubious pod, because
C<App::PodLinkCheck> is just meant to check links.  C<$options_hashref> can
have C<verbose> to give full messages from C<Pod::Simple>.

    $parser = App::PodLinkCheck::ParseSections->new({ verbose => 1 });

It also works to set C<$parser-E<gt>no_whining()> as desired at any time.

=item C<$parser-E<gt>parse_file($filename)>

Parse the pod from C<$filename>.  All the various C<Pod::Simple> parse input
styles can be used too.

=item C<$hashref = $parser-E<gt>sections_hashref()>

Return a hashref of the names of POD sections seen by C<$parser>.  The keys
are the section names.  The values are true (presently just 1).

Sections names are mildly normalized by collapsing whitespace to a single
space each and removing leading and trailing whitespace.  Believe that's
mostly how the pod formatters end up treating section names for linking
purposes.  (That sort of treatment being the intention here.)

The first word (of non-whitespace) of a section name is added as a hash
entry too.  This is in the style of C<Pod::Checker> and is how the
formatters help links to function names in for example L<perlfunc>.

The section names accumulate everything seen by C<$parser>.  No attention is
paid to any "Document" start etc.  Usually a new
C<App::PodLinkCheck::ParseSections> is used for each file (unless some union
of section names is in fact wanted).

=back

=head1 SEE ALSO

L<App::PodLinkCheck>,
L<App::PodLinkCheck::ParseLinks>

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
