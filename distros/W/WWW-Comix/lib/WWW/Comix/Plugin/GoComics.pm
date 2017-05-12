package WWW::Comix::Plugin::GoComics;
use strict;
use warnings;
use Carp;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Readonly;
use HTML::Entities qw( decode_entities );
use HTML::LinkExtor;

Readonly my $HOMEPAGE  => 'http://www.gocomics.com';
Readonly my $PROBEPAGE => 'http://www.gocomics.com/features/';
Readonly my $STRIPSURI => 'http://picayune.uclick.com/comics';

extends qw( WWW::Comix::Plugin );

has last_visited => (is => 'rw');

sub get_name     { return 'Go Comics'; }
sub get_priority { return -5 }

sub probe {
   my $sp    = shift;
   my $agent = $sp->get_agent();          # automatically DWIM
   my $res   = $agent->get($PROBEPAGE);
   croak "couldn't get probe page '$PROBEPAGE': ", $res->status_line()
     unless $res->is_success();

   # Encoded with gzip by default! Use decoded_content
   my ($section) = $res->decoded_content() =~ m{
      >Comic \s+ Strips:</h3>
      (.*?)
      <br
   }mxs;

   croak "no section found!" unless defined $section;

   my %config_for;
   for my $line (split /\n/, $section) {
      my ($url, $name) =
        $line =~ m{<a \s+ href="(.+?)" .*? > (.+?) </a>}mxs
        or next;
      $name = decode_entities($name);
      $name =~ s{<.*?>}{ }gmxs;
      $config_for{decode_entities($name)} = $HOMEPAGE . $url;
   } ## end for my $line (split /\n/...
   $sp->set_config(%config_for);

   return;
} ## end sub probe

sub _get_calendar_iterator {
   my ($self, $year, $month, $featureCode, $featureID) = @_;
   my $agent        = $self->get_agent();
   my $calendar_uri = "$HOMEPAGE/features/$featureID/calendar.js";
   return sub {
      return unless $year;

      my $uri = "$calendar_uri?year=$year&month=$month";
      my $res = $agent->get($uri);
      if (! $res->is_success()) {
         carp "couldn't get calendar at '$uri'";
         return;
      }
      my $json = $res->decoded_content();

      # Build up response
      my @uris;
      while (
         $json =~ m{
               "page_url" \s*:\s* 
               "
                  [^"]+ \\/ (\d{4}) \\/ (\d\d) \\/ (\d\d) 
               "
            }gmxs
        )
      {
         my ($y, $m, $d) = ($1, $2, $3);
         my $sy = substr $y, 2;    # last two digits in year
         push @uris, "$STRIPSURI/$featureCode/$y/$featureCode$sy$m$d.gif";
      } ## end while ($json =~ m{ )
      @uris = reverse sort @uris;

      # Prepare for next iteration
      ($year, $month) = ();        # exhausted by default
      if (@uris
         && (my ($previous) = $json =~ m/"previous"\s*:\s*{(.*?)}/mxs))
      {
         ($year)  = $previous =~ m/"year"\s*:\s*(\d+)/mxs;
         ($month) = $previous =~ m/"month"\s*:\s*(\d+)/mxs;
      } ## end if (@uris && (my ($previous...

      return @uris if wantarray;
      return \@uris;
     }
} ## end sub _get_calendar_iterator

sub get_id_iterator {
   my $self  = shift;
   my $agent = $self->get_agent();

   # Get homepage for comic, where data to get calendar lie in javascript
   my $config_for = $self->get_config();
   my $comic = $self->get_comic();
   my $cpage = $config_for->{$comic} or croak "unhandled comic '$comic'";
   my $res   = $agent->get($cpage);
   croak "couldn't get '$comic' page '$cpage': ", $res->status_line()
     unless $res->is_success();

   my ($year, $month, $featureCode, $featureID) =
     $res->decoded_content() =~ m{
         year \s* : \s* (\d+) \s*, \s*
         month \s* : \s* (\d+) \s*, \s*
         .*?
         featureCode \s* : \s* '(.*?)' \s*, \s*
         featureID \s* : \s* (\d+),
     }mxs or croak "could not find calendar data for $comic in '$cpage'";

   my $calendar_iterator =
     $self->_get_calendar_iterator($year, $month, $featureCode,
      $featureID);

   my @uris;
   return sub {
      @uris = $calendar_iterator->() unless @uris;
      return shift @uris;
   };

} ## end sub get_id_iterator

sub get_available_ids {
   my $iterator = shift->get_id_iterator();
   local $_;
   my @retval;
   push @retval, $_ while $_ = $iterator->();
   return @retval;
} ## end sub get_available_ids

sub id_to_uri {
   my ($self, $id) = @_;
   return $id;
} ## end sub id_to_uri

1;    # Magic true value required at end of module
__END__

=head1 NAME

WWW::Comix::Plugin::GoComics - WWW::Comix plugin for http://www.gocomics.com/

=head1 DESCRIPTION

This module is not inteded for direct usage, see
L<WWW::Comix> and L<WWW::Comix::Plugin>.

B<Note>: the L<WWW::Comix::Plugin/get_available_ids> method in this plugin
is particularly heavy (network-wise speaking). You should avoid using it,
and favour the iterator approach.

=head1 DIAGNOSTICS

For each of the following messages, chances are that Go Comics changed
something in their web site.

=over

=item C<< no section found! >>

=item C<< couldn't get '%s' page '%s': %s >>

=item C<< could not find calendar data for %s in '%s' >>

=back


=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.x itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl 5.8.x stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=cut
