package meon::Web::Form::ImageUpload;

use File::Copy 'copy';
use Imager;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form-image-upload');
has '+widget_wrapper' => ( default => 'Bootstrap' );
has '+enctype' => ( default => 'multipart/form-data');
#sub build_form_element_class { ['form-horizontal'] };

has_field 'file' => ( type => 'Upload', required=>1, label => '');

has_field 'submit' => (
    type => 'Submit',
    value => 'Upload',
    max_size => 1024*4000,
    css_class => 'form-row',
);

sub submitted {
    my ($self) = @_;

    my $c = $self->c;
    my $upload = $self->field('file')->value;
    my $upload_to = $self->get_config_folder('upload-to');
    my $upload_as =
        eval { $self->get_config_text('upload-as') }
        || $upload->filename
    ;
    my $max_width =
        eval { $self->get_config_text('max-width') }
        || 640
    ;
    my $max_height =
        eval { $self->get_config_text('max-height') }
        || 640
    ;
    my $redirect = $self->get_config_text('redirect');

    unless (-e $upload_to) {
        $upload_to->mkpath || die 'failed to create archive folder - '.$upload_to;
    }
    my $img = Imager->new(file => $upload->tempname)
        or die Imager->errstr();
    if ($img->getwidth > $max_width) {
        $img = $img->scale(xpixels => $max_width)
            || die 'failed to scale image - '.$img->errstr;
    }
    if ($img->getheight > $max_height) {
        $img = $img->scale(ypixels => $max_height)
            || die 'failed to scale image - '.$img->errstr;
    }
    $img->write(file => $upload_to->file($upload_as).'') || die 'failed to save image - '.$img->errstr;

    $self->redirect($redirect);
}

no HTML::FormHandler::Moose;

1;
