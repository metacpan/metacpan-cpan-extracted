package WebService::Bloglines::Entries;

use vars qw($VERSION);
$VERSION = 0.09;

use strict;
use Carp;
use Encode;
use XML::RSS::LibXML;
use XML::LibXML;

sub parse {
    my($class, $xml, $liberal) = @_;

    # temporary workaround till Bloglines fixes this bug
    $xml =~ s!<webMaster>(.*?)</webMaster>!encode_xml($1)!eg;

    # okay, Bloglines has sometimes include \xEF in their feeds and
    # that can't be decoded as UTF-8. Trying to fix it by roundtrips
    $xml = Encode::decode_utf8($xml);
    $xml = Encode::encode_utf8($xml);

    my $parser;
    if ($liberal) {
        eval { require XML::Liberal };
        if ($@) {
            croak "XML::Liberal is not installed: $@";
        }
        $parser = XML::Liberal->new('LibXML');
    } else {
        $parser = XML::LibXML->new;
    }

    my $doc    = $parser->parse_string($xml);
    my $rssparent   = $doc->find("/rss")->get_node(0);
    my $channelnode = $doc->find("/rss/channel");
    $rssparent->removeChildNodes();

    my @entries;
    for my $node ($channelnode->get_nodelist()) {
	my $xml = $rssparent->toString();
	my $channel = $node->toString();
	$xml =~ s!<(rss.*?)/>$!<$1>\n$channel\n</rss>!; # wooh
	push @entries, $class->new($xml);
    }
    return wantarray ? @entries : $entries[0];
}

my %Map = ('&' => '&amp;', '"' => '&quot;',
           '<' => '&lt;', '>' => '&gt;',
           '\'' => '&apos;');
my $RE  = join '|', keys %Map;

sub encode_xml {
    my $str = shift;
    $str =~ s!($RE)!$Map{$1}!g;
    $str;
}

sub new {
    my($class, $xml) = @_;
    my $self = bless {
	_xml => $xml,
    }, $class;
    $self->_parse_xml();
    $self;
}

sub _parse_xml {
    my $self = shift;

    my $rss = XML::RSS::LibXML->new();
    $rss->add_module(prefix => "bloglines", uri => "http://www.bloglines.com/services/module");
    $rss->parse($self->{_xml});
    $self->{_rss} = $rss;
}

sub feed {
    my $self = shift;
    return $self->{_rss}->{channel};
}

sub items {
    my $self = shift;
    return wantarray ? @{$self->{_rss}->{items}} : $self->{_rss}->{items};
}

1;

