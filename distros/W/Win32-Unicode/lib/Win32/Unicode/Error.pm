package Win32::Unicode::Error;

use strict;
use warnings;
use 5.008003;
use Exporter 'import';

our $VERSION = '0.38';

use Win32::Unicode::Constant;
use Win32::Unicode::Util;
use Win32::Unicode::XS;

# export subs
our @EXPORT    = qw/errorW/;
our @EXPORT_OK = qw/error/;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

sub errorW {
    my $buff = foramt_message();
    $buff = utf16_to_utf8($buff);
    $buff =~ s/\r\n$//;
    return $buff;
}

my $ERROR_TABLE;
sub _set_errno {
    my $errno = $_[0] ? set_last_error($_[0]) : get_last_error();
    unless ($ERROR_TABLE) {
        require Errno;
        $ERROR_TABLE = {
            ERROR_FILE_EXISTS, => Errno::EEXIST(),
        };
    }
    $! = $ERROR_TABLE->{$errno} || $errno;
    return;
}

*error = *errorW;

1;
__END__
=head1 NAME

Win32::Unicode::Error - return error message.


=head1 SYNOPSIS

  use Win32::Unicode;

  mkdirW($exists_dir) or dieW errorW

=head1 DESCRIPTION

Wn32::Unicode::Error is return to Win32API error message.

=head1 FUNCTIONS

=over

=item B<errorW()>

get last error message.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@gmail.comE<gt>

=head1 SEE ALSO

L<Win32::Unicode>

L<Win32::Unicode::Dir>

L<Win32::Unicode::File>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
