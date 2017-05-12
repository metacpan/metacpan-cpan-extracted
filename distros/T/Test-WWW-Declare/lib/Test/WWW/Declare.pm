package Test::WWW::Declare;
use warnings;
use strict;
use base 'Test::More';
use Test::WWW::Mechanize;
use Test::Builder;

our $VERSION  = '0.02';

our @EXPORT = qw(flow run get session check mech match follow_link content
                 should shouldnt click href button fill form SKIP _twd_dummy
                 title equal caselessly contain matches equals contains
                 never always lack lacks url uri);
our $BUILDER = Test::Builder->new();
our $WWW_MECHANIZE;
our $IN_FLOW;
our %mechs;

=begin private

=head2 import_extra

Called by L<Test::More>'s C<import> code when L<Test::WWW::Declare> is first
C<use>'d, it asks Test::More to export its symbols to the namespace that
C<use>'d this one.

=end private

=cut

sub import_extra {
    Test::More->export_to_level(2);
}

=head1 NAME

Test::WWW::Declare - declarative testing for your web app

=head1 SYNOPSIS

    use Test::WWW::Declare tests => 3;
    use Your::Web::App::Test;

    Your::Web::App::Test->start_server;

    session 'testuser' => run {
        flow 'log in and out' => check {
            flow 'log in' => check {
                get 'http://localhost/';
                fill form 'login' => {
                    username => 'testuser',
                    password => 'drowssap',
                };
                content should contain 'log out';
            };

            flow 'log out' => check {
                get 'http://localhost/';
                click href 'log out';
            };
        };
    };

=head1 DESCRIPTION

Often in web apps, tests are very dependent on the state set up by previous
tests. If one test fails (e.g. "follow the link to the admin page") then it's
likely there will be many more failures. This module aims to alleviate this
problem, as well as provide a nicer interface to L<Test::WWW::Mechanize>.

The central idea is that of "flow". Each flow is a sequence of commands ("fill
in this form") and assertions ("content should contain 'testuser'"). If any of
these commands or assertions fail then the flow is aborted. Only that one
failure is reported to the test harness and user. Flows may also contain other
flows. If an inner flow fails, then the outer flow fails as well.

=head1 FLOWS AND SESSIONS

=head2 session NAME => run { CODE }

Sessions are a way of associating a set of flows with a L<WWW::Mechanize>
instance. A session is mostly equivalent with a user interacting with your web
app.

Within a session, every command (C<get>, C<click link>, etc) is operating on
that session's L<WWW::Mechanize> instance. You may have multiple sessions in
one test file. Two sessions with the same name are in fact the same session.
This lets you write code like the following, simplified slightly:

    session 'first user' => run {
        get "$URL/give?task=1&victim=other";
        session 'other user' => run {
            get "$URL/tasks";
            content should match qr/task 1/;

            # this is the same session/mech as the outermost 'first user'
            session 'first user' => run {
                get "$URL/tasks";
                content shouldnt match qr/task 1/;
            };
        };
    };

=head2 flow NAME => check { CODE }

A flow encompasses a single test. As described above, each flow is a sequence
of commands, assertions, and other flows. If any of the components of a flow
fail, the rest of the flow is aborted and one or more test failures are
reported to the test harness.

=head1 COMMANDS

=head2 get URL

=head2 click button

=head2 click href

=head2 follow_link

=head2 fill form NAME => {FIELD1 => VALUE1, FIELD2 => VALUE2}

=head1 ASSERTIONS

Every assertion has two parts: a subject and a verb.

=head2 SUBJECTS

=head3 content

=head3 title

=head3 url

=head2 VERBS

=head3 should(nt) (caselessly) match REGEX

=head3 should(nt) (caselessly) contain STRING

=head3 should(nt) (caselessly) lack STRING

=head3 should(nt) (caselessly) equal STRING

=cut

# DSLey functions
sub to($) { return $_[0] }

sub _args {
    my $args = shift;
    return $args if ref($args) eq 'HASH';
    return {expected => $args};
}

sub should ($) {
    return _args(shift);
}

sub shouldnt ($) {
    my $args = _args(shift);
    $args->{negative} = 1;
    return $args;
}

sub match ($) {
    my $args = _args(shift);
    $args->{match} = 'regex';
    return $args;
}

sub equal ($) {
    my $args = _args(shift);
    $args->{match} = 'equality';
    return $args;
}

sub contain ($) {
    my $args = _args(shift);
    $args->{match} = 'index';
    return $args;
}

sub lack ($) {
    my $args = _args(shift);
    $args->{match} = 'index';
    $args->{negative} = 1;
    return $args;
}

sub caselessly ($) {
    my $args = _args(shift);
    $args->{case_insensitive} = 1;
    return $args;
}

sub check (&) {
    my $coderef = shift;

    return $coderef;
}

sub run (&) {
    my $coderef = shift;

    return $coderef;
}

# alternates (e.g. "foo matches bar" instead of "foo should match bar")
sub contains ($) { contain  $_[0] }
sub equals   ($) { equal    $_[0] }
sub matches  ($) { match    $_[0] }
sub lacks    ($) { lack     $_[0] }

sub always   ($) { should   $_[0] }
sub never    ($) { shouldnt $_[0] }

# Mech interactions
sub mech(;$) {
    my $name = shift;
    return defined $name ? $mechs{$name} : $WWW_MECHANIZE;
}

sub get {
    my $url = shift;

    mech()->get($url);
    if (!$IN_FLOW)
    {
        $BUILDER->ok(mech->success, "navigated to $url");
    }

    return if mech->success;

    Carp::croak mech->status
             . (mech->response ? ' - ' . mech->response->message : '')
}

sub href ($) {
    return (shift, 'href');
}

sub button ($) {
    return (shift, 'button');
}

sub click {
    my $link = shift;
    my $type = shift;

    if ($type eq 'button') {
        my $ok = mech()->click_button(value => $link);
        $ok = $ok->is_success if $ok;
        my $verb = ref($link) eq 'Regexp' ? "matching " : "";
        $BUILDER->ok($ok, "Clicked button $verb$link") if !$IN_FLOW;
        return $ok;
    }
    else {
        if (ref $link ne 'Regexp') {
            Carp::croak "click doesn't know what to do with a link type of "
              . ref($link);
        }
        my $ok;
        my $response = mech()->follow_link(text_regex => $link);
        $ok = 1 if $response && $response->is_success;
        $BUILDER->ok($ok, "Clicked link matching $link") if !$IN_FLOW;
        Carp::croak($response ? $response->as_string : "No link matching $link found") if !$ok;
        return $ok;
    }
}

sub follow_link {
    my $ret = mech()->follow_link(@_);

    if (!$ret) {
        Carp::croak "follow_link couldn't find a link matching "
          . "(" . join(', ', @_) . ")";
    }
}

sub content ($) {
    _magic_match({got => mech()->content, name => "Content", %{shift @_}});
}

sub title ($) {
    my $title = mech()->title;
    _magic_match({got => $title, name => "Title '$title'", %{shift @_}});
}

sub url ($) {
    my $url = mech()->uri;
    _magic_match({got => $url, name => "URL '$url'", %{shift @_}});
}
*uri = \&url;

# yes, there's a little too much logic in here. that's why it's magic
sub _magic_match {
    my $orig = shift @_;
    my %args = %$orig;
    my $match;
    my @output;

    $args{negative} ||= 0;

    push @output, $args{name};
    push @output, $args{negative} ? ()
                                  : "does not";

    if ($args{match} eq 'equality') {
        if ($args{case_insensitive}) {
            push @output, "caselessly";
            $args{got} = lc $args{got};
            $args{expected} = lc $args{expected};
        }

        push @output, $args{negative} ? "equals"
                                      : "equal";
        push @output, $orig->{expected};

        $match = $args{got} eq $args{expected};
    }
    elsif ($args{match} eq 'index') {
        if ($args{case_insensitive}) {
            push @output, "caselessly";
            $args{got} = lc $args{got};
            $args{expected} = lc $args{expected};
        }

        push @output, $args{negative} ? "contains"
                                      : "contain";
        push @output, $orig->{expected};

        $match = index($args{got}, $args{expected}) >= 0;
    }
    elsif ($args{match} eq 'regex') {
        if ($args{case_insensitive}) {
            push @output, "caselessly";
            push @output, $args{expected};
            $args{expected} = "(?i:$args{expected})";
        }

        push @output, $args{negative} ? "matches"
                                      : "match";
        push @output, $orig->{expected};

        $match = $args{got} =~ $args{expected};
    }
    else {
        Carp::croak "No \$args{match} (yes this error needs to be fixed)";
    }

    my $ok = ($match ? 1 : 0) ^ $args{negative};
    if (!$IN_FLOW) {
        $BUILDER->ok($ok, join(' ', @output));
        return $ok;
    }

    return 1 if $ok;
    Carp::croak join(' ', @output);
}

sub form ($$) {
    my $form_name = shift;
    my $data = shift;

    my $form = mech()->form_name($form_name);

    if (!defined($form)) {
        Carp::croak "There is no form named '$form_name'";
    }

    return $data;
}

sub fill {
    my $data = shift;

    Carp::croak "fill expects a hashref" if ref($data) ne 'HASH';

    mech()->set_fields(%{$data});
}

# the meat of the module
sub SKIP ($) {
    my $reason = shift;

    Carp::croak "SKIP: $reason";
}

sub flow ($$) {
    my $name = shift;
    my $coderef = shift;

    eval { local $IN_FLOW = 1; $coderef->() };

    if ($@ =~ /^SKIP: (.*)$/) {
        my $reason = $1;
        $BUILDER->skip($reason);
    }
    elsif ($@) {
        if ($IN_FLOW) {
            if ($@ =~ /^Flow '/)
            {
                die $@;
            }
            die "Flow '$name' failed: $@";
        }

        $BUILDER->ok(0, $name);

        if ($@ =~ /^Flow '/) {
            $BUILDER->diag($@);
        }
        else {
            $BUILDER->diag("Flow '$name' failed: $@");
        }
    }
    else {
        $BUILDER->ok(1, $name);
    }
}

sub session ($$) {
    my $title = shift;
    my $coderef = shift;

    $mechs{$title} ||= Test::WWW::Mechanize->new(quiet => 1);
    local $WWW_MECHANIZE = $mechs{$title};

    $coderef->();

    if ($@ =~ /^SKIP: (.*)$/) {
        my $reason = $1;
        $BUILDER->skip($reason);
    }
    elsif ($@ =~ /^Flow '/) {
        # flow already displayed the error
    }
    elsif ($@) {
        $BUILDER->diag($@);
    }
}

sub dump($) {
    my $file = shift;
    mech->save_content($file);
}

# used only for testing that we got T:W:D's goods
sub _twd_dummy { "XYZZY" }

=head1 SUBCLASSING

One of the goals of this module is to let you subclass it to provide extra
features, such as automatically logging in a user each time a session is
created.

=head1 CAVEATS

If you fail any tests, then the actual number of tests run may be fewer than
you have in your file. This is because when a flow fails, it immediately aborts
the rest of its body (which may include other flows). So if you're setting the
number of tests based on how many ran, make sure that all tests passed.

=head1 BUGS

Hopefully few. We'd like to know about any of them. Please report them to
C<bug-test-www-declare@rt.cpan.org>.

=head1 SEE ALSO

L<Test::WWW::Mechanize>, L<Jifty>.

=head1 MAINTAINER

Shawn M Moore C<< <sartak@bestpractical.com> >>

=head1 ORIGINAL AUTHOR

Jesse Vincent C<< <jesse@bestpractical.com> >>

=head1 COPYRIGHT

Copyright 2007-2008 Best Practical Solutions, LLC

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

