package Xmms::Config;

use 5.005;
use strict;
use DynaLoader ();

{
    no strict;
    @ISA = qw(DynaLoader);
    $VERSION = '0.01';
    __PACKAGE__->bootstrap($VERSION);
}

1;
__END__

=head1 NAME

Xmms::Config - Perl Interface to xmms_cfg API

=head1 SYNOPSIS

 my $file = Xmms::Config->file; #$ENV{HOME}/.xmms/config
 my $cfg = Xmms::Config->new($file);

=head1 DESCRIPTION

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO

xmms(1), Xmms::Remote(3)

=cut
