package Unicode::Semantics;
use base 'Exporter';
$VERSION = "1.02";
@EXPORT = qw(us up);

sub us ($) {
    utf8::upgrade($_[0]);
    return $_[0];
}

*up = \&us;

1;

__END__

=head1 NAME

Unicode::Semantics - Work around *the* Perl 5 Unicode bug

=head1 SYNOPSIS

    $foo;     # could be anything
    up $foo;  # force Unicode semantics

or:

    up($foo) =~ s/\W/_/g;  # Upgrade and use immediately

=head1 DESCRIPTION

Although the internal encoding of a string is hidden from the Perl programmer,
it does unfortunately affect semantics. Perl uses Unicode semantics when the
internal encoding for a string is UTF8, but it uses I<ASCII> semantics when the
internal encoding is ISO-8859-1.

Because you shouldn't (and often don't) know what the internal encoding will
be, it's hard to predict whether these operations will actually do what you
want. Unicode::Semantics::us() gives you predictable results for your string.

Normally, the non-ASCII part of the character set is ignored when for the
following operations on a string of which the internal encoding is ISO-8859-1:

    * uc, lc, ucfirst, lcfirst, \U, \L, \u, \l
    * \d, \s, \w, \D, \S, \W
    * /.../i, (?i:...)
    * /[[:posix:]]/

This module exports C<us> that upgrades your string to UTF-8 internally and
returns the string. An alias, C<up>, is also exported by default. After
initially releasing the module with C<us>, I changed my mind and starting
liking C<up> better.

You can also use the built-in function C<utf8::upgrade>, which upgrades the
string and returns the number of octets used for the internal UTF8 buffer.

Non-string values (like numbers, references, objects, and undef) are
stringified on upgrade.

C<us>, C<up>, and C<utf8::upgrade> mutate the variable's actual value. If you
need to upgrade only a copy of a string, make the copy first:

    up(my $copy = $original);

Upgrading an already upgraded variable does not re-upgrade, so it is safe.

=head1 WHY THIS MODULE

While using a module for something that is built-in may be silly, there's one
good reason to use it anyway: "use Unicode::Semantics" is an implicit reference
to this documentation, that explains the problem, whereas the reason for using
utf8::upgrade may not be obvious.

This module is meant for production use.

Released minutes before the lightning talk "Working around *the* Unicode bug"
during YAPC::Europe 2007, in Vienna. See
http://juerd.nl/files/slides/2007yapceu/unicodesemantics.html for slides.

=head1 AUTHOR

Juerd Waalboer <#####@juerd.nl>

=head1 LICENSE

Pick your favourite OSI approved license :)

http://www.opensource.org/licenses/alphabetical

=head1 SEE ALSO

L<perlunitut>, L<perlunifaq>, L<utf8>.
