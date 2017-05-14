package WWWXML::Form;
use strict;
use base 'CGI::FormBuilder';

sub fields_enabled {
    my $self = shift;
    my @fields_enabled = grep { !$_->disabled } $self->fields;
    return wantarray ? @fields_enabled : { map { ($_->name => scalar $_->value) } @fields_enabled };
}

sub fields_invalid {
    my ($self, $invalid_fields) = @_;
    return unless @$invalid_fields;
    $self->field(name => $_, invalid => 1) foreach @$invalid_fields;
    $::logger->debug('Form "' . $self->name . '" contains invalid values for fields: '. join(', ', @$invalid_fields));
}

sub start {
    my $self = shift;

    # append hidden fields required for all forms
    my $form_start = $self->SUPER::start(@_);
    $form_start .= CGI::FormBuilder::htmltag(
        'input',
        name  => 'action',
        type  => 'hidden',
        value => $self->field('action'),
    );
    $form_start .= CGI::FormBuilder::htmltag(
        'input',
        name  => 'submit_action',
        type  => 'hidden',
        value => '',
    );

    return $form_start;
}

sub prepare {
    my $self = shift;
    
    # get prepared template parameters
    my $template_params = $self->SUPER::prepare(@_);

    # add separate per-option fields for checkboxes and radio buttons with no labels
#    foreach my $field (values %{$template_params->{field}}) {
#    
#        if($self->{disabled}) {
#            if(ref($field->{options}) eq 'ARRAY' && ref($field->{value}) eq 'ARRAY') {
#                $field->{options} = $field->{value};
#            }
#        }
#    
        # skip to next unless field is checkbox or radio button and name is a token
#        next
#            unless $field->{options}
#                && ($field->{type} eq 'checkbox' || $field->{type} eq 'radio')
#                && $field->{name} =~ /^\w+$/;
#        for (my $i = $#{$field->{options}}; $i >= 0; --$i) {
            # create temporary field object based on field's properties
#            my @value = $self->field($field->{name});
#            my $field_tmp = $self->new_field(
#                name      => $field->{name} . '_' . $field->{options}->[$i],
#                options   => [ [ $field->{options}->[$i] => '' ] ],
#                values    => [ $field->{values}->[$i] ],
#                value     => [ @value ],
#                disabled  => $field->{disabled} || $self->{disabled},
#                map { ($_ => $field->{$_}) } qw(type cleanopts jsclick multiple required invalid),
#            );
#
            # get tag and replace it's name with field's name (remove option from name)
#            (my $tag = $field_tmp->tag) =~ s/name="\Q$field_tmp->{name}\E"/name="$field->{name}"/;
            # leave only input tag
#            $tag =~ s/^(<[^>]+?>).*$/$1/;
#
            # add field to template parameters
#            $template_params->{field}->{$field_tmp->{name}} = {
#                %$field_tmp,
#                field => $tag,
#            };
#            push @{$template_params->{fields}}, $template_params->{field}->{$field_tmp->{name}};
#        }
#    }

    # mark invalid and required fields with CSS class, rename select to dropdown where needed
    my $is_form_invalid = 0;
    foreach my $field (values %{$template_params->{field}}) {
        if ($field->{invalid}) {
            $is_form_invalid ||= 1;
            $field->{field} =~ s/(<(input|textarea|select)\b[^>]+\bclass="$self->{styleclass}\w+)/$1 $self->{styleclass}_invalid/g;
        }
        if ($field->{required}) {
            $field->{field} =~ s/(<(input|textarea|select)\b[^>]+\bclass="$self->{styleclass}\w+)/$1 $self->{styleclass}_required/g;
        };
        if ($field->{disabled} && $field->{type} =~ /^(text|password|textarea)$/) {
            $field->{field} =~ s/\bdisabled\b/readonly/g;
            $field->{field} =~ s/(<(input|textarea)\b[^>]+\bclass="$self->{styleclass}\w+)/$1 $self->{styleclass}_readonly/g;
        }
        $field->{field} =~ s/\b$self->{styleclass}_$field->{type}\b/$self->{styleclass}_dropdown/g
            if $field->{type} eq 'select' && !$field->{multiple};
    }
    
    push @{$template_params->{submit_error} ||= []}, +{ text => "The highlighted fields are invalid." } if $is_form_invalid;
    return wantarray ? %$template_params : $template_params;
}

sub version {
    # suppress default copyright message (not required by license)
    return '';
}

sub user_param {
    my ($self, $p) = @_;
    $self->{_user_param_} = $p if($p);
    return $self->{_user_param_};
}

sub error {
    my ($self, $e) = (shift, shift);
    push @{$self->{_error_} ||= []}, sprintf($e, @_);
}

sub warn {
    my ($self, $e) = (shift, shift);
    push @{$self->{_warn_} ||= []}, sprintf($e, @_);
}

sub comment {
    my ($self, %c) = @_;
    $self->tmpl_param("field_${_}_comment" => $c{$_}) for keys %c;
}

#sub validate {
#    my $self = shift;
#    if(@_) {
#        $self->{__user_validate__} = [@_];
#    }
#    
#    $::logger->debug("VALIDATE: $self->{__user_validate__}");
#    
#    return 1 unless $self->{__user_validate__};
#    return $self->SUPER::validate(@{$self->{__user_validate__}});
#}

1;
