package Zapp::Type;
# ABSTRACT: Input/output handling for data types

#pod =head1 SYNOPSIS
#pod
#pod     package My::Type;
#pod     use Mojo::Base 'Zapp::Type';
#pod     sub process_config( $self, $c, $form_value ) {
#pod         # Return the $config_value
#pod     }
#pod
#pod     sub process_input( $self, $c, $config_value, $form_value ) {
#pod         # Return the $input_value
#pod     }
#pod
#pod     sub task_input( $self, $config_value, $input_value ) {
#pod         # Return the $task_value
#pod     }
#pod
#pod     sub task_output( $self, $config_value, $task_value ) {
#pod         # Return the $input_value
#pod     }
#pod
#pod     __DATA__
#pod     @@ config.html.ep
#pod     %# Form to configure the input
#pod
#pod     @@ input.html.ep
#pod     %# Form for the user to fill in
#pod
#pod     @@ output.html.ep
#pod     %# Template to display the value
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the base class for Zapp types. Types are configured when
#pod building a plan, then filled out by the user when running the plan.
#pod Tasks then get the type's value as input, and can return a value
#pod of the given type.
#pod
#pod =head2 Type Value
#pod
#pod The type value returned from L</process_input> should contain all the
#pod information needed to use the value in a task. This does not need to be
#pod the actual content that tasks will use, but can be an identifier to look
#pod up that content.
#pod
#pod For example, the L<Zapp::Type::File> type stores a path relative to the
#pod application's home directory. When saving plans or starting runs, the
#pod file gets uploaded, saved to the home directory, and the path saved to
#pod the database. When a task needs the file, it gets the full path as
#pod a string.
#pod
#pod Another example could be a map of user passwords in a config file. The
#pod type value could be the username, which would be stored in the database
#pod for the plan/run. Then when a task needed the password, it could be
#pod looked up using the username.
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base -base, -signatures;
use Scalar::Util qw( blessed );
use Mojo::Loader qw( data_section );

#pod =head1 ATTRIBUTES
#pod
#pod =head2 app
#pod
#pod The application object. A L<Zapp> object.
#pod
#pod =cut

has app =>;

#pod =head1 METHODS
#pod
#pod =head2 config_field
#pod
#pod Get the field for configuration input. Reads the C<@@ config.html.ep>
#pod file from the C<__DATA__> section of the type class.
#pod
#pod =cut

sub config_field( $self, $c, $config_value=undef ) {
    my $class = blessed $self;
    my $tmpl = data_section( $class, 'config.html.ep' );
    return '' if !$tmpl;
    # XXX: Use Mojo::Template directly to get better names than 'inline
    # template XXXXXXXXXXXX'?
    return $c->render_to_string(
        inline => $tmpl,
        self => $self,
        config => $config_value,
    );
}

#pod =head2 process_config
#pod
#pod Process the form value for configuring this type. Return the type config
#pod to be stored in the database.
#pod
#pod =cut

sub process_config( $self, $c, $form_value ) {
    ...;
}

#pod =head2 input_field
#pod
#pod Get the field for user input. Reads the C<@@ input.html.ep> file from
#pod the C<__DATA__> section of the type class.
#pod
#pod =cut

sub input_field( $self, $c, $config_value, $input_value=undef ) {
    my $class = blessed $self;
    my $tmpl = data_section( $class, 'input.html.ep' );
    # XXX: Use Mojo::Template directly to get better names than 'inline
    # template XXXXXXXXXXXX'?
    return $c->render_to_string(
        inline => $tmpl,
        self => $self,
        config => $config_value,
        value => $input_value,
    );
}

#pod =head2 process_input
#pod
#pod Process the form value when saving a run. Return the type value to be
#pod stored in the database.
#pod
#pod =cut

sub process_input( $self, $c, $config_value, $form_value ) {
    ...;
}

#pod =head2 task_input
#pod
#pod Convert the type value stored in the database to the value used by the
#pod task.
#pod
#pod =cut

sub task_input( $self, $config_value, $input_value ) {
    ...;
}

#pod =head2 task_output
#pod
#pod Convert a value from a task's output into a type value to be stored in
#pod the database.
#pod
#pod =cut

sub task_output( $self, $config_value, $task_value ) {
    ...;
}

#pod =head2 display_value
#pod
#pod Show the value on the run page.
#pod
#pod =cut

sub display_value( $self, $c, $config_value, $input_value ) {
    my $class = blessed $self;
    my $tmpl = data_section( $class, 'output.html.ep' );
    # XXX: Use Mojo::Template directly to get better names than 'inline
    # template XXXXXXXXXXXX'?
    return $c->render_to_string(
        inline => $tmpl,
        self => $self,
        config => $config_value,
        value => $input_value,
    );
}

1;

__END__

=pod

=head1 NAME

Zapp::Type - Input/output handling for data types

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package My::Type;
    use Mojo::Base 'Zapp::Type';
    sub process_config( $self, $c, $form_value ) {
        # Return the $config_value
    }

    sub process_input( $self, $c, $config_value, $form_value ) {
        # Return the $input_value
    }

    sub task_input( $self, $config_value, $input_value ) {
        # Return the $task_value
    }

    sub task_output( $self, $config_value, $task_value ) {
        # Return the $input_value
    }

    __DATA__
    @@ config.html.ep
    %# Form to configure the input

    @@ input.html.ep
    %# Form for the user to fill in

    @@ output.html.ep
    %# Template to display the value

=head1 DESCRIPTION

This is the base class for Zapp types. Types are configured when
building a plan, then filled out by the user when running the plan.
Tasks then get the type's value as input, and can return a value
of the given type.

=head2 Type Value

The type value returned from L</process_input> should contain all the
information needed to use the value in a task. This does not need to be
the actual content that tasks will use, but can be an identifier to look
up that content.

For example, the L<Zapp::Type::File> type stores a path relative to the
application's home directory. When saving plans or starting runs, the
file gets uploaded, saved to the home directory, and the path saved to
the database. When a task needs the file, it gets the full path as
a string.

Another example could be a map of user passwords in a config file. The
type value could be the username, which would be stored in the database
for the plan/run. Then when a task needed the password, it could be
looked up using the username.

=head1 SEE ALSO

=head1 ATTRIBUTES

=head2 app

The application object. A L<Zapp> object.

=head1 METHODS

=head2 config_field

Get the field for configuration input. Reads the C<@@ config.html.ep>
file from the C<__DATA__> section of the type class.

=head2 process_config

Process the form value for configuring this type. Return the type config
to be stored in the database.

=head2 input_field

Get the field for user input. Reads the C<@@ input.html.ep> file from
the C<__DATA__> section of the type class.

=head2 process_input

Process the form value when saving a run. Return the type value to be
stored in the database.

=head2 task_input

Convert the type value stored in the database to the value used by the
task.

=head2 task_output

Convert a value from a task's output into a type value to be stored in
the database.

=head2 display_value

Show the value on the run page.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
