package XML::OPML::LibXML::Document;
use strict;
use warnings;
use XML::OPML::LibXML::Outline;

our $AUTOLOAD;

sub new_from_doc {
    my($class, $doc) = @_;
    bless { doc => $doc->documentElement }, $class;
}

sub first_node {
    my($doc, $tag) = @_;
    return $doc->getChildrenByLocalName($tag)->shift;
}

sub head {
    my($self, $elem) = @_;
    my $head = first_node($self->{doc}, 'head') or return;
    my $node = first_node($head, $elem)         or return;
    return $node->textContent;
}

sub outline {
    my $self = shift;
    my $body = first_node($self->{doc}, 'body') or return;
    my @outline = map XML::OPML::LibXML::Outline->new_from_elem($_),
        $body->getChildrenByTagName('outline');
    return wantarray ? @outline : \@outline;
}

sub walkdown {
    my $self = shift;
    my($cb)  = @_;

    my $body = first_node($self->{doc}, 'body') or return;
    my @outline = $body->getChildrenByTagName('outline');

    # eval so callback can die to return immediately
    eval {
        for my $node (@outline) {
            $self->_walk($node, $cb);
        }
    };
}

sub _walk {
    my($self, $node, $cb) = @_;

    # some duplicated code to save memory
    my $outline = XML::OPML::LibXML::Outline->new_from_elem($node);
    $cb->($outline);

    if ($outline->is_container) {
        for my $child ($outline->{elem}->getChildrenByLocalName('outline')) {
            $self->_walk($child, $cb);
        }
    }
}

sub AUTOLOAD {
    my $self = shift;
    (my $elem = $AUTOLOAD) =~ s/.*:://;
    $elem =~ s/_(\w)/uc($1)/eg;
    $self->head($elem);
}

1;

