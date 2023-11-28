package WWW::Suffit::Util;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Util - The Suffit utilities

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use WWW::Suffit::Util;

=head1 DESCRIPTION

Exported utility functions

=head2 color

    say color(blue => "Format %s %s" => "text", "foo");
    say color(cyan => "text");
    say color("red on_bright_yellow" => "text");
    say STDERR color("red on_bright_yellow" => "text");

Returns colored formatted string if is session was runned from terminal

Supported normal foreground colors:

    black, red, green, yellow, blue, magenta, cyan, white

Bright foreground colors:

    bright_black, bright_red,     bright_green, bright_yellow
    bright_blue,  bright_magenta, bright_cyan,  bright_white

Normal background colors:

    on_black, on_red,     on_green, on yellow
    on_blue,  on_magenta, on_cyan,  on_white

Bright background color:

    on_bright_black, on_bright_red,     on_bright_green, on_bright_yellow
    on_bright_blue,  on_bright_magenta, on_bright_cyan,  on_bright_white

See also L<Term::ANSIColor>

=head2 dformat

    $string = dformat( $mask, \%replacehash );
    $string = dformat( $mask, %replacehash );

Replace substrings "[...]" in mask and
returns replaced result. Data for replacing get from \%replacehash

For example:

    # -> 01-foo-bar.baz.tgz
    $string = dformat( "01-[NAME]-bar.[EXT].tgz", {
        NAME => 'foo',
        EXT  => 'baz',
    });

See also L<CTK::Util/dformat>

=head2 fbytes

    print fbytes( 123456 );

Returns formatted size value

=head2 fdate

    print fdate( time );

Returns formatted date value

=head2 fdatetime

    print fdatetime( time );

Returns formatted date value

=head2 fduration

    print fduration( 123 );

Returns formatted duration value

=head2 human2bytes

    my $bytes = human2bytes("100 kB");

Converts a human readable byte count into the pure  number of bytes without any suffix

=head2 json_load

    my $hash  = json_load( $file );

Loads JSON file and returns data as perl struct

=head2 json_save

    my $path = json_save( $file, {foo => [1, 2], bar => 'hello!', baz => \1} );

Save perl struct to file as JSON document and returns the L<Mojo::File> object

=head2 md5sum

    my $md5 = md5sum( $file );

See L<Digest::MD5>

=head2 parse_expire

    print parse_expire("+1d"); # 86400
    print parse_expire("-1d"); # -86400

Returns offset of expires time (in secs).

Original this function is the part of CGI::Util::expire_calc!

This internal routine creates an expires time exactly some number of hours from the current time.
It incorporates modifications from  Mark Fisher.

format for time can be in any of the forms:

    now   -- expire immediately
    +180s -- in 180 seconds
    +2m   -- in 2 minutes
    +12h  -- in 12 hours
    +1d   -- in 1 day
    +3M   -- in 3 months
    +2y   -- in 2 years
    -3m   -- 3 minutes ago(!)

If you don't supply one of these forms, we assume you are specifying the date yourself

=head2 parse_time_offset

    my $off = parse_time_offset("1h2m24s"); # 4344
    my $off = parse_time_offset("1h 2m 24s"); # 4344

Returns offset of time (in secs)

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Digest::MD5>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION @EXPORT_OK @EXPORT /;
$VERSION = '1.02';

use Carp;
use Term::ANSIColor qw/colored/;
use POSIX qw/ ceil strftime /;
use Digest::MD5;

use Mojo::Util qw/ trim /;
use Mojo::JSON qw/ decode_json encode_json /;
use Mojo::File qw/ path /;

use WWW::Suffit::Const qw/ IS_TTY DATE_FORMAT DATETIME_FORMAT /;

use base qw/Exporter/;
@EXPORT = (qw/
        parse_expire parse_time_offset
    /);
@EXPORT_OK = (qw/
        fbytes fdate fdatetime fduration human2bytes
        dformat
        md5sum
        json_load json_save
        color
    /, @EXPORT);

use constant HUMAN_SUFFIXES => {
    'B' => 0,
    'K' => 10, 'KB' => 10, 'KIB' => 10,
    'M' => 20, 'MB' => 20, 'MIB' => 20,
    'G' => 30, 'GB' => 30, 'GIB' => 30,
    'T' => 40, 'TB' => 40, 'TIB' => 40,
    'P' => 50, 'PB' => 50, 'PIB' => 50,
    'E' => 60, 'EB' => 60, 'EIB' => 60,
    'Z' => 70, 'ZB' => 70, 'ZIB' => 70,
    'Y' => 80, 'YB' => 80, 'YIB' => 80,
};

sub fbytes {
    my $n = int(shift);
    if ($n >= 1024 ** 3) {
        return sprintf "%.3g GiB", $n / (1024 ** 3);
    } elsif ($n >= 1024 ** 2) {
        return sprintf "%.3g MiB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KiB", $n / 1024.0;
    } else {
        return "$n B"; # bytes
    }
}
sub human2bytes {
    my $h = shift || 0;
    return 0 unless $h;
    my ($bts, $sfx) = $h =~ /([0-9.]+)\s*([a-zA-Z]*)/;
    return 0 unless $bts;
    my $exp = HUMAN_SUFFIXES->{($sfx ? uc($sfx) : "B")} || 0;
    return ceil($bts * (2 ** $exp));
}
sub fduration {
    my $msecs = shift || 0;
    my $secs = int($msecs);
    my $hours = int($secs / (60*60));
    $secs -= $hours * 60*60;
    my $mins = int($secs / 60);
    $secs %= 60;
    if ($hours) {
        return sprintf("%d hours %d minutes", $hours, $mins);
    } elsif ($mins >= 2) {
        return sprintf("%d minutes", $mins);
    } elsif ($secs < 2*60) {
        return sprintf("%.4f seconds", $msecs);
    } else {
        $secs += $mins * 60;
        return sprintf("%d seconds", $secs);
    }
}
sub fdate {
    my $t = shift || time;
    return strftime(DATE_FORMAT, localtime($t));
}
sub fdatetime {
    my $t = shift || time;
    return strftime(DATETIME_FORMAT, localtime($t));
}
sub parse_expire {
    my $t = trim(shift(@_) // 0);
    my %mult = (
            's' => 1,
            'm' => 60,
            'h' => 60*60,
            'd' => 60*60*24,
            'w' => 60*60*24*7,
            'M' => 60*60*24*30,
            'y' => 60*60*24*365
        );
    if (!$t || (lc($t) eq 'now')) {
        return 0;
    } elsif ($t =~ /^\d+$/) {
        return $t; # secs
    } elsif ($t=~/^([+-]?(?:\d+|\d*\.\d*))([smhdwMy])/) {
        return ($mult{$2} || 1) * $1;
    }
    return $t;
}
sub parse_time_offset {
    my $s = trim(shift(@_) // 0);
    return $s if $s =~ /^\d+$/;
    my $r = 0;
    my $c = 0;
    while ($s =~ s/([+-]?(?:\d+|\d*\.\d*)[smhdMy])//) {
        my $i = parse_expire("$1");
        $c++ if $i < 0;
        $r += $i < 0 ? $i*-1 : $i;
    }
    return $c ? $r*-1 : $r;
}
sub md5sum {
    my $f = shift;
    my $md5 = Digest::MD5->new;
    my $sum = '';
    return $sum unless -e $f;
    open( my $md5_fh, '<', $f) or (carp("Can't open '$f': $!") && return $sum);
    if ($md5_fh) {
        binmode($md5_fh);
        $md5->addfile($md5_fh);
        $sum = $md5->hexdigest;
        close($md5_fh);
    }
    return $sum;
}
sub json_save {
    my $file = shift // '';
    my $data = shift;
    croak("No file specified") unless length $file;
    croak("No data (perl struct) specified") unless ref $data eq 'ARRAY' || ref $data eq 'HASH';

    # my $bytes = encode_json {foo => [1, 2], bar => 'hello!', baz => \1};
    my $path = path($file)->spurt( encode_json($data) );
    return $path;
}
sub json_load {
    my $file = shift // '';
    croak("No file specified") unless length $file;
    unless (-e $file) {
        carp("JSON file not found: $file");
        return undef;
    }

    # my $hash  = decode_json $bytes;
    my $data = decode_json( path($file)->slurp );
    return $data;
}
sub dformat {
    my $f = shift;
    my $d = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $f =~ s/\[([A-Z0-9_\-.]+?)\]/(defined($d->{$1}) ? $d->{$1} : "[$1]")/eg;
    return $f;
}

# Colored helper function
sub color {
    my $clr = shift;
    my $txt = (scalar(@_) == 1) ? shift(@_) : sprintf(shift(@_), @_);
    return $txt unless defined($clr) && length($clr);
    return IS_TTY ? colored([$clr], $txt) : $txt;
}

1;

__END__
