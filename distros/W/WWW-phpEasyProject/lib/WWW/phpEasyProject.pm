package WWW::phpEasyProject;

our $DATE = '2017-02-22'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    require WWW::Mechanize::GZip;

    my ($class, %args) = @_;

    $args{_mech} = WWW::Mechanize::GZip->new(
        (agent => $args{agent}) x !!defined($args{agent}),

        # this is because phpEasyProject uses 500 error to show login form
        onerror => undef,
    );

    bless \%args, $class;
}

sub login {
    my $self = shift;

    return if $self->{_logged_in};

    my $url = $self->{url} . ($self->{url} =~ m!/\z! ? '' : '/') .
        'index.php?'.rand(); # too-aggresive squid cache

    my $res = $self->{_mech}->get($url);
    die "Can't get $url: ".$res->code." ".$res->message
        unless $res->code =~ /^(200|500)/;

    $res = $self->{_mech}->submit_form(
        with_fields => {
            username => $self->{username},
            password => $self->{password},
        }
    );
    die "Can't login to $url: ".$res->code." ".$res->message
        unless $res->is_success;

    my $ct = $res->content;
    if ($ct =~ m!<ul id="errors"><li>(.+?)</li>!s) {
        die "Can't login to $url: $1";
    } elsif ($ct =~ m!<div id="loginbox">User: !) {
        $self->{_logged_in}++;
        return 1;
    } else {
        die "Unknown response when login to $url (can't find out if login succeeded or failed)";
    }
}

sub logout {
    my $self = shift;

    return unless $self->{_logged_in};

    my $url = $self->{url} . ($self->{url} =~ m!/\z! ? '' : '/') .
        'index.php?'.rand(); # too-aggresive squid cache

    my $res = $self->{_mech}->get($url);
    die "Can't get $url: ".$res->code." ".$res->message
        unless $res->is_success;

    $res = $self->{_mech}->submit_form(
        with_fields => {
            action => 'logout',
        }
    );
    die "Can't login to $url: ".$res->code." ".$res->message
        unless $res->is_success;

    my $ct = $res->content;
    if ($ct =~ m!<span class="tab selected">Login</span>!) {
        $self->{_logged_in} = 0;
        return 1;
    } else {
        die "Can't logout: did not receive login page again";
    }
}

sub add_task {
    my ($self, %args) = @_;

    my $url = $self->{url} . ($self->{url} =~ m!/\z! ? '' : '/') .
        'index.php?'.rand(); # too-aggresive squid cache

    $self->login;
    my $res = $self->{_mech}->submit_form(
        with_fields => {
            movefield => '',
            formsend => 1,
            todotitle => $args{title} // '',
            (todoproject => $args{project})          x !!defined($args{project}),
            (todostart => $args{start_date})         x !!defined($args{start_date}),,
            (todofinish => $args{finish_date})       x !!defined($args{finish_date}),
            (todoprio => $args{priority})            x !!defined($args{priority}),
            (todowarndiff => $args{warn_period})     x !!defined($args{warn_period}),
            (tododof => $args{degree_of_completion}) x !!defined($args{degree_of_completion}), # 0 = 0%, 1 = 25%, 2 = 50%, 3 = 75%, 4 = 100%
            (todocomment => $args{comment})          x !!defined($args{comment}),
            (todoprivat => 1)                        x !!($args{is_private}),
            (todoagreed => 1)                        x !!($args{is_agreed}),
        },
    );
    die "Can't add task at $url: ".$res->code." ".$res->message
        unless $res->is_success;

    my $ct = $res->content;
    if ($ct =~ m!Errors:.+?<li>(.+?)</li>!s) {
        die "Can't add task at $url: $1";
    } else {
        # assume it's successful
        return 1;
    }
}

1;
# ABSTRACT: API to phpEasyProject-based website

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::phpEasyProject - API to phpEasyProject-based website

=head1 VERSION

This document describes version 0.001 of WWW::phpEasyProject (from Perl distribution WWW-phpEasyProject), released on 2017-02-22.

=head1 SYNOPSIS

 use WWW::phpEasyProject;

 my $pep = WWW::phpEasyProject->new(
     url      => 'http://project.example.com/',
     username => 'foo',
     password => 'secret',
     #agent   => '...', # passed to WWW::Mechanize
 );

 $pep->add_task(

 );

=head1 METHODS

=head2 new

=head2 login

=head2 logout

=head2 add_task

Usage: $pep->add_task(%args) => 1 (or die)

Known arguments:

=over

=item * title => str

=item * project => int

=item * start_date => str (e.g. "12-25-2017")

=item * finish_date => str (e.g. "12-25-2017")

=item * priority => int (e.g. 2)

=item * warn_period => int (e.g. 86400 to mean 1 day)

=item * degree_of_completion => int (0..4, 0 means 0%, 1 means 25%, 2 means 50%, 3 means 75%, 4 means 100%)

=item * comment => str

=item * is_private => bool

=item * is_agreed => bool

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WWW-phpEasyProject>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WWW-phpEasyProject>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-phpEasyProject>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://www.phpeasyproject.com/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
