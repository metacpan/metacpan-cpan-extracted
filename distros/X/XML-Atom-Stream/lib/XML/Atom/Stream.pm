package XML::Atom::Stream;

use strict;
our $VERSION = '0.11';

use Carp;
use LWP::UserAgent;
use HTTP::Request;
use XML::SAX::ParserFactory;
use XML::LibXML::SAX;

sub new {
    my($class, %param) = @_;
    my $self = bless \%param, $class;
    $self->init();
    $self;
}

sub init {
    my $self = shift;
    $self->{ua} ||= LWP::UserAgent->new(
        agent => "XML::Atom::Stream/$VERSION",
        timeout => $self->{timeout} || 15,
    );
    $self->{callback} or Carp::croak("no callback specified.");
}

sub _setup_parser {
    my $self = shift;
    my $handler = XML::Atom::Stream::SAXHandler->new;
       $handler->{callback} = $self->{callback};
       $handler->{debug}    = $self->{debug};
    local $XML::SAX::ParserPackage = "XML::LibXML::SAX::Better";
    my $factory = XML::SAX::ParserFactory->new;
    my $parser  = $factory->parser(Handler => $handler);
    return $parser;
}

sub connect {
    my($self, $url) = @_;
    $url or Carp::croak("URL needed for connect()");

    $self->{parser} = $self->_setup_parser;
    $self->{ua}->get($url, ':content_cb' => sub { $self->on_content_cb(@_) });

    if ($self->{debug}) {
        warn "Disconnected.", $@ ? " ($@)" : "";
    }

    if ($self->{reconnect} && (!$self->{__exception} || $self->{__exception} =~ /xmlParse/)) {
        warn "Trying to reconnect" if $self->{debug};
        delete $self->{__exception};
        $self->connect($url);
    }
}

sub on_content_cb {
    my($self, $data, $res, $proto) = @_;
    warn ".\n" if $data =~ /<time>/ && $self->{debug};
    eval { $self->{parser}->parse_chunk($data) };
    if ($@) {
        $self->{__exception} = $@;
        die $@;
    }
}

package XML::Atom::Stream::SAXHandler;
use XML::Atom::Feed;
use XML::Handler::Trees;
use base qw( XML::Handler::Tree );

sub start_element {
    my $self = shift;
    my($ref) = @_;
    return if $ref->{LocalName} eq 'time' || $ref->{LocalName} eq 'atomStream';

    if ($ref->{LocalName} eq 'sorryTooSlow') {
        warn "You're too slow and missed ", $ref->{Attributes}->{'{}youMissed'}->{Value}, " entries"
            if $self->{debug};
        return;
    }

    if ($ref->{LocalName} eq 'feed') {
        $self->{Curlist} = [];
    }
    $self->SUPER::start_element(@_);
}

sub end_element {
    my $self = shift;
    my($ref) = @_;

    $self->SUPER::end_element(@_);
    if ($ref->{LocalName} eq 'feed') {
        my $element = $self->{Curlist};
        my $xml = qq(<?xml version="1.0" encoding="utf-8"?>\n);
        my %ns;
        my $dumper;
        $dumper = sub {
            my($ref) = @_;
            my($elem, $stuff) = splice @$ref, 0, 2;
            if ($elem eq '0') {
                $xml .= encode_xml($stuff);
            }
            elsif ($elem =~ /^\{(.*?)\}([\w\-]+)$/) {
                my($xmlns, $tag) = ($1, $2);
                my $attr = shift @$stuff;
                $xml .= qq(<$tag);

                my $has_xmlns;

                # extract and replace xmlns declarations
                for my $key (keys %$attr) {
                    if ($key =~ m!^\{http://www\.w3\.org/2000/xmlns/\}([\w\-]+)$!) {
                        my $uri   = delete $attr->{$key};
                        $ns{$uri} = $1;
                        $attr->{"xmlns:$1"} = $uri;
                    }
                }

                for my $key (keys %$attr) {
                    my $attr_key;
                    if ($key =~ /^\{(.*?)\}(\w+)$/) {
                        my($xmlns, $prefix) = ($1, $2);
                        my $ns = $ns{$xmlns} || 'xml'; # xml:lang
                        $attr_key = "$ns:$prefix";
                    } else {
                        $attr_key  = $key;
                        $has_xmlns = 1 if $key eq 'xmlns';
                    }

                    $xml .= qq( $attr_key=") . encode_xml($attr->{$key}) . qq(");
                }

                $xml .= qq( xmlns="$xmlns") if $xmlns ne 'http://www.w3.org/2005/Atom' && !$has_xmlns;

                if (@$stuff) {
                    $xml .= ">";
                    $dumper->($stuff);
                    $xml .= "</$tag>";
                } else {
                    $xml .= "/>";
                }
            }
            $dumper->($ref) if @$ref;
        };
        $dumper->($element);
        my $feed = eval { XML::Atom::Feed->new(Stream => \$xml) };
        $dumper = 0; # to avoid memory leak
        if ($@) {
            warn "Feed parse error: $@" if $self->{debug};
            return;
        }

        $self->{callback}->($feed);
    }
}

my %Map = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;',
           '\'' => '&apos;');
my $RE = join '|', keys %Map;

sub encode_xml {
    my($str, $no_cdata) = @_;
    if (!$no_cdata && $str =~ m/
        <[^>]+>  ## HTML markup
        |        ## or
        &(?:(?!(\#([0-9]+)|\#x([0-9a-fA-F]+))).*?);
                 ## something that looks like an HTML entity.
        /x) {
        ## If ]]> exists in the string, encode the > to &gt;.
        $str =~ s/]]>/]]&gt;/g;
        $str = '<![CDATA[' . $str . ']]>';
    } else {
        $str =~ s!($RE)!$Map{$1}!g;
    }
    $str;
}

# from http://code.sixapart.com/svn/djabberd/trunk/dev/xml-test.pl
package XML::LibXML::SAX::Better;
use strict;
use XML::LibXML;
use XML::SAX::Base;
use base qw(XML::SAX::Base);

sub new {
    my ($class, @params) = @_;
    my $inst = $class->SUPER::new(@params);

    my $libxml = XML::LibXML->new;
    $libxml->set_handler( $inst );
    $inst->{LibParser} = $libxml;

    # setup SAX.  1 means "with SAX"
    $libxml->_start_push(1);
    $libxml->init_push;

    return $inst;
}

sub parse_chunk {
    my ( $self, $chunk ) = @_;
    my $libxml = $self->{LibParser};
    my $rv = $libxml->push($chunk);
}

sub finish_push {
    my $self = shift;
    return 1 unless $self->{LibParser};
    my $parser = delete $self->{LibParser};
    return eval { $parser->finish_push };
}


# compat for test:

sub _parse_string {
    my ( $self, $string ) = @_;
#    $self->{ParserOptions}{LibParser}      = XML::LibXML->new;
    $self->{ParserOptions}{LibParser}      = XML::LibXML->new()     unless defined $self->{ParserOptions}{LibParser};
    $self->{ParserOptions}{ParseFunc}      = \&XML::LibXML::parse_string;
    $self->{ParserOptions}{ParseFuncParam} = $string;
    return $self->_parse;
}

sub _parse {
    my $self = shift;
    my $args = bless $self->{ParserOptions}, ref($self);

    $args->{LibParser}->set_handler( $self );
    $args->{ParseFunc}->($args->{LibParser}, $args->{ParseFuncParam});

    if ( $args->{LibParser}->{SAX}->{State} == 1 ) {
        croak( "SAX Exception not implemented, yet; Data ended before document ended\n" );
    }

    return $self->end_document({});
}

package XML::Atom::Stream;

1;
__END__

=head1 NAME

XML::Atom::Stream - A client interface for AtomStream

=head1 SYNOPSIS

  use XML::Atom::Stream;

  my $url = "http://updates.sixapart.com/atom-stream.xml";

  my $client = XML::Atom::Stream->new(
      callback  => \&callback,
      reconnect => 1,
      debug     => 1,
      timeout   => 30,
  );
  $client->connect($url);

  sub callback {
      my($atom) = @_;
      # $atom is a XML::Atom::Feed object
  }

=head1 DESCRIPTION

XML::Atom::Stream is a consumer of AtomStream. It connects to Atom
stream, the never ending Atom feed and parses the feed by SAX pull
parser. Whenever it retrieves a new feed, your callback function will
be invoked.

=head1 METHODS

=over 4

=item new

  my $client = XML::Atom::Stream->new(
      callback  => \&callback,
      reconnect => 1,
      debug     => 1,
  );

Creates a new XML::Atom::Stream instance.

=over 8

=item callback

Callback reference to handle new Atom feed. Callback function will
receive only one parameter, XML::Atom::Feed object. You can abort the
connection by throwing an exception (die) inside the callback.

=item reconnect

Whether to do automatic reconnection when the SAX parser fails to
parse the stream data, or the connection gets disconnected. Note that
if you abort the connection by dying inside the callback, it won't
reconnect. Defaults to 0.

=item timeout

timeout variable which is passed to LWP::UserAgent. Defaults to 15.

=item ua

an object of LWP::UserAgent or its subclass to use to connect to the
Atom stream. Optional and by default it tries to create its own
LWP::UserAgent object.

=item debug

Whether to display debug messages. Defaults to 0.

=back

=item connect

  $client->connect($url);

Connects to the Atom stream URL and waits for the incoming feeds.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt> with tips from
Benjamin Trott and Brad Fitzpatrick.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Atom>,
L<XML::Atom::Filter>,
http://www.livejournal.com/users/brad/2143713.html

=cut
