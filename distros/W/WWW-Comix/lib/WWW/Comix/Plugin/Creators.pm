package WWW::Comix::Plugin::Creators;
use strict;
use warnings;
use Carp;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Readonly;
use URI;

Readonly my $HOST      => 'www.creators.com';
Readonly my $HOMEPAGE  => "http://$HOST/";
Readonly my $PROBEPAGE => "http://$HOST/comics.html";

extends qw( WWW::Comix::Plugin );

sub get_priority { return -1 }

sub probe {
   my $sp    = shift;
   my $agent = $sp->get_agent();          # automatically DWIM
   my $res   = $agent->get($PROBEPAGE);
   croak "couldn't get probe page '$PROBEPAGE': ", $res->status_line()
     unless $res->is_success();

   my @alts = map { quotemeta $_->alt() }
     grep { length $_->alt() }
     $agent->find_all_images(
      url_regex => qr{ /comic_artists/\d+ _index_image\. }mxs);

   my %config_for;
   for my $link (
      $agent->find_all_links(url_regex => qr{ /comics/[\w.-]+\.html }mxs))
   {
      my $name = $link->text();
      for my $alt (@alts) {
         if ($name =~ s{\A $alt \s}{}mxs) {
            $name =~ s/[^\w.'-]\z//mxs;
            $config_for{$name} = $link->url();
         }
      } ## end for my $alt (@alts)
   } ## end for my $link ($agent->find_all_links...
   $sp->set_config(%config_for);

   return;
} ## end sub probe

sub get_available_ids {
   my $iterator = shift->get_id_iterator();
   local $_;
   my @retval;
   push @retval, $_ while $_ = $iterator->();
   return @retval;
} ## end sub get_available_ids

sub get_id_iterator {
   my $self = shift;
   my $wit  = $self->_get_weeks_iterator();
   my $sit  = $self->_get_strip_iterator();    # empty strip iterator
   return sub {
      if (my $next_id = $sit->()) { return $next_id; }
      $sit = $self->_get_strip_iterator($wit->());
      return $sit->();
   };
} ## end sub get_id_iterator

sub _get_strip_iterator {
   my $self = shift;
   my ($week_uri) = @_;
   return sub { return } unless $week_uri;

   my $agent = $self->get_agent();
   $agent->get($HOMEPAGE) unless _agent_on_target($agent);
   $agent->get($week_uri);

   my @strips;
   for my $line (split /\n/, $agent->content()) {
      my ($month, $day, $year, $uri) = $line =~ m{
         \A <div .*?> \s*
         (\d\d)/(\d\d)/(\d\d\d\d) \s*
         <img \s+ src="(.+?)" .*?> 
         .*? ico_zoom\.gif
      }mxs or next;
      push @strips, "$year$month$day $uri";
   }

   return sub { return shift @strips; }
} ## end sub _get_strip_iterator

sub _agent_on_target {
   my $agent = shift;
   my $uri = eval {$agent->uri()} or return;
   my $host = $uri->host() or return;
   return $host eq $HOST;
}

sub _get_weeks_iterator {
   my $self = shift;

   my $config_for = $self->get_config();
   my $comic = $self->get_comic();
   croak "unhandled comic '$comic'" unless exists $config_for->{$comic};

   my $agent = $self->get_agent();
   $agent->get($HOMEPAGE) unless _agent_on_target($agent);
   $agent->get($config_for->{$comic});

   my $URI = URI->new($HOMEPAGE);
   (my $path = $config_for->{$comic}) =~ s{\.html}{/archive.html}mxs;
   $URI->path($path);

   my $form = $agent->form_with_fields('DATE_START')
     or croak "no form with 'DATE_START', bailing out";

   my $input = $form->find_input('DATE_START');
   my @uris  =
     map {
      $URI->query_form(DATE_START => $_);
      $URI->as_string()
     }
     reverse sort grep { length } $input->possible_values();

   return sub { return shift @uris };
} ## end sub _get_weeks_iterator

sub id_to_uri {
   my ($self, $id) = @_;
   my ($date, $uri) = split /\s/, $id, 2;
   return $uri;
}

override guess_filename => sub {
   my $self = shift;
   my %args = @_;

   my ($date, $uri) = split /\s/, $args{id}, 2;
   my $config_for = $self->get_config();
   my ($radix) = $config_for->{$self->get_comic()} =~ m{([\w.-]+)\.html}mxs;
   my $ext = $self->guess_file_extension(%args);
   return "$radix-$date.$ext";
};

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::Comix::Plugin::Creators - WWW::Comix plugin for http://www.creators.com/

=head1 DESCRIPTION

This module is not inteded for direct usage, see
L<WWW::Comix> and L<WWW::Comix::Plugin>.

B<Note>: the L<WWW::Comix::Plugin/get_available_ids> method in this plugin
is particularly heavy (network-wise speaking). You should avoid using it,
and favour the iterator approach.

=head1 DIAGNOSTICS

=over

=item C<< no form with 'DATE_START', bailing out >>

the page format isn't as expected, maybe it's time to update the plugin.

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
