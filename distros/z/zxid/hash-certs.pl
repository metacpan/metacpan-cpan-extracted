#!/usr/bin/perl
# 2.4.1998, Sampo Kellomaki <sampo@iki.fi>
#
# Generate SSLeay certificate directory hashes for the gien files.
#
# Usage: cd ca/cert; ../../hash-certs.pl *.pem

$ENV{'PATH'} .= ':/usr/local/ssl/bin';

foreach $cert (@ARGV) {
    $ext = ($cert =~ /\.pem$/i) ? 'pem' : 'der';
    $hash = `openssl x509 -inform $ext -hash -noout <$cert`;
    chomp $hash;
    unlink $hash;
    `ln -s $cert $hash.0`;
    print "$cert --> $hash.0\n";
}

__END__
