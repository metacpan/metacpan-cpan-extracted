package WWW::Suffit::Util;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Util - The Suffit utilities

=head1 SYNOPSIS

    use WWW::Suffit::Util;

=head1 DESCRIPTION

Exported utility functions

=head2 color

Deprecated in this module! See L<Acrux::Util/color>

See also L<Term::ANSIColor>

=head2 dformat

Deprecated in this module! See L<Acrux::Util/dformat>

See also L<CTK::Util/dformat>

=head2 fbytes

Deprecated in this module! See L<Acrux::Util/fbytes>

=head2 fdate

Deprecated in this module! See L<Acrux::Util/fdate>

=head2 fdatetime

Deprecated in this module! See L<Acrux::Util/fdatetime>

=head2 fduration

Deprecated in this module! See L<Acrux::Util/fduration>

=head2 humanize_duration

Deprecated in this module! See L<Acrux::Util/humanize_duration>

=head2 human2bytes

Deprecated in this module! See L<Acrux::Util/human2bytes>

See also L<Mojo::Util/humanize_bytes>

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

Deprecated in this module! See L<Acrux::Util/parse_expire>

=head2 parse_time_offset

Deprecated in this module! See L<Acrux::Util/parse_time_offset>

=head2 randchars

Deprecated in this module! See L<Acrux::Util/randchars>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acrux::Util>, L<Digest::MD5>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.06';

use Carp;
use Term::ANSIColor qw/colored/;
use POSIX qw/ ceil strftime /;
use Digest::MD5;

use Mojo::Util qw/ trim monkey_patch /;
use Mojo::JSON qw/ decode_json encode_json /;
use Mojo::File qw/ path /;

use WWW::Suffit::Const qw/ IS_TTY DATE_FORMAT DATETIME_FORMAT /;

use base qw/Exporter/;
our @EXPORT = (qw/
        parse_expire parse_time_offset
    /);
our @EXPORT_OK = (qw/
        fbytes fdate fdatetime fduration human2bytes humanize_duration
        dformat
        md5sum
        json_load json_save
        randchars
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

# Patches
monkey_patch 'Mojo::File', spew => sub { goto &Mojo::File::spurt } unless Mojo::File->can('spew');

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
sub humanize_duration {
    my $msecs = shift || 0;
    my $secs = int($msecs);
    my $years = int($secs / (60*60*24*365));
       $secs -= $years * 60*60*24*365;
    my $days = int($secs / (60*60*24));
       $secs -= $days * 60*60*24;
    my $hours = int($secs / (60*60));
       $secs -= $hours * 60*60;
    my $mins = int($secs / 60);
       $secs %= 60;
    if ($years) { return sprintf("%d years %d days %s hours", $years, $days, $hours) }
    elsif ($days) { return sprintf("%d days %s hours %d minutes", $days, $hours, $mins) }
    elsif ($hours) { return sprintf("%d hours %d minutes %d seconds", $hours, $mins, $secs) }
    elsif ($mins >= 2) { return sprintf("%d minutes %d seconds", $mins, $secs) }
    elsif ($secs > 5) { return sprintf("%d seconds", $secs + $mins * 60) }
    elsif ($msecs - $secs) { return sprintf("%.4f seconds", $msecs) }
    return sprintf("%d seconds", $secs);
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
    my $path = path($file)->spew( encode_json($data) ); # spurt
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
sub randchars {
    my $l = shift || return '';
    return '' unless $l =~/^\d+$/;
    my $arr = shift;
    my $r = '';
    my @chars = ($arr && ref($arr) eq 'ARRAY') ? (@$arr) : (0..9,'a'..'z','A'..'Z');
    $r .= $chars[(int(rand($#chars+1)))] for (1..$l);
    return $r;
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
