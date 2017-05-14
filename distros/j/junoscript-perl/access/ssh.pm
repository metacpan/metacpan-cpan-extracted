#
# $Id: ssh.pm,v 1.7 2003/02/03 16:45:45 rjohnst Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

@acmethod_ssh_classes = qw(
    libz.a
    Compress::Zlib
    Digest::HMAC_MD5
    Digest::HMAC_SHA1
    pari
    Math::Pari
    Crypt::Random
    Class::Loader
    Crypt::DSA
    String::CRC32
    gmp
    Math::GMP
    Convert::ASN1
    Convert::PEM
    Crypt::DH
    Crypt::DES
    Digest::SHA1
    Convert::ASCII::Armour
    Crypt::CBC
    Tie::EncryptedHash
    Crypt::Blowfish
    Sort::Versions
    Data::Buffer
    Crypt::Primes
    MD5
    Crypt::RSA
    Digest::BubbleBabble
    Crypt::DES_EDE3
);

# Net::SSH installation is interactive, should be installed by hand
@acmethod_ssh_classes_excp = qw(
    Net::SSH::Perl
);

@ssh_c_modules = qw(
    gmp
    pari
);

%ssh_prereqs = (
    	    'libz.a' => "1.1.4",
    	    Class::Loader => "2.02",
    	    Compress::Zlib => "1.19",
    	    Convert::ASCII::Armour => "1.4",
            Convert::ASN1 => "0.16",
	    Convert::PEM => "0.06",
    	    Crypt::Blowfish => "2.09",
	    Crypt::CBC => "2.08",
    	    Crypt::DES => "2.03",
    	    Crypt::DES_EDE3 => "0.0.1",
	    Crypt::DH => "0.03",
	    Crypt::DSA => "0.12",
	    Crypt::Primes => "0.49",
	    Crypt::Random => "1.11",
	    Crypt::RSA => "1.48",
    	    Data::Buffer => "0.04",
    	    Digest::BubbleBabble => "0.01",
	    Digest::HMAC_MD5 => "1.01",
	    Digest::HMAC_SHA1 => "1.01",
	    Digest::SHA1 => "2.01",
	    Math::GMP => "2.03",
	    Math::Pari => "2.010305",
       	    MD5 => "2.02",
	    Net::SSH::Perl => "1.23-JUNOS",
     	    Sort::Versions => "1.4",
	    String::CRC32 => "1.2",
    	    Tie::EncryptedHash => "1.21",
	    pari => "2.1.4",
      gmp => "4.1.1",
);

%ssh_estimates = (
    	    'libz.a' => "00:00:00",
    	    Class::Loader => "00:00:04",
    	    Compress::Zlib => "00:00:08",
    	    Convert::ASCII::Armour => "00:00:03",
            Convert::ASN1 => "00:00:05",
	    Convert::PEM => "00:00:05",
    	    Crypt::Blowfish => "00:00:07",
	    Crypt::CBC => "00:00:04",
    	    Crypt::DES => "00:00:04",
    	    Crypt::DES_EDE3 => "00:00:04",
	    Crypt::DH => "00:00:03",
	    Crypt::DSA => "00:00:30",
	    Crypt::Primes => "00:01:46",
	    Crypt::Random => "00:00:09",
	    Crypt::RSA => "00:02:41",
    	    Data::Buffer => "00:00:03",
    	    Digest::BubbleBabble => "00:00:03",
	    Digest::HMAC_MD5 => "00:00:03",
	    Digest::HMAC_SHA1 => "00:00:03",
	    Digest::SHA1 => "00:00:04",
	    Math::GMP => "00:00:13",
	    Math::Pari => "00:01:45",
 	    MD5 => "00:00:03",
	    Net::SSH::Perl => "00:00:20",
     	    Sort::Versions => "00:00:02",
	    String::CRC32 => "00:00:04",
    	    Tie::EncryptedHash => "00:00:08",
	    pari => "00:02:32",
      gmp => "00:00:45",
);

%ssh_tarballs = (
    	    'libz.a' => "zlib-1.1.4.tar.gz",
    	    Class::Loader => "Class-Loader-2.02.tar.gz",
    	    Compress::Zlib => "Compress-Zlib-1.19.tar.gz",
    	    Convert::ASCII::Armour => "Convert-ASCII-Armour-1.4.tar.gz",
            Convert::ASN1 => "Convert-ASN1-0.16.tar.gz",
	    Convert::PEM => "Convert-PEM-0.06.tar.gz",
    	    Crypt::Blowfish => "Crypt-Blowfish-2.09.tar.gz",
    	    Crypt::CBC => "Crypt-CBC-2.08.tar.gz",
    	    Crypt::DES => "Crypt-DES-2.03.tar.gz",
    	    Crypt::DES_EDE3 => "Crypt-DES_EDE3-0.01.tar.gz",
	    Crypt::DH => "Crypt-DH-0.03.tar.gz",
	    Crypt::DSA => "Crypt-DSA-0.12.tar.gz",
	    Crypt::Primes => "Crypt-Primes-0.49.tar.gz",
	    Crypt::Random => "Crypt-Random-1.11.tar.gz",
	    Crypt::RSA => "Crypt-RSA-1.48.tar.gz",
    	    Data::Buffer => "Data-Buffer-0.04.tar.gz",
    	    Digest::BubbleBabble => "Digest-BubbleBabble-0.01.tar.gz",
	    Digest::HMAC_MD5 => "Digest-HMAC-1.01.tar.gz",
	    Digest::HMAC_SHA1 => "Digest-HMAC-1.01.tar.gz",
	    Digest::SHA1 => "Digest-SHA1-2.01.tar.gz",
	    Math::GMP => "Math-GMP-2.03.tar.gz",
	    Math::Pari => "Math-Pari-2.010305.tar.gz",
	    MD5 => "MD5-2.02.tar.gz",
	    Net::SSH::Perl => "Net-SSH-Perl-1.23-JUNOS.tar.gz",
     	    Sort::Versions => "Sort-Versions-1.4.tar.gz",
	    String::CRC32 => "String-CRC32-1.2.tar.gz",
    	    Tie::EncryptedHash => "Tie-EncryptedHash-1.21.tar.gz",
	    pari => "pari-2.1.4.tar.gz",
      gmp => "gmp-4.1.1.tar.gz",
);

%ssh_authors = (
	    'libz.a' => 'Jean-loup Gailly (jloup@gzip.org)',
	    Class::Loader => 'Vipul Ved Prakash (mail@vipul.net)',
    	    Compress::Zlib => 'Paul Marquess (Paul.Marquess@btinternet.com)',
    	    Convert::ASCII::Armour => 'Vipul Ved Prakash (mail@vipul.net)',
            Convert::ASN1 => 'Graham Barr (gbarr@pobox.com)',
	    Convert::PEM => 'Benjamin Trott (ben@rhumba.pair.com)',
    	    Crypt::Blowfish => 'Dave Paris (amused@pobox.com)',
    	    Crypt::CBC => 'Lincoln D. Stein (lstein@cshl.org)',
    	    Crypt::DES => 'Dave Paris (amused@pobox.com)',
    	    Crypt::DES_EDE3 => 'Benjamin Trott (ben@rhumba.pair.com)',
	    Crypt::DH => 'Benjamin Trott (ben@rhumba.pair.com)',
	    Crypt::DSA => 'Benjamin Trott (ben@rhumba.pair.com)',
	    Crypt::Primes => 'Vipul Ved Prakash (mail@vipul.net)',
	    Crypt::Random => 'Vipul Ved Prakash (mail@vipul.net)',
	    Crypt::RSA => 'Vipul Ved Prakash (mail@vipul.net)',
    	    Data::Buffer => 'Benjamin Trott (ben@rhumba.pair.com)',
    	    Digest::BubbleBabble => 'Benjamin Trott (ben@rhumba.pair.com)',
	    Digest::HMAC_MD5 => 'Gisle Aas (gisle@ActiveState.com)',
	    Digest::HMAC_SHA1 => 'Gisle Aas (gisle@ActiveState.com)',
	    Digest::SHA1 => 'Gisle Aas (gisle@ActiveState.com)',
	    Math::GMP => 'Chip Turner (cturner@redhat.com)',
	    Math::Pari => 'Ilya Zakharevich (ilya@math.ohio-state.edu)',
	    MD5 => 'Gisle Aas (gisle@ActiveState.com)',
	    Net::SSH::Perl => 'Benjamin Trott (ben@rhumba.pair.com)',
     	    Sort::Versions => 'Kenneth Albanowski (kjahds@kjahds.com)',
	    String::CRC32 => 'Soenke J. Peters (peters+perl@opcenter.de)',
    	    Tie::EncryptedHash => 'Vipul Ved Prakash (mail@vipul.net)',
	    pari => 'PARI Development (pari-dev@list.cr.yp.to)',
      gmp => 'GNU Project (bug-gmp@gnu.org)',
);

%ssh_modifiers = (
            Math::Pari => "install::modify_Math_Pari",
);

%ssh_class_searchers = (
	    pari => "install::pari_exists",
);

sub modify_Math_Pari
{
    my ($kernel, $prefix, $install_directory) = @_;
    print "**** Patching Math-Path/libPARI/Makefile\n";
    return 1 if ($kernel ne 'FreeBSD');
    modify_file("$prefix/libPARI/Makefile", '^INC = ', 'INC = -I$(PARI_DIR)/Ofreebsd-ix86 ');
    modify_file("$prefix/libPARI/Makefile", '^OPTIMIZE = ', 'OPTIMIZE = -O ');
    modify_file("$prefix/Makefile", '^OPTIMIZE = ', 'OPTIMIZE = -O ');
}

sub pari_exists
{
    my ($binary, $install_directory) = @_;

    # Check whether Math::Pari exists.  If it does, don't
    # bother to install pari.
    my $targetlib = 'Math::Pari'; 
    my $targetvers = get_version($targetlib);
    return 1 if (class_exists($targetlib, $targetvers));

    return 0;
}

sub ssh_add_install_flags
{
    my ($install_directory) = @_;
    # Set the install_flags anyway, just incase -force_override is turned on
    set_install_flags('pari', 
        $install_directory?"./Configure --prefix=$install_directory/..":"./Configure");
    set_install_flags('libz.a', 
        $install_directory?"./configure --prefix=$install_directory/..":"./configure");
    set_install_flags('gmp', 
        $install_directory?"./configure --prefix=$install_directory/..":"./configure");
}

add_access_method(
    name => 'ssh',
    c_modules => \@ssh_c_modules,
    prereqs => \%ssh_prereqs,
    estimates => \%ssh_estimates,
    tarballs => \%ssh_tarballs,
    authors => \%ssh_authors,
    class_searchers => \%ssh_class_searchers,
    modifiers => \%ssh_modifiers,
);

1;
