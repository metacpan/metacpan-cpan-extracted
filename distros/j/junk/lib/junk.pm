package junk;
our $VERSION   = '0.004';
our $AUTHORITY = 'cpan:TOBYINK';
use strict; use Carp; use MIME::Base64;
sub import{my$class=shift or return$=;if(!@_){strict->unimport,return
}my@A=@_;my$caller=caller;foreach my$x(@A){$x=~s{_D\d}{$1}g;$x=~s{_P}
{+}g;$x=~s{_S}{/}g;$x.='='while(length$x)%3;croak"invalid base64: $x"
if$x=~m~[^A-Za-z0-9\+\/\=]~;my$o;my$eval=join q..,qq, package $caller
;,,decode_base64($x);warn"$eval\n"if$ENV{PERL_JUNK_DEBUG};eval$eval}}
sub unimport{strict->import(qw,vars subs,)}import

__END__

=head1 NAME

junk - use junk

=head1 SYNOPSIS

 use 5.010;
 use junk KnRlaCdiaXRlPSp0YWRwb2xlJ3dheD0qZGFyZSd5b3U9c3Vie3BvcH0K;
 no junk;
 say bite teh wax tadpole "monkey brains" if you dare "punkass",
     or alarm my $accountant;

=head1 DESCRIPTION

The "junk" module performs two very different tasks depending on whether
you type C<< use junk >> or C<< no junk >>.

=head2 C<< import >>

C<< use junk >> takes each of its arguments, performs some unescaping
on each, decodes them as base64, and then passes them each to C<eval>.

The unescaping is as follows:

 "_D0"   => "0"
 "_D1"   => "1"
 "_D2"   => "2"
 "_D3"   => "3"
 "_D4"   => "4"
 "_D5"   => "5"
 "_D6"   => "6"
 "_D7"   => "7"
 "_D8"   => "8"
 "_D9"   => "9"
 "_P"    => "+"
 "_S"    => "/"

This allows base64 to be encoded as Perl barewords (provided you're
not in strict mode).

Called with no arguments, it switches off switch mode.

=head2 C<< unimport >>

C<< no junk >> is equivalent to saying C<< use strict 'subs', 'vars' >>.

I don't know about you, but 'refs' is the only part of strict that I ever
disable, so C<< no junk >> just enables all of strict except 'refs'.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=junk>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

