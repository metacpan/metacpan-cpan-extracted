package meon::Web::Form::FileUpload;

use File::Copy 'copy';

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form-file-upload');
has '+widget_wrapper' => ( default => 'Bootstrap' );
has '+enctype' => ( default => 'multipart/form-data');
#sub build_form_element_class { ['form-horizontal'] };

has_field 'file' => (
    type => 'Upload', required=>1, label => '',
    max_size => 1024*10_000,
);

has_field 'submit' => (
    type => 'Submit',
    value => 'Upload',
    css_class => 'form-row',
);

sub submitted {
    my ($self) = @_;

    my $c = $self->c;
    my $upload = $self->field('file')->value;
    my $upload_to = $self->get_config_folder('upload-to');

    unless (-e $upload_to) {
        $upload_to->mkpath || die 'failed to create archive folder - '.$upload_to;
    }
    copy($upload->tempname, $upload_to->file($upload->filename)) || die 'failed to copy file to archive - '.$!;

    $self->detach;
}

no HTML::FormHandler::Moose;

1;
