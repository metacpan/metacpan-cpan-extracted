package Web::Detect;

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.05'; # VERSION

use strict;
use warnings;

sub import {
    if ( @_ > 1 ) {
        no strict 'refs';
        if ( grep /^detect_web$/, @_ ) {
            *{ caller() . '::detect_web' } = \&detect_web;
        }

        if ( grep /^detect_web_fast$/, @_ ) {
            *{ caller() . '::detect_web_fast' } = \&detect_web_fast;
        }
    }
}

sub detect_web {
    my ($first) = @_;
    my %res;

    if ( $ENV{MOD_PERL} ) {    # verified on mod_perl 1.3 and mod_perl 2.0
        $res{mod_perl} = 1;
        return \%res if $first;
    }

    if ( $ENV{PLACK_ENV} ) {
        $res{plack} = 1;
        $res{psgi}  = 1;
        return \%res if $first;
    }

    if ( $ENV{'PANGEA'} ) {
        $res{'pangea'} = 1;
        $res{'psgi'}   = 1;
        return \%res if $first;
    }

    if ( $ENV{'CPANEL'} || $ENV{'WHM50'} ) {
        $res{'cpanel'} = 1;
        return \%res if $first;
    }

    if ( $ENV{'CATALYST_SCRIPT_GEN'} ) {
        $res{'catalyst'} = 1;
        return \%res if $first;
    }

    if ( $ENV{'DANCER_APPDIR'} ) {
        $res{'dancer'} = 1;
        return \%res if $first;
    }

    if ( $ENV{'MOJO_EXE'} ) {
        $res{'mojo'} = 1;
        return \%res if $first;
    }

    if ( $ENV{'FCGI_ROLE'} ) {
        $res{'FCGI.pm'} = 1;
        return \%res if $first;
    }

    if ( $ENV{'INSTANCE_ID'} ) {
        $res{'IIS'} = 1;
        return \%res if $first;
    }

    # now, do more generic checks after specific server checks:
    if ( defined $ENV{GATEWAY_INTERFACE} && $ENV{GATEWAY_INTERFACE} =~ m/^CGI/ ) {
        $res{cgi} = 1;
        return \%res if $first;
    }

    # General server vars:
    if ( $ENV{'SCRIPT_NAME'} || $ENV{'SCRIPT_FILENAME'} || $ENV{'REMOTE_ADDR'} || $ENV{'HTTPS'} || $ENV{'QUERY_STRING'} || $ENV{'DOCUMENT_ROOT'} ) {
        $res{'general'} = 1;
        return \%res if $first;
    }

    # still nothing? yikes ...
    for my $k ( keys %ENV ) {
        if ( $k =~ m/^(?:HTTP|SERVER|REQUEST)_/ ) {
            $res{'general'} += 2;
            return \%res if $first;
        }
    }

    # the way scripts are run in some web servers they are still technically
    # "interactive", so interactivity is only reliable for this if it is false
    # (IO::Interactive::Tiny)
    #
    # ditto +/- for term detection (Term::Detect)

    return unless %res;
    return \%res;
}

sub detect_web_fast {
    @_ = (1);
    goto &detect_web;
}

1;

# ABSTRACT: Detect if program is running under some web environment

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Detect - Detect if program is running under some web environment

=head1 VERSION

This document describes version 0.05 of Web::Detect (from Perl distribution Web-Detect), released on 2015-01-03.

=head1 SYNOPSIS

    use Web::Detect qw(detect_web detect_web_fast);
    use IO::Interactive::Tiny ();

    if (Web::Detect::detect_web_fast()) {
        # do HTML
    }
    else {
        # do CLI
        if (IO::Interactive::Tiny::is_interactive()) {
            # prompt/ANSI/etc
        }
        else {
            # do not prompt/plain text/etc
        }
    }

=head1 DESCRIPTION

Knowing if you are under a web environment or not is very handy.

For example, often you need to decide whether to output HTML or plaintext.

=head1 FUNCTIONS

Functions are exportable but are not exported by default.

=head2 detect_web() => HASHREF

Return false if not detected running under any web environment.

Return a hash otherwise.

These keys exists if it is detected that we are running under the given
environment and the value is suitable as a boolean (always true).

=over 4

=item C<mod_perl>

=item C<plack>

=item C<pangea>

=item C<cpanel>

L<http://cpanel.net>

=item C<catalyst>

=item C<dancer>

=item C<mojo>

=item C<FCGI.pm>

=item C<IIS>

=item C<cgi>

General CGI

=item C<general>

Value can be 1 if it was detected during the first general check, 2 if it was
detected during the second general check, and 3 if it was detected under both.

=back

Additionally, C<psgi> is also true if we know its a PSGI environment.

=head2 detect_web_fast()

Same as detect_web() but return HASHREF upon first successful check instead of
trying all heuristics.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Web-Detect>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Web-Detect>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Web-Detect>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
