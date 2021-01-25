package Text::Trim;

use strict;
use warnings;

=head1 NAME

Text::Trim - remove leading and/or trailing whitespace from strings

=head1 VERSION

version 1.04

=cut

our $VERSION = '1.04';

=head1 SYNOPSIS

    use Text::Trim;

    $text = "\timportant data\n";
    $data = trim $text;
    # now $data contains "important data" and $text is unchanged
    
    # or:
    trim $text; # work in-place, $text now contains "important data"

    @lines = <STDIN>;
    rtrim @lines; # remove trailing whitespace from all lines

    # Alternatively:
    @lines = rtrim <STDIN>;

    # Or even:
    while (<STDIN>) {
        trim; # Change $_ in place
        # ...
    }

=head1 DESCRIPTION

This module provides functions for removing leading and/or trailing whitespace
from strings. It is basically a wrapper around some simple regexes with a
flexible context-based interface.

=head1 EXPORTS

All functions are exported by default.

=cut

use Exporter;

our @ISA = qw( Exporter );
our @EXPORT = qw( rtrim ltrim trim );

=head1 CONTEXT HANDLING

=head2 void context

Functions called in void context change their arguments in-place

    trim(@strings); # All strings in @strings are trimmed in-place

    ltrim($text);   # remove leading whitespace on $text

    rtrim;          # remove trailing whitespace on $_

No changes are made to arguments in non-void contexts.

=head2 list context

Values passed in are changed and returned without affecting the originals.

    @result = trim(@strings);    # @strings is unchanged

    @result = rtrim;             # @result contains rtrimmed $_

    ($result) = ltrim(@strings); # like $result = ltrim($strings[0]);

=head2 scalar context

As list context but multiple arguments are stringified before being returned.
Single arguments are unaffected.  This means that under these circumstances,
the value of C<$"> (C<$LIST_SEPARATOR>) is used to join the values. If you
don't want this, make sure you only use single arguments when calling in
scalar context.

    @strings = ("\thello\n", "\tthere\n");
    $trimmed = trim(@strings);
    # $trimmed = "hello there"

    local $" = ', ';
    $trimmed = trim(@strings);
    # Now $trimmed = "hello, there"

    $trimmed = rtrim;
    # $trimmed = $_ minus trailing whitespace

=head2 Undefined values

If any of the functions are called with undefined values, the behaviour is in
general to pass them through unchanged. When stringifying a list (calling in
scalar context with multiple arguments) undefined elements are excluded, but
if all elements are undefined then the return value is also undefined.

    $foo = trim(undef);        # $foo is undefined
    $foo = trim(undef, undef); # $foo is undefined
    @foo = trim(undef, undef); # @foo contains 2 undefined values
    trim(@foo)                 # @foo still contains 2 undefined values
    $foo = trim('', undef);    # $foo is ''

=head1 FUNCTIONS

=head2 trim

Removes leading and trailing whitespace from all arguments, or C<$_> if none
are provided.

=cut

sub trim {
    @_ = @_ ? @_ : $_ if defined wantarray;

    for (@_ ? @_ : $_) { next unless defined; s/\A\s+//; s/\s+\z// }

    return @_ if wantarray || !defined wantarray;

    if (my @def = grep defined, @_) { return "@def" } else { return }
}

=head2 rtrim 

Like C<trim()> but removes only trailing (right) whitespace.

=cut

sub rtrim {
    @_ = @_ ? @_ : $_ if defined wantarray;

    for (@_ ? @_ : $_) { next unless defined; s/\s+\z// }

    return @_ if wantarray || !defined wantarray;

    if (my @def = grep defined, @_) { return "@def" } else { return }
}

=head2 ltrim

Like C<trim()> but removes only leading (left) whitespace.

=cut

sub ltrim {
    @_ = @_ ? @_ : $_ if defined wantarray;

    for (@_ ? @_ : $_) { next unless defined; s/\A\s+// }

    return @_ if wantarray || !defined wantarray;

    if (my @def = grep defined, @_) { return "@def" } else { return }
}

1;

__END__

=head1 UNICODE

Because this module is implemented using Perl regular expressions, it is capable
of recognising and removing unicode whitespace characters (such as non-breaking
spaces) from scalars with the utf8 flag on. See L<Encode> for details about the
utf8 flag.

Note that this only applies in the case of perl versions after 5.8.0 or so.

=head1 SEE ALSO

Brent B. Powers' L<String::Strip> performs a similar function in XS.

=head1 AUTHORS

B<Matt Lawrence> E<lt>mattlaw@cpan.orgE<gt> - Original author and maintainer

B<Ryan Thompson> E<lt>rjt@cpan.orgE<gt> - Co-maintainer, miscellaneous fixes

=head1 SUPPORT

L<https://github.com/rjt-pl/Text-Trim/issues>: Bug reports and feature requests

L<https://github.com/rjt-pl/Text-Trim.git>: Source repository

=head1 ACKNOWLEDGEMENTS

Terrence Brannon E<lt>metaperl@gmail.comE<gt> for bringing my attention to
L<String::Strip> and suggesting documentation changes.

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

L<http://dev.perl.org/licenses/artistic.html>

=cut

vim: ts=8 sts=4 sw=4 sr et
