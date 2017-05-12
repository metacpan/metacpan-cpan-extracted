package Form::Processor::Field::URL;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';


sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $url = $self->input;

    return $self->add_error('Enter a plain url "e.g. http://google.com/"')
        unless $url =~ m{^\w+://[^/\s]+/\S*$}; 

    return 1;


}


=head1 NAME

Form::Processor::Field::URL - Tests that a url looks like a url.

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This validates input and tests if it matches the regular expression:

 m{^\w+://[^/\s]+/\S*$}

Currently, the URL is NOT converted to a URI object.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text".

=head1 AUTHORS

Bill Moseley

=head1 COPYRIGHT

See L<Form::Processor> for copyright.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=cut




1;

