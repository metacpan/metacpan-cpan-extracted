package Time::Date;

use 5.006;
use strict;
use warnings;
use POSIX ();

use overload '""' => \&str;

our $VERSION = "0.03";

sub new {
    my ($class, $str) = @_;
    return undef if !$str;
    $str =~ /^(\d{4})(-(\d+)(-(\d+)((\s+|T)(\d+)(:(\d+)(:(\d+)(\.(\d+))?)?)?)?)?)?(.*)$/;
    my $year = $1;
    my $mon = $3 || 1;
    my $mday = $5 || 1;
    my $hour = $8 || 0;
    my $min = $10 || 0;
    my $sec = $12 || 0;
    my $msec = $14 || 0;
    my $ampm = $15;
    return undef if !defined $year;
    if ($ampm =~ /^\s*am?$/i) {
        $hour -= 12 if $hour == 12;
    }
    elsif ($ampm =~ /^\s*pm?$/i) {
        $hour += 12 if $hour != 12;
    }
    elsif ($ampm !~ /^\s*$/) {
        return undef;
    }
    $mon -= 1;
    $year -= 1900;
    my $epoch = POSIX::mktime($sec, $min, $hour, $mday, $mon, $year, 0, 0, -1);
    return undef if !defined $epoch;
    my $self = bless {epoch => $epoch}, $class;
    return $self;
}

sub mktime {
    my ($class, $year, $mon, $mday, $hour, $min, $sec, $wday, $yday, $isdst) = @_;
    $sec ||= 0;
    $min ||= 0;
    $hour ||= 0;
    $mday = defined $mday ? $mday : 1;
    $mon ||= 0;
    $year ||= 0;
    $wday ||= 0;
    $yday ||= 0;
    $isdst = defined $isdst ? $isdst : -1;
    my $epoch = POSIX::mktime($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
    return undef if !defined $epoch;
    my $self = bless {epoch => $epoch}, $class;
    return $self;
}

sub new_epoch {
    my ($class, $epoch) = @_;
    my $self = bless {epoch => $epoch}, $class;
    return $self;
}

sub now {
    my ($class) = @_;
    my $self = bless {epoch => time}, $class;
    return $self;
}

sub str {
    my ($self) = @_;
    my $str = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($self->{epoch}));
    return $str;
}

sub strftime {
    my ($self, $fmt) = @_;
    my $str = POSIX::strftime($fmt, localtime($self->{epoch}));
    return $str;
}

my $now;
sub natural {
    my ($self) = @_;
    $now = time if !$now;
    my $delta = $now - $self->{epoch};
    if ($delta < -32 * 24 * 60 * 60) {
        return POSIX::strftime("%b %Y", localtime($self->{epoch}));
    }
    elsif ($delta < -2 * 24 * 60 * 60) {
        return "in " . int(-$delta / (24 * 60 * 60)) . " days";
    }
    elsif ($delta < -24 * 60 * 60) {
        return "in 1 day";
    }
    elsif ($delta < -2 * 60 * 60) {
        return "in " . int(-$delta / (60 * 60)) . " hours";
    }
    elsif ($delta < -60 * 60) {
        return "in 1 hour";
    }
    elsif ($delta < -2 * 60) {
        return "in " . int(-$delta / 60) . " minutes";
    }
    elsif ($delta < -60) {
        return "in 1 minute";
    }
    elsif ($delta < -1) {
        return "in $delta seconds";
    }
    elsif ($delta < 0) {
        return "in 1 second";
    }
    elsif ($delta < 1) {
        return "right now";
    }
    elsif ($delta < 2) {
        return "1 second ago";
    }
    if ($delta < 60) {
        return "$delta seconds ago";
    }
    elsif ($delta < 2 * 60) {
        return "1 minute ago";
    }
    elsif ($delta < 60 * 60) {
        return int($delta / 60) . " minutes ago";
    }
    elsif ($delta < 2 * 60 * 60) {
        return "1 hour ago";
    }
    elsif ($delta < 24 * 60 * 60) {
        return int($delta / (60 * 60)) . " hours ago";
    }
    elsif ($delta < 2 * 24 * 60 * 60) {
        return "1 day ago";
    }
    elsif ($delta < 32 * 24 * 60 * 60) {
        return int($delta / (24 * 60 * 60)) . " days ago";
    }
    else {
        return POSIX::strftime("%b %Y", localtime($self->{epoch}));
    }
}

sub time_zones {
    my %time_zones;
    open my $fh, "<", "/usr/share/zoneinfo/zone.tab" or return [];
    while (my $line = <$fh>) {
        $line =~ m{^[A-Z]{2}\s+\S+\s+(\w+)/(\S+)} or next;
        my $region = $1;
        my $name = $2;
        my $zone = "$region/$name";
        $name =~ s{_}{ }g;
        $name =~ s{/}{ - }g;
        push @{$time_zones{$region}}, {zone => $zone, name => $name};
    }
    close $fh;
    my @time_zones;
    push @time_zones, {name => "Local", zone => ""};
    my $i = 0;
    for my $region (sort keys %time_zones) {
        push @time_zones, {region => $region, i => $i};
        $i++;
        my @zones = sort {$a->{name} cmp $b->{name}} @{$time_zones{$region}};
        push @time_zones, @zones;
    }
    push @time_zones, {region => "UTC", i => $i};
    for my $offset (qw{
        -12 -11:30 -11 -10:30 -10 -9:30 -8:30 -8 -7:30 -7 -6:30 -6 -5:30
        -5 -4:30 -4 -3:30 -3 -2:30 -2 -1:30 -1 -0:30 +0 +0:30 +1 +1:30
        +2 +2:30 +3 +3:30 +4 +4:30 +5 +5:30 +6 +6:30 +7 +7:30 +8 +8:30
        +9 +9:30 +10 +10:30 +11 +11:30 +12}) {
        push @time_zones, {zone => "UTC$offset", name => "UTC$offset"};
    }
    return \@time_zones;
}

1;

__END__

=head1 NAME

Time::Date - A time and date object for Perl

=head1 SYNOPSIS

    use Time::Date;
    my $t = Time::Date->new("2015-09-14 17:44");
    print $t->strftime("%Y-%m-%d %H:%M:%S") . "\n";
    my $s = Time::Date->now;
    print "That was " . ($s->{epoch} - $t->{epoch}) . " seconds ago";

=head1 DESCRIPTION

Time::Date is a class that can be used to represent a date as an
object. Unlike other modules, this one just stores a Unix epoch
within the object and relies heavily on the underlying operating
system so it's very fast. It provides functionality for working
with common representations of dates, displaying dates naturally
(like "5 minutes ago"), and for listing timezones. Also, it will
stringify automatically if you use the object in a string.

=head1 TIME ZONES

If you want to use a different timezone, you have to set the TZ
environment variable as is the standard on most operating systems.
This takes effect when parsing and displaying dates. For example,
if you want to parse a date from Ashgabat and display it for a user
in Rarotonga, you have to write it like this:

    $ENV{TZ} = "Asia/Ashgabat";
    my $t = Time::Date->new("2015-09-14 11:44 am");
    $ENV{TZ} = "Pacific/Rarotonga";
    print "$t";

Use time_zones subroutine to get a list of valid timezones.

=head1 DATE MATH

You can add or subtract time by adding or subtracting a number of
seconds from the "epoch" field in the object. For example, to add
a day you would write:

    $t->{epoch} += 60 * 60 * 24;

=head1 CONSTRUCTORS

=head2 new($str)

Takes a date in string form and parses it into Unix timestamp. The
format is meant to work well with MySQL date strings, and you can
leave any part out after the year and it will fill in the rest for
you. for example Time::Date->new("2005-10") is the same as
Time::Date->new("2005-10-01 00:00:00"). It also works fine with dates
formatted as ISO8601 Time::Date->new("2005-10-01T03:04:05").

=head2 new_epoch($epoch)

Takes a epoch as an argument and returns an object. It does no
parsing. Just wraps the Unix timestamp (epoch) into an object.

=head2 now()

Returns an object representing the current time (now).

=head2 mktime($year, $mon, $mday, $hour, $min, $sec, $wday, $yday, $isdst)

Returns an object from mktime arguments. See mktime(3) man page for
how to use mktime. http://linux.die.net/man/3/mktime. mktime is
very useful for finding the last day of the month since it handles
overflow and negative numbers nicely. For example, this is the last
day of Febuary:

    my $t = Time::Date->mktime(115, 2, 0);

=head1 METHODS

=head2 strftime($format)

Returns a string of the date represented by $t. See the strftime(3)
man page for info on the format options.
http://man7.org/linux/man-pages/man3/strftime.3.html. For example, you can use:

    print $t->strftime("%B %d, %Y") . "\n";
    # prints "September 14, 2015"

=head2 str()

Prints the date as a string. The format is the same as if you used
$t->strftime("%Y-%m-%d %H:%M:%S"). You can always pass this string
back into new(), if you need to recreate the object later. This is
the default stringification when you use the object in a string.
for example:

    print "$t\n";
    # prints "2015-09-14 14:23:31"

=head2 natural()

Prints the date in a natural format such as "25 seconds ago" or "in 5 days".

=head1 CLASS SUBROUTINES

=head2 time_zones()

Returns a list of time zone names from the Olson database on your
system. Could be useful if you need to display a list of them. For
example, if you wanted an HTML select tag:

    my $zones = Time::Date::time_zones;
    my $output = "<select name=\"timezone\">\n";
    for my $zone (@$zones) {
        if ($zone->{region}) {
            $output .= "</optgroup>\n" if $zone->{i};
            $output .= "<optgroup label=\"$zone->{region}\">\n";
        }
        else {
            $output .= "    <option value=\"$zone->{zone}\">$zone->{name}</option>\n";
        }
    }
    $output .= "</optgroup>\n</select>\n";
    print $output;

=head1 METACPAN

L<https://metacpan.org/pod/Time::Date>

=head1 REPOSITORY

L<https://github.com/zorgnax/timedate>

=head1 AUTHOR

Jacob Gelbman, E<lt>gelbman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

