package experimentals;
our $VERSION = '0.017';

use 5.010;
use strict;
use warnings;
use feature      ();

# Module enables/disables these features...
my %FEATURES
    = map { $_ => 1 } ( $] >  5.015006 ? keys %feature::feature
                      : $] >= 5.011002 ? qw< say state switch unicode_strings  >
                      : $] >= 5.010000 ? qw< say state switch                  >
                      :                  qw<                                   >
                      );

# Module disables these warnings...
my %WARNINGS = map { $_ => 1 } grep { /^experimental::/ } keys %warnings::Offsets;

# In -report mode, the code is not run...
my $DO_NOT_RUN;
{
    no warnings 'void';
    INIT { exit if $DO_NOT_RUN; }
}

# Grab and reformat experimental warnings (when assigned to $SIG{__WARN__})...
sub _report_experimentals {
    my $warning = "@_";

    # Reformat any experimental warning (ignoring anything else)...
    if ($warning =~ m{\A(.*) is experimental\b(?:.*) at (.* line \d+)}) {
        printf {*STDERR} "%s:\t%s\n", $2, ucfirst $1;
    }
}

# Handle 'use experimentals'...
sub import {

    # Always enable all available features...
    feature->import(keys %FEATURES);

    # Are we reporting???
    my $reporting = grep { defined $_ && lc($_) eq '-report' } @_;

    # If not reporting, disable all warnings avout experimental features...
    if (!$reporting) {
        warnings->unimport(keys %WARNINGS);
    }

    # Otherwise, set up a filter to grab and reformat experimental warnings...
    else {
        # Enable the warnings we're going to grab...
        warnings->import(keys %WARNINGS);

        # Install the code to grab them...
        $SIG{__WARN__} = \&_report_experimentals;

        # Prevent actual code execution...
        $DO_NOT_RUN = 1;
    }
}

# Handle 'no experimentals'...
sub unimport {
    # Enable features that don't have experimental warnings...
    feature->import(grep { !$WARNINGS{"experimental::$_"} } keys %FEATURES);

    # Enable experimental warnings...
    warnings->import(keys %WARNINGS);
}

1; # Magic true value required at end of module

__END__

=head1 NAME

experimentals - Experimental features made even easier


=head1 VERSION

This document describes experimentals version 0.017


=head1 SYNOPSIS

    use experimentals;
    # All experimental features for this Perl version are now enabled

    {
        no experimentals;
        # No experimental features enabled in this scope
    }

=head1 DESCRIPTION

C<use experimental> is a life-saver under modern Perls,
but if you want to be truly modern Perl hacker you need something like:

    use v5.22;
    use experimental qw(
            fc          postderef     current_sub
            say         regex_sets    unicode_eval
            state       array_base    postderef_qq
            switch      smartmatch    lexical_subs
            bitwise     signatures    lexical_topic
            evalbytes   refaliasing   unicode_strings
            autoderef
    );

which is uncomfortably verbose.

This module reduces that to:

    use v5.22;
    use experimentals;


=head1 INTERFACE

You load the module and it enables all the Perl 5.10+ features that are
available under whatever version of Perl you are using. It also silences
the I<"...is experimental"> warnings on those features that are still
considered experimental (as listed in L<perlexperiment>)

If you specify:

    no experimentals;

then all "experimental" features are disabled (i.e. their warnings are
re-enabled). However, non-experimental features (such as C<say>, C<state>,
or C<__SUB__>) are unaffected by C<no experimentals>.


=head2 Selectively disabling or re-enabling particular features

This module works seamlessly with C<experimental.pm>
(because they both wrap the same underlying pragmas).

So you can turn on every modern feature, except one or two you don't
trust, like so:

    use experimentals;
    no experimental 'lexical_topic', 'smartmatch', 'array_base';

Likewise, in some inner scope you can lexically disable all experimental features, except
the few you actually need, with:

    no experimentals;
    use experimental 'signatures', 'refaliasing';


=head2 Locating forward-compatibility issues

Another annoyance with experimental warnings is that several new
features of Perl were subsequently retconned to "experimental" status in
later versions of Perl.

For example, from Perl 5.10 to 5.16 the use of smartmatching (either via
an explicit C<~~>, or implicitly in a C<given>/C<when>) did not generate
an "experimental" warning. From 5.18 onwards, it does.

Similarly, Perl 5.14 added the ability to pass an array reference as the
first argument of C<push>. But in 5.20, this feature was retconned to
"experimental" status, and started generating a warning. In Perl 5.24
the feature was removed entirely, and now generates a compile-time error.

This means that, when porting existing code to run under Perl 5.18 or
later, you may start getting spurious warnings if that code contains any
of the various retconned experimental features.

The C<experimentals> module can assist with porting older code to newer
Perls, via the C<-report> option.

For example, if you are porting code from 5.14 to Perl 5.22, you could
put the following at the start of your file:

    use experimentals -report;

and then run the code under Perl 5.22.

With the C<-report> flag, C<experimentals> will list every use of any
feature that would generate an "experimentals" warning under the version
of Perl with which you compile the code.

So, for example, the following code:

    use experimentals -report;

    my $_ = 'A1';
    my $aref = [];

    given (readline) {
        when (1) { say 'okay';        }
        when (0) { say fc $_ ~~ //;   }
        default  { push $aref, 1 | 2; }
    }

produces no output at all under Perl 5.14 or 5.16.

But under Perl 5.18, it reports:

    old_code.pl line 7:     Use of my $_
    old_code.pl line 10:    Given
    old_code.pl line 11:    When
    old_code.pl line 12:    When
    old_code.pl line 12:    Smartmatch

whilst under Perl 5.22, it reports:

    old_code.pl line 7:     Use of my $_
    old_code.pl line 10:    Given
    old_code.pl line 11:    When
    old_code.pl line 12:    When
    old_code.pl line 12:    Smartmatch
    old_code.pl line 13:    The bitwise feature
    old_code.pl line 13:    Push on reference

Note that, when C<use experimentals -report> is specified
all other non-fatal compile-time warnings are suppressed,
and the code itself is only compiled, not executed.

Fatal errors cannot be suppressed, however, so under Perl
5.24 the report would look like:

    old_code.pl line 10:     Given
    old_code.pl line 11:     When
    old_code.pl line 12:     When
    old_code.pl line 12:     Smartmatch
    old_code.pl line 13:     The bitwise feature
    Can't use global $_ in "my" at old_code.pl line 7, near "my $_ "
    Experimental push on scalar is now forbidden at old_code.pl line 13, near "2;"
    Execution of old_code.pl aborted due to compilation errors.

Note too that the module is lexically scoped, so it cannot
report problems inside an C<eval $STRING> call...unless the
S<C<use experimentals -report>> itself is inside the string as well.
In that case, obviously, the code I<will> be executed, since the C<eval>
is performed at run-time.


=head3 Vim integration of forward-compatibility checks

If you are using the Vim editor, you can add the following code:

    nmap er :call Experimental_Report()<CR>

    function! Experimental_Report ()
        normal 1GOuse experimentals -report;
        setlocal makeprg=perl\ %  errorformat=%f\ line\ %l:%m
        make
        set makeprg<  errorformat<
        normal 1Gdd``
        redraw
        cc
    endfunction

to your F<.vimrc> to create a Normal-mode mapping that runs the
current buffer under:

    #! /usr/bin/env perl
    use experimentals -report

and then initializes your "quickfix" list with the resulting
compatibility report.

For details of using quickfix mode in Vim, see:

    :help quickfix




=head1 DIAGNOSTICS

None. (That's the point. ;-)


=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-experimentals@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
