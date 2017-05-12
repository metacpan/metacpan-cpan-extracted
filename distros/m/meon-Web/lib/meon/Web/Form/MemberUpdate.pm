package meon::Web::Form::MemberUpdate;

use meon::Web::Util;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form-member-update');
has '+widget_wrapper' => ( default => 'Bootstrap' );
sub build_form_element_class { ['form-horizontal'] };

has 'configured_field_list' => (is=>'ro',isa=>'ArrayRef',lazy_build=>1);

sub _build_configured_field_list {
    my $self = shift;

    my $member = $self->c->member;
    my $xpc = meon::Web::Util->xpc;
    my $form_config = $self->config;
    my @fields = map {
        my $name  = $_->getAttribute('name');
        my $type  = $_->getAttribute('type');
        my $label = $_->getAttribute('label');
        my $multi = $_->getAttribute('multiple');
        my @options;

        if ($type eq 'Select') {
             @options = $xpc->findnodes('w:option',$_);
        }

        (
            $name => {
                type     => $type,
                value    => '',
                required => !!$_->getAttribute('required'),
                default  => $member->get_member_meta($name),
                (defined($label) ? (label => $label) : ()),
                (defined($multi) ? (multiple => $multi) : ()),
                (@options ? (
                    options => [
                        map {+{
                            label => $_->textContent,
                            value => $_->getAttribute('value'),
                        }} @options
                    ],
                ) : ()),
            }
        )
    } $xpc->findnodes('w:fields/w:field',$form_config);
    die 'no fields provided' unless @fields;

    return \@fields;
}

sub field_list {
    my $self = shift;
    return [
        @{$self->configured_field_list},
        submit => {
            type => 'Submit',
            value => 'Update',
            element_class => 'btn btn-primary',
        }
    ];
}

sub submitted {
    my $self = shift;

    my $redirect = $self->get_config_text('redirect');

    my @field_names;
    my @field_list = @{$self->configured_field_list};
    while (@field_list) {
        push(@field_names,shift(@field_list));
        shift(@field_list);
    }

    my $member = $self->c->member;
    foreach my $field_name (@field_names) {
        my $field_value = $self->field($field_name)->value;
        # empty array is like undef
        $field_value = undef
            if ((ref($field_value) eq 'ARRAY') && (@$field_value == 0));

        if (defined $field_value) {
            $member->set_member_meta($field_name, $field_value);
        }
        else {
            $member->delete_member_meta($field_name);
        }
    }
    $member->store;

    $self->redirect($redirect);
}

no HTML::FormHandler::Moose;

1;
