package WWW::Webrobot::Util;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use Exporter;
use base qw/Exporter/;
our @EXPORT_OK = qw/ascii textify octet/;


=head1 NAME

WWW::Webrobot::Util - some simple utilities

=head1 SYNOPSIS

 WWW::Webrobot::Util::ascii("a\x{76EE}b");

=head1 DESCRIPTION

Some simple utility functions.

=head1 METHODS

=cut

sub _encode_text {
    my ($fun) = shift;
    if (wantarray) {
        return map {$fun->($_)} @_;
    }
    else {
        return join "", map {$fun->($_)} @_;
    }
}

=over

=item ascii

encode all multi-byte and control characters in printable form

=cut

sub ascii {
    _encode_text(sub {
        join("",
            map {
                $_ > 255 ?                      # if wide character...
                    sprintf("\\x{%04X}", $_)    #     \x{...}
                : chr($_) =~ /[[:cntrl:]]/ ?    # else if control character ...
                    sprintf("\\x%02X", $_)      #     \x..
                :                               # else
                    chr($_)                     #     as themselves
            } unpack("U*", $_[0])
        );
    },
    @_);
}

=item textify

encode all multi-byte characters in printable form

=cut

sub textify {
    _encode_text(sub {
        join("",
            map {
                $_ > 255 ?                      # if wide character...
                    sprintf("\\x{%04X}", $_)    #     \x{...}
                :                               # else
                    chr($_)                     #     as themselves
            } unpack("U*", $_[0])
        );
    },
    @_);
}
 

=item octet

encode non-printables except control characters as octets

=cut

sub octet {
    _encode_text(sub {
        join("",
            map {
                $_ > 255 ?                      # if wide character...
                    sprintf("\\x{%04X}", $_)    #     \x{...}
                : $_ > 127 ?                    # if 1xxxxxxx
                    sprintf("\\x{%02X}", $_)      #     \x..
                :                               # else
                    chr($_)                     #     as themselves
            } unpack("C*", $_[0])
        );
    },
    @_);
}

=item octet_all

encode non-printables as octets

=cut

sub octet_all {
    _encode_text(sub {
        join("",
            map {
                $_ > 255 ?                      # if wide character...
                    sprintf("\\x{%04X}", $_)    #     \x{...}
                : chr($_) =~ /[[:cntrl:]]/ ?    # else if control character ...
                    sprintf("\\x{%02X}", $_)      #     \x..
                : $_ > 127 ?                    # if 1xxxxxxx
                    sprintf("\\x{%02X}", $_)      #     \x..
                :                               # else
                    chr($_)                     #     as themselves
            } unpack("C*", $_[0])
        );
    },
    @_);
}

=back

=cut

1;
