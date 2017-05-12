package Text::Demoroniser;

use strict;
use warnings;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Encode::ZapCP1252;

BEGIN {
    require Exporter;
    $VERSION = '0.07';
    @ISA = qw( Exporter );
    @EXPORT = qw();
    %EXPORT_TAGS = (
        'all' => [ qw( demoroniser demoroniser_utf8 ) ]
    );
    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
}

my %character = (   #   ASCII   UTF8
    "\xE2\x80\x9A" => [ ',',    "\x201A" ],     # 82 - SINGLE LOW-9 QUOTATION MARK
    "\xE2\x80\x9E" => [ ',,',   "\x201E" ],     # 84 - DOUBLE LOW-9 QUOTATION MARK
    "\xE2\x80\xA6" => [ '...',  "\x2026" ],     # 85 - HORIZONTAL ELLIPSIS
    "\xCB\x86"     => [ '^',    "\x02C6" ],     # 88 - MODIFIER LETTER CIRCUMFLEX ACCENT
    "\xE2\x80\x98" => [ '`',    "\x2018" ],     # 91 - LEFT SINGLE QUOTATION MARK
    "\xE2\x80\x99" => [ q{'},   "\x2019" ],     # 92 - RIGHT SINGLE QUOTATION MARK
    "\xE2\x80\x9C" => [ '"',    "\x201C" ],     # 93 - LEFT DOUBLE QUOTATION MARK
    "\xE2\x80\x9D" => [ '"',    "\x201D" ],     # 94 - RIGHT DOUBLE QUOTATION MARK
    "\xE2\x80\xA2" => [ '*',    "\x2022" ],     # 95 - BULLET
    "\xE2\x80\x93" => [ '-',    "\x2013" ],     # 96 - EN DASH
    "\xE2\x80\x94" => [ '-',    "\x2014" ],     # 97 - EM DASH

    "\xE2\x80\xB9" => [ '<',    "\x2039" ],     # 8B - SINGLE LEFT-POINTING ANGLE
                                                #      QUOTATION MARK
    "\xE2\x80\xBA" => [ '>',    "\x203A" ],     # 9B - SINGLE RIGHT-POINTING ANGLE
                                                #      QUOTATION MARK
);

my $characters_re = '(' . join( '|', keys %character ) . ')';

sub demoroniser {
    my $str = shift;
    return  unless(defined $str);

    $str =~ s/$characters_re/$character{$1}[0]/g;

    zap_cp1252($str);

    return $str;
}

sub demoroniser_utf8 {
    my $str = shift;
    return  unless(defined $str);

    $str =~ s/$characters_re/$character{$1}[1]/g;

    fix_cp1252($str);

    return $str;
}

1;

__END__

=pod

=head1 NAME

Text::Demoroniser - A text filter that allows you to demoronise a string.

=head1 SYNOPSIS

  use Text::Demoroniser qw(demoroniser);

  my $bad  = 'string with smart characters in'
  my $good = demoroniser($bad);

=head1 DESCRIPTION

A text filter that allows you to replace inappropriate Microsoft characters a
string with something more suitable.

=head1 API

This module exports following filters:

=head2 demoroniser

Given a string, will replace the Microsoft "smart" characters with sensible
ACSII versions.

=head2 demoroniser_utf8

The same as demoroniser, but converts into correct UTF8 versions.

=head1 SEE ALSO

L<Encode::ZapCP1252>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Text-Demoronmiser

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2015 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
