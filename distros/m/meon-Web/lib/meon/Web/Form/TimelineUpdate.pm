package meon::Web::Form::TimelineUpdate;

use meon::Web::Util;
use meon::Web::TimelineEntry;
use meon::Web::XML2Comment;
use Path::Class 'dir';

use utf8;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form-timeline-update');
has '+widget_wrapper' => ( default => 'Bootstrap' );
has '+enctype' => ( default => 'multipart/form-data');
sub build_form_element_class { ['form-horizontal'] };

has_field 'category'     => (
    type => 'Select', required => 1, label => 'Category',
);

has_field 'title'     => (
    type => 'Text', required => 1, label => 'Title',
    element_attr => { placeholder => 'title or a short message' }
);

has_field 'intro'     => (
    type => 'TextArea', required => 0, label => 'Introduction',
    rows => '3',
    element_attr => { placeholder => 'short text or introduction' }
);

has_field 'text'     => (
    type => 'TextArea', required => 0, label => 'Body text',
    element_attr => { placeholder => 'long text' }
);

has_field 'image'     => (
    type => 'Upload', required => 0, label => 'Image',
);

has_field 'attachment'     => (
    type => 'Upload', required => 0, label => 'File Upload',
    max_size => 1024*10_000,
);

has_field 'link'     => (
    type => 'Text', required => 0, label => 'Web Link',
    element_attr => { placeholder => 'http://' }
);

has_field 'source_link'     => (
    type => 'Text', required => 0, label => 'Source Link',
    element_attr => { placeholder => 'http://' }
);

has_field 'audio'     => (
    type => 'Text', required => 0, label => 'Audio Widget Code',
    element_attr => { placeholder => '&lt;iframe … &gt;' }
);

has_field 'video'     => (
    type => 'Text', required => 0, label => 'Video Widget Code',
    element_attr => { placeholder => '&lt;iframe … &gt;' }
);

has_field 'quote_author'     => (
    type => 'Text', required => 0, label => 'Author',
    element_attr => { placeholder => 'author name' }
);

has_field 'submit' => (
    type => 'Submit',
    value => 'Post',
    element_class => 'btn btn-primary',
);

sub entry_fields {
    return qw(category title intro text image attachment link source_link audio video quote_author);
}

sub submitted {
    my $self = shift;

    my $c = $self->c;
    my %fields = map {
        $_ => $self->field($_)->value
    } $self->entry_fields;
    my $comment_to_uri = $c->stash->{back_link};
    my $comment_to;
    if ($comment_to_uri) {
        $fields{category} = 'comment';
        $comment_to = meon::Web::XML2Comment->new(
            path => $comment_to_uri,
        );
    }

    for my $upload_name (qw(image attachment)) {
        next unless defined $fields{$upload_name};
        $fields{$upload_name} = $c->req->upload($upload_name);
    }

    my $timeline_path = $self->get_config_text('timeline');
    my $timeline_full_path = dir(meon::Web::Util->full_path_fixup($timeline_path));
    my $entry = meon::Web::TimelineEntry->new(
        timeline_dir => $timeline_full_path,
        author       => $c->user->username,
        (
            map {
                my $val = $fields{$_};
                (defined($val) ? ($_ => $val) : ()),
            } ($self->entry_fields)
        ),
        (defined($comment_to) ? (comment_to => $comment_to)  : ()),
    );
    $entry->create;

    $self->redirect($comment_to_uri // $timeline_path);
}

sub options_category {
    my $self = shift;

    my $xpc = meon::Web::Util->xpc;
    my $form_config = $self->config;
    my @options = map {
        +{ value => $_->getAttribute('value'), label => $_->textContent },
    } $xpc->findnodes('w:category/w:option',$form_config);
    return \@options
        if @options;

    return [
        { value => 'news',     label => "News" },
        { value => 'thought',  label => "Thought" },
        { value => 'question', label => "Question" },
    ];
}

no HTML::FormHandler::Moose;

1;
