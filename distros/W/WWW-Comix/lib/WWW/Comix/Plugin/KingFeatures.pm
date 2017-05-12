package WWW::Comix::Plugin::KingFeatures;
use strict;
use warnings;
use Carp;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Readonly;

Readonly my $HOMEPAGE =>
  'http://www.kingfeatures.com/features/comics/comics.htm';
Readonly my $PROBEPAGE =>
  'http://www.kingfeatures.com/features/comics/comicsNav.htm';

extends qw( WWW::Comix::Plugin );

sub get_name { return 'King Features'; }
sub get_priority { return 10 };

sub probe {
   my $sp    = shift;
   my $agent = $sp->get_agent();          # automatically DWIM
   my $res   = $agent->get($PROBEPAGE);
   croak "couldn't get probe page '$PROBEPAGE': ", $res->status_line()
      unless $res->is_success();

   my %config_for;
   for my $line (split /\n/, $res->content()) {
      my ($url, $name) =
         $line =~ m{<a \s+ href="(.+?)" \s+ target="_top"> (.+?) </a>}mxs
         or next;
      $url =~ s/about\.htm/aboutMaina.php/;
      $config_for{$name} = $url;
   } ## end for my $line (split /\n/...
   $sp->set_config(%config_for);

   return;
} ## end sub probe

sub get_available_ids {
   my $self = shift;

   my $config_for = $self->get_config();
   my $comic = $self->get_comic();
   croak "unhandled comic '$comic'" unless exists $config_for->{$comic};
   my $uri  = $config_for->{$comic};

   my $agent = $self->get_agent();
   $agent->get($HOMEPAGE);
   $agent->get($uri);

   my $form = $agent->form_with_fields('date')
     or croak "no form with field 'date' in page '$uri'";

   my $input = $form->find_input('date');
   return
     map { $uri . '?date=' . $_ } reverse sort $input->possible_values();
} ## end sub get_available_ids

sub id_to_uri {
   my ($self, $id) = @_;

   my $agent = $self->get_agent();
   $agent->get($HOMEPAGE);
   $agent->get($id);
   my $image = $agent->find_image(url_regex => qr/date=/mxs);

   return $image->url_abs();
} ## end sub id_to_uri

override guess_filename => sub {
   my $self = shift;
   my %args = @_;
   
   (my $radix = $args{id}) =~ s{ / .* date= }{-}msx;
   my $extension = $self->guess_file_extension(%args);
   return "$radix.$extension";
};

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::Comix::Plugin::KingFeatures - WWW::Comix plugin for http://www.kingfeatures.com/

=head1 DESCRIPTION

This module is not inteded for direct usage, see
L<WWW::Comix> and L<WWW::Comix::Plugin>.

=head1 DIAGNOSTICS

=over

=item C<< no form with field 'date' in page '%s' >>

this is likely an error in the way that the page is constructed, and
it's probably due to a change in the page format.

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
