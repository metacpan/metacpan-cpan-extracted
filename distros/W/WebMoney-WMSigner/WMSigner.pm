package WebMoney::WMSigner;

use strict;

require Exporter;
require DynaLoader;

use vars qw( @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION );

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WMSigner ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.02';

bootstrap WebMoney::WMSigner $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

WebMoney::WMSigner - WebMoney signer module

=head1 SYNOPSIS

  use WebMoney::WMSigner;

  my $signed_str = WebMoney::WMSigner::sign( $wmid, $passwd, $path_to_keyfile, $str_to_sign );

=head1 DESCRIPTION

This is signer module that signs any data using specified WebMoney key file.
Key file is protected by password.
See more details at http://www.webmoney.ru.

In the original WMSigner distribution
(http://download.webmoney.ru/WMSigner.zip)
signer is implemented as an external command-line utility - this is not
very convenient interface.
This module implements native Perl interface without using any external
command-line utilities. WMSigner code is compiled as XS module - this
makes many advantages.

=head1 EXPORT

None by default.

=head1 AUTHOR

Walery Studennikov, <despair@cpan.org>
Based on code of WMSigner utility by WebMoney <unix_support@webmoney.ru>

=head1 SEE ALSO

http://www.webmoney.ru

=cut
