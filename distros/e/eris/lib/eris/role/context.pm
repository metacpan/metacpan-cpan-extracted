package eris::role::context;
# ABSTRACT: Role for implementing a log context

use Moo::Role;
use Types::Standard qw(Str Defined Int);
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION


requires qw(
    contextualize_message
    sample_messages
);
with qw(
    eris::role::plugin
);

########################################################################


has 'field' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_field',
);

sub _build_field { 'program' }


has 'matcher' => (
    is      => 'ro',
    isa     => Defined,
    lazy    => 1,
    builder => '_build_matcher',
);

sub _build_matcher { my ($self) = shift; $self->name; }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::context - Role for implementing a log context

=head1 VERSION

version 0.008

=head1 ATTRIBUTES

=head2 B<field>

The field in the context of the log to use to use with the C<matcher> to select
a log for parsing.  This defaults to the 'program' field and uses the
C<context> object's C<name> method as a default equality check.

This means C<eris::log::context::sshd> will match any log with the 'program'
key set to 'sshd'.

The rules for parsing are:

=over 2

=item B<*>

Reserved for it's use as with C<matcher> set to '*', which forces the context
to be evaluated for every document.

    sub _build_field   { '*' }
    sub _build_matcher { '*' }

Will run the contextualizer for every document.

=item B<_exists_>

Instead of apply the C<matcher> to the value, we'll check it against the key.

Say we wanted to run a reverse DNS check on an IP we could:

    sub _build_field   { '_exists_' }
    sub _build_matcher { /_ip$/ }

Exists supports the following matchers:

=over 2

=item B<String>

Simple string match against the key

=item B<Regex>

Apply the regex to the key

=item B<ArrayRef>

Checks if the key is contained in the array

=back

=item B<String>

The string is considered the name of the field in the document.  That key is
used to check it's value against the C<matcher>.  Using a string are a field name supports
the following C<matcher>'s.

=over 2

=item B<String>

Check if the lowercase string matches the value at the key designated by B<field>, i.e.

    sub _build_field   { 'program' }
    sub _build_matcher { 'sshd' }

This context will call C<contextualize_message> on documents with a field
'program' which has the value 'sshd'.

=item B<Regex>

Checks the value in the field for against the regex.

    sub _build_field   { 'program' }
    sub _build_matcher { /^postfix/ }

This context will call C<contextualize_message> on documents with a field
'program' matching the regex '^postfix'.

=item B<ArrayRef>

Checks the value in the field against all values in the array.

    sub _build_field   { 'program' }
    sub _build_matcher { [qw(sort suricata)] }

This context will call C<contextualize_message> on documents with a field
'program' that is either 'snort' or 'suricata'.

=item B<CodeRef>

Check the return value of the code reference passing the value at the field
into the function.

    sub _build_field   { 'src_ip' }
    sub _build_matcher { \&check_bad_ips }

This context will call C<contextualize_message> on documents with a field
'src_ip' and call the C<check_bad_ips()> function with the value in the
'src_ip' field if the sub routine return true.

=back

=back

=head2 B<matcher>

Maybe a B<String>, B<Regex>, B<ArrayRef>, or a B<CodeRef>. See documentation on
L<field> for information on the combinations and how to use them.

=head1 INTERFACE

=head2 contextualize_message

This method will be called every time a log matches this context.  It receives
an C<eris::log> object.  Call C<eris::log->add_context> with the name of the
context to add to the log context.

=head2 sample_message

This is used in sampling and the test suite.

Return an array of log message you expect to use.

This is helpful when developing or testing new elements, call:

    eris-context.pl --sample <name_of_context>

To use those messages to see what the contextualizer is doing.

=head1 SEE ALSO

L<eris::log::contexts>, L<eris::log::contextualizer>, L<eris::role::plugin>,
L<eris::log::context::sshd>, L<eris::log::context::snort>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
