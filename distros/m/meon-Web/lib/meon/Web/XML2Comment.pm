package meon::Web::XML2Comment;

use Moose;
use MooseX::Types::Path::Class;
use 5.010;

use meon::Web::Util;
use Path::Class 'dir';
use Carp 'croak';
use XML::LibXML 'XML_TEXT_NODE';

has 'path' => (is=>'rw',isa=>'Path::Class::File',required=>1,coerce=>1);
has '_full_path' => (is=>'ro',isa=>'Path::Class::File',lazy=>1,builder=>'_build_full_path');
has 'xml'  => (is=>'ro', isa=>'XML::LibXML::Document', lazy => 1, builder => '_build_xml');
has 'title'        => (is=>'ro', isa=>'Str',lazy_build=>1,);

sub _build_xml {
    my ($self) = @_;

    return XML::LibXML->load_xml(
        location => $self->_full_path,
    );
}

sub _build_full_path {
    my ($self) = @_;
    my $path = $self->path;
    $path = $path.'index' if $path =~ m{/$};
    return meon::Web::Util->full_path_fixup($path.'.xml');
}

sub _build_title {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc  = meon::Web::Util->xpc;
    my ($title) = $xc->findnodes('/w:page/w:content//w:timeline-entry/w:title',$xml);
    ($title) = $xc->findnodes('/w:page/w:meta/w:title',$xml)
        unless $title;
    die 'missing title in '.$self->_full_path
        unless $title;

    return $title->textContent;
}

sub web_uri {
    my ($self) = @_;

    my $base_dir = meon::Web::env->content_dir;
    my $path = $self->_full_path;
    $path = '/'.$path->relative($base_dir);
    $path =~ s/\.xml$//;
    return $path;
}

sub add_comment {
    my ($self, $comment_path) = @_;
    croak 'missing comment_path argument'
        unless $comment_path;

    my $xml = $self->xml;
    my $xpc = meon::Web::Util->xpc;
    my ($comments_el) = $xpc->findnodes('/w:page/w:content//w:timeline[@class="comments"]',$xml);
    croak 'comments not allowed'
        unless $comments_el;

    $comments_el->appendText(' 'x4);
    my $entry_node = $comments_el->addNewChild( undef, 'w:timeline-entry' );
    $entry_node->setAttribute('href' => $comment_path);
    $comments_el->appendText("\n".' 'x4);

    IO::Any->spew($self->_full_path, $xml->toString, { atomic => 1 });
}

sub rm_comment {
    my ($self, $comment_path) = @_;
    croak 'missing comment_path argument'
        unless $comment_path;

    return
        unless -e $self->_full_path;

    my $xml = $self->xml;
    my $xpc = meon::Web::Util->xpc;
    my ($comment_el) = $xpc->findnodes('/w:page/w:content//w:timeline[@class="comments"]/w:timeline-entry[@href="'.$comment_path.'"]',$xml);
    return unless $comment_el;

    my $timeline = $comment_el->parentNode;
    my (@whitespaces) =
        grep { $_->nodeType == XML_TEXT_NODE && $_->textContent =~ m/^\s*$/ }
        ($comment_el->previousSibling);
    foreach my $el ($comment_el, @whitespaces) {
        $timeline->removeChild($el);
    }

    IO::Any->spew($self->_full_path, $xml->toString, { atomic => 1 });
}

__PACKAGE__->meta->make_immutable;

1;
