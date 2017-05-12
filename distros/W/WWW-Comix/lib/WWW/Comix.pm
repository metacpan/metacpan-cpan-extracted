package WWW::Comix;

use version; our $VERSION = qv('0.1.1');

use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );

=for comment
   There is some blur about what "plugin" means here, because you can
   refer to a plugin either by name (and this is what you see from the
   outside) or by package (most operations rely on this in this module).
   To help distinguish the two cases, all package-oriented functions
   are prepended with an underscore, just to mark that these functions
   should remain private here. Caveat emptor.

=cut

use Module::Pluggable require => 1, sub_name => '_unsorted_plugins';

sub new {
   my $package = shift;
   my %args    = @_;

   croak "no comic specified\n"
     unless exists $args{comic} && defined($args{comic});

   if (exists $args{plugin}) {
      my $plugin = _plugin_from_name($args{plugin});
      return $plugin->new(@_);
   }

   for my $plugin (_sorted_plugins()) {
      my $agent = eval { $plugin->new(@_); };
      carp $EVAL_ERROR if $EVAL_ERROR;
      next unless $agent && $agent->is_ok();
      return $agent;
   } ## end for my $plugin (_sorted_plugins...

   croak "comic $args{comic} not available";
} ## end sub new

sub get_plugins {
   my @plugins = map { $_->get_name() } _unsorted_plugins();
   return @plugins if wantarray;
   return \@plugins;
}

sub get_plugins_capabilities {
   my $package = shift;
   my %args    = @_;

   my %comic_for;
   for my $plugin (_unsorted_plugins()) {
      eval {
         $comic_for{$plugin->get_name()} =
           [sort $plugin->get_comics_list(@_)];
      } or carp $EVAL_ERROR;
   } ## end for my $plugin (_unsorted_plugins...

   return %comic_for if wantarray;
   return \%comic_for;
} ## end sub get_plugins_capabilities

sub get_comics_list {
   my $package = shift;

   my %plugin_for;
   for my $plugin (_sorted_plugins()) {
      eval {
         my $plugin_name = $plugin->get_name();
         for my $comic ($plugin->get_comics_list(@_)) {
            push @{$plugin_for{$comic}}, $plugin_name;
         }
         1;
        }
        or carp $EVAL_ERROR;
   } ## end for my $plugin (_sorted_plugins...

   return %plugin_for if wantarray;
   return \%plugin_for;
} ## end sub get_comics_list

sub probe {
   $_[0]->get_plugins_capabilities(probe => 'ok');
}

sub _plugin_from_name {
   my $pack = shift;
   my $name = shift || $pack;
   for (_unsorted_plugins()) {
      return $_ if $name eq $_->get_name();
   }
   croak "no plugin for '$name'";
} ## end sub _plugin_from_name

sub _get_plugins_priorities {    # package-wise
   map { $_ => $_->get_priority() } _unsorted_plugins();
}

sub get_plugins_priorities {     # name-wise
   my %priority_for = _get_plugins_priorities();
   map { $_->get_name() => $priority_for{$_} } keys %priority_for;
}

sub _sorted_plugins {
   my %priority_for = _get_plugins_priorities();
   return
     sort { $priority_for{$a} <=> $priority_for{$b} } _unsorted_plugins();
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

WWW::Comix - programmatically access comics on the web

=head1 VERSION

This document describes WWW::Comix version 0.1.1. Most likely, this
version number here is outdate, and you should peek the source.


=head1 SYNOPSIS

   use WWW::Comix;

   # List of available plugins
   my @available_plugins = WWW::Comix->get_plugins();

   # List of plugins and their comics
   my %comics_for = WWW::Comix->get_plugins_list(probe => 'ok');
   while (my ($name, $comics) = each %comics_for) {
      print {*STDOUT} "$plugin\n";
      print {*STDOUT} "   $_\n" for @$comics;
   }

   # List comics by plugins that provide them, in order of priority
   my %plugins_for = WWW::Comix->get_comics_list(probe => 'ok');
   while (my ($comic, $plugin) = each %plugin_for) {
      print {*STDOUT} $comic, ': ';
      print {*STDOUT} join ', ', @$plugin;
   }

   # So what's the priority of each plugin?
   my %priority_for = WWW::Comix->get_plugins_priorities();

   # Ok, I have a $feature I'm interested into...
   WWW::Comix->probe();
   my $comix = WWW::Comix->new(comic => $feature);
   my $iterator = $comix->get_id_iterator();
   while (my $id = $iterator->()) {
      my $blob = $comix->get(id => $id);
      # ... $blob contains the image data...
   }

   # I'd like to save it immediately, in directory /path/to/comix
   WWW::Comix->probe();  # only one probe is necessary!
   my $comix = WWW::Comix->new(
      comic => $feature, directory => '/path/to/comix');
   my $iterator = $comix->get_id_iterator();
   while (my $id = $iterator->()) {
      my $filename = $comix->getstore(id => $id);
      # filename is somewhat guessed but should be ok most times
      # see docs for ways to set your filename/filename rules
   }


=head1 DESCRIPTION

This modules eases the programmatical access to comic publishing sites.
It deals with the differences in any of them, providing you with an
abstraction layer that hides all the weird bits. New sites can be
added easily by means of its plugin system.

The philosophy, and many ideas, have been taken by the excellent
L<WWW::Comic> by Nicola Worthington. In particular, the idea of
"probing" and the general organisation of the plugins is more or less
the same. Why another module then? The main thing that is lacking in
L<WWW::Comic> is a way to programmatically access the whole list
of available comics in a site.

In particular, L<WWW::Comic> allows you to specify an id for the feature
you're interested into, but when it comes to knowing which ids are
actually available you're on your own. L<WWW::Comix> fills this gap.

This module acts as a front-end towards the various plugins that do
the actual work behind the scenes. To get an "agent" for comic download
you'll need to know - ehr - which comic you're interested into:

   my $comix = WWW::Comix->new(comic => $feature, probe => 'ok');

Whether you need to probe or not depends on your application. If you
already probed before, chances are that you don't need to do that
again.

Every plugin behaves the same, and you should take a look to 
L<WWW::Comix::Plugin> to see the exact behaviour. Anyway, you can
access the list of available ids in basically two manners:

=over

=item B<< $comix->get_available_ids() >>

gives the full list of available comics, and

=item B<< $comix->get_iterator() >>

gives you an iterator, i.e. a sub reference that will give out
an id each time you call it, until there's no more in which case
it will give back C<undef>.

=back

Again, whether it's better for you to use one or another depends
entirely on your application. In general, the B<iterator> way is
safer, because some providers can have very long lists, spread over
many pages, so getting the full list can be heavy. When in doubt,
use the iterator.

Now that you have one (or more) ids, you only have to grab the comics
you need. You can either get the image's data:

   my $blob = $comix->get(id => $id);

or save it directly to a file:

   my $filename = $comix->getstore(id => $id);

Plugins (should) do their best to guess the filename correctly, but
you can get in the loop anyway:

   $comix->getstore(id => $id, filename => 'whatever.png');

By default, C<getstore> saves in the current directory, but you can
provide a C<directory> parameter to the constructor, or set it later:

   my $comix = WWW::Comix->new(
      comic     => $feature, 
      probe     => 'ok',
      directory => '/path/to/somewhere',
   );
   $comix->set_directory('/path/to/somewhere/else');

See L<WWW::Comix::Plugin> if you need more flexibility.

=head2 An Important Note

Beware that there's a difference between the tool and using the tool.

Whether you're allowed to use this module, and the tools that come with
it, is entirely up to you. This collection of modules gives you a
framework for accessing comics programmatically, shaping it around a
metaphor that proves to be effective in the most popular comics sites.

On the other hand, the fact that these pieces of software are there
does not mean that you're allowed to use them. You should peruse the
documentation of every and each site before deciding that you can
use it; moreover, when you do it you understand that you'll be the
sole responsible. In poor's man words, if the rules of the particular
site say that you're not allowed to systematically download features,
or access the site with anything different from a web browser, than
you should either get permissions or refrain from using the module.
Note that I don't even support the idea that this module, and the tools
that come with it, can be regarded as a browser.

If you're even in doubt about your possibility to use it, chances are
that you're not allowed to do, so I urge you B<NOT> to use it. See also
the L</DISCLAIMER OF WARRANTY> and L</NEGAZIONE DELLA GARANZIA>.


=head1 INTERFACE 

All the following subs are package methods, so you should invoke them
using the object-oriented style.

=over

=item B<< new >>

get a handler to some object capable of dealing with a specific comic.

Returns a reference if successful, croaks otherwise.

Arguments include:

=over

=item B<< comic >> (mandatory)

the comic you want to interact with;

=item B<< plugin >> (optional)

the plugin you want to use. Usually, WWW::Comix will try to find out
the best plugin for handling a specific comic, but you might want to
override its choice.

=item B<< probe >> (optional)

request the plugins to probe the respective web pages;

=item I<< any other >>

all other parameters are passed to the actual plugin constructor,
see the relevant page for any additional information.

=back

=item B<< probe >>

command a probing on all available plugins. This means that each of them
will likely access the site it's bound to in order to retrieve the relevant
information about available comics.

Does not return anything meaningful. Does not need any parameter.

=item B<< get_plugins >>

get the list of available plugins.

Returns the list of plugins in list context, a reference to an array
with the list in scalar context. Does not need parameters.

This method is independent of the probing status.

=item B<< get_plugins_priorities >>

get the priority associated to each plugin.

Each plugin is associated to a priority. The lower the priority, the first
the plugin is tried in a quest to find out who deals with a specific
feature. The rationale is that many sites have overlaps on the comics
they offer, but some might offer a longer archive (hence a better
priority).

Each plugin "publishes" its priority, so this is actually nothing you
have to worry about: it's all done automatically.

In list context,
returns a hash with the associations between the plugin names and their
priorities. Returns a reference to the hash in scalar context. Does not
need parameters.

=item B<< get_plugins_capabilities >>

get the comics that each plugin is capable of providing.

Returns a hash with the plugin names as keys, and a reference to an array
with the supported comics as values, in list context. Returns a reference
to the hash in scalar context.

Most likely, you
will need to have L</probe>d before, or you have to specify the C<probe>
parameter to get meaningful results, but it might depend on the
particular feature you're interested into (and in the particular plugin that
is able to handle the feature itself).

=item B<< get_comics_list >>

get the list of all supported comics, with the plugins that are able
to provide them.

This is some counterpart to L</get_plugins_capabilities>. For each comic,
a list of the available providers is established, where "better" plugins
(in the sense of better priorities) come first.

In list context, 
returns a hash with the comic names as keys, and an array reference to the
providers for each of them as values. Returns a reference to the hash in
scalar context.

Most likely, you
will need to have L</probe>d before, or you have to specify the C<probe>
parameter to get meaningful results, but it might depend on the
particular feature you're interested into (and in the particular plugin that
is able to handle the feature itself).

=back

=head1 DIAGNOSTICS

As a rule of thumb, every time there's an error you will get an
exception. Exceptions are thrown with C<croak>, warnings with C<carp>.

=head2 Exceptions

This module generates the following exceptions (be sure to look into
the sub-modules for other exceptions):

=over

=item C<< no comic specified >>

you must provide a C<comic> parameter to the L</new> constructor method.

=item C<< comic %s not available >>

sorry, it's not your lucky day. Try to double-check the comic name, and
to see if it matches the name of the comic in a specific site.

You can use L</get_comics_list> to get a list of all supported comics.

=item C<< no plugin for '%s' >>

in the L</new> method, you tried to ask for a specific plugin, but it
is not supported.

=back

=head2 Warnings

In some cases, exceptions thrown by a particular plugin could be
catched and given as warnings. For example, in the search for a plugin
capable of providing a specific comic, an error in a plugin is ignored,
in the hope that some other plugin will be able to take care of the
comic itself.


=head1 CONFIGURATION AND ENVIRONMENT

WWW::Comix requires no configuration files or environment variables.


=head1 DEPENDENCIES

The dependencies here are for the general WWW::Comix system:

=over

=item *

HTML::Entities

=item *

HTML::LinkExtor

=item *

Module::Pluggable

=item *

Moose

=item *

Moose::Policy

=item *

Path::Class

=item *

Readonly

=item *

URI

=item *

version

=item *

WWW::Mechanize

=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/


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
