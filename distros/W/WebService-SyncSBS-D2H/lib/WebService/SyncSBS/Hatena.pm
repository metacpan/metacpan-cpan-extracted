package WebService::SyncSBS::Hatena;

use strict;
require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.03';

use Encode;
use HTTP::Request;
use XML::Atom::Entry;
use XML::Atom::Link;
use XML::Atom::Client;

my $ep_root = 'http://b.hatena.ne.jp/atom';
my $ep_post = $ep_root . '/post';
my $ep_edit = $ep_root . '/edit';
my $ep_feed = $ep_root . '/feed';

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = bless {
	user => $args->{user},
	pass => $args->{pass},
    }, $class;

    $self->{api} = XML::Atom::Client->new;
    $self->{api}->username($self->{user});
    $self->{api}->password($self->{pass});

    return $self;
}

sub get_recent {
    my $self = shift;


    my $ret = {};
    my $feed = $self->{api}->getFeed($ep_feed);
    return $ret unless $feed;
    foreach ($feed->entries) {
	my $href;
	foreach my $link ($_->link) {
	    $href = $link->href if $link->rel eq 'related';
	}

	my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');

	my @tags;
	my $description = $_->summary;

        while ($description =~ /\[([^\]]+)\]/) {
            my $k = $1;
            push(@tags, $k);
            $k =~ s/([^0-9a-zA-Z])/\\$1/g;
            $description =~ s/\[$k\]//;
	}
	unshift(@tags, $_->getlist($dc, 'subject'));

	$ret->{$href} = {
	    url         => $href,
	    title       => $_->title,
	    description => $description,
	    tags        => join(' ', @tags),
	    issued      => $_->issued,
	};
    }

    return $ret;
}

sub createEntry {
    my $self = shift;
    my $ep   = shift;
    my $xml  = shift;

    my $req = HTTP::Request->new(POST => $ep);
    $req->content_type('application/x.atom+xml');
    $xml = Encode::encode('utf8', $xml);
    $req->content_length(length $xml);
    $req->content($xml);
    my $res = $self->{api}->make_request($req);
    return $self->{api}->error("Error on POST $ep: " . $res->status_line)
	unless $res->code == 201;
    $res->header('Location') || 1;
}

sub add {
    my $self = shift;
    my $obj  = shift;

    my(@tag, @notag);
    my $tags = $obj->{tags};
    $tags =~ s/^ +//og;
    $tags =~ s/ +$//og;
    $tags =~ s/ +/ /og;
    foreach my $key (split(' ', $tags)) {
	if (length($key) <= 32) {
	    unless ($key =~ /[\?\/\%\[\]]/) {
		if (scalar(@tag) < 10) {
		    push(@tag, $key);
		    next;
		}
	    }
	}
	push(@notag, $key);
    }
    $tags = join(' ', @tag);
    $tags =~ s/ /\]\[/og;
    $tags = '[' . $tags . ']' if $tags;
    $tags .= ' ' . join(' ', @notag) if scalar(@notag);

    my $url = $obj->{url};
    $url =~ s|"|&quot;|og;

    my $xml = '<?xml version="1.0"?><entry xmlns="http://purl.org/atom/ns#"><title>';
    $xml .= $obj->{title};
    $xml .= '</title><summary>';
    $xml .= $tags.$obj->{description};
    $xml .= '</summary><link type="text/xml" rel="related" href="';
    $xml .= $url;
    $xml .= '"/></entry>';

    $self->createEntry($ep_post, $xml);

    #my $link = XML::Atom::Link->new;
    #$link->href($obj->{url});
    #$link->rel('related');
    #$link->type('text/xml');

    #my $entry = XML::Atom::Entry->new;
    #$entry->title($obj->{title});
    #$entry->summary($tags.$obj->{description});
    #$entry->add_link($link);
    #$self->{api}->createEntry($ep_post, $entry);
}

sub delete {
    my $self = shift;
}

1;
__END__
