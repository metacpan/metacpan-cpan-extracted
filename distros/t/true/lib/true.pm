package true;

use strict;
use warnings;

use B::Hooks::OP::Annotation;
use B::Hooks::OP::Check;
use Devel::StackTrace;
use XSLoader;

# XXX this declaration must be on a single line
# https://metacpan.org/pod/version#How-to-declare()-a-dotted-decimal-version
use version 0.77; our $VERSION = version->declare('v1.0.2');

our %TRUE;

# set the logger from the first rule which matches the $TRUE_PM_DEBUG
# environment variable:
#
#  - warn with a backtrace (cluck) if it's an integer > 1
#  - warn (without a backtrace) if it's truthy
#  - otherwise (default), do nothing
#
our $DEBUG = do {
    my $debug = $ENV{TRUE_PM_DEBUG} || '0';
    $debug = $debug =~ /^\d+$/ ? int($debug) : 1;
    $debug && ($debug > 1 ? do { require Carp; \&Carp::cluck } : sub { warn(@_) });
};

XSLoader::load(__PACKAGE__, $VERSION);

sub _debug($) {
    $DEBUG->(@_, $/) if ($DEBUG);
}

# return the full path of the file that's currently being compiled.
# XXX CopFILE(&PL_compiling) gives the wrong result here (it works in the
# OP-checker in the XS).
sub ccfile() {
    my ($file, $source, $line);
    my $trace = Devel::StackTrace->new;

    # find the innermost require frame
    #
    # for "use Foo::Bar" or "require Foo::Bar", the evaltext contains
    # "Foo/Bar.pm", and the filename/line refer to the file where the
    # use/require statement appeared.

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

sub import {
    my ($file, $source, $line) = ccfile();

    if (defined($file) && not($TRUE{$file})) {
        $TRUE{$file} = 1;
        _debug "true: enabling true for $file at $source line $line";
        xs_enter();
    }
}

sub unimport {
    my ($file, $source, $line) = ccfile();

    if (defined($file) && $TRUE{$file}) {
        _debug "true: disabling true for $file at $source line $line";
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

Perl's C<require> builtin (and its C<use> wrapper) requires the files it loads
to return a true value. This is usually accomplished by placing a single

    1;

statement at the end of included scripts or modules. It's not onerous to add
but it's a speed bump on the Perl novice's road to enlightenment. In addition,
it appears to be a I<non-sequitur> to the uninitiated, leading some to attempt
to mitigate its appearance with a comment:

    1; # keep require happy

or:

    1; # Do not remove this line

or even:

    1; # Must end with this, because Perl is bogus.

This module packages this "return true" behaviour so that it doesn't need to be
written explicitly. It can be used directly, but it is intended to be invoked
from the C<import> method of a L<Modern::Perl|Modern::Perl>-style module that
enables modern Perl features and conveniences and cleans up legacy Perl warts.

=head2 METHODS

C<true> is file-scoped rather than lexically-scoped. Importing it anywhere in a
file (e.g. at the top-level or in a nested scope) causes that file to return true,
and unimporting it anywhere in a file restores the default behaviour. Redundant
imports/unimports are ignored.

=head3 import

Enable the "automatically return true" behaviour for the currently-compiling
file. This should typically be invoked from the C<import> method of a module
that loads C<true>. Code that uses this module solely on behalf of its callers
can load C<true> without importing it e.g.

    use true (); # don't import

    sub import {
        true->import();
    }

    1;

But there's nothing stopping a wrapper module also importing C<true> to obviate
its own need to explicitly return a true value:

    use true; # both load and import it

    sub import {
        true->import();
    }

    # no need to return true

=head3 unimport

Disable the "automatically return true" behaviour for the currently-compiling file.

=head2 EXPORTS

None by default.

=head1 NOTES

Because the unquoted name C<true> represents the boolean value C<true> in YAML,
the module name must be quoted when written as a dependency in META.yml. In cases
where this can't easily be done, a dependency can be declared on the package
L<true::VERSION>, which has the same version as C<true.pm>.

=head1 VERSION

1.0.2

=head1 SEE ALSO

=over

=item * L<latest>

=item * L<Modern::Perl>

=item * L<nonsense>

=item * L<perl5i>

=item * L<Toolkit>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2020 by chocolateboy.

This library is free software; you can redistribute it and/or modify it under the
terms of the L<Artistic License 2.0|https://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
