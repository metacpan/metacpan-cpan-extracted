#!perl

use v5.10;
use Test::More;
use Data::Dumper;

use CPAN::DistnameInfo;
use URI::PackageURL;

while (my $file = <DATA>) {

    chomp $file;

    my $d = CPAN::DistnameInfo->new($file);

    next unless $d->cpanid;
    next unless $d->dist;

    subtest "$file" => sub {

        my $qualifiers = {};

        # "tar.gz" is the default extension for CPAN distributions
        if ($d->extension ne 'tar.gz') {
            $qualifiers->{ext} = $d->extension;
        }

        my $purl = URI::PackageURL->new(
            type       => 'cpan',
            namespace  => $d->cpanid,
            name       => $d->dist,
            version    => $d->version,
            qualifiers => $qualifiers
        );

        ok($purl, "Conversion: $file --> $purl");

        my $purl2 = URI::PackageURL->from_string($purl->to_string);

        is($d->cpanid,  $purl2->namespace, 'dist(cpanid)  == purl(namespace)');
        is($d->dist,    $purl2->name,      'dist(dist)    == purl(name)');
        is($d->version, $purl2->version,   'dist(version) == purl(version)');

    };

}

done_testing();

__DATA__
CPAN/authors/id/J/JA/JAMCC/ngb-101.zip
CPAN/authors/id/J/JS/JSHY/DateTime-Fiscal-Year-0.01.tar.gz
CPAN/authors/id/G/GA/GARY/Math-BigInteger-1.0.tar.gz
CPAN/authors/id/T/TE/TERRY/VoiceXML-Server-1.6.tar.gz
CPAN/authors/id/J/JA/JAMCC/ngb-100.tar.gz
CPAN/authors/id/J/JS/JSHY/DateTime-Fiscal-Year-0.02.tar.gz
CPAN/authors/id/G/GA/GARY/Crypt-DES-1.0.tar.gz
CPAN/authors/id/G/GA/GARY/Stream-1.00.tar.gz
CPAN/authors/id/T/TM/TMAEK/DBIx-Cursor-0.14.tar.gz
CPAN/authors/id/G/GA/GARY/Crypt-IDEA-1.0.tar.gz
CPAN/authors/id/G/GA/GARY/Math-TrulyRandom-1.0.tar.gz
CPAN/authors/id/T/TE/TERRY/VoiceXML-Server-1.13.tar.gz
JWILLIAMS/MasonX-Lexer-MSP-0.02.tar.gz
CPAN/authors/id/J/JA/JAMCC/Tie-CacheHash-0.50.tar.gz
CPAN/authors/id/T/TM/TMAEK/DBIx-Cursor-0.13.tar.gz
CPAN/authors/id/J/JD/JDUTTON/Parse-RandGen-0.100.tar.gz
id/N/NI/NI-S/Tk400.202.tar.gz
authors/id/G/GB/GBARR/perl5.005_03.tar.gz
M/MS/MSCHWERN/Test-Simple-0.48_01.tar.gz
id/J/JV/JV/PostScript-Font-1.09.tar.gz
id/I/IB/IBMTORDB2/DBD-DB2-0.77.tar.gz
id/I/IB/IBMTORDB2/DBD-DB2-0.99.tar.bz2
CPAN/authors/id/L/LD/LDS/CGI.pm-2.34.tar.gz
CPAN/authors/id/J/JE/JESSE/perl-5.12.0-RC0.tar.gz
CPAN/authors/id/G/GS/GSAR/perl-5.6.1-TRIAL3.tar.gz
CPAN/authors/id/R/RJ/RJBS/Dist-Zilla-2.100860-TRIAL.tar.gz
CPAN/authors/id/M/MI/MINGYILIU/Bio-ASN1-EntrezGene-1.10-withoutworldwriteables.tar.gz
CPAN/authors/id/I/IL/ILYAZ/modules/Term-Gnuplot-0.90380906.zip
CPAN/authors/id/S/SA/SANDEEPV/GuiBuilder_v0_3.zip
CPAN/authors/id/I/IL/ILYAZ/modules/Term-Gnuplot-0.90380906.zip
BDFOY/authors/id/B/BD/BDFOY/Mojolicious-Plugin-DirectoryServer-1.003.tar
KMACLEOD/Frontier-RPC-0.07b4.tar.gz
RTFIREFLY/Frontier-RPC-0.07b4p1.tar.gz
AJPEACOCK/HTML-Table-2.08a.tar.gz
DANPEDER/MIME-Base32-1.02a.tar.gz
CPAN/authors/id/G/GD/GDT/URI-PackageURL-2.20.tar.gz
