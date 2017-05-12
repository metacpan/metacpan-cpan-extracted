package Xmms::Remote;

use 5.005;
use strict;
use DynaLoader ();

{
    no strict;
    @ISA = qw(DynaLoader);
    $VERSION = '0.03';
    __PACKAGE__->bootstrap($VERSION);
}

sub all_win_toggle {
    my($remote, $show) = @_;
    for (qw(main pl eq)) {
        my $meth = "${_}_win_toggle";
        my $is = "is_${_}_win";
        next if $remote->$is() == $show;
        $remote->$meth($show);
    }
}

1;
__END__

=head1 NAME

Xmms::Remote - Perl Interface to xmms_remote API

=head1 SYNOPSIS

  use Xmms::Remote ();
  my $remote = Xmms::Remote->new;
  $remote->play;

=head1 DESCRIPTION

This module provides a Perl interface to the xmms remote control interface.
No docs yet, sorry, see test.pl and Xmms.pm for now

=head1 SEE ALSO

xmms(1), Xmms(3), MPEG::MP3Info(3)

=head1 AUTHOR

Doug MacEachern

=cut
