package Zapp::Type::SelectBox;
use Mojo::Base 'Zapp::Type', -signatures;
use List::Util qw( any first );
use Mojo::Loader qw( data_section );

# XXX: This cannot be used as task output without default options!
# Should we have a way to configure options in task output, or should we
# have a way to disable types for output?

has default_options => sub { undef };

sub _value_label( $self, $config, $value ) {
    my $option = first { $_->{value} eq $value } $config->{options}->@*;
    return $option->{label} // $value;
}

sub _field_values( $self, $config, $selected_value ) {
    $selected_value //= $config->{options}[ $config->{selected_index} ]{value};
    return [
        map {
            [
                $_->{label}, $_->{value},
                ( selected => 'selected' )x!!( $_->{value} eq $selected_value ),
            ]
        } @{ $config->{options} }
    ];
}

sub _check_value( $self, $options, $value ) {
    $options //= $self->default_options;
    die "Invalid value for selectbox: $value"
        unless any { $_->{value} eq $value } @{$options};
}

# Form value -> Type value
sub process_config( $self, $c, $form_value ) {
    return $form_value;
}

sub process_input( $self, $c, $config_value, $form_value ) {
    $self->_check_value( $config_value->{options}, $form_value );
    return $form_value;
}

# Type value -> Task value
sub task_input( $self, $config_value, $input_value ) {
    $self->_check_value( $config_value->{options}, $input_value );
    return $input_value;
}

# Task value -> Type value
sub task_output( $self, $config_value, $task_value ) {
    $self->_check_value( $config_value->{options}, $task_value );
    return $task_value;
}

1;

=pod

=head1 NAME

Zapp::Type::SelectBox

=head1 VERSION

version 0.005

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ config.html.ep
<%
    my @options = (
        @{
            $config->{options} // $self->default_options // [ {} ]
        }
    );
    my $selected_index = $config->{selected_index} // 0;
%>
% my $selectbox_tmpl = begin
    % my ( $i, $opt ) = @_;
    <div data-zapp-array-row class="form-row">
        <div class="col flex-grow-1">
            <% if ( $i eq 0 ) { %><label for="config.options[<%= $i %>].label">Label</label><% } %>
            %= text_field "config.options[$i].label", $opt->{label} // '', class => 'form-control'
        </div>
        <div class="col flex-grow-1">
            <% if ( $i eq 0 ) { %><label for="config.options[<%= $i %>].value">Value</label><% } %>
            %= text_field "config.options[$i].value", $opt->{value} // '', class => 'form-control'
        </div>
        <div class="col-auto align-self-end py-2">
            %= radio_button 'config.selected_index', $i, ( checked => 'checked' )x!!( $i eq $selected_index )
        </div>
        <button type="button" class="btn btn-outline-danger align-self-end" data-zapp-array-remove>
            <i class="fa fa-times-circle"></i>
        </button>
    </div>
% end
<div data-zapp-array>
    <template><%= $selectbox_tmpl->( '#', {} ) %></template>
    % for my $i ( 0 .. $#options ) {
        %= $selectbox_tmpl->( $i, $options[$i] )
    % }
    <div class="form-row justify-content-end">
        <button type="button" class="btn btn-outline-success" data-zapp-array-add>
            <i class="fa fa-plus"></i>
        </button>
    </div>
</div>

@@ input.html.ep
%= select_field 'value', $self->_field_values( $config, $value ), class => 'form-control'

@@ output.html.ep
%= $self->_value_label( $config, $value )

