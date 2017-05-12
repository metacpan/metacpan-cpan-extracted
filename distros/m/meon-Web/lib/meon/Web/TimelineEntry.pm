package meon::Web::TimelineEntry;

use meon::Web::Util;
use meon::Web::env;
use meon::Web::SPc;
use DateTime::Format::Strptime;
use File::Copy 'copy';
use Path::Class qw();

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Path::Class;
use 5.010;
use utf8;

has 'xc'           => (is=>'ro', isa=>'XML::LibXML::XPathContext',lazy_build=>1,);
has 'file'         => (is=>'rw', isa=>'Path::Class::File',coerce=>1,lazy_build=>1,predicate=>'has_file');
has 'timeline_dir' => (is=>'rw', isa=>'Path::Class::Dir',coerce=>1,lazy_build=>1);
has 'xml'          => (is=>'rw', isa=>'XML::LibXML::Document', lazy_build => 1);
has 'title'        => (is=>'ro', isa=>'Str',lazy_build=>1,);
has 'created'      => (is=>'rw', isa=>'DateTime',lazy_build=>1,);
has 'author'       => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_author');
has 'intro'        => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_intro');
has 'text'         => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_text');
has 'comment_to'   => (is=>'ro', isa=>'Maybe[Object]',lazy_build=>1,predicate=>'has_parent');
has 'category'     => (is=>'ro', isa=>'Str',lazy_build=>1,);
has 'image'        => (is=>'ro', lazy_build=>1,predicate=>'has_image');
has 'attachment'   => (is=>'ro', lazy_build=>1,predicate=>'has_attachment');
has 'link'         => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_link');
has 'source_link'  => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_source_link');
has 'audio'        => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_audio');
has 'video'        => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_video');
has 'quote_author' => (is=>'ro', isa=>'Maybe[Str]',lazy_build=>1,predicate=>'has_quote_author');

my $strptime_iso8601 = DateTime::Format::Strptime->new(
    pattern => '%FT%T',
    time_zone => 'UTC',
    on_error => 'croak',
);
my $IDENT = ' 'x4;
my $MEON_WEB_NS = "http://web.meon.eu/";

sub _build_file {
    my ($self) = @_;

    my $year  = $self->created->strftime('%Y');
    my $month = $self->created->strftime('%m');
    my $filename = meon::Web::Util->filename_cleanup($self->title);
    while (length($filename) < 5) {
        $filename .= chr(97+rand(26));
    }
    $filename .= ".xml";
    return $self->timeline_dir->subdir($year)->subdir($month)->file($filename);
}

sub _build_timeline_dir {
    my ($self) = @_;

    return $self->file->dir->parent->parent;
}

sub _build_xml {
    my ($self) = @_;

    return XML::LibXML->load_xml(
        location => $self->file
    );
}

sub _build_xc {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc = XML::LibXML::XPathContext->new($xml);
    $xc->registerNs('w', $MEON_WEB_NS);
    $xc->registerNs('x', 'http://www.w3.org/1999/xhtml');
    return $xc;
}

sub _build_title {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc  = $self->xc;
    my ($title) = $xc->findnodes('/w:page/w:content//w:timeline-entry/w:title');
    die 'missing title in '.$self->file
        unless $title;

    return $title->textContent;
}

sub _build_created {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc  = $self->xc;
    my ($created_iso8601) = $xc->findnodes('/w:page/w:content//w:timeline-entry/w:created');
    die 'missing created in '.$self->file
        unless $created_iso8601;
    $created_iso8601 = $created_iso8601->textContent;

    return $strptime_iso8601->parse_datetime($created_iso8601);
}

sub _build_author {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc  = $self->xc;
    my ($author) = $xc->findnodes('/w:page/w:content//w:timeline-entry/w:author');
    return undef unless $author;

    return $author->textContent;
}

sub _build_intro {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc  = $self->xc;
    my ($intro) = $xc->findnodes('/w:page/w:content//w:timeline-entry/w:intro');
    return undef unless $intro;

    return $intro->textContent;
}

sub _build_text {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc  = $self->xc;
    my (undef,$text) = $xc->findnodes('/w:page/w:content//w:timeline-entry/w:text');
    return undef unless $text;

    return $text->textContent;
}

sub _build_category {
    my ($self) = @_;

    my $category;

    if ($self->has_file) {
        my $xml = $self->xml;
        my $xc  = $self->xc;
        ($category) = $xc->findnodes('/w:page/w:content//w:timeline-entry/@category');
    }
    return 'news'
        unless $category;

    return $category->textContent;
}

sub create {
    my ($self) = @_;

    my $created  = DateTime->now(time_zone=>'UTC');
    $self->created($created);
    $created = $created->iso8601;

    my $title      = $self->title;

    my $xml = XML::LibXML->load_xml(string => qq{<?xml version="1.0" encoding="UTF-8"?>
<page
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns="$MEON_WEB_NS"
    xmlns:w="$MEON_WEB_NS"
>

<meta>
    <title/>
    <form>
        <owner-only/>
        <process>Delete</process>
        <redirect>../../</redirect>
    </form>
</meta>

<content><div xmlns="http://www.w3.org/1999/xhtml">

<w:timeline-entry/>

<div class="delete-confirmation"><w:form copy-id="form-delete"/></div>
</div></content>

</page>
});

    $self->xml($xml);
    my $xc  = $self->xc;
    my ($title_el) = $xc->findnodes('/w:page/w:meta/w:title');
    $title_el->appendText($title);
    my ($content_el) = $xc->findnodes('/w:page/w:content/x:div');
    my ($entry_el) = $xc->findnodes('//w:timeline-entry',$content_el);
    $entry_el->setAttribute(category => $self->category);
    $entry_el->appendText("\n");
    appendTextElement($entry_el,'w:created',$created);
    if ($self->has_parent) {
        appendTextElement($entry_el,'w:parent',$self->comment_to->web_uri)
            ->setAttribute('title' => $self->comment_to->title);
    }

    foreach my $el_name (qw(author title intro text image attachment link source_link audio video quote_author)) {
        my $el_has = 'has_'.$el_name;
        appendTextElement($entry_el,'w:'.$el_name,$self->$el_name) if $self->$el_has;
    }

    appendTextElement($entry_el,'w:timeline',"\n$IDENT")->setAttribute('class' => 'comments');
    return $self->store;
}

sub appendTextElement {
    my ($el,$child_name,$child_text) = @_;
    $el->appendText($IDENT);
    my $child = $el->addNewChild($MEON_WEB_NS,$child_name);
    $child->appendText($child_text);
    $el->appendText("\n");
    return $child;
}

sub store {
    my $self = shift;
    my $xml = $self->xml;
    my $file = $self->file;
    my $dir  = $file->dir;
    my $timeline_dir = $self->timeline_dir;

    $dir->mkpath
        unless -e $dir;
    unless (-e $dir->file('index.xml')) {
        $dir->resolve;
        $timeline_dir->resolve;
        my $list_index_file = Path::Class::file(
            meon::Web::SPc->datadir, 'meon-web', 'template', 'xml','timeline-list-index.xml'
        );
        my $timeline_index_file = Path::Class::file(
            meon::Web::SPc->datadir, 'meon-web', 'template', 'xml','timeline-index.xml'
        );
        copy($list_index_file, $dir->file('index.xml')) or die 'copy failed: '.$!;

        while (($dir = $dir->parent) && $timeline_dir->contains($dir) && !-e $dir->file('index.xml')) {
            copy($timeline_index_file, $dir->file('index.xml')) or die 'copy failed: '.$!;
        }
        $dir = $file->dir;
    }

    foreach my $upload_name (qw(image attachment)) {
        my $has = 'has_'.$upload_name;
        next unless $self->$has;
        next unless eval { $self->$upload_name->isa('Catalyst::Request::Upload') };

        my $upload = $self->$upload_name;
        my $upload_filename = $upload->filename;
        my $upload_file = $self->non_existing_filename($dir->file($upload_filename));
        copy($upload->tempname, $upload_file) || die 'failed to copy upload file - '.$!;
        $upload_filename = $upload_file->basename;

        my $xc  = $self->xc;
        my ($el) = $xc->findnodes('//w:timeline-entry/w:'.$upload_name.'/text()', $xml);
        $el->setData($upload_filename);
    }

    $file = $self->non_existing_filename($file);
    $file->spew($xml->toString);
    if ($self->has_parent) {
        my $base_dir = meon::Web::env->content_dir;
        my $path = $file->resolve;
        $path = '/'.$path->relative($base_dir);
        $path =~ s/\.xml$//;
        $self->comment_to->add_comment($path);
    }
}

sub non_existing_filename {
    my ($self,$file) = @_;
    while (-e $file) {
        my $ext = ($file =~ m/\.([^.]+)$/ ? $1 : '');
        if ($file =~ m/^(.+)-(\d{2,})\.$ext/) {
            $file = $1.'-'.sprintf('%02d', $2+1).'.'.$ext;
        }
        else {
            $file = substr($file,0,-1-length($ext)).'-01.'.$ext;
        }
        $file = Path::Class::file($file);
    }
    return $file;
}

sub element {
    my ($self) = @_;

    my $xml = $self->xml;
    my $xc  = $self->xc;
    my ($el) = $xc->findnodes('/w:page/w:content//w:timeline-entry');
    die 'no timeline entry in '.$self->file
        unless $el;

    return $el;
}

__PACKAGE__->meta->make_immutable;

1;
