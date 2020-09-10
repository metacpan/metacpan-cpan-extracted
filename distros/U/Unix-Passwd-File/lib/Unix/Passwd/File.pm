## no critic (InputOutput::RequireBriefOpen)

package Unix::Passwd::File;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-29'; # DATE
our $DIST = 'Unix-Passwd-File'; # DIST
our $VERSION = '0.251'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
#use Log::ger;

use File::Flock::Retry;
use List::Util qw(max first);
use List::MoreUtils qw(firstidx);

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       add_delete_user_groups
                       add_group
                       add_user
                       add_user_to_group
                       delete_group
                       delete_user
                       delete_user_from_group
                       get_group
                       get_max_gid
                       get_max_uid
                       get_user
                       get_user_groups
                       group_exists
                       is_member
                       list_groups
                       list_users
                       list_users_and_groups
                       modify_group
                       modify_user
                       set_user_groups
                       set_user_password
                       user_exists
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Manipulate /etc/{passwd,shadow,group,gshadow} entries',
};

my %common_args = (
    etc_dir => {
        summary => 'Specify location of passwd files',
        schema  => ['str*' => {default=>'/etc'}],
        tags    => ['common'],
    },
);
my %write_args = (
    backup => {
        summary => 'Whether to backup when modifying files',
        description => <<'_',

Backup is written with `.bak` extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

_
        schema  => ['bool' => {default=>0}],
    },
);

our $re_user   = qr/\A[A-Za-z0-9._-]+\z/;
our $re_group  = $re_user;
our $re_field  = qr/\A[^\n:]*\z/;
our $re_posint = qr/\A[1-9][0-9]*\z/;

our %passwd_fields = (
    user => {
        summary => 'User (login) name',
        schema  => ['unix::username*' => {match => $re_user}],
        pos     => 0,
    },
    pass => {
        summary => 'Password, generally should be "x" which means password is '.
            'encrypted in shadow',
        schema  => ['str*' => {match => $re_field}],
        pos     => 1,
    },
    uid => {
        summary => 'Numeric user ID',
        schema  => 'unix::uid*',
        pos     => 2,
    },
    gid => {
        summary => 'Numeric primary group ID for this user',
        schema  => 'unix::gid*',
        pos     => 3,
    },
    gecos => {
        summary => 'Usually, it contains the full username',
        schema  => ['str*' => {match => $re_field}],
        pos     => 4,
    },
    home => {
        summary => 'User\'s home directory',
        schema  => ['dirname*' => {match => $re_field}],
        pos     => 5,
    },
    shell => {
        summary => 'User\'s shell',
        schema  => ['filename*' => {match=>qr/\A[^\n:]*\z/}],
        pos     => 6,
    },
);
our @passwd_field_names;
for (keys %passwd_fields) {
    $passwd_field_names[$passwd_fields{$_}{pos}] = $_;
    delete $passwd_fields{$_}{pos};
}

our %shadow_fields = (
    user => {
        summary => 'User (login) name',
        schema  => ['unix::username*' => {match => $re_user}],
        pos     => 0,
    },
    encpass => {
        summary => 'Encrypted password',
        schema  => ['str*' => {match => $re_field}],
        pos     => 1,
    },
    last_pwchange => {
        summary => 'The date of the last password change, '.
            'expressed as the number of days since Jan 1, 1970.',
        schema  => 'int',
        pos     => 2,
    },
    min_pass_age => {
        summary => 'The number of days the user will have to wait before she '.
            'will be allowed to change her password again',
        schema  => 'int',
        pos     => 3,
    },
    max_pass_age => {
        summary => 'The number of days after which the user will have to '.
            'change her password',
        schema  => 'int',
        pos     => 4,
    },
    pass_warn_period => {
        summary => 'The number of days before a password is going to expire '.
            '(see max_pass_age) during which the user should be warned',
        schema  => 'int',
        pos     => 5,
    },
    pass_inactive_period => {
        summary => 'The number of days after a password has expired (see '.
            'max_pass_age) during which the password should still be accepted '.
                '(and user should update her password during the next login)',
        schema  => 'int',
        pos     => 6,
    },
    expire_date => {
        summary => 'The date of expiration of the account, expressed as the '.
            'number of days since Jan 1, 1970',
        schema  => 'int',
        pos     => 7,
    },
    reserved => {
        summary => 'This field is reserved for future use',
        schema  => ['str*' => {match => $re_field}],
        pos     => 8,
    }
);
our @shadow_field_names;
for (keys %shadow_fields) {
    $shadow_field_names[$shadow_fields{$_}{pos}] = $_;
    delete $shadow_fields{$_}{pos};
}

our %group_fields = (
    group => {
        summary => 'Group name',
        schema  => ['unix::groupname*' => {match => $re_group}],
        pos     => 0,
    },
    pass => {
        summary => 'Password, generally should be "x" which means password is '.
            'encrypted in gshadow',
        schema  => ['str*' => {match => $re_field}],
        pos     => 1,
    },
    gid => {
        summary => 'Numeric group ID',
        schema  => 'unix::gid*',
        pos     => 2,
    },
    members => {
        summary => 'List of usernames that are members of this group, '.
            'separated by commas',
        schema  => ['str*' => {match => $re_field}],
        pos     => 3,
    },
);
our @group_field_names;
for (keys %group_fields) {
    $group_field_names[$group_fields{$_}{pos}] = $_;
    delete $group_fields{$_}{pos};
}

our %gshadow_fields = (
    group => {
        summary => 'Group name',
        schema  => ['unix::groupname*' => {match => $re_group}],
        pos     => 0,
    },
    encpass => {
        summary => 'Encrypted password',
        schema  => ['str*' => {match=> $re_field}],
        pos     => 1,
    },
    admins => {
        summary => 'It must be a comma-separated list of user names, or empty',
        schema  => ['str*' => {match => $re_field}],
        pos     => 2,
    },
    members => {
        summary => 'List of usernames that are members of this group, '.
            'separated by commas; You should use the same list of users as in '.
                '/etc/group.',
        schema  => ['str*' => {match => $re_field}],
        pos     => 3,
    },
);
our @gshadow_field_names;
for (keys %gshadow_fields) {
    $gshadow_field_names[$gshadow_fields{$_}{pos}] = $_;
    delete $gshadow_fields{$_}{pos};
}

sub _arg_from_field {
    my ($fields, $name, %extra) = @_;
    my %spec = %{ $fields->{$name} };
    $spec{$_} = $extra{$_} for keys %extra;
    ($name => \%spec);
}

sub _backup {
    my ($fh, $path) = @_;
    seek $fh, 0, 0 or return [500, "Can't seek: $!"];
    open my($bak), ">", "$path.bak" or return [500, "Can't open $path.bak: $!"];
    while (<$fh>) { print $bak $_ }
    close $bak or return [500, "Can't write $path.bak: $!"];
    # XXX set ctime & mtime of backup file?
    [200];
}

# all public functions in this module use the _routine(), which contains the
# basic flow, to avoid duplication of code. admittedly this makes _routine()
# quite convoluted, as it tries to accomodate all the functions' logic in a
# single routine. _routine() accepts these special arguments for flow control:
#
# - _read_shadow   = 0*/1/2 (2 means optional, don't exit if fail)
# - _read_passwd   = 0*/1
# - _read_gshadow  = 0*/1/2 (2 means optional, don't exit if fail)
# - _read_group    = 0*/1
# - _lock          = 0*/1 (whether to lock)
# - _after_read    = code (executed after reading all passwd/group files)
# - _after_read_passwd_entry = code (executed after reading a line in passwd)
# - _after_read_group_entry = code (executed after reading a line in group)
# - _write_shadow  = 0*/1
# - _write_passwd  = 0*/1
# - _write_gshadow = 0*/1
# - _write_group   = 0*/1
#
# all the hooks are fed $stash, sort of like a bag or object containing all
# data. should return enveloped response. _routine() will return with response
# if response is non success. _routine() will also return immediately if
# $stash{exit} is set.
#
# to write, we open once but with mode '+<' instead of '<'. we read first then
# we seek back to beginning and write from in-memory data. if
# $stash{write_passwd} and so on is set to false, _routine() cancels the write
# (can be used e.g. when there is no change so no need to write).
#
# final result is in $stash{res} or non-success result returned by hook.
sub _routine {
    my %args = @_;

    my $etc     = $args{etc_dir} // "/etc";
    my $detail  = $args{detail};
    my $wfn     = $args{with_field_names} // 1;
    my @locks;
    my ($fhp, $fhs, $fhg, $fhgs);
    my %stash;

    my $e = eval {

        if ($args{_lock}) {
            for (qw/passwd shadow group gshadow/) {
                push @locks, File::Flock::Retry->lock("$etc/$_", {retries=>3});
            }
        }

        # read files

        my @shadow;
        my %shadow;
        my @shadowh;
        $stash{shadow}   = \@shadow;
        $stash{shadowh}  = \@shadowh;
        if ($args{_read_shadow} || $args{_write_shadow}) {
            unless (open $fhs, ($args{_write_shadow} ? "+":"")."<",
                    "$etc/shadow") {
                if ($args{_read_shadow} == 2 && !$args{_write_shadow}) {
                    goto L1;
                } else {
                    return [500, "Can't open $etc/shadow: $!"];
                }
            }
            while (<$fhs>) {
                chomp;
                next unless /\S/; # skip empty line
                my @r = split /:/, $_, scalar(keys %shadow_fields);
                push @shadow, \@r;
                $shadow{$r[0]} = \@r;
                if ($wfn) {
                    my %r;
                    @r{@shadow_field_names} = @r;
                    push @shadowh, \%r;
                }
            }
        }

      L1:
        my @passwd;
        my @passwdh;
        $stash{passwd}   = \@passwd;
        $stash{passwdh}  = \@passwdh;
        if ($args{_read_passwd} || $args{_write_passwd}) {
            open $fhp, ($args{_write_passwd} ? "+":"")."<", "$etc/passwd"
                or return [500, "Can't open $etc/passwd: $!"];
            while (<$fhp>) {
                chomp;
                next unless /\S/; # skip empty line
                my @r = split /:/, $_, scalar(keys %passwd_fields);
                push @passwd, \@r;
                if ($wfn) {
                    my %r;
                    @r{@shadow_field_names} = @{ $shadow{$r[0]} }
                        if $shadow{$r[0]};
                    @r{@passwd_field_names} = @r;
                    push @passwdh, \%r;
                }
                if ($args{_after_read_passwd_entry}) {
                    my $res = $args{_after_read_passwd_entry}->(\%stash);
                    return $res if $res->[0] != 200;
                    return if $stash{exit};
                }
            }
        }

        my @gshadow;
        my %gshadow;
        my @gshadowh;
        $stash{gshadow}  = \@gshadow;
        $stash{gshadowh} = \@gshadowh;
        if ($args{_read_gshadow} || $args{_write_gshadow}) {
            unless (open $fhgs, ($args{_write_gshadow} ? "+":"")."<",
                    "$etc/gshadow") {
                if ($args{_read_gshadow} == 2 && !$args{_write_gshadow}) {
                    goto L2;
                } else {
                    return [500, "Can't open $etc/gshadow: $!"];
                }
            }
            while (<$fhgs>) {
                chomp;
                next unless /\S/; # skip empty line
                my @r = split /:/, $_, scalar(keys %gshadow_fields);
                push @gshadow, \@r;
                $gshadow{$r[0]} = \@r;
                if ($wfn) {
                    my %r;
                    @r{@gshadow_field_names} = @r;
                    push @gshadowh, \%r;
                }
            }
        }

      L2:
        my @group;
        my @grouph;
        $stash{group}    = \@group;
        $stash{grouph}   = \@grouph;
        if ($args{_read_group} || $args{_write_group}) {
            open $fhg, ($args{_write_group} ? "+":"")."<",
                "$etc/group"
                    or return [500, "Can't open $etc/group: $!"];
            while (<$fhg>) {
                chomp;
                next unless /\S/; # skip empty line
                my @r = split /:/, $_, scalar(keys %group_fields);
                push @group, \@r;
                if ($wfn) {
                    my %r;
                    @r{@gshadow_field_names} = @{ $gshadow{$r[0]} }
                        if $gshadow{$r[0]};
                    @r{@group_field_names}   = @r;
                    push @grouph, \%r;
                }
                if ($args{_after_read_group_entry}) {
                    my $res = $args{_after_read_group_entry}->(\%stash);
                    return $res if $res->[0] != 200;
                    return if $stash{exit};
                }
            }
        }

        if ($args{_after_read}) {
            my $res = $args{_after_read}->(\%stash);
            return $res if $res->[0] != 200;
            return if $stash{exit};
        }

        # write files

        if ($args{_write_shadow} && ($stash{write_shadow}//1)) {
            if ($args{backup}) {
                my $res = _backup($fhs, "$etc/shadow");
                return $res if $res->[0] != 200;
            }
            seek $fhs, 0, 0 or return [500, "Can't seek in $etc/shadow: $!"];
            for (@shadow) {
                print $fhs join(":", map {$_//""} @$_), "\n";
            }
            truncate $fhs, tell($fhs);
            close $fhs or return [500, "Can't close $etc/shadow: $!"];
            chmod 0640, "$etc/shadow"; # check error?
        }

        if ($args{_write_passwd} && ($stash{write_passwd}//1)) {
            if ($args{backup}) {
                my $res = _backup($fhp, "$etc/passwd");
                return $res if $res->[0] != 200;
            }
            seek $fhp, 0, 0 or return [500, "Can't seek in $etc/passwd: $!"];
            for (@passwd) {
                print $fhp join(":", map {$_//""} @$_), "\n";
            }
            truncate $fhp, tell($fhp);
            close $fhp or return [500, "Can't close $etc/passwd: $!"];
            chmod 0644, "$etc/passwd"; # check error?
        }

        if ($args{_write_gshadow} && ($stash{write_gshadow}//1)) {
            if ($args{backup}) {
                my $res = _backup($fhgs, "$etc/gshadow");
                return $res if $res->[0] != 200;
            }
            seek $fhgs, 0, 0 or return [500, "Can't seek in $etc/gshadow: $!"];
            for (@gshadow) {
                print $fhgs join(":", map {$_//""} @$_), "\n";
            }
            truncate $fhgs, tell($fhgs);
            close $fhgs or return [500, "Can't close $etc/gshadow: $!"];
            chmod 0640, "$etc/gshadow"; # check error?
        }

        if ($args{_write_group} && ($stash{write_group}//1)) {
            if ($args{backup}) {
                my $res = _backup($fhg, "$etc/group");
                return $res if $res->[0] != 200;
            }
            seek $fhg, 0, 0 or return [500, "Can't seek in $etc/group: $!"];
            for (@group) {
                print $fhg join(":", map {$_//""} @$_), "\n";
            }
            truncate $fhg, tell($fhg);
            close $fhg or return [500, "Can't close $etc/group: $!"];
            chmod 0644, "$etc/group"; # check error?
        }

        [200, "OK"];
    }; # eval
    $e = [500, "Died: $@"] if $@;

    # release the locks
    undef @locks;

    $stash{res} //= $e if $e && $e->[0] != 200;
    $stash{res} //= $e if $e && $e->[0] != 200;
    $stash{res} //= [500, "BUG: res not set"];

    $stash{res};
}

$SPEC{list_users} = {
    v => 1.1,
    summary => 'List Unix users in passwd file',
    args => {
        %common_args,
        detail => {
            summary => 'If true, return all fields instead of just usernames',
            schema => ['bool' => {default => 0}],
        },
        with_field_names => {
            summary => 'If false, don\'t return hash for each entry',
            schema => [bool => {default=>1}],
            description => <<'_',

By default, when `detail=>1`, a hashref is returned for each entry containing
field names and its values, e.g. `{user=>"titin", pass=>"x", uid=>500, ...}`.
With `with_field_names=>0`, an arrayref is returned instead: `["titin", "x",
500, ...]`.

_
        },
    },
};
sub list_users {
    my %args = @_;
    my $detail = $args{detail};
    my $wfn    = $args{with_field_names} // ($detail ? 1:0);

    _routine(
        %args,
        _read_passwd     => 1,
        _read_shadow     => $detail ? 2:0,
        with_field_names => $wfn,
        _after_read      => sub {
            my $stash = shift;

            my @rows;
            my $passwd  = $stash->{passwd};
            my $passwdh = $stash->{passwdh};

            for (my $i=0; $i < @$passwd; $i++) {
                if (!$detail) {
                    push @rows, $passwd->[$i][0];
                } elsif ($wfn) {
                    push @rows, $passwdh->[$i];
                } else {
                    push @rows, $passwd->[$i];
                }
            }

            $stash->{res} = [200, "OK", \@rows];
            $stash->{res}[3]{'table.fields'} = [\@passwd_field_names]
                if $detail;
            $stash->{exit}++;
            [200];
        },
    );
}

$SPEC{get_user} = {
    v => 1.1,
    summary => 'Get user details by username or uid',
    description => <<'_',

Either `user` OR `uid` must be specified.

The function is not dissimilar to Unix's `getpwnam()` or `getpwuid()`.

_
    args_rels => {
        'choose_one' => [qw/user uid/],
    },
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
        },
        uid => {
            schema => 'unix::uid*',
        },
        with_field_names => {
            summary => 'If false, don\'t return hash',
            schema => [bool => {default=>1}],
            description => <<'_',

By default, a hashref is returned containing field names and its values, e.g.
`{user=>"titin", pass=>"x", uid=>500, ...}`. With `with_field_names=>0`, an
arrayref is returned instead: `["titin", "x", 500, ...]`.

_
        },
    },
};
sub get_user {
    my %args = @_;
    my $wfn  = $args{with_field_names} // 1;
    my $user = $args{user};
    my $uid  = $args{uid};
    return [400, "Please specify user OR uid"]
        unless defined($user) xor defined($uid);

    _routine(
        %args,
        _read_passwd     => 1,
        _read_shadow     => 2,
        with_field_names => $wfn,
        detail           => 1,
        _after_read_passwd_entry => sub {
            my $stash = shift;

            my @rows;
            my $passwd  = $stash->{passwd};
            my $passwdh = $stash->{passwdh};

            if (defined($user) && $passwd->[-1][0] eq $user ||
                    defined($uid) && $passwd->[-1][2] == $uid) {
                $stash->{res} = [200,"OK", $wfn ? $passwdh->[-1]:$passwd->[-1]];
                $stash->{exit}++;
            }
            [200];
        },
        _after_read => sub {
            my $stash = shift;
            [404, "Not found"];
        },
    );
}

$SPEC{user_exists} = {
    v => 1.1,
    summary => 'Check whether user exists',
    args_rels => {
        choose_one => [qw/user uid/],
    },
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
        },
        uid => {
            schema => 'unix::uid*',
        },
    },
    result_naked => 1,
    result => {
        schema => 'bool*',
    },
};
sub user_exists {
    my %args = @_;
    my $res = get_user(%args);
    if ($res->[0] == 404) { return 0 }
    elsif ($res->[0] == 200) { return 1 }
    else { return undef }
}

$SPEC{list_groups} = {
    v => 1.1,
    summary => 'List Unix groups in group file',
    args => {
        %common_args,
        detail => {
            summary => 'If true, return all fields instead of just group names',
            schema => ['bool' => {default => 0}],
        },
        with_field_names => {
            summary => 'If false, don\'t return hash for each entry',
            schema => [bool => {default=>1}],
            description => <<'_',

By default, when `detail=>1`, a hashref is returned for each entry containing
field names and its values, e.g. `{group=>"titin", pass=>"x", gid=>500, ...}`.
With `with_field_names=>0`, an arrayref is returned instead: `["titin", "x",
500, ...]`.

_
        },
    },
};
sub list_groups {
    my %args = @_;
    my $detail = $args{detail};
    my $wfn    = $args{with_field_names} // ($detail ? 1:0);

    _routine(
        %args,
        _read_group      => 1,
        _read_gshadow    => $detail ? 2:0,
        with_field_names => $wfn,
        _after_read      => sub {
            my $stash = shift;

            my @rows;
            my $group    = $stash->{group};
            my $grouph   = $stash->{grouph};

            for (my $i=0; $i < @$group; $i++) {
                if (!$detail) {
                    push @rows, $group->[$i][0];
                } elsif ($wfn) {
                    push @rows, $grouph->[$i];
                } else {
                    push @rows, $group->[$i];
                }
            }

            $stash->{res} = [200, "OK", \@rows];
            $stash->{res}[3]{'table.fields'} = [\@group_field_names] if $detail;
            $stash->{exit}++;
            [200];
        },
    );
}

$SPEC{get_group} = {
    v => 1.1,
    summary => 'Get group details by group name or gid',
    description => <<'_',

Either `group` OR `gid` must be specified.

The function is not dissimilar to Unix's `getgrnam()` or `getgrgid()`.

_
    args_rels => {
        choose_one => [qw/group gid/],
    },
    args => {
        %common_args,
        group => {
            schema => 'unix::username*',
        },
        gid => {
            schema => 'unix::gid*',
        },
        with_field_names => {
            summary => 'If false, don\'t return hash',
            schema => [bool => {default=>1}],
            description => <<'_',

By default, a hashref is returned containing field names and its values, e.g.
`{group=>"titin", pass=>"x", gid=>500, ...}`. With `with_field_names=>0`, an
arrayref is returned instead: `["titin", "x", 500, ...]`.

_
        },
    },
};
sub get_group {
    my %args  = @_;
    my $wfn   = $args{with_field_names} // 1;
    my $gn    = $args{group};
    my $gid   = $args{gid};
    return [400, "Please specify group OR gid"]
        unless defined($gn) xor defined($gid);

    _routine(
        %args,
        _read_group      => 1,
        _read_gshadow    => 2,
        with_field_names => $wfn,
        detail           => 1,
        _after_read_group_entry => sub {
            my $stash = shift;

            my @rows;
            my $group  = $stash->{group};
            my $grouph = $stash->{grouph};

            if (defined($gn) && $group->[-1][0] eq $gn ||
                    defined($gid) && $group->[-1][2] == $gid) {
                $stash->{res} = [200,"OK", $wfn ? $grouph->[-1]:$group->[-1]];
                $stash->{exit}++;
            }
            [200];
        },
        _after_read => sub {
            my $stash = shift;
            [404, "Not found"];
        },
    );
}

$SPEC{list_users_and_groups} = {
    v => 1.1,
    summary => 'List Unix users and groups in passwd/group files',
    description => <<'_',

This is basically `list_users()` and `list_groups()` combined, so you can get
both data in a single call. Data is returned in an array. Users list is in the
first element, groups list in the second.

_
    args => {
        %common_args,
        detail => {
            summary => 'If true, return all fields instead of just names',
            schema => ['bool' => {default => 0}],
        },
        with_field_names => {
            summary => 'If false, don\'t return hash for each entry',
            schema => [bool => {default=>1}],
        },
    },
};
sub list_users_and_groups {
    my %args = @_;
    my $detail = $args{detail};
    my $wfn    = $args{with_field_names} // ($detail ? 1:0);

    _routine(
        %args,
        _read_passwd     => 1,
        _read_shadow     => $detail ? 2:0,
        _read_group      => 1,
        _read_gshadow    => $detail ? 2:0,
        with_field_names => $wfn,
        _after_read      => sub {
            my $stash = shift;

            my @users;
            my $passwd  = $stash->{passwd};
            my $passwdh = $stash->{passwdh};
            for (my $i=0; $i < @$passwd; $i++) {
                if (!$detail) {
                    push @users, $passwd->[$i][0];
                } elsif ($wfn) {
                    push @users, $passwdh->[$i];
                } else {
                    push @users, $passwd->[$i];
                }
            }

            my @groups;
            my $group   = $stash->{group};
            my $grouph  = $stash->{grouph};
            for (my $i=0; $i < @$group; $i++) {
                if (!$detail) {
                    push @groups, $group->[$i][0];
                } elsif ($wfn) {
                    push @groups, $grouph->[$i];
                } else {
                    push @groups, $group->[$i];
                }
            }

            $stash->{res} = [200, "OK", [\@users, \@groups]];

            $stash->{exit}++;
            [200];
        },
    );
}

$SPEC{group_exists} = {
    v => 1.1,
    summary => 'Check whether group exists',
    args_rels => {
        choose_one => [qw/group gid/],
    },
    args => {
        %common_args,
        group => {
            schema => 'unix::groupname*',
        },
        gid => {
            schema => 'unix::gid*',
        },
    },
    result_naked => 1,
    result => {
        schema => 'bool',
    },
};
sub group_exists {
    my %args = @_;
    my $res = get_group(%args);
    if ($res->[0] == 404) { return 0 }
    elsif ($res->[0] == 200) { return 1 }
    else { return undef }
}

$SPEC{get_user_groups} = {
    v => 1.1,
    summary => 'Return groups which the user belongs to',
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        detail => {
            summary => 'If true, return all fields instead of just group names',
            schema => ['bool' => {default => 0}],
        },
        with_field_names => {
            summary => 'If false, don\'t return hash for each entry',
            schema => [bool => {default=>1}],
            description => <<'_',

By default, when `detail=>1`, a hashref is returned for each entry containing
field names and its values, e.g. `{group=>"titin", pass=>"x", gid=>500, ...}`.
With `with_field_names=>0`, an arrayref is returned instead: `["titin", "x",
500, ...]`.

_
        },
    },
};
# this is a routine to list groups, but filtered using a criteria. can be
# refactored into a common routine (along with list_groups) if needed, to reduce
# duplication.
sub get_user_groups {
    my %args = @_;
    my $user = $args{user} or return [400, "Please specify user"];
    my $detail = $args{detail};
    my $wfn    = $args{with_field_names} // ($detail ? 1:0);

    _routine(
        %args,
        _read_passwd     => 1,
        _read_group      => 1,
        _read_gshadow    => $detail ? 2:0,
        with_field_names => $wfn,
        _after_read      => sub {
            my $stash = shift;

            my $passwd = $stash->{passwd};
            return [404, "User not found"]
                unless first {$_->[0] eq $user} @$passwd;

            my @rows;
            my $group    = $stash->{group};
            my $grouph   = $stash->{grouph};

            for (my $i=0; $i < @$group; $i++) {
                my @mm = split /,/, $group->[$i][3];
                next unless $user ~~ @mm || $group->[$i][0] eq $user;
                if (!$detail) {
                    push @rows, $group->[$i][0];
                } elsif ($wfn) {
                    push @rows, $grouph->[$i];
                } else {
                    push @rows, $group->[$i];
                }
            }

            $stash->{res} = [200, "OK", \@rows];

            $stash->{exit}++;
            [200];
        },
    );
}

$SPEC{is_member} = {
    v => 1.1,
    summary => 'Check whether user is member of a group',
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        group => {
            schema => 'unix::groupname*',
            req => 1,
            pos => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => 'bool',
    },
};
sub is_member {
    my %args = @_;
    my $user  = $args{user}  or return undef;
    my $group = $args{group} or return undef;
    my $res = get_group(etc_dir=>$args{etc_dir}, group=>$group);
    return undef unless $res->[0] == 200;
    my @mm = split /,/, $res->[2]{members};
    return $user ~~ @mm ? 1:0;
}

$SPEC{get_max_uid} = {
    v => 1.1,
    summary => 'Get maximum UID used',
    args => {
        %common_args,
    },
};
sub get_max_uid {
    my %args  = @_;
    _routine(
        %args,
        _read_passwd     => 1,
        detail           => 0,
        with_field_names => 0,
        _after_read      => sub {
            my $stash = shift;
            my $passwd = $stash->{passwd};
            $stash->{res} = [200, "OK", max(
                map {$_->[2]} @$passwd
            )];
            $stash->{exit}++;
            [200];
        },
    );
}

$SPEC{get_max_gid} = {
    v => 1.1,
    summary => 'Get maximum GID used',
    args => {
        %common_args,
    },
};
sub get_max_gid {
    require List::Util;

    my %args  = @_;
    _routine(
        %args,
        _read_group      => 1,
        detail           => 0,
        with_field_names => 0,
        _after_read      => sub {
            my $stash = shift;
            my $group = $stash->{group};
            $stash->{res} = [200, "OK", List::Util::max(
                map {$_->[2]} @$group
            )];
            $stash->{exit}++;
            [200];
        },
    );
}

sub _enc_pass {
    require Crypt::Password::Util;
    Crypt::Password::Util::crypt(shift);
}

sub _add_group_or_user {
    my ($which, %args) = @_;

    # TMP,schema
    my ($user, $gn);
    my $create_group = 1;
    if ($which eq 'user') {
        $user = $args{user} or return [400, "Please specify user"];
        $user =~ /$re_user/o
            or return [400, "Invalid user, please use $re_user"];
        $gn = $args{group} // $user;
        $create_group = 0 if $gn ne $user;
    }
    $gn //= $args{group};
    $gn or return [400, "Please specify group"];
    $gn =~ /$re_group/o
        or return [400, "Invalid group, please use $re_group"];

    my $gid     = $args{gid};
    my $min_gid = $args{min_gid} //  1000; $min_gid =     0 if $min_gid<0;
    my $max_gid = $args{max_gid} // 65535; $max_gid = 65535 if $max_gid>65535;
    my $members;
    if ($which eq 'group') {
        $members = $args{members};
        if ($members && ref($members) eq 'ARRAY') {
            $members = join(",",@$members);
        }
        $members //= "";
        $members =~ /$re_field/o
            or return [400, "Invalid members, please use $re_field"];
    } else {
        $members = "$user";
    }

    my ($uid, $min_uid, $max_uid);
    my ($pass, $gecos, $home, $shell);
    my ($encpass, $last_pwchange, $min_pass_age, $max_pass_age,
        $pass_warn_period, $pass_inactive_period, $expire_date);
    if ($which eq 'user') {
        $uid = $args{uid};
        $min_uid = $args{min_uid} //  1000; $min_uid =     0 if $min_uid<0;
        $max_uid = $args{max_uid} // 65535; $max_uid = 65535 if $min_uid>65535;

        $pass = $args{pass} // "";
        if ($pass !~ /$re_field/o) { return [400, "Invalid pass"] }

        $gecos = $args{gecos} // "";
        if ($gecos !~ /$re_field/o) { return [400, "Invalid gecos"] }

        $home = $args{home} // "";
        if ($home !~ /$re_field/o) { return [400, "Invalid home"] }

        $shell = $args{shell} // "";
        if ($shell !~ /$re_field/o) { return [400, "Invalid shell"] }

        $encpass = $args{encpass} // ($pass eq '' ? '*' : _enc_pass($pass));
        if ($encpass !~ /$re_field/o) { return [400, "Invalid encpass"] }

        $last_pwchange = int($args{last_pwchange} // time()/86400);
        $min_pass_age  = int($args{min_pass_age} // 0);
        $max_pass_age  = int($args{max_pass_age} // 99999);
        $pass_warn_period = int($args{max_pass_age} // 7);
        $pass_inactive_period = $args{pass_inactive_period} // "";
        if ($pass_inactive_period !~ /$re_field/o) {
            return [400, "Invalid pass_inactive_period"] }
        $expire_date = $args{expire_date} // "";
        if ($expire_date !~ /$re_field/o) {
            return [400, "Invalid expire_date"] }
    }

    _routine(
        %args,
        _lock            => 1,
        _write_group     => 1,
        _write_gshadow   => 1,
        _write_passwd    => $which eq 'user',
        _write_shadow    => $which eq 'user',
        _after_read      => sub {
            my $stash = shift;

            my $group   = $stash->{group};
            my $gshadow = $stash->{gshadow};
            my $write_g;
            my $cur_g = first { $_->[0] eq $gn } @$group;

            if ($which eq 'group' && $cur_g) {
                return [412, "Group $gn already exists"] if $cur_g;
            } elsif ($cur_g) {
                $gid = $cur_g->[2];
            } elsif (!$create_group) {
                return [412, "Group $gn must already exist"];
            } else {
                my @gids = map { $_->[2] } @$group;
                if (!defined($gid)) {
                    for ($min_gid .. $max_gid) {
                        do { $gid = $_; last } unless $_ ~~ @gids;
                    }
                    return [412, "Can't find available GID"]
                        unless defined($gid);
                }
                push @$group  , [$gn, "x", $gid, $members];
                push @$gshadow, [$gn, "*", "", $members];
                $write_g++;
            }
            my $r = {gid=>$gid};

            if ($which eq 'user') {
                my $passwd  = $stash->{passwd};
                my $shadow  = $stash->{shadow};
                return [412, "User $gn already exists"]
                    if first { $_->[0] eq $user } @$passwd;
                my @uids = map { $_->[2] } @$passwd;
                if (!defined($uid)) {
                    for ($min_uid .. $max_uid) {
                        do { $uid = $_; last } unless $_ ~~ @uids;
                    }
                    return [412, "Can't find available UID"]
                        unless defined($uid);
                }
                $r->{uid} = $uid;
                push @$passwd, [$user, "x", $uid, $gid, $gecos, $home, $shell];
                push @$shadow, [$user, $encpass, $last_pwchange, $min_pass_age,
                                $max_pass_age, $pass_warn_period,
                                $pass_inactive_period, $expire_date, ""];

                # add user as member of group
                for my $l (@$group) {
                    next unless $l->[0] eq $gn;
                    my @mm = split /,/, $l->[3];
                    unless ($user ~~ @mm) {
                        $l->[3] = join(",", @mm, $user);
                        $write_g++;
                        last;
                    }
                }
            }

            $stash->{write_group} = $stash->{write_gshadow} = 0 unless $write_g;
            $stash->{res} = [200, "OK", $r];
            [200];
        },
    );
}

$SPEC{add_group} = {
    v => 1.1,
    summary => 'Add a new group',
    args => {
        %common_args,
        %write_args,
        group => {
            schema => 'unix::groupname*',
            req => 1,
            pos => 0,
        },
        gid => {
            summary => 'Pick a specific new GID',
            schema => 'unix::gid*',
            description => <<'_',

Adding a new group with duplicate GID is allowed.

_
        },
        min_gid => {
            summary => 'Pick a range for new GID',
            schema => [int => {between=>[0, 65535], default=>1000}],
            description => <<'_',

If a free GID between `min_gid` and `max_gid` is not found, error 412 is
returned.

_
         },
        max_gid => {
            summary => 'Pick a range for new GID',
            schema => [int => {between=>[0, 65535], default=>65535}],
            description => <<'_',

If a free GID between `min_gid` and `max_gid` is not found, error 412 is
returned.

_
        },
        members => {
            summary => 'Fill initial members',
        },
    },
};
sub add_group {
    _add_group_or_user('group', @_);
}

$SPEC{add_user} = {
    v => 1.1,
    summary => 'Add a new user',
    args => {
        %common_args,
        %write_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        group => {
            summary => 'Select primary group '.
                '(default is group with same name as user)',
            schema => 'unix::groupname*',
            description => <<'_',

Normally, a user's primary group with group with the same name as user, which
will be created if does not already exist. You can pick another group here,
which must already exist (and in this case, the group with the same name as user
will not be created).

_
        },
        gid => {
            summary => 'Pick a specific GID when creating group',
            schema => 'int*',
            description => <<'_',

Duplicate GID is allowed.

_
        },
        min_gid => {
            summary => 'Pick a range for GID when creating group',
            schema => 'int*',
        },
        max_gid => {
            summary => 'Pick a range for GID when creating group',
            schema => 'int*',
        },
        uid => {
            summary => 'Pick a specific new UID',
            schema => 'int*',
            description => <<'_',

Adding a new user with duplicate UID is allowed.

_
        },
        min_uid => {
            summary => 'Pick a range for new UID',
            schema => [int => {between=>[0,65535], default=>1000}],
            description => <<'_',

If a free UID between `min_uid` and `max_uid` is not found, error 412 is
returned.

_
        },
        max_uid => {
            summary => 'Pick a range for new UID',
            schema => [int => {between=>[0,65535], default=>65535}],
            description => <<'_',

If a free UID between `min_uid` and `max_uid` is not found, error 412 is
returned.

_
        },
        map( {($_=>$passwd_fields{$_})} qw/pass gecos home shell/),
        map( {($_=>$shadow_fields{$_})}
                 qw/encpass last_pwchange min_pass_age max_pass_age
                   pass_warn_period pass_inactive_period expire_date/),
    },
};
sub add_user {
    _add_group_or_user('user', @_);
}

sub _modify_group_or_user {
    my ($which, %args) = @_;

    # TMP,schema
    my ($user, $gn);
    if ($which eq 'user') {
        $user = $args{user} or return [400, "Please specify user"];
    } else {
        $gn = $args{group} or return [400, "Please specify group"];
    }

    if ($which eq 'user') {
        if (defined($args{uid}) && $args{uid} !~ /$re_posint/o) {
            return [400, "Invalid uid"] }
        if (defined($args{gid}) && $args{gid} !~ /$re_posint/o) {
            return [400, "Invalid gid"] }
        if (defined($args{gecos}) && $args{gecos} !~ /$re_field/o) {
            return [400, "Invalid gecos"] }
        if (defined($args{home}) && $args{home} !~ /$re_field/o) {
            return [400, "Invalid home"] }
        if (defined($args{shell}) && $args{shell} !~ /$re_field/o) {
            return [400, "Invalid shell"] }
        if (defined $args{pass}) {
            $args{encpass} = $args{pass} eq '' ? '*' : _enc_pass($args{pass});
            $args{pass} = "x";
        }
        if (defined($args{encpass}) && $args{encpass} !~ /$re_field/o) {
            return [400, "Invalid encpass"] }
        if (defined($args{last_pwchange}) && $args{last_pwchange} !~ /$re_posint/o) {
            return [400, "Invalid last_pwchange"] }
        if (defined($args{min_pass_age}) && $args{min_pass_age} !~ /$re_posint/o) {
            return [400, "Invalid min_pass_age"] }
        if (defined($args{max_pass_age}) && $args{max_pass_age} !~ /$re_posint/o) {
            return [400, "Invalid max_pass_age"] }
        if (defined($args{pass_warn_period}) && $args{pass_warn_period} !~ /$re_posint/o) {
            return [400, "Invalid pass_warn_period"] }
        if (defined($args{pass_inactive_period}) &&
                $args{pass_inactive_period} !~ /$re_posint/o) {
            return [400, "Invalid pass_inactive_period"] }
        if (defined($args{expire_date}) && $args{expire_date} !~ /$re_posint/o) {
            return [400, "Invalid expire_date"] }
    }

    my ($gid, $members);
    if ($which eq 'group') {
        if (defined($args{gid}) && $args{gid} !~ /$re_posint/o) {
            return [400, "Invalid gid"] }
        if (defined $args{pass}) {
            $args{encpass} = $args{pass} eq '' ? '*' : _enc_pass($args{pass});
            $args{pass} = "x";
        }
        if (defined($args{encpass}) && $args{encpass} !~ /$re_field/o) {
            return [400, "Invalid encpass"] }
        if (defined $args{members}) {
            if (ref($args{members}) eq 'ARRAY') { $args{members} = join(",",@{$args{members}}) }
            $args{members} =~ /$re_field/o or return [400, "Invalid members"];
        }
        if (defined $args{admins}) {
            if (ref($args{admins}) eq 'ARRAY') { $args{admins} = join(",",@{$args{admins}}) }
            $args{admins} =~ /$re_field/o or return [400, "Invalid admins"];
        }
    }

    _routine(
        %args,
        _lock            => 1,
        _write_group     => $which eq 'group',
        _write_gshadow   => $which eq 'group',
        _write_passwd    => $which eq 'user',
        _write_shadow    => $which eq 'user',
        _after_read      => sub {
            my $stash = shift;

            my ($found, $changed);
            if ($which eq 'user') {
                my $passwd = $stash->{passwd};
                for my $l (@$passwd) {
                    next unless $l->[0] eq $user;
                    $found++;
                    for my $f (qw/pass uid gid gecos home shell/) {
                        if (defined $args{$f}) {
                            my $idx = firstidx {$_ eq $f} @passwd_field_names;
                            $l->[$idx] = $args{$f};
                            $changed++;
                        }
                    }
                    last;
                }
                return [404, "Not found"] unless $found;
                $stash->{write_passwd} = 0 unless $changed;

                $changed = 0;
                my $shadow = $stash->{shadow};
                for my $l (@$shadow) {
                    next unless $l->[0] eq $user;
                    for my $f (qw/encpass last_pwchange min_pass_age max_pass_age
                                  pass_warn_period pass_inactive_period expire_date/) {
                        if (defined $args{$f}) {
                            my $idx = firstidx {$_ eq $f} @shadow_field_names;
                            $l->[$idx] = $args{$f};
                            $changed++;
                        }
                    }
                    last;
                }
                $stash->{write_shadow} = 0 unless $changed;
            } else {
                my $group = $stash->{group};
                for my $l (@$group) {
                    next unless $l->[0] eq $gn;
                    $found++;
                    for my $f (qw/pass gid members/) {
                        if ($args{_before_set_group_field}) {
                            $args{_before_set_group_field}->($l, $f, \%args);
                        }
                        if (defined $args{$f}) {
                            my $idx = firstidx {$_ eq $f} @group_field_names;
                            $l->[$idx] = $args{$f};
                            $changed++;
                        }
                    }
                    last;
                }
                return [404, "Not found"] unless $found;
                $stash->{write_group} = 0 unless $changed;

                $changed = 0;
                my $gshadow = $stash->{gshadow};
                for my $l (@$gshadow) {
                    next unless $l->[0] eq $gn;
                    for my $f (qw/encpass admins members/) {
                        if (defined $args{$f}) {
                            my $idx = firstidx {$_ eq $f} @gshadow_field_names;
                            $l->[$idx] = $args{$f};
                            $changed++;
                        }
                    }
                    last;
                }
                $stash->{write_gshadow} = 0 unless $changed;
            }
            $stash->{res} = [200, "OK"];
            [200];
        },
    );
}

$SPEC{modify_group} = {
    v => 1.1,
    summary => 'Modify an existing group',
    description => <<'_',

Specify arguments to modify corresponding fields. Unspecified fields will not be
modified.

_
    args => {
        %common_args,
        %write_args,
        _arg_from_field(\%group_fields, 'group', req=>1, pos=>0),
        _arg_from_field(\%group_fields, 'pass'),
        _arg_from_field(\%group_fields, 'gid'),
        _arg_from_field(\%group_fields, 'members'),

        _arg_from_field(\%gshadow_fields, 'encpass'),
        _arg_from_field(\%gshadow_fields, 'admins'),
    },
};
sub modify_group {
    _modify_group_or_user('group', @_);
}

$SPEC{modify_user} = {
    v => 1.1,
    summary => 'Modify an existing user',
    description => <<'_',

Specify arguments to modify corresponding fields. Unspecified fields will not be
modified.

_
    args => {
        %common_args,
        %write_args,
        _arg_from_field(\%passwd_fields, 'user', req=>1, pos=>0),
        _arg_from_field(\%passwd_fields, 'uid'),
        _arg_from_field(\%passwd_fields, 'gid'),
        _arg_from_field(\%passwd_fields, 'gecos'),
        _arg_from_field(\%passwd_fields, 'home'),
        _arg_from_field(\%passwd_fields, 'shell'),

        _arg_from_field(\%shadow_fields, 'encpass'),
        _arg_from_field(\%shadow_fields, 'last_pwchange'),
        _arg_from_field(\%shadow_fields, 'min_pass_age'),
        _arg_from_field(\%shadow_fields, 'max_pass_age'),
        _arg_from_field(\%shadow_fields, 'pass_warn_period'),
        _arg_from_field(\%shadow_fields, 'pass_inactive_period'),
        _arg_from_field(\%shadow_fields, 'expire_date'),
    },
};
sub modify_user {
    _modify_group_or_user('user', @_);
}

$SPEC{add_user_to_group} = {
    v => 1.1,
    summary => 'Add user to a group',
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        group => {
            schema => 'unix::groupname*',
            req => 1,
            pos => 1,
        },
    },
};
sub add_user_to_group {
    my %args = @_;
    my $user = $args{user} or return [400, "Please specify user"];
    $user =~ /$re_user/o or return [400, "Invalid user"];
    my $gn   = $args{group}; # will be required by modify_group

    # XXX check user exists
    _modify_group_or_user(
        'group',
        %args,
        _before_set_group_field => sub {
            my ($l, $f, $args) = @_;
            return unless $l->[0] eq $gn;
            my @mm = split /,/, $l->[3];
            return if $user ~~ @mm;
            push @mm, $user;
            $args->{members} = join(",", @mm);
        },
    );
}


$SPEC{delete_user_from_group} = {
    v => 1.1,
    summary => 'Delete user from a group',
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        group => {
            schema => 'unix::groupname*',
            req => 1,
            pos => 1,
        },
    },
};
sub delete_user_from_group {
    my %args = @_;
    my $user = $args{user} or return [400, "Please specify user"];
    $user =~ /$re_user/o or return [400, "Invalid user"];
    my $gn   = $args{group}; # will be required by modify_group

    # XXX check user exists
    _modify_group_or_user(
        'group',
        %args,
        _before_set_group_field => sub {
            my ($l, $f, $args) = @_;
            return unless $l->[0] eq $gn;
            my @mm = split /,/, $l->[3];
            return unless $user ~~ @mm;
            @mm = grep {$_ ne $user} @mm;
            $args->{members} = join(",", @mm);
        },
    );
}

$SPEC{add_delete_user_groups} = {
    v => 1.1,
    summary => 'Add or delete user from one or several groups',
    description => <<'_',

This can be used to reduce several `add_user_to_group()` and/or
`delete_user_from_group()` calls to a single call. So:

    add_delete_user_groups(user=>'u',add_to=>['a','b'],delete_from=>['c','d']);

is equivalent to:

    add_user_to_group     (user=>'u', group=>'a');
    add_user_to_group     (user=>'u', group=>'b');
    delete_user_from_group(user=>'u', group=>'c');
    delete_user_from_group(user=>'u', group=>'d');

except that `add_delete_user_groups()` does it in one pass.

_
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        add_to => {
            summary => 'List of group names to add the user as member of',
            schema => [array => {of=>'unix::groupname*', default=>[]}],
        },
        delete_from => {
            summary => 'List of group names to remove the user as member of',
            schema => [array => {of=>'unix::groupname*', default=>[]}],
        },
    },
};
sub add_delete_user_groups {
    my %args = @_;
    my $user = $args{user} or return [400, "Please specify user"];
    $user =~ /$re_user/o or return [400, "Invalid user"];
    my $add  = $args{add_to} // [];
    my $del  = $args{delete_from} // [];

    # XXX check user exists

    _routine(
        %args,
        _lock            => 1,
        _write_group     => 1,
        _after_read      => sub {
            my $stash = shift;

            my $group = $stash->{group};
            my $changed;

            for my $l (@$group) {
                my @mm = split /,/, $l->[-1];
                if ($l->[0] ~~ $add && !($user ~~ @mm)) {
                    $changed++;
                    push @mm, $user;
                }
                if ($l->[0] ~~ $del && $user ~~ @mm) {
                    $changed++;
                    @mm = grep {$_ ne $user} @mm;
                }
                if ($changed) {
                    $l->[-1] = join ",", @mm;
                }
            }
            $stash->{write_group} = 0 unless $changed;
            $stash->{res} = [200, "OK"];
            [200];
        },
    );
}

$SPEC{set_user_groups} = {
    v => 1.1,
    summary => 'Set the groups that a user is member of',
    args => {
        %common_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        groups => {
            summary => 'List of group names that user is member of',
            schema => [array => {of=>'unix::groupname*', default=>[]}],
            req => 1,
            pos => 1,
            greedy => 1,
            description => <<'_',

Aside from this list, user will not belong to any other group.

_
        },
    },
};
sub set_user_groups {
    my %args = @_;
    my $user = $args{user} or return [400, "Please specify user"];
    $user =~ /$re_user/o or return [400, "Invalid user"];
    my $gg   = $args{groups} or return [400, "Please specify groups"];

    # XXX check user exists

    _routine(
        %args,
        _lock            => 1,
        _write_group     => 1,
        _after_read      => sub {
            my $stash = shift;

            my $group = $stash->{group};
            my $changed;

            for my $l (@$group) {
                my @mm = split /,/, $l->[-1];
                if ($l->[0] ~~ $gg && !($user ~~ @mm)) {
                    $changed++;
                    push @mm, $user;
                }
                if (!($l->[0] ~~ $gg) && $user ~~ @mm) {
                    $changed++;
                    @mm = grep {$_ ne $user} @mm;
                }
                if ($changed) {
                    $l->[-1] = join ",", @mm;
                }
            }
            $stash->{write_group} = 0 unless $changed;
            $stash->{res} = [200, "OK"];
            [200];
        },
    );
}

$SPEC{set_user_password} = {
    v => 1.1,
    summary => 'Set user\'s password',
    args => {
        %common_args,
        %write_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
        pass => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
    },
};
sub set_user_password {
    my %args = @_;

    $args{user} or return [400, "Please specify user"];
    defined($args{pass}) or return [400, "Please specify pass"];
    modify_user(%args);
}

sub _delete_group_or_user {
    my ($which, %args) = @_;

    # TMP,schema
    my ($user, $gn);
    if ($which eq 'user') {
        $user = $args{user} or return [400, "Please specify user"];
        $gn = $user;
    }
    $gn //= $args{group};
    $gn or return [400, "Please specify group"];

    _routine(
        %args,
        _lock            => 1,
        _write_group     => 1,
        _write_gshadow   => 1,
        _write_passwd    => $which eq 'user',
        _write_shadow    => $which eq 'user',
        _after_read      => sub {
            my $stash = shift;
            my ($i, $changed);

            my $group = $stash->{group};
            $changed = 0; $i = 0;
            while ($i < @$group) {
                if ($which eq 'user') {
                    # also delete all mention of the user in any group
                    my @mm = split /,/, $group->[$i][3];
                    if ($user ~~ @mm) {
                        $changed++;
                        $group->[$i][3] = join(",", grep {$_ ne $user} @mm);
                    }
                }
                if ($group->[$i][0] eq $gn) {
                    $changed++;
                    splice @$group, $i, 1; $i--;
                }
                $i++;
            }
            $stash->{write_group} = 0 unless $changed;

            my $gshadow = $stash->{gshadow};
            $changed = 0; $i = 0;
            while ($i < @$gshadow) {
                if ($which eq 'user') {
                    # also delete all mention of the user in any group
                    my @mm = split /,/, $gshadow->[$i][3];
                    if ($user ~~ @mm) {
                        $changed++;
                        $gshadow->[$i][3] = join(",", grep {$_ ne $user} @mm);
                    }
                }
                if ($gshadow->[$i][0] eq $gn) {
                    $changed++;
                    splice @$gshadow, $i, 1; $i--;
                    last;
                }
                $i++;
            }
            $stash->{write_gshadow} = 0 unless $changed;

            if ($which eq 'user') {
                my $passwd = $stash->{passwd};
                $changed = 0; $i = 0;
                while ($i < @$passwd) {
                    if ($passwd->[$i][0] eq $user) {
                        $changed++;
                        splice @$passwd, $i, 1; $i--;
                        last;
                    }
                    $i++;
                }
                $stash->{write_passwd} = 0 unless $changed;

                my $shadow = $stash->{shadow};
                $changed = 0; $i = 0;
                while ($i < @$shadow) {
                    if ($shadow->[$i][0] eq $user) {
                        $changed++;
                        splice @$shadow, $i, 1; $i--;
                        last;
                    }
                    $i++;
                }
                $stash->{write_shadow} = 0 unless $changed;
            }

            $stash->{res} = [200, "OK"];
            [200];
        },
    );
}

$SPEC{delete_group} = {
    v => 1.1,
    summary => 'Delete a group',
    args => {
        %common_args,
        %write_args,
        group => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
    },
};
sub delete_group {
    _delete_group_or_user('group', @_);
}

$SPEC{delete_user} = {
    v => 1.1,
    summary => 'Delete a user',
    args => {
        %common_args,
        %write_args,
        user => {
            schema => 'unix::username*',
            req => 1,
            pos => 0,
        },
    },
};
sub delete_user {
    _delete_group_or_user('user', @_);
}

1;
# ABSTRACT: Manipulate /etc/{passwd,shadow,group,gshadow} entries

__END__

=pod

=encoding UTF-8

=head1 NAME

Unix::Passwd::File - Manipulate /etc/{passwd,shadow,group,gshadow} entries

=head1 VERSION

This document describes version 0.251 of Unix::Passwd::File (from Perl distribution Unix-Passwd-File), released on 2020-04-29.

=head1 SYNOPSIS

 use Unix::Passwd::File;

 # list users. by default uses files in /etc (/etc/passwd, /etc/shadow, et al)
 my $res = list_users(); # [200, "OK", ["root", ...]]

 # change location of files, return details
 $res = list_users(etc_dir=>"/some/path", detail=>1);
     # [200, "OK", [{user=>"root", uid=>0, ...}, ...]]

 # also return detail, but return array entries instead of hash
 $res = list_users(detail=>1, with_field_names=>0);
     # [200, "OK", [["root", "x", 0, ...], ...]]

 # get user/group information
 $res = get_group(user=>"paijo"); # [200, "OK", {user=>"paijo", uid=>501, ...}]
 $res = get_user(user=>"titin");  # [404, "Not found"]

 # check whether user/group exists
 say user_exists(user=>"paijo");   # 1
 say group_exists(group=>"titin"); # 0

 # get all groups that user is member of
 $res = get_user_groups(user=>"paijo"); # [200, "OK", ["paijo", "satpam"]]

 # check whether user is member of a group
 $res = is_member(user=>"paijo", group=>"satpam"); # 1

 # adding user/group, by default adding user will also add a group with the same
 # name
 $res = add_user (user =>"ujang", ...); # [200, "OK", {uid=>540, gid=>541}]
 $res = add_group(group=>"ujang", ...); # [412, "Group already exists"]

 # modify user/group
 $res = modify_user(user=>"ujang", home=>"/newhome/ujang"); # [200, "OK"]
 $res = modify_group(group=>"titin"); # [404, "Not found"]

 # deleting user will also delete user's group
 $res = delete_user(user=>"titin");

 # change user password
 $res = set_user_password(user=>"ujang", pass=>"foobar");
 $res = modify_user(user=>"ujang", pass=>"foobar"); # same thing

 # add/delete user to/from group
 $res = add_user_to_group(user=>"ujang", group=>"wheel");
 $res = delete_user_from_group(user=>"ujang", group=>"wheel");

 # others
 $res = get_max_uid(); # [200, "OK", 65535]
 $res = get_max_gid(); # [200, "OK", 65534]

=head1 DESCRIPTION

This module can be used to read and manipulate entries in Unix system password
files (/etc/passwd, /etc/group, /etc/group, /etc/gshadow; but can also be told
to search in custom location, for testing purposes).

This module uses a procedural (non-OO) interface. Each function in this module
open and read the passwd files once. Read-only functions like `list_users()` and
`get_max_gid()` open in read-only mode. Functions that might write to the files
like `add_user()` or `delete_group()` first lock `passwd` file, open in
read+write mode and also read the files in the first pass, then seek to the
beginning and write back the files.

No caching is done so you should do your own if you need to.

=head1 FUNCTIONS


=head2 add_delete_user_groups

Usage:

 add_delete_user_groups(%args) -> [status, msg, payload, meta]

Add or delete user from one or several groups.

This can be used to reduce several C<add_user_to_group()> and/or
C<delete_user_from_group()> calls to a single call. So:

 add_delete_user_groups(user=>'u',add_to=>['a','b'],delete_from=>['c','d']);

is equivalent to:

 add_user_to_group     (user=>'u', group=>'a');
 add_user_to_group     (user=>'u', group=>'b');
 delete_user_from_group(user=>'u', group=>'c');
 delete_user_from_group(user=>'u', group=>'d');

except that C<add_delete_user_groups()> does it in one pass.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_to> => I<array[unix::groupname]> (default: [])

List of group names to add the user as member of.

=item * B<delete_from> => I<array[unix::groupname]> (default: [])

List of group names to remove the user as member of.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<user>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 add_group

Usage:

 add_group(%args) -> [status, msg, payload, meta]

Add a new group.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 0)

Whether to backup when modifying files.

Backup is written with C<.bak> extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<gid> => I<unix::gid>

Pick a specific new GID.

Adding a new group with duplicate GID is allowed.

=item * B<group>* => I<unix::groupname>

=item * B<max_gid> => I<int> (default: 65535)

Pick a range for new GID.

If a free GID between C<min_gid> and C<max_gid> is not found, error 412 is
returned.

=item * B<members> => I<any>

Fill initial members.

=item * B<min_gid> => I<int> (default: 1000)

Pick a range for new GID.

If a free GID between C<min_gid> and C<max_gid> is not found, error 412 is
returned.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 add_user

Usage:

 add_user(%args) -> [status, msg, payload, meta]

Add a new user.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 0)

Whether to backup when modifying files.

Backup is written with C<.bak> extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

=item * B<encpass> => I<str>

Encrypted password.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<expire_date> => I<int>

The date of expiration of the account, expressed as the number of days since Jan 1, 1970.

=item * B<gecos> => I<str>

Usually, it contains the full username.

=item * B<gid> => I<int>

Pick a specific GID when creating group.

Duplicate GID is allowed.

=item * B<group> => I<unix::groupname>

Select primary group (default is group with same name as user).

Normally, a user's primary group with group with the same name as user, which
will be created if does not already exist. You can pick another group here,
which must already exist (and in this case, the group with the same name as user
will not be created).

=item * B<home> => I<dirname>

User's home directory.

=item * B<last_pwchange> => I<int>

The date of the last password change, expressed as the number of days since Jan 1, 1970.

=item * B<max_gid> => I<int>

Pick a range for GID when creating group.

=item * B<max_pass_age> => I<int>

The number of days after which the user will have to change her password.

=item * B<max_uid> => I<int> (default: 65535)

Pick a range for new UID.

If a free UID between C<min_uid> and C<max_uid> is not found, error 412 is
returned.

=item * B<min_gid> => I<int>

Pick a range for GID when creating group.

=item * B<min_pass_age> => I<int>

The number of days the user will have to wait before she will be allowed to change her password again.

=item * B<min_uid> => I<int> (default: 1000)

Pick a range for new UID.

If a free UID between C<min_uid> and C<max_uid> is not found, error 412 is
returned.

=item * B<pass> => I<str>

Password, generally should be "x" which means password is encrypted in shadow.

=item * B<pass_inactive_period> => I<int>

The number of days after a password has expired (see max_pass_age) during which the password should still be accepted (and user should update her password during the next login).

=item * B<pass_warn_period> => I<int>

The number of days before a password is going to expire (see max_pass_age) during which the user should be warned.

=item * B<shell> => I<filename>

User's shell.

=item * B<uid> => I<int>

Pick a specific new UID.

Adding a new user with duplicate UID is allowed.

=item * B<user>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 add_user_to_group

Usage:

 add_user_to_group(%args) -> [status, msg, payload, meta]

Add user to a group.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<group>* => I<unix::groupname>

=item * B<user>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 delete_group

Usage:

 delete_group(%args) -> [status, msg, payload, meta]

Delete a group.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 0)

Whether to backup when modifying files.

Backup is written with C<.bak> extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<group>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 delete_user

Usage:

 delete_user(%args) -> [status, msg, payload, meta]

Delete a user.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 0)

Whether to backup when modifying files.

Backup is written with C<.bak> extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<user>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 delete_user_from_group

Usage:

 delete_user_from_group(%args) -> [status, msg, payload, meta]

Delete user from a group.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<group>* => I<unix::groupname>

=item * B<user>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_group

Usage:

 get_group(%args) -> [status, msg, payload, meta]

Get group details by group name or gid.

Either C<group> OR C<gid> must be specified.

The function is not dissimilar to Unix's C<getgrnam()> or C<getgrgid()>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<gid> => I<unix::gid>

=item * B<group> => I<unix::username>

=item * B<with_field_names> => I<bool> (default: 1)

If false, don't return hash.

By default, a hashref is returned containing field names and its values, e.g.
C<< {group=E<gt>"titin", pass=E<gt>"x", gid=E<gt>500, ...} >>. With C<< with_field_names=E<gt>0 >>, an
arrayref is returned instead: C<["titin", "x", 500, ...]>.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_max_gid

Usage:

 get_max_gid(%args) -> [status, msg, payload, meta]

Get maximum GID used.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_max_uid

Usage:

 get_max_uid(%args) -> [status, msg, payload, meta]

Get maximum UID used.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_user

Usage:

 get_user(%args) -> [status, msg, payload, meta]

Get user details by username or uid.

Either C<user> OR C<uid> must be specified.

The function is not dissimilar to Unix's C<getpwnam()> or C<getpwuid()>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<uid> => I<unix::uid>

=item * B<user> => I<unix::username>

=item * B<with_field_names> => I<bool> (default: 1)

If false, don't return hash.

By default, a hashref is returned containing field names and its values, e.g.
C<< {user=E<gt>"titin", pass=E<gt>"x", uid=E<gt>500, ...} >>. With C<< with_field_names=E<gt>0 >>, an
arrayref is returned instead: C<["titin", "x", 500, ...]>.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_user_groups

Usage:

 get_user_groups(%args) -> [status, msg, payload, meta]

Return groups which the user belongs to.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

If true, return all fields instead of just group names.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<user>* => I<unix::username>

=item * B<with_field_names> => I<bool> (default: 1)

If false, don't return hash for each entry.

By default, when C<< detail=E<gt>1 >>, a hashref is returned for each entry containing
field names and its values, e.g. C<< {group=E<gt>"titin", pass=E<gt>"x", gid=E<gt>500, ...} >>.
With C<< with_field_names=E<gt>0 >>, an arrayref is returned instead: C<["titin", "x",
500, ...]>.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 group_exists

Usage:

 group_exists(%args) -> bool

Check whether group exists.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<gid> => I<unix::gid>

=item * B<group> => I<unix::groupname>


=back

Return value:  (bool)



=head2 is_member

Usage:

 is_member(%args) -> bool

Check whether user is member of a group.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<group>* => I<unix::groupname>

=item * B<user>* => I<unix::username>


=back

Return value:  (bool)



=head2 list_groups

Usage:

 list_groups(%args) -> [status, msg, payload, meta]

List Unix groups in group file.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

If true, return all fields instead of just group names.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<with_field_names> => I<bool> (default: 1)

If false, don't return hash for each entry.

By default, when C<< detail=E<gt>1 >>, a hashref is returned for each entry containing
field names and its values, e.g. C<< {group=E<gt>"titin", pass=E<gt>"x", gid=E<gt>500, ...} >>.
With C<< with_field_names=E<gt>0 >>, an arrayref is returned instead: C<["titin", "x",
500, ...]>.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_users

Usage:

 list_users(%args) -> [status, msg, payload, meta]

List Unix users in passwd file.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

If true, return all fields instead of just usernames.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<with_field_names> => I<bool> (default: 1)

If false, don't return hash for each entry.

By default, when C<< detail=E<gt>1 >>, a hashref is returned for each entry containing
field names and its values, e.g. C<< {user=E<gt>"titin", pass=E<gt>"x", uid=E<gt>500, ...} >>.
With C<< with_field_names=E<gt>0 >>, an arrayref is returned instead: C<["titin", "x",
500, ...]>.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_users_and_groups

Usage:

 list_users_and_groups(%args) -> [status, msg, payload, meta]

List Unix users and groups in passwdE<sol>group files.

This is basically C<list_users()> and C<list_groups()> combined, so you can get
both data in a single call. Data is returned in an array. Users list is in the
first element, groups list in the second.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

If true, return all fields instead of just names.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<with_field_names> => I<bool> (default: 1)

If false, don't return hash for each entry.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 modify_group

Usage:

 modify_group(%args) -> [status, msg, payload, meta]

Modify an existing group.

Specify arguments to modify corresponding fields. Unspecified fields will not be
modified.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<admins> => I<str>

It must be a comma-separated list of user names, or empty.

=item * B<backup> => I<bool> (default: 0)

Whether to backup when modifying files.

Backup is written with C<.bak> extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

=item * B<encpass> => I<str>

Encrypted password.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<gid> => I<unix::gid>

Numeric group ID.

=item * B<group>* => I<unix::groupname>

Group name.

=item * B<members> => I<str>

List of usernames that are members of this group, separated by commas.

=item * B<pass> => I<str>

Password, generally should be "x" which means password is encrypted in gshadow.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 modify_user

Usage:

 modify_user(%args) -> [status, msg, payload, meta]

Modify an existing user.

Specify arguments to modify corresponding fields. Unspecified fields will not be
modified.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 0)

Whether to backup when modifying files.

Backup is written with C<.bak> extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

=item * B<encpass> => I<str>

Encrypted password.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<expire_date> => I<int>

The date of expiration of the account, expressed as the number of days since Jan 1, 1970.

=item * B<gecos> => I<str>

Usually, it contains the full username.

=item * B<gid> => I<unix::gid>

Numeric primary group ID for this user.

=item * B<home> => I<dirname>

User's home directory.

=item * B<last_pwchange> => I<int>

The date of the last password change, expressed as the number of days since Jan 1, 1970.

=item * B<max_pass_age> => I<int>

The number of days after which the user will have to change her password.

=item * B<min_pass_age> => I<int>

The number of days the user will have to wait before she will be allowed to change her password again.

=item * B<pass_inactive_period> => I<int>

The number of days after a password has expired (see max_pass_age) during which the password should still be accepted (and user should update her password during the next login).

=item * B<pass_warn_period> => I<int>

The number of days before a password is going to expire (see max_pass_age) during which the user should be warned.

=item * B<shell> => I<filename>

User's shell.

=item * B<uid> => I<unix::uid>

Numeric user ID.

=item * B<user>* => I<unix::username>

User (login) name.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 set_user_groups

Usage:

 set_user_groups(%args) -> [status, msg, payload, meta]

Set the groups that a user is member of.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<groups>* => I<array[unix::groupname]> (default: [])

List of group names that user is member of.

Aside from this list, user will not belong to any other group.

=item * B<user>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 set_user_password

Usage:

 set_user_password(%args) -> [status, msg, payload, meta]

Set user's password.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 0)

Whether to backup when modifying files.

Backup is written with C<.bak> extension in the same directory. Unmodified file
will not be backed up. Previous backup will be overwritten.

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<pass>* => I<str>

=item * B<user>* => I<unix::username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 user_exists

Usage:

 user_exists(%args) -> bool

Check whether user exists.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<etc_dir> => I<str> (default: "/etc")

Specify location of passwd files.

=item * B<uid> => I<unix::uid>

=item * B<user> => I<unix::username>


=back

Return value:  (bool)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Unix-Passwd-File>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Unix-Passwd-File>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Unix-Passwd-File>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Old modules on CPAN which do not support shadow files are pretty useless to me
(e.g. L<Unix::ConfigFile>). Shadow passwords have been around since 1988 (and in
Linux since 1992), FFS!

L<Passwd::Unix>. I created a fork of Passwd::Unix v0.52 called
L<Passwd::Unix::Alt> in 2011 to fix some of the deficiencies/quirks in
Passwd::Unix, including: lack of tests, insistence of running as root (despite
allowing custom passwd files), use of not-so-ubiquitous bzip2, etc. Then in 2012
I decided to create Unix::Passwd::File. Here are how Unix::Passwd::File differs
compared to Passwd::Unix (and Passwd::Unix::Alt):

=over 4

=item * tests in distribution

=item * no need to run as root

=item * no need to be able to read the shadow file for some operations

For example, C<list_users()> will simply not return the C<encpass> field if the
shadow file is unreadable. Of course, access to shadow file is required when
getting or setting password.

=item * strictly procedural (non-OO) interface

I consider this a feature :-)

=item * detailed error message for each operation

=item * removal of global error variable

=item * working locking

Locking is done by locking C<passwd> file.

=back

L<Setup::Unix::User> and L<Setup::Unix::Group>, which use this module.

L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
