#!/usr/bin/env perl
package Test::HTTP::Server::Simple::StashWarnings;
use strict;
use warnings;
use base 'Test::HTTP::Server::Simple';

use 5.008;
our $VERSION = '0.04';

use NEXT;
use Storable ();

sub test_warning_path {
    my $self = shift;
    die "You must override test_warning_path in $self to tell " . __PACKAGE__ . " where to provide test warnings.";
}

sub background {
    my $self = shift;

    local $SIG{__WARN__} = sub {
        push @{ $self->{'thss_stashed_warnings'} }, @_;
        warn @_ if $ENV{TEST_VERBOSE};
    };

    return $self->NEXT::background(@_);
}

sub handler {
    my $self = shift;

    if ($self->{thss_test_path_hit}) {
        my @warnings = splice @{ $self->{'thss_stashed_warnings'} };
        my $content  = $self->encode_warnings(@warnings);

        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: application/x-perl\r\n";
        print "Content-Length: ", length($content), "\r\n";
        print "\r\n";
        print $content;

        return;
    }

    return $self->NEXT::handler(@_);
}

sub setup {
    my $self = shift;
    my @copy = @_;

    delete $self->{thss_test_path_hit};

    while (my ($item, $value) = splice @copy, 0, 2) {
        if ($item eq 'request_uri') {
            # a little bit of canonicalization is okay I guess
            $value =~ s{^/+}{/};

            $self->{thss_test_path_hit} = $value eq $self->test_warning_path;
        }
    }

    return $self->NEXT::setup(@_);
}

sub encode_warnings {
    my $self = shift;
    my @warnings = @_;

    return Storable::nfreeze(\@warnings);
}

sub decode_warnings {
    my $self = shift;
    my $text = shift;

    return @{ Storable::thaw($text) };
}

sub DESTROY {
    my $self = shift;
    for (@{ $self->{'thss_stashed_warnings'} }) {
        warn "Unhandled warning: $_";
    }
}

1;

__END__

=head1 NAME

Test::HTTP::Server::Simple::StashWarnings - catch your forked server's warnings

=head1 SYNOPSIS

    package My::Webserver::Test;
    use base qw/Test::HTTP::Server::Simple::StashWarnings My::Webserver/;

    sub test_warning_path { "/__test_warnings" }


    package main;
    use Test::More tests => 42;

    my $s = My::WebServer::Test->new;

    my $url_root = $s->started_ok("start up my web server");

    my $mech = WWW::Mechanize->new;

    $mech->get("$url_root/some_action");

    $mech->get("/__test_warnings");
    my @warnings = My::WebServer::Test->decode_warnings($mech->content);
    is(@warnings, 0, "some_action gave no warnings");

=head1 DESCRIPTION

Warnings are an important part of any application. Your web application should
warn the user when something is amiss.

Almost as importantly, we want to be able to test that the web application
gracefully copes with bad input, the back button, and all other aspects of the
user experience.

Unfortunately, tests seldom cover what happens when things go poorly. Are you
C<sure> that your application checks authorization for that action? Are you
C<sure> it will tomorrow?

This module lets you retrieve the warnings that your forked server throws. That
way you can test that your application continues to throw warnings when it
makes sense. Catching the warnings also keeps your test output tidy. Finally,
you'll be able to see when your application throws new, unexpected warnings.

=head1 SETUP

The way this module works is it catches warnings and makes them available on a
special URL (which must be defined by you in the C<test_warning_path> method).
You can use C<WWW::Mechanize> (or whichever HTTP agent you prefer) to download
the warnings. The warnings will be serialized. Use L<decode_warnings> to get
the list of warnings seen so far (since last request anyway).

Warnings are encoded using L<Storable> by default, but your subclass may override the C<encode_warnings> and C<decode_warnings> methods.

=head1 TIPS

Setting the C<TEST_VERBOSE> environment variable to a true value will cause
warnings to be displayed immediately, even if they would be captured and tested
later.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at bestpractical.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-http-server-simple-stashwarnings at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=test-http-server-simple-stashwarnings>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

