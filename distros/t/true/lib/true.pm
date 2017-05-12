package true;

use strict;
use warnings;

use B::Hooks::OP::Annotation;
use B::Hooks::OP::Check;
use Devel::StackTrace;
use XSLoader;

our $VERSION = '0.18';
our %TRUE;

XSLoader::load(__PACKAGE__, $VERSION);

# XXX CopFILE(&PL_compiling) gives the wrong result here (it works in the OP checker in the XS).
# return the full path of the file that's currently being compiled
sub ccfile() {
    my ($file, $source, $line);
    my $trace = Devel::StackTrace->new;

    # find the innermost require frame
    #
    # for "use Foo::Bar" or "require Foo::Bar", the evaltext contains "Foo/Bar.pm", and
    # the filename/line refer to the file where the use/require statement appeared.

    # work from the innermost frame out
    while (my $frame = $trace->next_frame) {
        next unless ($frame->is_require);
        my $required = $frame->evaltext;

        if (defined($file = $INC{$required})) {
            $source = $frame->filename;
            $line = $frame->line;
        } else { # shouldn't happen
            warn "true: can't find required file ($required) in \%INC";
        }

        last;
    }

    return wantarray ? ($file, $source, $line) : $file;
}

# XXX should add a debug option
sub import {
    my ($file, $source, $line) = ccfile();

    if (defined($file) && not($TRUE{$file})) {
        $TRUE{$file} = 1;
        # warn "true: enabling true for $file at $source line $line", $/;
        xs_enter();
    }
}

sub unimport {
    my ($file, $source, $line) = ccfile();

    if (defined($file) && $TRUE{$file}) {
        # warn "true: disabling true for $file at $source line $line", $/;
        delete $TRUE{$file};
        xs_leave() unless (%TRUE);
    }
}

1;

__END__

=head1 NAME

true - automatically return a true value when a file is required

=head1 SYNOPSIS

  package Contemporary::Perl;

  use strict;
  use warnings;
  use true;

  sub import {
      strict->import();
      warnings->import();
      true->import();
  }

=head1 DESCRIPTION

Perl's C<require> builtin (and its C<use> wrapper) requires the files it loads to return a true value.
This is usually accomplished by placing a single

    1;

statement at the end of included scripts or modules. It's not onerous to add but it's
a speed bump on the Perl novice's road to enlightenment. In addition, it appears to be
a I<non-sequitur> to the uninitiated, leading some to attempt to mitigate its appearance
with a comment:

    1; # keep require happy

or:

    1; # Do not remove this line

or even:

    1; # Must end with this, because Perl is bogus.

This module packages this "return true" behaviour so that it need not be written explicitly.
It can be used directly, but it is intended to be invoked from the C<import> method of a
L<Modern::Perl|Modern::Perl>-style module that enables modern Perl features and conveniences
and cleans up legacy Perl warts.

=head2 METHODS

C<true> is file-scoped rather than lexically-scoped. Importing it anywhere in a
file (e.g. at the top-level or in a nested scope) causes that file to return true,
and unimporting it anywhere in a file restores the default behaviour. Redundant imports/unimports
are ignored.

=head3 import

Enable the "automatically return true" behaviour for the currently-compiling file. This should
typically be invoked from the C<import> method of a module that loads C<true>. Code that uses
this module solely on behalf of its callers can load C<true> without importing it e.g.

    use true (); # don't import

    sub import {
        true->import();
    }

    1;

But there's nothing stopping a wrapper module also importing C<true> to obviate its own need to
explicitly return a true value:

    use true; # both load and import it

    sub import {
        true->import();
    }

    # no need to return true

=head3 unimport

Disable the "automatically return true" behaviour for the currently-compiling file.

=head2 EXPORT

None by default.

=head1 NOTES

Because some versions of L<YAML::XS> may interpret the key of C<true>
as a boolean, you may have trouble declaring a dependency on true.pm.
You can work around this by declaring a dependency on the package L<true::VERSION>,
which has the same version as true.pm.

=head1 SEE ALSO

=over

=item * L<latest|latest>

=item * L<Modern::Perl|Modern::Perl>

=item * L<nonsense|nonsense>

=item * L<perl5i|perl5i>

=item * L<Toolkit|Toolkit>

=item * L<uni::perl|uni::perl>

=back

=head1 AUTHOR

chocolateboy, E<lt>chocolate@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
