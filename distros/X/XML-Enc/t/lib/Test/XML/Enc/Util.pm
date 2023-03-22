package Test::XML::Enc::Util;
use warnings;
use strict;

# ABSTRACT: Utils for testsuite of XML::Enc

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
    get_xmlsec_features
    get_openssl_features
 );

our @EXPORT_OK;

our %EXPORT_TAGS = (
    all => [@EXPORT, @EXPORT_OK],
);

use File::Which;
use Crypt::OpenSSL::Guess;

#########################################################################
# get_xmlsec_features
#
# Parameter:    none
#
# Returns a hash of the major, minor and letter version of xmlsec
# it also sets features to true or false depending if it is supported
# in the version that is installed
#
# Response: hash
#
#       %features = (
#                   installed   => 1,
#                   major       => '1',
#                   minor       => '3',
#                   patch       => '0',
#                   ripemd160   => 0,
#       );
##########################################################################
sub get_xmlsec_features {
    return unless which('xmlsec1');

    my ($cmd, $ver, $engine) = split / /, (`xmlsec1 --version`);
    my ($major, $minor, $patch) = split /\./, $ver;

    my %xmlsec = (
                    installed   => 1,
                    major       => $major,
                    minor       => $minor,
                    patch       => $patch,
                    ripemd160   => ($major >= 1 and $minor >= 3) ? 1 : 0,
                    aes_gcm     => ($major >= 1 and $minor >= 2 and $patch >= 27) ? 1 : 0,
                    lax_key_search => ($major >= 1 and $minor >= 3) ? 1 : 0,
                );
    return \%xmlsec;
}

#########################################################################
# get_openssl_features
#
# Parameter:    none
#
# Returns a hash of the major, minor and letter version of openssl
# it also sets features to true or false depending if it is supported
# in the version that is installed
#
# Response: hash
#
#       %features = (
#                   major       => '3.0',
#                   minor       => '0',
#                   letter      => '',
#                   ripemd160   => 0,
#       );
##########################################################################
sub get_openssl_features {
    my ($major, $minor, $letter) = Crypt::OpenSSL::Guess->openssl_version();

    my %openssl = (
                    major       => $major,
                    minor       => $minor,
                    letter      => (defined $letter) ? $letter : '',
                    ripemd160   => ($major eq '3.0' and ($minor >= 0) and ($minor <= 7)) ? 0 : 1,
                );
    return \%openssl;
}

1;

__END__

=head1 DESCRIPTION

=head1 SYNOPSIS

    use Test::XML::Enc;

    my $features = get_xmlsec_features();
    my $features = get_openssl_features();
    # go from here
