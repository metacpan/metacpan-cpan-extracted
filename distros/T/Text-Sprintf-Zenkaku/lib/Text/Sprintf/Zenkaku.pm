package Text::Sprintf::Zenkaku;
use 5.008001;
use strict;
use warnings;
use utf8;
use Carp;
use Encode;

our $VERSION = "0.09";

use Exporter 'import';
our @EXPORT_OK = qw(sprintf);

our $cp932 = Encode::find_encoding("cp932");

our $conversions = qr/\A[cduoxefgXEGbBpnaA]\Z/;
$conversions = qr/\A[cduoxefgXEGbBpn]\Z/ if $] lt 5.022000;
$conversions = qr/\A[cduoxefgXEGbpn]\Z/ if $] lt 5.010000;

sub calc_width {
    my ($w, $s) = @_;

    my $ofs;
    if ($w >= 0) {
        $ofs = $w - ((length $cp932->encode($s)) - (length $s));
    } else {
        $ofs = (abs $w) - ((length $cp932->encode($s)) - (length $s));
        $ofs *= -1;
    }

    return $ofs;
}

sub sprintf {
    my @argv = @_;
    my $fmt  = defined $argv[0] ? $argv[0] : "";

    my $ofs   = 0;
    my $state = "IDL";

    my $index   = 1;
    my $tmp     = "";
    my $fmt_new = "";
    my $length  = length $fmt;
    my $is_uniq = {};

    while ($ofs < $length) {
        my $s = substr $fmt, $ofs, 1;
        if ($state eq "IDL") {
            if ($s eq "%") {
                $tmp   = $s;
                $state = "READ_FORMAT";
            } else {
                $fmt_new .= $s;
            }
        } elsif ($state eq "READ_FORMAT") {
            if ($s eq "%") {
                # 'a percent sign' literal
                $fmt_new .= $tmp . $s;
                $tmp = "";
                $state = "IDL";

            } elsif ($s eq "s") {
                # %s
                $tmp .= $s;

                if ($tmp =~ /^%([1-9][0-9]*)\$( *)\*([1-9][0-9]*)\$s$/) {
                    my $s_index = int $1;
                    my $space   = $2;
                    my $w_index = int $3;

                    my $s = $_[$s_index];
                    my $w = $_[$w_index];

                    my $width = calc_width($w, $s);
                    if (not exists $is_uniq->{$w_index}) {
                        $argv[$w_index] = $width;
                        $is_uniq->{$w_index}++;
                    } else {
                        $tmp = '%' . $s_index . '$' . $space . $width . 's';
                    }

                } elsif ($tmp =~ /^%([1-9][0-9]*)\$( *)\*s$/) {
                    my $s_index = int $1;
                    my $space   = $2;
                    my $w_index = $index;

                    my $s = $_[$s_index];
                    my $w = $_[$w_index];

                    my $width = calc_width($w, $s);
                    if (not exists $is_uniq->{$w_index}) {
                        $argv[$w_index] = $width;
                        $is_uniq->{$w_index}++;
                    } else {
                        $tmp = '%' . $s_index . '$' . $space . $width . 's';
                    }
                    $index++;

                } elsif ($tmp =~ /^%([1-9][0-9]*)\$( *)(-?[0-9]+)s$/) {
                    my $s_index = int $1;
                    my $space   = $2;

                    my $s = $_[$s_index];
                    my $w = $3;

                    $w = calc_width($w, $s);

                    $tmp = '%' . $s_index . '$' . $space . $w . 's';
                    $index++;

                } elsif ($tmp =~ /^%([1-9][0-9]*)\$( *)s$/) {
                    # do nothing
                    $index++;

                } elsif ($tmp =~ /^%( *)\*([1-9][0-9]*)\$s$/) {
                    my $s_index = $index;
                    my $space   = $1;
                    my $w_index = int $2;

                    my $s = $_[$s_index];
                    my $w = $_[$w_index];

                    my $width = calc_width($w, $s);
                    if (not exists $is_uniq->{$w_index}) {
                        $argv[$w_index] = $width;
                        $is_uniq->{$w_index}++;
                    } else {
                        $tmp = '%' . $space . $width . 's';
                    }
                    $index++;

                } elsif ($tmp =~ /^%( *)\*s$/) {
                    my $s_index = $index + 1;
                    my $space   = $1;
                    my $w_index = $index;
                    $index++;

                    my $s = $_[$s_index];
                    my $w = $_[$w_index];

                    my $width = calc_width($w, $s);

                    if (not exists $is_uniq->{$w_index}) {
                        $argv[$w_index] = $width;
                        $is_uniq->{$w_index}++;
                    } else {
                        #$tmp = '%' . $space . $width . 's';
                        $argv[$w_index] = $width;
                        $is_uniq->{$w_index}++;
                    }
                    $index++;

                } elsif ($tmp =~ /^%( *)(-?[0-9]+)s$/) {
                    my $space   = $1;

                    my $s = $_[$index];
                    my $w = int $2;

                    $w = calc_width($w, $s);

                    $tmp = '%' . $space . $w . 's';
                    $index++;

                } else {
                    # do nothing
                    $index++;

                }

                $fmt_new .= $tmp;
                $tmp = "";
                $state = "IDL";
            } elsif ($s =~ /$conversions/) {
                # %c, %d, %u, %o, %x, %e, %f, %g, ...
                $fmt_new .= $tmp . $s;
                $tmp = "";
                $index++;
                $state = "IDL";
            } elsif ($s eq "*") {
                $tmp .= $s;
                $state = "READ_ARGUMENT_NUMBER";
            } elsif ($s =~ /\A[0-9]\Z/) {
                $tmp .= $s;
                $state = "READ_FORMAT_OR_ARGUMENT_NUMBER";
            } elsif ($s =~ /\A[-+ #\.v]\Z/) {
                $tmp .= $s;
                if ($tmp =~ /\*v/) {
                    $index++;
                }
            } else {
                croak "not supported : $fmt";
            }
        } elsif ($state eq "READ_ARGUMENT_NUMBER") {
            if ($s =~ /\A[0-9]\Z/) {
                $tmp .= $s;
            } elsif ($s eq '$') {
                $tmp .= $s;
                $state = "READ_FORMAT";
            } else {
                $state = "READ_FORMAT";
                #$index++;
                next;
            }
        } else {
            # $state eq "READ_FORMAT_OR_ARGUMENT_NUMBER"
            if ($s =~ /\A[0-9]\Z/) {
                $tmp .= $s;
            } elsif ($s eq '$') {
                $tmp .= $s;
                $state = "READ_FORMAT";
            } else {
                $state = "READ_FORMAT";
                next;
            }
        }
        $ofs++;
    }

    $fmt_new .= $tmp;

    shift @argv;
    return CORE::sprintf $fmt_new, @argv;
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Sprintf::Zenkaku - sprintf with zenkaku chars

=head1 SYNOPSIS

    use Text::Sprintf::Zenkaku qw(sprintf);

    sprintf "<%3s>", "あ"; # zenkaku char works good

=head1 DESCRIPTION

Text::Sprintf::Zenkaku is sprintf with zenkaku chars.

=head1 METHOD

=head2 sprintf()

sprintf() with zenkaku chars.

=head2 calc_width($width, $str)

Zenkaku considered calc width.

=head1 REPOSITORY

L<https://github.com/sago35/Text-Sprintf-Zenkaku>

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>takasago@cpan.orgE<gt>

=cut

