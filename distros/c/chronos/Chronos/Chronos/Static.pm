# $Id: Static.pm,v 1.9 2002/09/17 00:20:17 nomis80 Exp $
#
# Copyright (C) 2002  Linux Québec Technologies
#
# This file is part of Chronos.
#
# Chronos is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Chronos is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Chronos::Static;

# This package contains functions that should be useable outside of mod_perl.
# Standalone scripts can therefore include this module and use its functions.
# remindd and chronosadmin do so.

use strict;
use Exporter;
use HTML::Entities;
# If we are running under mod_perl, we can use Apache::DBI, which will cache
# database handles.
if ( exists $ENV{MOD_PERL} ) {
    eval { require Apache::DBI };
    die $@ if $@;
    die "Couldn't include Apache::DBI: $!\n" if $!;
} else {
    eval { require DBI };
    die $@ if $@;
    die "Couldn't include DBI: $!\n" if $!;
}

our @ISA       = qw(Exporter);
our @EXPORT_OK =
  qw(&gettext &conf &dbh &datetime2values &Compare_YMDHMS &to_datetime &from_datetime &Compare_YMD &from_date &userstring &to_date &lang &get &from_time &to_time);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '1.1.6';
sub VERSION { $VERSION }

sub gettext {
    my $lang = shift || lang();
    my $noentities = shift;

    $lang = substr $lang, 0, 2;
    my $en = parselang( 'en', $noentities );
    # Merge English with $lang. This makes sure that untranslated strings will
    # at least show up as English.
    my %text = ( %$en, %{ parselang( $lang, $noentities ) } );
    return \%text;
}

sub parselang {
    my $lang       = shift;
    my $noentities = shift;

    open LANG, "/usr/share/chronos/lang/$lang";
    my %text;
    while (<LANG>) {
        next if /^#/ or /^\s*$/ or not /=/;
        my ( $key, $value ) = $_ =~ /^(\w+)\s*=\s*(.*)/;
        if ( $value eq '<<EOF' ) {
            undef $value;
            while ( my $line = <LANG> ) {
                last if $line =~ /^EOF$/;
                $value .= $line;
            }
        }
        $value = encode_entities( $value, "\200-\377" ) unless $noentities;
        $text{$key} = $value;
    }
    close LANG;
    return \%text;
}

sub lang {
    my $lang = $ENV{LC_MESSAGES} || $ENV{LANG} || 'en';
    return substr $lang, 0, 2;
}

sub dbh {
    my $conf    = conf();
    my $db_type = $conf->{DB_TYPE} || 'mysql';
    my $db_name = $conf->{DB_NAME} || 'chronos';
    my $db_host = $conf->{DB_HOST};
    my $db_port = $conf->{DB_PORT};
    my $db_user = $conf->{DB_USER} || 'chronos';
    my $db_pass = $conf->{DB_PASS};
    if ( not $db_pass ) {
        warn("I need a DB_PASS in the configuration file");
        return;
    }

    my $dsn =
      "dbi:$db_type:$db_name"
      . ( $db_host ? ":$db_host" : '' )
      . ( $db_port ? ":$db_port" : '' );
    my $dbh = DBI->connect(
        $dsn, $db_user, $db_pass,
        {
            RaiseError => 1,
            PrintError => 0
        }
    );
    return $dbh;
}

sub conf {
    my $file = shift || "/etc/chronos.conf";

    my %conf;
    open CONF, $file or die "Can't open $file for reading: $!\n";
    while (<CONF>) {
        next if /^#/ or /^\s*$/;
        my ( $key, $value ) = $_ =~ /^(\w+?)\s*=\s*(.*)/;
        next unless $key and $value;
        $key = uc $key;
        $conf{$key} = $value;

        # Defaults
        $conf{DB_TYPE}                  ||= 'mysql';
        $conf{DB_HOST}                  ||= 'localhost';
        $conf{DB_PORT}                  ||= 3306;
        $conf{DB_NAME}                  ||= 'chronos';
        $conf{DB_USER}                  ||= 'chronos';
        $conf{DB_PASS}                  ||= '';
        $conf{HOLIDAYS}                 ||= '';
        $conf{SENDMAIL}                 ||= '/usr/sbin/sendmail';
        $conf{STYLESHEET}               ||= '/chronos_static/chronos.css';
        $conf{DAY_DATE_FORMAT}          ||= '%k:%M';
        $conf{DAY_MULTIDAY_DATE_FORMAT} ||= '%(long) %k:%M';
        $conf{DAY_NOTIME_DATE_FORMAT}   ||= '';
        $conf{DAY_MULTIDAY_NOTIME_DATE_FORMAT}   ||= '%(long)';
        $conf{MONTH_DATE_FORMAT}                 ||= '%k:%M';
        $conf{MONTH_MULTIDAY_DATE_FORMAT}        ||= '%F %k:%M';
        $conf{MONTH_NOTIME_DATE_FORMAT}          ||= '';
        $conf{MONTH_MULTIDAY_NOTIME_DATE_FORMAT} ||= '%F';
        $conf{WEEK_DATE_FORMAT}                  ||= '%k:%M';
        $conf{WEEK_MULTIDAY_DATE_FORMAT}         ||= '%F %k:%M';
        $conf{WEEK_NOTIME_DATE_FORMAT}           ||= '';
        $conf{WEEK_MULTIDAY_NOTIME_DATE_FORMAT}  ||= '%F';
        $conf{MINIMONTH_DATE_FORMAT}             ||= '%(long)';
        $conf{HEADER_DATE_FORMAT}                ||= '%(long) %k:%M';
        $conf{DAYVIEW_DATE_FORMAT}               ||= '%(long)';
        $conf{DEFAULT_ACTION}                    ||= 'showday';
    }
    return \%conf;
}

sub datetime2values {
    my $datetime = shift;
    my ( $year, $month, $day, $hour, $minute, $second ) =
      $datetime =~ /^(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/;
    return ( $year, $month, $day, $hour, $minute, $second );
}

sub Compare_YMDHMS {
    my ( $y1, $M1, $d1, $h1, $m1, $s1, $y2, $M2, $d2, $h2, $m2, $s2 ) = @_;
    return ( $y1 <=> $y2
          || $M1 <=> $M2
          || $d1 <=> $d2
          || $h1 <=> $h2
          || $m1 <=> $m2
          || $s1 <=> $s2 );
}

sub Compare_YMD {
    my ( $y1, $M1, $d1, $y2, $M2, $d2 ) = @_;
    return ( $y1 <=> $y2 || $M1 <=> $M2 || $d1 <=> $d2 );
}

sub to_datetime {
    return sprintf '%04d-%02d-%02d %02d-%02d-%02d', @_;
}

sub from_datetime {
    return shift =~ /^(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/;
}

sub from_date {
    return shift =~ /^(\d{4})-(\d\d)-(\d\d)$/;
}

sub from_time {
    return shift =~ /^(\d\d):(\d\d):(\d\d)$/;
}

sub to_date {
    return sprintf '%04d-%02d-%02d', @_;
}

sub to_time {
    return sprintf '%02d:%02d:%02d', @_;
}

sub userstring {
    my ( $user, $name, $email ) = @_;
    if ($name) {
        if ($email) {
            return "$name &lt;<a href=\"mailto:$email\">$email</a>&gt;";
        } else {
            return $name;
        }
    } else {
        return $user;
    }
}

{
    my $text;
    sub get {
        my $prompt  = shift;
        my $options = shift;

        my %enum;
        if ( $options->{Enum} ) {
            %enum = map { $_ => 1 } @{ $options->{Enum} };
        }

        my $value;
        while ( not $value ) {
            print "$prompt: ";
            if ( $options->{Enum} ) {
                print "(" . join ( ",", @{ $options->{Enum} } ) . ") ";
            }
            if ( $options->{Default} ) {
                print "[$options->{Default}] ";
            }
            if ( $options->{Password} ) {
                system "stty -echo";
                chomp( $value = <STDIN> );
                system "stty echo";
                print "\n";
                unless ( $options->{NoConfirm} ) {
                    $text ||= gettext();
                    printf "$text->{chronosadmin_confirm} ";
                    system "stty -echo";
                    chomp( my $confirmation = <STDIN> );
                    system "stty echo";
                    print "\n";
                    undef $value unless $value eq $confirmation;
                }
            } else {
                chomp( $value = <STDIN> );
            }

            $value ||= $options->{Default};

            if (%enum) {
                undef $value if not $enum{$value};
            }
        }
        return $value;
    }
}

1;

# vim: set et ts=4 sw=4 ft=perl:
