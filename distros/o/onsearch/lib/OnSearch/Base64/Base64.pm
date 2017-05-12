package OnSearch::Base64;

use 5.006;
use strict;
use warnings;
use Errno;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(&encode_base64 &decode_base64);

our @EXPORT = qw();
our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined OnSearch::Base64 macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap OnSearch::Base64 $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

OnSearch::Base64 - Base64 encoding and decoding library.

=head1 SYNOPSIS

  use OnSearch::Base64;
  my $base64_str = encode_base64 ($str);
  my $str = decode_base64 ($str);

=head1 DESCRIPTION

OnSearch::Base64 provides Base64 encoding and decoding functions.

=head1 EXPORT

=head2 encode_base64 (I<str>)

Encode a string using Base 64 encoding.
=======
OnSearch::Base64 provides Base64 encoding and decoding functions.

=head1 EXPORT

=head2 encode_base64 (I<str>)

Encode a string using Base 64 encoding.

=head2 decode_base64 (I<base64_str>)

Decode a Base 64 string.

=head1 VERSION AND COPYRIGHT


=head1 VERSION AND COPYRIGHT

$Id: Base64.pm,v 1.5 2005/07/24 08:04:24 kiesling Exp $

Written by Robert Kiesling <rkies@cpan.org> and licensed under the
same terms as Perl.  Refer to the file, "Artistic," for information.

The encoding and decoding algorithms are derived from, F<encdec.c,>
which was posted to the comp.mail.mime news group.

=head1 SEE ALSO

L<OnSearch(3)>

=cut
