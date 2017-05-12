package WWW::Comix::Plugin;
use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );
use Path::Class qw( dir file );
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;

has its_agent => (
   lazy      => 1,
   default   => \&get_an_agent,
   predicate => 'has_agent',
   reader    => 'get_its_agent',
   writer    => 'set_agent',
);

has directory => (
   is        => 'rw',
   lazy      => 1,
   default   => '.',
   predicate => 'has_directory',
);

has comic => (
   is       => 'rw',
   required => 1,
);

# The real core you need to implement in subclasses
sub get_available_ids {
   croak 'derived classes MUST implement get_available_ids()';
}

sub id_to_uri {
   croak 'derived classes MUST implement method id_to_uri()';
}

sub probe {
   croak 'derived classes MUST implement method id_to_uri()';
}

# What comes for free

{ # Handle plugin-specific configurations
   my %config_for;

   sub BUILD {
      my $self = shift;
      my $args = shift;

      $self->probe() if $args->{probe};

      return;
   } ## end sub BUILD

   sub set_config {
      my $sp = shift;
      my %cfg = @_ == 1 ? %{$_[0]} : @_;
      $config_for{$sp->get_name()} = \%cfg;
      return;
   }

   sub get_config {
      my $sp = shift;
      my %args = @_;

      $sp->probe() if $args{probe};

      my $name = $sp->get_name();
      my $rval = $config_for{$name}
         or croak "plugin $name: didn't probe, no configuration";

      return $rval unless wantarray();
      return %$rval;
   }

   sub get_comics_list {
      my $sp = shift;
      my %cfg = $sp->get_config(@_);
      return keys %cfg;
   } ## end sub get_comics_list

   sub is_ok {
      my $self = shift;
      my $config = $self->get_config(); # croaks if...
      return exists $config->{$self->get_comic()};
   }
}

sub get_name {   # By default, the name is derived from the package
   (my $name = ref($_[0]) || $_[0])=~ s{.*::}{}mxs;
   return $name;
}

sub get_priority { return 100 }  # default priority

sub get_agent {    # This can be called both as class and instance method
   my $self = shift;
   return $self->get_its_agent() if ref $self;
   return $self->get_an_agent();
}

sub get_http_response {
   my $self = shift;
   return $self->get_agent()->get(_get_uri($self, @_));
}

sub get_current_id { return $_[0]->get_id_iterator()->(); }

sub get_id_iterator {
   my $self = shift;
   my @ids  = $self->get_available_ids();
   return sub { return shift @ids; };
}

sub get { return _get(@_)->content(); }

sub getstore {
   my $res  = _get(@_);
   my $self = shift;

   my $filename = $self->get_filename(@_, response => $res);
   open my $fh, '>', $filename or croak "open('$filename'): $OS_ERROR";
   binmode $fh;
   print {$fh} $res->content();
   close $fh;

   return $filename;
} ## end sub getstore

sub get_filename {
   my $self = shift;
   my (%args) = @_;

   my $filename =
     exists($args{filename})
     ? $args{filename}
     : $self->guess_filename(%args);

   $filename = $filename->($self, %args) if ref $filename;

   return $filename if file($filename)->is_absolute();

   my $directory =
     exists($args{directory}) ? $args{directory} : $self->get_directory();
   return dir($directory)->file($filename)->stringify();
} ## end sub get_filename

sub guess_filename {
   my $self = shift;
   my %args = @_;

   my $response = $args{response}
     or croak "can't guess a filename without a HTTP::Response";

   my $filename;
   if (my $disp = $response->header('Content-Disposition')) {
      ($filename) = $disp =~ m{
         ; \s* filename \s* = \s* (
               " (?: \\. | [^"])* "
            |    [^"][^;]*
         )
      }mxs;
      if (defined $filename) {
         $filename =~ s/\\(.)/$1/g;
         $filename =~ s/\A " | " \z//g;
      }
   } ## end if (my $disp = $response...

   if (!defined $filename) {
      require URI;
      $filename = URI->new(_get_uri($self, @_))->path();
   }

   return $self->normalise_filename(%args, filename => $filename);
} ## end sub guess_filename

sub normalise_filename {
   my $self = shift;
   my %args = @_;

   my $filename = $args{filename}
     or croak "can't normalise a filename without a filename";

   if ($filename !~ m{\. (?: jpe?g | png | gif ) \z}imxs) {
      my $extension = $self->guess_file_extension(%args);
      $filename =~ s/\.\w+\z//mxs;
      $filename .= '.' . lc($extension);
   }
   $filename =~ s/jpeg\z/jpg/mxs;

   require File::Basename;
   $filename = File::Basename::basename($filename);
   $filename = 'image-' . time() . rand(0xFFFF) . $filename
     if substr($filename, 0, 1) eq '.';

   return $filename;
} ## end sub normalise_filename

sub guess_file_extension {
   my $self = shift;
   my %args = @_;

   my $response = $args{response}
     or croak "can't guess file extension without a HTTP::Response";

   if (my ($type) =
      $response->header('Content-Type') =~ m{\A image/ ([\w-]+)}mxs)
   {
      $type =~ s/jpeg\z/jpg/mxs;
      return $type;
   } ## end if (my ($type) = $response...

   # Taken from WWW::Comic::Plugin::_image_format
   my $content = $response->content();
   return 'gif' if $content =~ /\AGIF8[79]a/mxs;
   return 'jpg' if $content =~ /\A\xFF\xD8/mxs;
   return 'png' if $content =~ /\A\x89PNG\x0d\x0a\x1a\x0a/mxs;

   croak q{can't guess type of file, bailing out};
} ## end sub guess_file_extension

sub get_an_agent {
   require WWW::Mechanize;
   my @agents = (
         'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1).',
         'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) '.
         'Gecko/20050718 Firefox/1.0.4 (Debian package 1.0.4-2sarge1)',
         'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.7.5) '.
         'Gecko/20041110 Firefox/1.0',
         'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) '.
         'AppleWebKit/125.5.5 (KHTML, like Gecko) Safari/125.12',
         'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)',
      );
   my $agent = WWW::Mechanize->new(
      agent       => $agents[rand @agents],
      agent       => 'BrowsHer/1.2 (winshaw)',
      autocheck   => 1,
      stack_depth => 2,
      timeout     => 20,
   );
   $agent->env_proxy();
   return $agent;
} ## end sub get_an_agent

sub _get {
   my $self     = shift;
   my $response = $self->get_http_response(@_);
   return $response if $response->is_success();

   my $uri = _get_uri($self, @_); # for croaking below
   croak "error getting '$uri': ", $response->status_line();
} ## end sub _get

sub _get_uri {
   my ($self, %args) = @_;
   my $uri =
     exists($args{id})
     ? $self->id_to_uri($args{id})
     : $self->id_to_uri($self->get_current_id());

   return $uri;
} ## end sub _get_uri

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::Comix::Plugin - base class for plugins in WWW::Comix

=head1 SYNOPSIS

   use WWW::Comix;

   # The constructor for WWW::Comix returns a plugin instance actually
   my $comix = WWW::Comix->new(
      comic => 'whatever',
      probe => 'ok',
      directory => '/path/to/repository',
   );

   # Get current strip and save as 'current.jpg'
   $comix->getstore(filename => 'current.jpg');

   # Iterate over available strips, getting image data
   my $iterator = $comix->get_iterator();
   while (my $id = $iterator->()) {
      my $blob = $comix->get(id => $id);
   }

=head1 DESCRIPTION

This is the real workhorse for WWW::Comix, encapsulating all the logic and
leaving the derived classes to implement only three mandatory methods.

This module, and the plugins shipped with it, is proudly based on
L<Moose>.

=head1 INTERFACE 

You will not need to call a constructor directly, use L<WWW::Comix> to
get a new object. If you already know the name of the plugin you want to
use, just pass it to the L<WWW::Comix/new> method:

   my $comix = WWW::Comix->new(plugin => $plugin, ...);

The available methods are divided by functionality. Anyway, the methods
that you're likely to need are the following:

=over

=item *

L</get_comics_list>

=item *

L</get_available_ids> or L</get_id_iterator>

=item *

L</get> or L</getstore>

=back

All the other methods aren't likely to satisfy any need of yours.

=head2 Accessors

=over

=item B<< get_agent >>

this method can be called either as a class or as an object method. In
the former case, it will give back the return value from L</get_an_agent>,
in the latter it will give back the return value from L</get_its_agent>.

=item B<< get_an_agent >>

get a L<WWW::Mechanize> user agent. This method is used to initialise
the C<agent> member (see below).

=item B<< has_agent >>

=item B<< set_agent >>

=item B<< get_its_agent >>

each plugin has an agent that will be used for actual WWW interactions. It
must support the same interface as L<WWW::Mechanize> (so it will either be
a L<WWW::Mechanize> object, or an object of some derived class).

By default gets an agent invoking L</get_an_agent>. You can tell if an
agent has already been set via the C<has_agent> method; the other two
methods are the normal setter/getter.

=item B<< has_directory >>

=item B<< set_directory >>

=item B<< get_directory >>

the L</getstore> method (see below) will save files inside a directory.

You can tell if a directory has been set with the C<has_directory> predicate
method. When needed, by default it will be set to C<.>.

=item B<< set_status >>

=item B<< is_ok >>

this holds the (boolean) status of the plugin. Each plugin can have its 
idea of what a "wrong" status is.

=item B<< set_comic >>

=item B<< get_comic >>

the comic that this plugin will deal with. You are obliged to pass at least
a comic name during the construction, but you can change your mind later.
Note that if you change the comic name to some unsupported comic Bad Things
can happen.

=back

=head2 Information Related

=over

=item B<< get_name >>

get plugin's name.

=item B<< get_priority >>

get plugin's priority. 

The priority is (or can be) used to establish the best provider for any
given comic. The lower the value, the higher the priority.

=item B<< get_comics_list >>

get the list of comics provided by the plugin.

Returns the list of available comics; it has no parameter.

=item B<< get_available_ids >>

get the list of available ids for the configured comic (see
L</set_comic> and L</get_comic>). 

Returns the list of available valid ids for the given plugin/comic; it
has no parameter.

Note that this method is always overriden by the specific plugin.

=item B<< get_id_iterator >>

get an iterator to cycle on all the available ids for the comic.

The iterator is a C<sub> that can be called without parameters to get the
next item in the list. Returns C<undef> once the list is exhausted.

It has no parameters.

=item B<< get_current_id >>

get the id of the latest available strip. This is the same as the first
item in the list returned by L</get_available_ids>, or the item returned
by the first invocation of an iterator taken with L</get_id_iterator>.

Returns a valid identifier for the given plugin/comic. It has no parameters.

=item B<< get_filename >>

get the full path to the file where L</getstore> will save the downloaded
data.

Returns the filename. Accepts the following named parameters:

=over

=item B<< filename >>

the filename to use. If not provided, L</guess_filename> will be called 
to make a reasonable guess.

If this parameter is a reference to a C<sub>, it will be invoked with
a reference to the object and all the available parameters passed
to the L</get_filename> method itself.

=item B<< directory >>

the directory where the file should be saved into. Defaults to what
L</get_directory> says.

=back

=item B<< guess_filename >>

try to figure out a sensible filename for a downloaded strip.

Returns an absolute path to a file. Requires a mandatory named 
parameter C<response>, which should hold
a reference to a L<HTTP::Response> object.

=item B<< normalise_filename >>

try to normalise a file name, e.g. giving it a sensible extension and
ensuring that it will not become a hidden file in some systems.

Accepts the following named parameters:

=over

=item B<< filename >> (mandatory)

the filename to normalise;

=item B<< response >> (mandatory)

a L<HTTP::Response> object associated with the image whose filename you
would like to normalise.

=back

=item B<< guess_file_extension >>

guess filename extension for image file based on the content type or
the image's first data octets.

Returns the guessed file extension, or dies trying. Requires a mandatory
named parameter C<response>, which holds a reference to a L<HTTP::Response>
object.

=item B<< id_to_uri >>

turn a comic id into a URI pointing towards the image file.

Accepts the id as the only parameter (non-named). Returns a URI.

Note that this method has to be overridden in a derived plugin.

=item B<< probe >>

probe the remote site for available comics.

Note that this method has to be overridden in a derived plugin.

=item B<< get_config >>

=item B<< set_config >>

these are actually class methods and not instance methods, and are useful
to set plugin-specific configurations for each comic.

It has to be set to a hash where keys are feature names, and the values can
be anything a plugin deems necessary. The hash is used by 
L</get_comics_list> to return the names of the available features.

C<get_config> returns the hash; depending on the call context (scalar or list),
it does the right thing. Accepts the optional named parameter C<probe>, to
trigger a L</probe> towards the remote site.

C<set_config> accepts either a single reference to a hash, or a list that will
be turned into a hash. Returns nothing.

=item B<< BUILD >>

Not to be used directly.

=back

=head2 Download Related

=over

=item B<< get >>

get the comic or die trying.

Returns a L<HTTP::Response> object if successful, C<croak>s otherwise.

Accepts a named parameter C<id> that is the identifier for the strip to
download; defaults to the id given back by L</get_current_id>.

=item B<< getstore >>

get the comic and saves to file, or die trying.

Accepts the following named parameters:

=over

=item B<< id >>

the identifier for the strip to
download; defaults to the id given back by L</get_current_id>.

=item B<< filename >>

=item B<< directory >>

passed on to L</get_filename> to determine the final filename.

=back


Accepts a name

=item B<< get_http_response >>

get the comic and return what the User Agent gives it back, whatever it is
(i.e. either a L<HTTP::Response> object, or C<undef>).

Accepts a named parameter C<id> that is the identifier for the strip to
download; defaults to the id given back by L</get_current_id>.

=back

=head2 Adding A Plugin

Integrating a new plugin requires that you derive your new module from
L<WWW::Comix::Plugin>, and that you override I<at least> the following
methods:

=over

=item *

L</probe>

=item *

L</get_available_ids>

=item *

L</id_to_uri>

=back

Probing is where you set the available comics, together with any
information you think necessary. The L</probe> method must be regarded
as a class method, and is supposed to set the configuration hash
via L</set_config>. For example, if you already know that your plugin
is going to provide only the two strips C<Foo bars> and B<Baz the Great>,
you could do the following:

   sub probe {
      my $sp = shift; # sp stands for "self or package"
      $sp->set_config(
         'Foo bars' => 'http://foo-bars.example.com/archive/',
         'Baz the Great' => 'http://baz-the-great.example.com/btg/',
      );
      return;
   }

How you're going to use the values is up to you, you can set whatever
you want.

As a general note, if you
foresee that the L</get_available_ids> can be too resource demanding
(e.g. because the whole list is spread over many pages), you should
turn to an iterator-based implementation like this:

   sub get_available_ids {
      my $self = shift;
      my @retval;
      my $it = $self->get_id_iterator();
      while (my $id = $it->()) {
         push @retval, $id;
      }
      return @retval;
   }

   sub get_id_iterator {
      # Override the parent's method here, with a more complicated
      # but less resource-demanding logic.
   }

You can see examples of this in L<WWW::Comix::Plugin::Creators> and
L<WWW::Comix::Plugin::GoComics>.

=head1 DIAGNOSTICS

Some errors can be generated by the Moose system; notably, if you call
the C<new> method without providing the C<comic> parameters, that is
mandatory.

=over

=item C<< derived classes MUST implement %s >>

you're trying to use some plugin that didn't implement all the needed
methods, see L</Adding A Plugin>.

=item C<< plugin %s: didn't probe, no configuration >>

Before asking for available comics, or even get the configurations
specific to some plugin, you have to call L</probe>. You can pass the 
probe parameter to the call, anyway.

=item C<< couldn't get probe page '%s': %s >>

something wrong with the Internet connection, apparently.

=item C<< unhandled comic '%s' >>

the given comic is not supported by this plugin.

=item C<< open('%s'): %s >>

this error can be given back by L</getstore> when trying to open a file
for writing the retrieved image data. The error given back by the
Operating System is reported in the error message.

=item C<< can't guess a filename without a HTTP::Response >>

L</guess_filename> needs at least a C<response> parameter holding a
reference to an L<HTTP::Response> object to work properly.

=item C<< can't normalise a filename without a filename >>

don't try to call L</normalise_filename> without providing a C<filename>
parameter. Ok, it's actually refusing to call your file C<0> actually.

=item C<< can't guess file extension without a HTTP::Response >>

nothing more to say, be sure to include a C<response> parameter holding
a reference to a L<HTTP::Response> object when calling 
L</guess_file_extension> and L</normalise_filename>.

=item C<< can't guess type of file, bailing out >>

L</guess_file_extension> (which is called by L</normalise_filename>)
couldn't determine a suitable file extension for the given image. And
it tries hard.

=item C<< error getting '%s': $s >>

either L</get> or L</getstore> had problems downloading the given image.

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
