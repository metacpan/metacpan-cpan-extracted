=head1 NAME

Wx::DialUpManager -  perl extension for wxDialUpManager

=head1 SYNOPSIS

    use Wx::DialUpManager qw[ EVT_DIALUP_CONNECTED EVT_DIALUP_DISCONNECTED ];
    EVT_DIALUP_CONNECTED( sub {warn "you're connected"});
    EVT_DIALUP_CONNECTED( sub {warn "you're dis-connected"});
    ...

=head1 DESCRIPTION

This is an example of writing an extension for wxPerl
(a more complete sample than Wx::Sample::XS).

If you want to use this module,
please refer to the wxWindows documentation for wxDialUpManager.

=head1 BUGS

Please don't report bugs ;)
But if you really really need to, go to 
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wx-DialUpManagerE<gt>
or send mail to E<lt>bug-Wx-DialUpManager#rt.cpan.orgE<gt>


=head1 AUTHOR

D. H. (PODMASTER)

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module distribution.


=head1 SEE ALSO

L<Wx|Wx>,
L<Wx::GLCanvas|Wx::GLCanvas>,
L<Wx::ActiveX|Wx::ActiveX>,
L<Wx::Sample::XS|Wx::Sample::XS>,
L<Wx::Metafile|Wx::Metafile>

=cut


package Wx::DialUpManager;
use strict;
use Wx();
use Exporter();
use base qw( Exporter Wx::EvtHandler );
use vars qw[ $VERSION @EXPORT_OK %EXPORT_TAGS ];
$VERSION = '0.03',
@EXPORT_OK = qw[ EVT_DIALUP_CONNECTED EVT_DIALUP_DISCONNECTED ];


$EXPORT_TAGS{'everything'} = \@EXPORT_OK;
$EXPORT_TAGS{'all'}        = \@EXPORT_OK;

Wx::wx_boot( 'Wx::DialUpManager', $VERSION );

# https://sourceforge.net/mailarchive/message.php?msg_id=4242508
sub EVT_DIALUP_CONNECTED($) {
    Wx::wxTheApp()->Connect( -1, -1, &Wx::wxEVT_DIALUP_CONNECTED, $_[0] );
}


sub EVT_DIALUP_DISCONNECTED($) {
    Wx::wxTheApp()->Connect( -1, -1, &Wx::wxEVT_DIALUP_CONNECTED, $_[0] )
}


package Wx::DialUpEvent;
use vars '@ISA';
@ISA = qw(Wx::Event);

1;
