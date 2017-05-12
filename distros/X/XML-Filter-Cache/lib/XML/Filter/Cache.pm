# $Id: Cache.pm,v 1.3 2002/01/30 12:33:21 matt Exp $

package XML::Filter::Cache;
use strict;

use vars qw($VERSION $AUTOLOAD @ISA);

$VERSION = '0.03';

use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

use Storable ();

sub new {
    my $class = shift;
    my $opts = (@_ == 1) ? { %{shift(@_)} } : {@_};

    $opts->{Class} ||= 'File';
    {
        no strict 'refs';
        eval "require XML::Filter::Cache::$opts->{Class};" 
            unless ${"XML::Filter::Cache::".$opts->{Class}."::VERSION"};
        if ($@) {
            die $@;
        }
    }

    return "XML::Filter::Cache::$opts->{Class}"->new($opts);
}

sub playback {
    my $self = shift;
    $self->open("r");
    while (my $record = $self->_read) {
        my $thawed = Storable::thaw($record);
        $self->_playback($thawed);
    }
    $self->close;
}

sub _playback {
    my ($self, $thawed) = @_;
    my ($method, $structure) = @$thawed;
    my $supermethod = "SUPER::$method";
    $self->$supermethod($structure);
}

sub record {
    my ($self, $event, $structure) = @_;
    my $frozen = Storable::nfreeze([$event, $structure]);
    $self->_write($frozen);
}

sub _read {
    die "Abstract base method _read called";
}

sub _write {
    die "Abstract base method _write called";
}

my @sax_events = qw(
    start_element
    end_element
    characters
    processing_instruction
    ignorable_whitespace
    start_prefix_mapping
    end_prefix_mapping
    start_cdata
    end_cdata
    skipped_entity
    notation_decl
    unparsed_entity_decl
    element_decl
    attribute_decl
    internal_entity_decl
    external_entity_decl
    comment
    start_dtd
    end_dtd
    start_entity
    end_entity
    );

my $methods = '';
foreach my $method (@sax_events) {
    $methods .= <<EOT
sub $method {
    my (\$self, \$param) = \@_;
    \$self->record($method => \$param);
    return \$self->SUPER::$method(\$param);
}
EOT
}
eval $methods;
if ($@) {
    die $@;
}

# Only some parsers call set_document_locator, and it's called before
# start_document. So we keep it in $self, and open the cache in start_document,
# then write out the set_document_locator event
sub set_document_locator {
    my ($self, $locator) = @_;
    $self->{_locator} = $locator;
    $self->SUPER::set_document_locator($locator);
}

sub start_document {
    my ($self, $doc) = @_;
    
    local $self->{Key} = $self->{Key} || $self->{_locator}{SystemId} || die "No cache Key supplied";
    $self->open("w");
    if (my $locator = delete $self->{_locator}) {
        $self->record(set_document_locator => { %$locator });
    }
    $self->record(start_document => $doc);
    $self->SUPER::start_document($doc);
}

sub end_document {
    my ($self, $doc) = @_;
    $self->record(end_document => $doc);
    $self->close();
    $self->SUPER::end_document($doc);
}

1;
__END__

=head1 NAME

XML::Filter::Cache - a SAX2 recorder/playback mechanism

=head1 SYNOPSIS

  use XML::SAX;
  use XML::Filter::Cache;
  use XML::SAX::Writer;
  
  my $writer = XML::SAX::Writer->new;
  my $filter = XML::Filter::Cache->new(
      Handler => $writer,
      Key => "foo.xml",
  );
  my $parser = XML::SAX::ParserFactory->new(Handler => $filter);

  $parser->parse_uri("foo.xml"); # caches

  $filter->playback; # un-caches

=head1 DESCRIPTION

This is a very simple filter module for SAX2 events. By default it caches
events into a big binary file on disk (the cache files are generally much
larger than the original XML at the moment, but I'll work on that), but
the storage backend is pluggable. It uses Storable to do the freeze/thaw
thing, and at the moment this is not pluggin replaceable, simply because
there's no better tool for the task at hand.

There's only one method you need to remember: C<playback>, which will play
the SAX events to the Handler from the cache.

The C<Key> parameter to new() is optional - however if you do not supply it,
your parser B<must> call set_document_locator so that XML::Filter::Cache can
pick up a C<Key> from the SystemId value.

=head1 LICENSE

This is free software, you may use it under the same terms as Perl itself.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org. Please send all bugs to rt.cpan.org, either
via the web interface, or by emailing bug-XML-Filter-Cache@rt.cpan.org

=head1 SEE ALSO

L<XML::Filter::Cache::File>

=cut
