package MMM::Utils;

use strict;
use warnings;

use base qw(Exporter);
use Date::Calc qw(Delta_YMDHMS);

our @EXPORT = qw(
    yes_no
    fmt_duration
    duration2m
);

=head1 NAME

MMM::Utils

=head1 METHODS

=head2 yes_no($val)

Parse $val to return true or false

=cut

sub yes_no {
    my ($val) = @_;
    $val ||= '';
    if ($val =~ /^(yes|true|on|\d+)$/i && $val ne 0) {
        return 1;
    } else {
        return 0;
    }
}

sub _get_meantime {
    my ($time) = @_;
    my ($Second, $Minute, $Hour, $Day, $Month,
        $Year, $WeekDay, $DayOfYear, $IsDST) = gmtime($time);
    $Year+=1900; $Month+=1;
    return ($Year, $Month, $Day, $Hour, $Minute, $Second);
}

=head2 fmt_duration($second)

Transform a duration in second to a string in form of
day/hours/minutes/seconds.

=cut

sub fmt_duration {
    my ($second1, $second2) = @_;
    my @gmt1 = _get_meantime($second1);
    my @gmt2 = _get_meantime($second2 || scalar(time));

    my ($D_y,$D_m,$D_d, $Dh,$Dm,$Ds) = Delta_YMDHMS(
        $second1 <= $second2
        ? (@gmt1, @gmt2)
        : (@gmt2, @gmt1)
    );

    return join(', ', grep { $_ } (
            $D_y ? sprintf('%d year%s'  , $D_y, $D_y > 1 ? 's' : '') : '',
            $D_m ? sprintf('%d month%s' , $D_m, $D_m > 1 ? 's' : '') : '',
            $D_d ? sprintf('%d day%s'   , $D_d, $D_d > 1 ? 's' : '') : '',
            sprintf ("%02dh%02dm%02ds", map { $_ || 0 } ($Dh, $Dm, $Ds)),
        )
    );
}


=head2 duration2m($duration)

Return in minutes a human readable value like 2d or 3h

=cut

sub duration2m {
    my ($v) = @_;
    if (my ($n, $u) = $v =~ /^(\d+)(\D)?/) {
        for (lc($u || 'm')) {
            /m/ and return $n;
            /h/ and return $n * 60;
            /d/ and return $n * 60 * 24;
            /w/ and return $n * 60 * 24 * 7;
        }
    }
    return $v;
}

=head2 setid($user, $group)

Change effective user and group to $user and optionnal $group.

Return arrayref containning old uid and gid on success. Return undef and
error message on failure.

=cut

sub setid {
    my ($user, $group) = @_;

    my ($uid, $gid);

    if ($user
        && ($> == 0 || $< == 0)) { # if we're not root, we can only ignore this
        if ($user =~ /^\d+$/) {
            $uid = $user;
            my @uinfo = POSIX::getpwuid($uid);
            if (!scalar(@uinfo)) {
                return(undef, sprintf('User %s don\'t exists', $uid));
            }
            $gid = $uinfo[3];
        } else {
            my @uinfo = POSIX::getpwnam($user);
            if (scalar(@uinfo)) {
                ($uid, $gid) = ($uinfo[2], $uinfo[3]);
                $group = $uinfo[3];
            } else {
                return(undef, sprintf('User %s don\'t exists', $user));
            }
        }
    }
    if ($group) {
        if ($group =~ /^\d+$/) {
            $gid = $group;
        } else {
            my @ginfo = POSIX::getgrnam($group);
            if (scalar(@ginfo)) {
                $gid = $ginfo[2];
            } else {
                return(undef, sprintf('group %s don\'t exists', $group));
            }
        }
    }

    my ($ouid, $ogid) = _setid($uid, $gid);

    if(!defined($ogid)) {
        return (undef, sprintf('Cannot change to group %s', $group));
    }
    if (!defined($ouid)) {
        return (undef, sprintf('Cannot become user %s', $user));
    }

    return([$ouid, $ogid]);


}

sub _setid {
    my ($uid, $gid) = @_;
    my ($olduid, $oldgid) = ($>, $));
    if (defined($gid) && $) != $gid) {
        $) = $gid;
        if ($) != $gid) {
            $oldgid = undef;
        }
    }
    if (defined($uid) && $> != $uid) {
        $> = $uid;
        if ($> != $uid) {
            $olduid = undef;
        }
    }
    return($olduid, $oldgid);
}

=head1 AUTHOR

Olivier Thauvin <nanardon@nanardon.zarb.org>

=cut
