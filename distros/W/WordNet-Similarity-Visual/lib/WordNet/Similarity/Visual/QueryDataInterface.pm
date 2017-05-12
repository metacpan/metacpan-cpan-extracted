package WordNet::Similarity::Visual::QueryDataInterface;

=head1 NAME

WordNet::Similarity::Visual::QueryDataInterface

=head1 SYNOPSIS

=head2 Basic Usage Example

  use WordNet::Similarity::Visual::QueryDataInterface;

  my $wn = WordNet::Similarity::Visual::QueryDataInterface->new;

  $wn->initialize;

  my ($result) = $wn->find_allsenses($word);

=head1 DESCRIPTION

This package provides an interface to WordNet::QueryData.

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=cut

use 5.008004;
use strict;
use warnings;
use Gtk2 '-init';
use WordNet::QueryData;
our $VERSION = '0.07';
use constant TRUE  => 1;
use constant FALSE => 0;
my $wn;

=item  $obj->new

The constructor for WordNet::Similarity::Visual::QueryDataInterface objects.

Return value: the new blessed object

=cut

sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

=item  $obj->initialize

To initialize WordNet::QueryData.

Return Value: None

=cut

sub initialize
{
  my ($self) = @_;
  $self->{ wn }=WordNet::QueryData->new;
}




=item  $obj->search_glosses

Parameter: The word(String) for which we are searching the glosses.

Return value: A hash with all the glosses for all the senses of the word.

=cut

sub search_senses
{
  my ($self, $word) = @_;
  my $count=0;
  my @wordglos=();
  if (length $word != 0 )
  {
    $word=lc $word;
    my @temp = split '#',$word;
    my $wordlevel = $#temp+1;
    my @allsenses = ();
    my $sense;
    my %allres;
    if ($wordlevel == 3)
    {
      @wordglos = $self->{ wn }->querySense($word, "glos");
      $allres{$word} = $wordglos[0];
      $count++;
    }
    elsif ($wordlevel == 2)
    {
        my @senses = $self->{ wn }->queryWord($word);
        my @wordglos;
        my $glos;
        my $wordsense;
        foreach $wordsense (@senses)
        {
          while (Gtk2->events_pending)
          {
            Gtk2->main_iteration;
          }
          @wordglos = $self->{ wn }->querySense($wordsense,"glos");
          $allres{$wordsense}=$wordglos[0];
          $count++;
        }
    }
    else
    {
      my @wordpos= ();
      @wordpos=$self->{ wn }->queryWord($word);
      my $pos;
      my $wordsense;
      my @senses = ();
      my $glos;
      my @wordglos;
      foreach $pos (@wordpos)
      {
        while (Gtk2->events_pending)
        {
          Gtk2->main_iteration;
        }
        @senses = $self->{ wn }->queryWord($pos);
        foreach $wordsense (@senses)
        {
          while (Gtk2->events_pending)
          {
            Gtk2->main_iteration;
          }
          @wordglos = $self->{ wn }->querySense($wordsense,"glos");
          $allres{$wordsense}=$wordglos[0];
          $count++;
        }
      }
    }
    if ($count > 0)
    {
      return \%allres;
    }
    else
    {
      return -1;
    }
  }
}

=item  $obj->find_allsenses

Parameter: The word(String) for which we are searching the senses.

Return value: A array of all the senses of this word found in WordNet.

=cut

sub find_allsenses
{
  my ($self, $word)=@_;
  my @temp = split '#',$word;
  my $wordlevel = $#temp+1;
  my $pos;
  my @wordsenses = ();
  my @wordsense;
  if($wordlevel==1)
  {
    @temp=$self->{ wn }->queryWord($word);
    foreach $pos (@temp)
    {
      @wordsense=$self->{ wn }->queryWord($pos);
      push (@wordsenses, @wordsense);
      @wordsense = ();
    }
  }
  elsif($wordlevel==2)
  {
    @wordsenses = $self->{ wn }->queryWord($word);
  }
  else
  {
    $wordsenses[0]=$word
  }
  return @wordsenses;
}



=item  $obj->find_allsyns

Parameter: The word(String) for which we are searching the synonyms.

Return value: A array of all the senses of this word found in WordNet.

=cut

sub find_allsyns
{
  my ($self, $word)=@_;
  my @syns1 = $self->{ wn }->querySense($word,"syns");
  return @syns1;
}

1;
__END__

=head2 Discussion

=back

This module provides an interface to WordNet::Querydata. It implements functions
that take a word as argument and return all the senses of this word listed in
WordNet. It also implements a function that returns a hash containing all the
senses of  the word and the glosses for these senses.

=head1 SEE ALSO

WordNet::QueryData

=head1 AUTHOR

Saiyam Kohli, University of Minnesota, Duluth
kohli003@d.umn.edu

Ted Pedersen, University of Minnesota, Duluth
tpederse@d.umn.edu


=head1 COPYRIGHT

Copyright (c) 2005-2006, Saiyam Kohli and Ted Pedersen

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at <http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut