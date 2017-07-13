package phpBB2::Simple;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use DBI;
use Perinci::Object;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'API for phpBB2',
};

our %common_args = (
    db_dsn => {
        schema => 'str*',
        req => 1,
        tags => ['common'],
    },
    db_user => {
        schema => 'str*',
        req => 1,
        tags => ['common'],
    },
    db_password => {
        schema => 'str*',
        req => 1,
        tags => ['common'],
    },
);

our %detail_arg = (
    detail => {
        summary => 'Returned detailed record for each item instead of just ID',
        schema => 'bool',
    },
);

sub __dbh {
    state $dbh;
    if (!$dbh) {
        my %args = @_;
        $dbh = DBI->connect(
            $args{db_dsn}, $args{db_user}, $args{db_password},
            {RaiseError=>1},
        );
    }
    $dbh;
}

$SPEC{list_users} = {
    v => 1.1,
    args => {
        %common_args,
        %detail_arg,
        active => {
            summary => 'Only list active users',
            schema  => 'bool',
            tags    => ['category:filtering'],
        },
        level => {
            summary => 'Only list users having certain level',
            schema  => ['str*', in=>['user', 'moderator', 'administrator']],
            tags    => ['category:filtering'],
        },
    },
};
sub list_users {
    my %args = @_;

    my $detail = $args{detail};

    my $sth = __dbh(%args)->prepare(
        "SELECT * FROM phpbb_users ORDER BY username");
    $sth->execute;
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {

        next if defined($args{active}) &&
            ($args{active} xor $row->{user_active});

        if (defined $args{level}) {
            next if $args{level} eq 'user' && $row->{user_level} != 0;
            next if $args{level} eq 'administrator' && $row->{user_level} != 1;
            next if $args{level} eq 'moderator' && $row->{user_level} != 2;
        }

        if ($args{detail}) {
            push @rows, {
                username  => $row->{username},
                email     => $row->{user_email},
                is_active => $row->{user_active},
                level     =>
                    $row->{user_level} == 0 ? "user" :
                        $row->{user_level} == 1 ? "administrator" :
                            $row->{user_level} == 2 ? "moderator" : "?",
            };
        } else {
            push @rows, $row->{username};
        }
    }
    [200, "OK", \@rows];
}

$SPEC{list_groups} = {
    v => 1.1,
    args => {
        %common_args,
        %detail_arg,
    },
};
sub list_groups {
    my %args = @_;

    my $detail = $args{detail};

    my $sth = __dbh(%args)->prepare(
        "SELECT * FROM phpbb_groups ORDER BY group_name");
    $sth->execute;
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        if ($args{detail}) {
            push @rows, {
                id          => $row->{group_id},
                name        => $row->{group_name},
                description => $row->{group_description},
                type        =>
                    $row->{group_type} == 0 ? "open" :
                        $row->{group_type} == 1 ? "closed" :
                            $row->{group_type} == 2 ? "hidden" : "?",
            };
        } else {
            push @rows, $row->{group_name};
        }
    }
    [200, "OK", \@rows];
}

$SPEC{list_group_members} = {
    v => 1.1,
    args => {
        group  => { schema=>'str*', req=>1, pos=>0 },
        %common_args,
    },
};
sub list_group_members {
    my %args = @_;

    my $sth_sel_group = __dbh(%args)->prepare(
        "SELECT group_id FROM phpbb_groups WHERE group_name=?");

    $sth_sel_group->execute($args{group});
    my $group_id = $sth_sel_group->fetchrow_array;
    return [404, "Unknown group '$args{group}'"] unless $group_id;

    my $sth = __dbh(%args)->prepare(
        "SELECT (SELECT username FROM phpbb_users u WHERE u.user_id=ug.user_id) username FROM phpbb_user_group ug WHERE group_id=? ORDER BY username");
    $sth->execute($group_id);
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        push @rows, $row->{username};
    }
    [200, "OK", \@rows];
}

$SPEC{list_user_groups} = {
    v => 1.1,
    summary => 'List groups which user belongs to',
    args => {
        %common_args,
        user => { schema=>'str*', req=>1, pos=>0 },
        # XXX option to include pending membership
    },
};
sub list_user_groups {
    my %args = @_;

    my $sth = __dbh(%args)->prepare(
        "SELECT (SELECT group_name FROM phpbb_groups g WHERE g.group_id=ug.group_id) group_name FROM phpbb_user_group ug WHERE ug.user_id=(SELECT user_id FROM phpbb_users WHERE username=?) ORDER BY group_name",
    );
    $sth->execute($args{user});
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        push @rows, $row->{group_name};
    }
    [200, "OK", \@rows];
}

$SPEC{add_user_to_groups} = {
    v => 1.1,
    summary => 'Add a user to one or more groups',
    args => {
        %common_args,
        user  => { schema=>'str*', req=>1, pos=>0 },
        group => { schema=>['array*', of=>'str*', min_len=>1],
                   req=>1, pos=>1, greedy=>1 },
    },
};
sub add_user_to_groups {
    my %args = @_;

    my $sth_sel_user = __dbh(%args)->prepare(
        "SELECT user_id FROM phpbb_users WHERE username=?");
    my $sth_sel_group = __dbh(%args)->prepare(
        "SELECT group_id FROM phpbb_groups WHERE group_name=?");
    my $sth_add = __dbh(%args)->prepare(
        "INSERT IGNORE INTO phpbb_user_group (user_id, group_id, user_pending) VALUES (?,?,0)");

    $sth_sel_user->execute($args{user});
    my ($user_id) = $sth_sel_user->fetchrow_array;
    return [404, "Unknown user '$args{user}'"] unless $user_id;

    my $res = riresmulti();
    for my $group (@{ $args{group} }) {
        $sth_sel_group->execute($group);
        my $group_id = $sth_sel_group->fetchrow_array;
        if (!$group_id) {
            $res->add_result(404, "Group not found", {item_id=>$group});
            next;
        }
        $sth_add->execute($user_id, $group_id);
        $res->add_result(200, "OK", {item_id=>$group});
    }
    $res->as_struct;
}

$SPEC{delete_user_from_groups} = {
    v => 1.1,
    summary => 'Delete a user from one or more groups',
    args => {
        %common_args,
        user  => { schema=>'str*', req=>1, pos=>0 },
        group => { schema=>['array*', of=>'str*', min_len=>1],
                   req=>1, pos=>1, greedy=>1 },
    },
};
sub delete_user_from_groups {
    my %args = @_;

    my $sth_sel_user = __dbh(%args)->prepare(
        "SELECT user_id FROM phpbb_users WHERE username=?");
    my $sth_sel_group = __dbh(%args)->prepare(
        "SELECT group_id FROM phpbb_groups WHERE group_name=?");
    my $sth_del = __dbh(%args)->prepare(
        "DELETE FROM phpbb_user_group WHERE user_id=? AND group_id=?");

    $sth_sel_user->execute($args{user});
    my ($user_id) = $sth_sel_user->fetchrow_array;
    return [404, "Unknown user '$args{user}'"] unless $user_id;

    my $res = envresmulti();
    for my $group (@{ $args{group} }) {
        $sth_sel_group->execute($group);
        my $group_id = $sth_sel_group->fetchrow_array;
        if (!$group_id) {
            $res->add_result(404, "Group not found", {item_id=>$group});
            next;
        }
        $sth_del->execute($user_id, $group_id);
        $res->add_result(200, "OK", {item_id=>$group});
    }
    $res->as_struct;
}

$SPEC{delete_user_from_all_forum_moderators} = {
    v => 1.1,
    summary => 'Delete a user from being moderator in all forums',
    args => {
        %common_args,
        user  => { schema=>'str*', req=>1, pos=>0 },
    },
};
sub delete_user_from_all_forum_moderators {
    my %args = @_;

    my $sth_sel_user = __dbh(%args)->prepare(
        "SELECT user_id FROM phpbb_users WHERE username=?");

    $sth_sel_user->execute($args{user});
    my ($user_id) = $sth_sel_user->fetchrow_array;
    return [404, "Unknown user '$args{user}'"] unless $user_id;

    __dbh(%args)->do("DELETE FROM phpbb_auth_access WHERE auth_mod=1 AND group_id IN (SELECT group_id FROM phpbb_user_group WHERE group_id IN (SELECT group_id FROM phpbb_groups WHERE group_single_user=1) AND user_id=?)", {}, $user_id);
    [200,"OK"];
}

1;
# ABSTRACT: API for phpBB2

__END__

=pod

=encoding UTF-8

=head1 NAME

phpBB2::Simple - API for phpBB2

=head1 VERSION

This document describes version 0.04 of phpBB2::Simple (from Perl distribution phpBB2-Simple), released on 2017-07-10.

=head1 SYNOPSIS

=head1 DESCRIPTION

I know, phpBB2 is beyond ancient (2007 and earlier), but our intranet board
still runs it and some things are more convenient to do via CLI script than via
web-based administration panel.

=head1 FUNCTIONS


=head2 add_user_to_groups

Usage:

 add_user_to_groups(%args) -> [status, msg, result, meta]

Add a user to one or more groups.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn>* => I<str>

=item * B<db_password>* => I<str>

=item * B<db_user>* => I<str>

=item * B<group>* => I<array[str]>

=item * B<user>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 delete_user_from_all_forum_moderators

Usage:

 delete_user_from_all_forum_moderators(%args) -> [status, msg, result, meta]

Delete a user from being moderator in all forums.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn>* => I<str>

=item * B<db_password>* => I<str>

=item * B<db_user>* => I<str>

=item * B<user>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 delete_user_from_groups

Usage:

 delete_user_from_groups(%args) -> [status, msg, result, meta]

Delete a user from one or more groups.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn>* => I<str>

=item * B<db_password>* => I<str>

=item * B<db_user>* => I<str>

=item * B<group>* => I<array[str]>

=item * B<user>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_group_members

Usage:

 list_group_members(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn>* => I<str>

=item * B<db_password>* => I<str>

=item * B<db_user>* => I<str>

=item * B<group>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_groups

Usage:

 list_groups(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn>* => I<str>

=item * B<db_password>* => I<str>

=item * B<db_user>* => I<str>

=item * B<detail> => I<bool>

Returned detailed record for each item instead of just ID.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_user_groups

Usage:

 list_user_groups(%args) -> [status, msg, result, meta]

List groups which user belongs to.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_dsn>* => I<str>

=item * B<db_password>* => I<str>

=item * B<db_user>* => I<str>

=item * B<user>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_users

Usage:

 list_users(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<active> => I<bool>

Only list active users.

=item * B<db_dsn>* => I<str>

=item * B<db_password>* => I<str>

=item * B<db_user>* => I<str>

=item * B<detail> => I<bool>

Returned detailed record for each item instead of just ID.

=item * B<level> => I<str>

Only list users having certain level.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/phpBB2-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-phpBB2-Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=phpBB2-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
