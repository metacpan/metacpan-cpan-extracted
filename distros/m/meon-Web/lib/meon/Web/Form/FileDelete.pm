package meon::Web::Form::FileDelete;

use Digest::SHA qw(sha1_hex);

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form-file-delete');
has '+widget_wrapper' => ( default => 'Bootstrap' );
sub build_form_element_class { ['form-horizontal'] };

has 'file_field_list' => (is=>'ro',isa=>'ArrayRef',lazy_build=>1);

sub _build_file_field_list {
    my $self = shift;

    my $dir = $self->get_config_folder('dir');

    my @fields = map {
        my $label = $_->basename;
        my $name  = sha1_hex($label);
        (
            $name => {
                type     => 'Checkbox',
                name     => $name,
                label    => $label,
            }
        )
    } sort $dir->children(no_hidden => 1);

    return \@fields;
}

sub field_list {
    my $self = shift;
    return [
        @{$self->file_field_list},
        submit => {
            type => 'Submit',
            value => 'Delete selected',
            element_class => 'btn btn-primary',
        }
    ];
}

sub submitted {
    my $self = shift;

    my $redirect = $self->get_config_text('redirect');

    my $dir = $self->get_config_folder('dir');
    foreach my $file ($dir->children(no_hidden => 1)) {
        my $field = $self->field(sha1_hex($file->basename));
        unlink $file
            if $field && $field->value;
    }

    $self->redirect($redirect);
}

no HTML::FormHandler::Moose;

1;
