package Form::Processor::Field::DateTime;
use strict;
use warnings;
use base 'Form::Processor::Field::DateTimeManip';
our $VERSION = '0.03';


=head1 NAME

Form::Processor::Field::DateTime - Maps to the current DateTime module.

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a module that allows mapping the DateTime field to
the actual field used.  Makes it easier to remap all the forms
in an application to a new field type by overriding instead of
editing all the forms.

Currently this is simply a subclass of L<Form::Processor::Field::DateTimeManip>.


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

