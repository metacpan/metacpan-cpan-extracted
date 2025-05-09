package Test::XML::Sig::Util;
use warnings;
use strict;

# ABSTRACT: Utils for testsuite of XML::Sig

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
    get_xmlsec_features
    get_openssl_features
    get_tmp_file
    slurp_file
    test_xmlsec1_ok
 );

our @EXPORT_OK;

our %EXPORT_TAGS = (
    all => [@EXPORT, @EXPORT_OK],
);

use File::Which;
use File::Temp;
use Crypt::OpenSSL::Guess;
require Test::More;


sub get_tmp_file {
    return File::Temp->new(DIR => 't');
}

sub slurp_file {
    my $name = shift;
    open (my $fh, '<', $name) or die "Unable to open $name";
    local $/ = undef;
    return <$fh>;
}

sub test_xmlsec1_ok {
    my $test = shift;
    my $contents = shift;

    my $fh = get_tmp_file;
    print $fh $contents;
    close $fh;

    my $xml_sec_args = join(" ", @_);

    my $filename = $fh->filename;

    my $response = `xmlsec1 $xml_sec_args $filename 2>&1`;
    my $ok = Test::More::like($response, qr/OK/, $test);

    if (!$ok) {
        Test::More::diag("calling xmlsec1 $xml_sec_args $filename failed");
        Test::More::diag($contents);
        Test::More::BAIL_OUT($test);
    }
}

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

    my $transforms = `xmlsec1 --list-transforms`;
    my $sha1_support = 0;
    $sha1_support = 1 if ($transforms =~ /\bsha1\b/mg);

    my %xmlsec = (
                    installed   => 1,
                    major       => $major,
                    minor       => $minor,
                    patch       => $patch,
                    version     => $ver,
                    ripemd160   => ($major >= 1 and $minor >= 3 and $patch < 7) ? 1 : 0,
                    aes_gcm     => ($major <= 1 and $minor <= 2 and $patch <= 27) ? 0 : 1,
                    lax_key_search => ($major >= 1 and $minor >= 3) ? 1 : 0,
                    sha1_support => $sha1_support,
                    dsakeyvalue => 0,
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

    use Test::XML::Sig;

    my $features = get_xmlsec_features();
    my $features = get_openssl_features();
    # go from here
