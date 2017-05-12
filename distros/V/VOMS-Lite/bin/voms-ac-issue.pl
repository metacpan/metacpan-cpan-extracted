#!/usr/bin/perl

use VOMS::Lite qw(Issue);
use VOMS::Lite::PEMHelper qw(writeAC readCert readPrivateKey);
use VOMS::Lite::CertKeyHelper qw(buildchain);

my $name=$0;
$name =~ s#.*/##g;
my $usage = "Usage: $name -attrib /VO[/subgroups]*[/role][/capability]\n".
" " x (length($name)+8). "-holder /path/to/cert.pem\n".
" " x (length($name)+8). "-issuer /path/to/issuing/cert.pem\n".
" " x (length($name)+8). "-issuerkey /path/to/issuing/cert's/key.pem\n".
" " x (length($name)+8). "-cadir /path/to/dir/of/hashed-CAs or -cafile /path/to/a/CA.pem ...\n".
" " x (length($name)+6). "[ -out /path/to/save/AC ]\n".
" " x (length($name)+6). "[ -server FQDN ]\n".
" " x (length($name)+6). "[ -lifetime N (hours, default 12 hours) ]\n".
" " x (length($name)+6). "[ -target URI ]...\n";

my ($holder,$cert,$issuer,$key);
my $lifetime=(12*3600);
my $outfile="/tmp/vomsAC_u$<";
my $server=(eval "require Sys::Hostname;") ? Sys::Hostname::hostname : "localhost.localdomain";
my @Attribs;
my @CAdirs;
my @CAfiles;
my @targets;
while ($_=shift @ARGV) {
  if    ( /^--?holder$/ ) {
    $holder=shift @ARGV;
    die "$& requires an argument" if ( ! defined $holder );
    die "cannot open certificate file $holder" if ( ! -r $holder );
  }
  elsif    ( /^--?out$/ ) {
    $outfile=shift @ARGV;
    die "$& requires an argument" if ( ! defined $outfile );
  }
  elsif ( /^--?(?:ca|CA)(?:path|dir)$/ ) {
    my $dir=shift @ARGV;
    die "$& requires an argument" if ( ! defined $dir );
    die "$dir is not a directory" if ( ! -d $dir );
    push @CAdirs, $dir;
  }
  elsif ( /^--?(?:ca|CA)file$/ ) {
    my $file=shift @ARGV;
    die "$& requires an argument" if ( ! defined $file );
    die "cannot open $file" if ( ! -r $file );
    push @CAfiles, $file;
  }
  elsif ( /^--?attrib$/ ) {
    my $attrib=shift @ARGV;
    die "$& requires an argument" if ( ! defined $attrib );
    if ( $attrib =~ m#^(/[^/]+(?:/[^/]+)*?(?:/Role=[^/]+)?(?:/Capability=[^/]+)?)$# ) { push @Attribs,$1; }
    else { die "Invalid Attribute $attrib"; }
  }
  elsif ( /^--?issuer$/ ) {
    $issuer=shift @ARGV;
    die "$& requires an argument" if ( ! defined $issuer );
    die "cannot open issuer certificate file $issuer" if ( ! -r $issuer );
  }
  elsif ( /^--?issuerkey$/ ) {
    $key=shift @ARGV;
    die "$& requires an argument" if ( ! defined $key );
    die "cannot open issuer certificate file $key" if ( ! -r $key );
  }
  elsif ( /^--?server$/ ) {
    $server = shift @ARGV;
    die "$& requires an argument" if ( ! defined $server );
  }
  elsif ( /^--?target$/ ) {
    my $target=shift @ARGV;
    die "$& requires an argument" if ( ! defined $target );
    push @targets,$target;
  }
  elsif ( /^--?lifetime$/ ) {
    my $lifetime=shift @ARGV;
    die "$& requires an argument" if ( ! defined $lifetime );
    if ( $lifetime =~ /^[0-9]+$/ ) { $lifetime=($1*3600); }
    else { die "$& requires a positive numeric integer argument."; }
  } 
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

die "need to specify a holder\n$usage"    if  ( ! defined $holder );
die "need to specify an issuer\n$usage"   if  ( ! defined $issuer );
die "need to specify a issuerkey\n$usage" if  ( ! defined $key );
die "No trust root specified, this is required, use -CAdir or -CAfile" if (@CAdirs == 0 && @CAfiles == 0);

my @certs=readCert($holder);
my @CAcerts=();
foreach (@CAfiles) { print "$_\n"; push @CAcerts, VOMS::Lite::PEMHelper::readCert($_); }

my %Chain = %{ buildchain( { trustedCAdirs => \@CAdirs, suppliedcerts => \@certs, trustedCAs => \@CAcerts } ) };
my $vomscert=readCert($issuer);
my $vomskey=readPrivateKey($key);

# Get AC
my $acref = VOMS::Lite::AC::Create( { Cert     =>  $Chain{EndEntityCert},
                                      VOMSCert => $vomscert,
                                      VOMSKey  => $vomskey,
                                      Lifetime => $lifetime,
                                      Server   => $server,
                                      Port     => $$,       #
                                      Serial   => time(),   #Reasonably different
                                      Code     => $$,       #
                                      Attribs  => \@Attribs,
                                      Broken   => 1 } );
my %hash=%$acref;
foreach my $hash (keys %hash) {
  if ( ref($hash{$hash}) eq "ARRAY" ) {
    my $arrayref=$hash{$hash};
    my @array=@$arrayref;
    my $tmp=$hash;
    foreach (@array) { printf "%-15s %s\n", "$tmp:","$_"; $tmp=""; }
  }
}

writeAC($outfile,$$acref{AC});

__END__

=head1 NAME

  voms-ac-issue.pl

=head1 SYNOPSIS

  A simple script to create VOMS attribute certificates using the VOMS::Lite library.

  Usage: voms-ac-issue.pl -attrib /VO[/subgroups]*[/role][/capability]
                          -holder /path/to/cert.pem
                          -issuer /path/to/issuing/cert.pem
                          -issuerkey /path/to/issuing/cert's/key.pem
                          -cadir /path/to/dir/of/hashed-CAs or -cafile /path/to/a/CA.pem ...
                        [ -out /path/to/save/AC ]
                        [ -server FQDN ]
                        [ -lifetime N (hours, default 12 hours) ]
                        [ -target URI ]...



=head1 DESCRIPTION

  Need I say more?

=head1 SEE ALSO

VOMS::Lite

This script was originally designed for SHEBANGS, a JISC funded project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/
 now http://www.rcs.manchester.ac.uk/projects/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

