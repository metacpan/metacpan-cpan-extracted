package usw;
use 5.012005;
use parent qw(utf8 strict warnings);
use Encode qw(is_utf8 encode_utf8 decode_utf8);

our $VERSION = "0.11";
my $enc;
sub _get_encoding {$enc}

sub import {
    $_->import for qw( utf8 strict warnings );   # borrowed from https://metacpan.org/pod/Mojo::Base
    require encoding;
    my $cp = encoding::_get_locale_encoding();    # borrowed from https://metacpan.org/pod/open
    $enc = $cp =~ /^utf-8/ ? 'UTF-8' : $cp;

    $| = 1;                                       # is this irrelevant?
    binmode \*STDIN  => ":encoding($enc)";
    binmode \*STDOUT => ":encoding($enc)";
    binmode \*STDERR => ":encoding($enc)";

    $SIG{__WARN__} = \&_redecode;
    $SIG{__DIE__}  = sub { die _redecode(@_) };
    return;
}

sub _redecode {
    $_[0] =~ /^(.+) at (.+) line (\d+)\.$/;
    my @texts = split $2, $_[0];
    return is_utf8($1)
        ? $texts[0] || '' . decode_utf8($2) . $texts[1] || ''
        : decode_utf8 $_[0];
}

1;

__END__

=encoding utf-8

=head1 NAME

usw - use utf8; use strict; use warnings; in one line.

=head1 SYNOPSIS

 use usw; # is just 8 bytes pragma instead of below:
 use utf8;
 use strict;
 use warnings;
 my $cp = '__YourCP__' || 'UTF-8';
 binmode \*STDIN,  ':encoding($cp)';
 binmode \*STDOUT, ':encoding($cp)';
 binmode \*STDERR, ':encoding($cp)';
  
=head1 DESCRIPTION

usw is like a shortcut pragma that works in any environment.

May be useful for those who write the above code every single time.

=head2 HOW TO USE

 use usw;

It seems a kind of pragmas but doesn't spent
L<%^H|https://metacpan.org/pod/perlpragma#Key-naming>
because overusing it is nonsense.

C<use usw;> should be just the very shortcut at beginning of your codes.

Therefore, if you want to set C<no>, you should do it the same way as before.

 no strict;
 no warnings;
 no utf8;

These still work as expected everywhere.

And writing like this doesn't work.

 no usw;

=head2 Automatically repairs bugs around file path which is encoded

It replaces C<$SIG{__WARN__}> or/and C<$SIG{__DIE__}>
to avoid the bug(This may be a strange specification)
of encoding only the file path like that:

 宣言あり at t/script/00_è­¦åãã.pl line 19.

=head2 features

Since version 0.07, you can relate automatically
C<STDIN>,C<STDOUT>,C<STDERR> with C<cp\d+>
which is detected by L<Win32> module.

Since version 0.08, you don't have to care if the environment is a Windows or not.

=head1 SEE ALSO

=over

=item L<Encode>

=item L<binmode|https://perldoc.perl.org/functions/binmode>

=item L<%SIG|https://perldoc.perl.org/variables/%25SIG>

=item L<Win32>

=back

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuki Yoshida(L<worthmine|https://github.com/worthmine>)

=cut
