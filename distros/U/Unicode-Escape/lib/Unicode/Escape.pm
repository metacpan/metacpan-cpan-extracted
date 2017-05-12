package Unicode::Escape;

use warnings;
use strict;
use Carp;

use Unicode::String;
use Exporter;
use Encode;

use vars qw( $VERSION @ISA @EXPORT_OK );

$VERSION = '0.0.2';

@ISA = qw(Exporter);

@EXPORT_OK = qw(
    escape
    unescape
);


sub new {
    my ($class, $str, $enc) = @_;
    $enc ||= 'utf8';
    Encode::from_to($str, $enc, 'utf8');
    return  bless \$str, $class;
}


sub escape {
    my ($self, $enc) = @_;
    $enc ||= 'utf8';
    my $str;
    if(ref $self) {
        $str = $$self;
    }
    else {
        Encode::from_to($self, $enc, 'utf8');
        $str = $self;
    }

    my $us = Unicode::String->new($str);
    my $rslt = '';
    while(my $uchar = $us->chop) {
        my $utf8 = $uchar->utf8;
        $rslt = (($utf8 =~ /[\x80-\xff]/) ? '\\u'.unpack('H4', $uchar->utf16be) : $utf8) . $rslt;
    }
    return $rslt;
}


sub unescape {
    my ($self, $enc) = @_;
    $enc ||= 'utf8';
    my $str = (ref $self) ? $$self : $self;
    
    my @chars = split(//, $str);
    my $us = Unicode::String->new();
    while(defined(my $char = shift(@chars))) {
        if($char eq '\\') {
            if(($char = shift(@chars)) eq 'u') {
                my $i = 0;
                for(; $i < 4; $i++) {
                    unless($chars[$i] =~ /[0-9a-fA-F]/){
                        last;
                    }               
                }
                if($i == 4) {
                    my $hex = hex(join('', splice(@chars, 0, 4)));
                    $us->append(Unicode::String::chr($hex));
                }
                else {
                    $us->append('u');
                }
            }
            else {
                $us->append('\\'.$char);
            }
        }
        else {
            $us->append($char);
        }
    }
    my $result = $us->utf8;
    Encode::from_to($result, 'utf8', $enc);
    return $result;
}


1;
__END__

=head1 NAME

Unicode::Escape - Escape and unescape Unicode characters other than ASCII


=head1 VERSION

This document describes Unicode::Escape version 0.0.1


=head1 SYNOPSIS

    # Escape Unicode charactors like '\\u3042\\u3043\\u3044'.
    # JSON thinks No more Garble!!

    # case 1
    use Unicode::Escape;
    my $escaped1 = Unicode::Escape::escape($str1, 'euc-jp');             # $str1 contains charactor that is not ASCII. $str1 is encoded by euc-jp.
    my $escaped2 = Unicode::Escape::escape($str2);     # default is utf8 # $str2 contains charactor that is not ASCII.
    my $unescaped1 = Unicode::Escape::unescape($str3, 'shiftjis');       # $str3 contains escaped Unicode character. return value is encoded by shiftjis.
    my $unescaped2 = Unicode::Escape::unescape($str4); # default is utf8 # $str4 contains escaped Unicode character.

    # case 2
    use Unicode::Escape qw(escape unescape);
    my $escaped1 = escape($str1, 'euc-jp');             # $str1 contains charactor that is not ASCII. $str1 is encoded by euc-jp.
    my $escaped2 = escape($str2);     # default is utf8 # $str2 contains charactor that is not ASCII.
    my $unescaped1 = unescape($str3, 'shiftjis');       # $str3 contains escaped Unicode character. return value is encoded by shiftjis.
    my $unescaped2 = unescape($str4); # default is utf8 # $str4 contains escaped Unicode character.

    # case 3
    use Unicode::Escape;
    my $escaper = Unicode::Escape->new($str, 'shiftjis'); # $str contains charactor that is not ASCII. $str is encoded by shiftjis.(default is utf8)
    my $escaped = $escaper->escape;

    # case 4
    use Unicode::Escape;
    my $escaper = Unicode::Escape->new($str); # $str contains escaped Unicode character.
    my $unescaped1 = $escaper->unescape('shiftjis');
    my $unescaped2 = $escaper->unescape;      # default is utf8.

=head1 DESCRIPTION

Escape and unescape Unicode characters other than ASCII.
When the server response is javascript code, it is convenient. 

=head1 METHODS 

=head2 new( $string[, $encode ] )

=over 2

=item string

Target string for escape or unescape. 

=item encode

For instance, 'utf8', 'shiftjis', and 'euc-jp', etc. (See L<Encode>)

=back

=head2 escape( $string[, $encode ] )

=over 2

=item string

Target string. This argument is unnecessary when called as object method.

=item encode

For instance, 'utf8', 'shiftjis', and 'euc-jp', etc. (See L<Encode>)
This argument is unnecessary when called as object method.

=back

=head2 unescape( $string[, $encode ] )

=over 2

=item string

Target string. This argument is unnecessary when called as object method.

=item encode

For instance, 'utf8', 'shiftjis', and 'euc-jp', etc. (See L<Encode>)

=back

=head1 SEE ALSO

L<Unicode::String>, L<Encode>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-unicode-escape@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Hitoshi Amano  C<< <seijro@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Hitoshi Amano C<< <seijro@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
