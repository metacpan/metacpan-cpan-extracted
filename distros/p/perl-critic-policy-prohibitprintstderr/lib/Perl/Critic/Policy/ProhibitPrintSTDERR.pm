package Perl::Critic::Policy::ProhibitPrintSTDERR;
$Perl::Critic::Policy::ProhibitPrintSTDERR::VERSION = '1.000';
# ABSTRACT: Print to STDERR throws away the one thing a diagnostic is for.

use strict;

# Not FATAL => 'all', which the house profile otherwise asks for.  This is a
# library loaded into somebody else's process to critique their code, and a new
# warning category in a later perl would then kill their run rather than say
# something about it.  Fatal warnings are for a program you control the exit of.
use warnings;    ## no critic (RequireFatalWarnings)

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $STDERR_BLOCK_RX => qr/\A [{] \s* \\? \s* [*]? \s* STDERR \s* [}] \z/xms;

Readonly::Scalar my $DESC => q{Print to STDERR};
Readonly::Scalar my $EXPL => q{Use warn, which carries the file and line and goes through $SIG{__WARN__} -- or '## no critic' if this is usage text rather than a diagnostic};

# print, and the two other builtins that take a filehandle the same way.
Readonly::Hash my %PRINTERS => map { $_ => 1 } qw{print printf say};


sub supported_parameters { return () }


sub default_severity { return $SEVERITY_MEDIUM }


sub default_themes { return qw(maintenance bugs) }


sub applies_to { return 'PPI::Token::Word' }


sub violates {
    my ( $self, $elem, undef ) = @_;

    return $self->violation( $DESC, $EXPL, $elem ) if _is_stderr_method_call($elem);

    return if !$PRINTERS{ $elem->content() };
    return if !is_function_call($elem);

    my $handle = $elem->snext_sibling();
    return if !$handle;

    return $self->violation( $DESC, $EXPL, $elem ) if _is_stderr_handle($handle);

    # print(STDERR "..."), where the parens make the handle the first thing
    # inside a list rather than the next thing along.
    return if !$handle->isa('PPI::Structure::List');

    my $first = $handle->schild(0);
    $first = $first->schild(0) if $first && $first->isa('PPI::Statement');

    return $self->violation( $DESC, $EXPL, $elem ) if $first && _is_stderr_handle($first);

    return;    # ok!
}

# STDERR->print(...), which reaches print as a method rather than as a builtin
# and so never looks like a function call.
sub _is_stderr_method_call {
    my ($elem) = @_;

    return 0 if $elem->content() ne 'print';

    my $arrow = $elem->sprevious_sibling();
    return 0 if !$arrow || !$arrow->isa('PPI::Token::Operator') || $arrow->content() ne '->';

    my $invocant = $arrow->sprevious_sibling();
    return 0 if !$invocant;

    return $invocant->isa('PPI::Token::Word') && $invocant->content() eq 'STDERR';
}

# The filehandle slot of a print, in each of the shapes PPI hands it back:
# a bareword, a glob, or a block holding either.
sub _is_stderr_handle {
    my ($elem) = @_;

    return 1 if $elem->isa('PPI::Token::Word')      && $elem->content() eq 'STDERR';
    return 1 if $elem->isa('PPI::Token::Symbol')    && $elem->content() eq '*STDERR';
    return 1 if $elem->isa('PPI::Structure::Block') && $elem->content() =~ $STDERR_BLOCK_RX;

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ProhibitPrintSTDERR - Print to STDERR throws away the one thing a diagnostic is for.

=head1 VERSION

version 1.000

=head1 Perl::Critic::Policy::ProhibitPrintSTDERR

C<warn> and C<print STDERR> put the same text on the same handle.  They differ
in what else they carry:

    print STDERR "could not read $file\n";   # that, and nothing more
    warn "could not read $file";             # ... at Foo.pm line 42.

C<warn> appends the file and line for free, goes through C<$SIG{__WARN__}> so a
program can route or count its own diagnostics, and can be promoted to fatal.
A print is text on a filehandle: whoever reads the log gets the sentence and no
way back to the line that produced it.  The two are the same amount of typing
and only one of them is still useful at three in the morning.

So this policy exists to make the print the deliberate choice rather than the
default one -- because the print is what you reach for when you are thinking
about the message, and C<warn> is what you want when somebody is thinking about
the failure.

=head2 PROHIBITED

Every spelling of the same thing, since a policy that only knew one would just
be an argument for using another:

    print STDERR "oh no\n";
    printf STDERR "%s\n", $why;
    say STDERR 'oh no';
    print {*STDERR} "oh no\n";
    print {\*STDERR} "oh no\n";
    print *STDERR "oh no\n";
    print(STDERR "oh no\n");
    STDERR->print("oh no\n");

=head2 ALLOWED

Anything not aimed at STDERR:

    print "ordinary output\n";
    print STDOUT "ordinary output\n";
    print {$fh} "into a file\n";
    warn "the thing this policy is asking for";

=head3 Usage and progress text

There is a real exception, and it is not diagnostics.  A script writing its
C<--help>, or narrating its progress so the transcript is readable, is using
STDERR as a channel to a person rather than reporting a failure -- and C<warn>
would staple a source location onto every line of it.

That is what the standard signoff is for, on the statement:

    print STDERR "Restarted $domain\n";    ## no critic (ProhibitPrintSTDERR)

or over a run of them, which is usually what usage text is:

    ## no critic (ProhibitPrintSTDERR)
    print STDERR "usage: $0 [--verbose] DOMAIN\n";
    print STDERR "  --verbose   say what is happening\n";
    ## use critic

Both leave a mark saying somebody decided, which is the whole point.  The
question the reviewer is then asking is not "why is this not warn" but "is this
really talking to a person", and that one can be answered by reading it.

=head2 CONFIGURATION

This policy is not configurable except for the standard options.

Deliberately: an exemption for "usage subs" or a list of blessed filenames
would be a second mechanism for something C<## no critic> already does, and it
would exempt the file rather than the line -- so the next diagnostic added to a
script full of usage text would inherit the exemption without anybody
deciding.

=head2 CAVEATS

The handle has to be visible in the source.  A print through a copy of it --

    my $err = \*STDERR;
    print {$err} "invisible to this policy\n";

-- reads as an ordinary filehandle here, because it is one by the time it gets
to the print.  The policy reads source, not data flow.

Likewise C<< STDERR->say(...) >> and the rest of L<IO::Handle> beyond C<print>:
only the C<print> method is recognised, since that is the one anybody writes.

=head2 METHODS

=head3 supported_parameters

None.

=head3 default_severity

SEVERITY_MEDIUM

=head3 default_themes

maintenance, bugs

=head3 applies_to

PPI::Token::Word

=head3 violates

Standard L<Perl::Critic::Policy> interface.  Returns a violation for a C<print>,
C<printf> or C<say> whose filehandle is STDERR, however it is spelled, and
nothing for one aimed anywhere else.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitprintstderr/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords George Baugh

George Baugh <andy@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
