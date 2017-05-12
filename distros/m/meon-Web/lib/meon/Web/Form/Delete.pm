package meon::Web::Form::Delete;

use Digest::SHA qw(sha1_hex);
use meon::Web::XML2Comment;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form-delete');
#has '+widget_wrapper' => ( default => 'Bootstrap' );
sub build_form_element_class { ['form-horizontal'] };

has_field 'yes_delete' => ( type => 'Checkbox', required => 1, label => 'Yes delete' );
has_field 'submit'   => ( type => 'Submit', value => 'Delete', );

sub submitted {
    my $self = shift;

    my $redirect = $self->get_config_text('redirect');
    my $xml = meon::Web::env->xml;
    my $xpc = meon::Web::env->xpc;

    my ($parent_el) = $xpc->findnodes('//w:timeline-entry/w:parent');
    if ($parent_el) {
        my $parent_path = $parent_el->textContent;
        my $comment_to = meon::Web::XML2Comment->new(
            path => $parent_path,
        );
        $comment_to->rm_comment(meon::Web::env->current_path);
    }
    my ($image_el) = $xpc->findnodes('//w:timeline-entry/w:image');
    if ($image_el) {
        meon::Web::env->current_dir->file($image_el->textContent)->remove;
    }
    my ($attachment_el) = $xpc->findnodes('//w:timeline-entry/w:attachment');
    if ($attachment_el) {
        meon::Web::env->current_dir->file($attachment_el->textContent)->remove;
    }

    meon::Web::env->xml_file->remove();
    $self->redirect($redirect);
}

no HTML::FormHandler::Moose;

1;
