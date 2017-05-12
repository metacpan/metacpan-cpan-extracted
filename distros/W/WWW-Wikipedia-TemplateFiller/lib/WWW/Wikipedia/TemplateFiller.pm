package WWW::Wikipedia::TemplateFiller;
use warnings;
use strict;

our $VERSION = '0.13';

use WWW::Search;
use Cache::SizeAwareFileCache;
use Carp;

=head1 NAME

WWW::Wikipedia::TemplateFiller - Fill Wikipedia templates with your eyes closed

=head1 SYNOPSIS

  use WWW::Wikipedia::TemplateFiller;

  my $filler = new WWW::Wikipedia::TemplateFiller();

  # Bit by bit
  my $source = $filler->get( pubmed_id => '2309482' )->fill;
  print $source->output;

  # Or all at once
  print $filler->get( pubmed_id => '2309482' )->fill->output;

  # With fill-time options
  $source = $filler->get( pubmed_id => '123456' )->fill( add_url => 1 );
  print $source->output;

  # With output-time (mostly formatting) options
  print $source->output( vertical => 1, add_accessdate => 1 );

=head1 DESCRIPTION

This module generates Wikipedia template markup for various sources of
information such as PubMed IDs, ISBNs, URLs, etc. While it works with
multiple templates, it was predominantly created to lower the
activation energy associated with filling out citation templates.

In writing a Wikipedia article, one aims to cite sufficient
references. The trouble is that there are many different ways of
citing different sources, all with different Wikipedia citation
templates, and many requiring information that may be difficult to
obtain. The initial goal of this module was to streamline the process
of generating citation templates. Sure, the module's grown and it's
been generalized to other templates (Drugbox, etc.), but the
principles persist.

=head1 METHODS

=head2 new

  my $filler = new WWW::Wikipedia::TemplateFiller( %attrs );

Creates a new template filler. Attributes are allowed in C<%attrs>.
These include C<isbndb_access_key>, which is the API key to be used
for making ISBN queries via isbndb.com.

=cut

sub new {
  my( $pkg, %attr ) = @_;
  $attr{__source} = undef;
  $attr{__cache} = new Cache::SizeAwareFileCache( {
    namespace => 'wiki_template_filler',
    default_expires_in => '10 minutes',
    max_size => '1000000'
  } );

  warn "ISBN lookups may be unavailable since isbndb_access_key was not provided to WWW::Wikipedia::TemplateFiller->new()"
    unless $attr{isbndb_access_key};

  return bless \%attr, $pkg;
}

=head2 get

  my $source = $filler->get( $source_type => $id, %attrs );

Grabs the requested data from the net and returns it as a source
object (actually a subclass of
L<WWW::Wikipedia::TemplateFiller::Source>). C<$source_type> is
something like C<pubmed_id>, C<drugbank_id>, C<hgnc_id>, C<isbn>,
etc. It corresponds to a class in the
C<WWW::Wikipedia::TemplateFiller::Source::> namespace.

C<$id> is the corresponding ID, the format of which varies depending
on the value of C<$source_type>. For example, C<$id> is numeric if
C<$source_type> is C<pubmed_id>.

C<%attrs> are additional attributes that are passed to the source
class used to grab the requested data. Consult
L<WWW::Wikipedia::TemplateFiller::Source> for information.

=cut

sub get {
  my( $self, $source_type, $id, %attrs ) = @_;
  die "no source type (eg, pubmed_id, isbn) given" unless $source_type;
  die "no $source_type given" unless $id;
  my $source_class = $self->__load_class( source => $source_type );
  my $source = $source_class->new( %attrs, filler => $self )->get($id);
  return $self->{__source} = $source;
}

=head2 cache

  my $cache = $filler->cache;

Returns the cache associated with this filler.

=cut

sub cache { shift->{__cache} }

sub __load_class {
  my( $pkg, $class_type, $which ) = @_;

  my @classes = $pkg->__to_classes( $class_type => $which );

  foreach my $class ( @classes ) {
    return $class if eval "use $class; 1" or $class->isa($pkg);
  }
  
  croak "Package for '$which' $class_type could not be loaded (tried @classes). Error: $@";
}

sub __to_classes {
  my( $pkg, $class_type, $which ) = @_;

  # Asinine hack for Mac OS X's case-insensitive but case-preserving
  # filesystem - 2009-01-29
  if( $which ) {
    $which = 'URL'  if $which =~ /^url$/i;
    $which = 'ISBN' if $which =~ /^isbn$/i;
  }

  $class_type = ucfirst lc $class_type;
  ( my $oneword = $which ) =~ s/\W/_/g;

  my $template = ref($pkg).'::'.$class_type.'::%s';
  return (
    sprintf( $template, $oneword ),
    $pkg->__type_to_std_class( source => $which ),
    sprintf( $template, uc($oneword) ),
    sprintf( $template, ucfirst($oneword) ),
  );
}

sub __type_to_std_class {
  my( $pkg, $class_type, $which ) = @_;
  $class_type = ucfirst lc $class_type;
  my @words = split /[_\s]/, $which;
  my $camelcase_class = join '', map { ucfirst lc } @words;
  return __PACKAGE__ . '::' . $class_type . '::' . $camelcase_class;
}

=head1 ISBNdb ACCESS

Currently W::W::TF uses ISBNdb (L<http://www.isbndb.com>) for
accessing information about books. This will likely change somewhat in
the future to allow for multiple book databases to be queried. For
now, however, ISBNdb is the only option. If you plan to use this
module for querying book data, then you must supply an ISBNdb access
key.

There are multiple ways to provide an access key. The first is
accomplished by passing a parameter to W::W::TF's new() method:

  use WWW::Wikipedia::TemplateFiller;
  my $tf = new WWW::Wikipedia::TemplateFiller(
    isbndb_access_key => 'your_access_key'
  );

The second method is used by the W::W::TF::WebApp web application.
For this, simply edit the C<%config> hash within the included web
application instance script in cgi/index.cgi. The C<INSTALL> file
provides more details.

The third method is to assign the access key to an environment
variable called C<ISBNDB_ACCESS_KEY>. This is accomplished by doing
something like this in your shell:

  $ export ISBNDB_ACCESS_KEY=your_access_key

(Note that this environment variable-based solution is the only way to
test ISBNdb support during installation.)

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

The distinction between fill() and output() parameters is subtle and
unnecessary. This will be resolved in a future release. In the
meantime, if you find that specifying a parameter in the fill() method
does not achieve the desired results (or has no effect at all), try
specifying it in the output() method instead. And vice versa. I
apologize for this gross aberration.

Please report any bugs or feature requests to
C<bug-www-wikipedia-templatefiller at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Wikipedia-TemplateFiller>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Wikipedia::TemplateFiller

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Wikipedia-TemplateFiller>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Wikipedia-TemplateFiller>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Wikipedia-TemplateFiller>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Wikipedia-TemplateFiller>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
