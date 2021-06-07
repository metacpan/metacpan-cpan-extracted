package Zapp::Type::Text;
use Mojo::Base 'Zapp::Type', -signatures;
use Mojo::Loader qw( data_section );

# XXX: Array type to hold another type
# XXX: KeyValue type?

# "die" for validation errors

# Form value -> Type value
sub process_config( $self, $c, $form_value ) {
    return $form_value;
}

sub process_input( $self, $c, $config_value, $form_value ) {
    return $form_value // $config_value;
}

# Type value -> Task value
sub task_input( $self, $config_value, $input_value ) {
    return $input_value;
}

# Task value -> Type value
sub task_output( $self, $config_value, $task_value ) {
    return $task_value;
}

1;

=pod

=head1 NAME

Zapp::Type::Text

=head1 VERSION

version 0.004

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ input.html.ep
%= text_field 'value', value => $value // $config, class => 'form-control'

@@ config.html.ep
<label for="config">Value</label>
%= text_field 'config', value => $config, class => 'form-control'

@@ output.html.ep
%= $value

