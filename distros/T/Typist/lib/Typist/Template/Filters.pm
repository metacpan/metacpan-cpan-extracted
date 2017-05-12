package Typist::Template::Filters;
use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = 0.11;

use Typist::Template::Context;

use Typist::Util::String
  qw( decode_html decode_xml remove_html encode_html encode_xml encode_js
  encode_php encode_url );

sub import {
    Typist::Template::Context->add_global_filter('trim_to' => \&trim_to);
    Typist::Template::Context->add_global_filter('trim'    => \&trim);
    Typist::Template::Context->add_global_filter('ltrim'   => \&ltrim);
    Typist::Template::Context->add_global_filter('rtrim'   => \&rtrim);
    Typist::Template::Context->add_global_filter(
                                                'decode_html' => \&decode_html);
    Typist::Template::Context->add_global_filter('decode_xml' => \&decode_xml);
    Typist::Template::Context->add_global_filter(
                                                'remove_html' => \&remove_html);
    Typist::Template::Context->add_global_filter(
                                                'encode_html' => \&encode_html);
    Typist::Template::Context->add_global_filter('encode_xml' => \&encode_xml);
    Typist::Template::Context->add_global_filter('encode_js'  => \&encode_js);
    Typist::Template::Context->add_global_filter('encode_php' => \&encode_php);
    Typist::Template::Context->add_global_filter('encode_url' => \&encode_url);
    Typist::Template::Context->add_global_filter('upper_case' => \&uppper_case);
    Typist::Template::Context->add_global_filter('lower_case' => \&lower_case);
    Typist::Template::Context->add_global_filter(
                                        'strip_linefeeds' => \&strip_linefeeds);
    Typist::Template::Context->add_global_filter('space_pad' => \&space_pad);
    Typist::Template::Context->add_global_filter('zero_pad'  => \&zero_pad);
    Typist::Template::Context->add_global_filter('sprintf'   => \&sprintf);
}

sub trim_to { $_[1] < length($_[0]) ? substr $_[0], 0, $_[1] : $_[0] }

sub trim {
    my $str = shift;
    $str =~ s/(^\s+|\s+$)//sg;
    $str;
}

sub ltrim {
    my $str = shift;
    $str =~ s/^\s+//s;
    $str;
}

sub rtrim {
    my $str = shift;
    $str =~ s/\s+$//s;
    $str;
}

sub upper_case { uc($_[0]) }
sub lower_case { lc($_[0]) }

sub strip_linefeeds {
    my $str = shift;
    $str =~ tr{\r\n}{}d;
    $str;
}

sub space_pad {
    my ($str, $len) = @_;
    $str = sprintf "%${len}s", $str;
    $str;
}

sub zero_pad {
    my ($str, $len) = @_;
    $str = sprintf "%0${len}s", $str;
    $str;
}

sub sprintf {
    my ($str, $format) = @_;
    $str = sprintf($format, $str);
    $str;
}

1;

__END__

=head1 NAME

Typist::Template::Filters - Standard global filters plugin

=head1 FILTERS

=over

=item trim_to

=item trim

=item ltrim

=item rtrim

=item decode_html

=item decode_xml

=item remove_html

=item encode_html

=item encode_xml

=item encode_js

=item encode_php

=item encode_url

=item upper_case

=item lower_case

=item strip_linefeeds

=item space_pad

=item zero_pad

=item sprintf

=back
