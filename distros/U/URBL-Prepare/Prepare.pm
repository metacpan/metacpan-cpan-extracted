
package URBL::Prepare;

use strict;
#use diagnostics;
use AutoLoader 'AUTOLOAD';
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.09 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub loadcache;
sub Destroy {};

=head1 NAME

URPL::Prepare -- prepare hostname for URBL domain lookup

=head1 SYNOPSIS

  require URBL::Prepare;

  my $ubp = new URBL::Prepare;

  $tlds = $blessed->cachetlds($localfilelistptr);
  $whitelist = $blessed->cachewhite($localfilelistptr);
  $domain = $blessed->urbldomain($hostname);
  $response_code = $proto->loadcache($url,$localfile);
  ($response,$message) = $proto->loadcache($url,$localfile);
  $rv = $blessed->urblblack($hostname);
  $rv = $blessed->urblwhite($hostname);

=head1 DESCRIPTION

=over 2

=item * my $urbl = new URBL::Prepare;

This method returns a blessed reference to an empty hash.

For use with other modules:

  require URBL::Prepare;

  @ISA = qw(URBL::Prepare);

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto || __PACKAGE__;
  bless {}, $class;
}

=head1 URBL Preparation for lookup methods

The following three methods are for facilitating URBL lookups.

  SEE:	http://www.uribl.com/about.shtml
  and	http://www.surbl.org/guidelines

=over 2

=item * $tldlist = $blessed->cachetlds($localfilelistptr);

This method opens local files in "file list" and extracts the tld's found
therein.

  input: 	ptr to array of local/file/path/names
  return:	array ptr to list of tld's

NOTE: place level 3 tld's ahead of level 2 tld's

=cut

# do level3 tld's first
sub cachetlds {
  my($bls,$files) = @_;
  my @tldlist;
  foreach my $infile (@$files) {
    my $tldf;
    next unless open $tldf, $infile;
    foreach (<$tldf>) {
      chomp;
      next unless $_ =~ /\S/;
      $_ =~ s/\./\\./g;
      push @tldlist, lc $_;
    }
  }
  $bls->{-urblpreparebad} = \@tldlist;
}

=item * $whitelist = $blessed->cachewhite($localfilelistptr);

This method opens local file(s) in "file list" and extracts the domains
found therein. 

  See http://wiki.apache.org/spamassassin/DnsBlocklists		and
  http://spamassasin.googlecode.com/svn-history/r6/trunk/share/spamassassin/

Note:: these URL's may change

  input:	ptr to array of local/file/path/names
  return:	array ptr to whitelist domain names

=cut

sub cachewhite {
  my($bls,$files) = @_;
  my @whitelist;
  foreach my $infile (@$files) {
    my $wfile;
    next unless open $wfile, $infile;
    foreach(<$wfile>) {
      next unless $_ =~ /uridnsbl_skip_domain\s+(.+)/;
      (my $white = $1) =~ s/\./\\./g;
      chomp $white;
      my @wtmp = split /\s+/, lc $white;
      push @whitelist, @wtmp;
    }
  }
  $bls->{-urblpreparewhite} = \@whitelist;
}

=item * $blacklist = $blessed->cacheblack($localfilelistptr);

This method opens local file(s) in "file list" and extracts the domains found
therein. The domains may be space seperated many to a line.

  input:	ptr to array of local/file/path/names
  return:	ptr to blacklist domain names

=cut

sub cacheblack {
  my($bls,$files) = @_;
  my @blacklist;
  foreach my $infile (@$files) {
    my $bkfile;
    next unless open $bkfile, $infile;
    foreach(<$bkfile>) {
      chomp;
      (my $black = $_) =~ s/\./\\./g;
      my @btmp = split /\s+/, lc $black;
      push @blacklist, @btmp;
    }
  }
  $bls->{-urblprepareblack} = \@blacklist;
}

=item * $domain = $blessed->urbldomain($hostname)

This method extracts a domain name to check against an SURBL. If the
hostname is whitelisted, the return value is false, otherwise a domain name
is returned.

  input:	hostname
  return:	false if whitelisted
	else	domain to check against SURBL

NOTE: optionally white or tld testing will be bypassed if the pointer 
is undefined or points to an empty array.

=cut

# Implementation Guidelines
#
# http://www.surbl.org/guidelines
#
# Extract base (registered) domains from those URIs. This includes removing
# all leading host names, subdomains, www., randomized subdomains, etc. In
# order to determine the level of domain to check, use our tables of two level
# and three level TLDs. Originally these were CCTLDs, but they now also
# include some frequently abused hosting domains. (Note that these files only
# rarely update. Please don't retrieve them more often than once per day.) The
# usage is:
#
#    For any domain on the three level list, check it at the fourth level.
#    For any domain on the two level list, check it at the third level.
#    For any other domain, check it at the second level.
#
# For example, any domain found in the two level list should have a third
# level domain name (such as foo.co.uk) checked against SURBLs. Domains not
# specifically on the two level list (such as foo.com or foo.fr) should be
# checked at two levels. Please do not check at levels other than these as
# doing so will cause unnecessary queries that won't result in matches.

sub urbldomain {
  my $bls   = shift;
  my $host  = lc shift;
  my $white = $bls->{-urblpreparewhite} || [];
  my $tlds  = $bls->{-urblpreparebad} || [];
  
  foreach(@$white) {
    return undef if $host =~ /$_$/;	# whitelisted?
  }
  foreach (@$tlds) {
    if ($host =~ /([^\.]+\.$_)$/) {
      ($host = $1) =~ s/\\//g;
      return $host;
    }
  }
  $host =~ /([^\.]+\.[^\.]+)$/;
  return $1;
}

=item * $rv = $blessed->urblblack($hostname)

This method check if a hostname is found within the local black list(s).

  input:	hostname
  return:	domain found, else false

=cut

sub urblblack {
  my $bls   = shift;
  my $host  = lc shift;
  my $tlds  = $bls->{-urblprepareblack} || [];
  foreach (@$tlds) {
    if ($host =~ /$_$/) {
      ($host = $_) =~ s/\\//g;
      return $host;
    }
  }
  return undef;
}

=item * $rv = $blessed->urbwhite($hostname)

This method check if a hostname is found within the local white list.

  input:	hostname
  return:	domain found, else false

=cut

sub urblwhite {
  my $bls   = shift;
  my $host  = lc shift;
  my $white  = $bls->{-urblpreparewhite} || [];
  foreach (@$white) {
    if ($host =~ /$_$/) {
      ($host = $_) =~ s/\\//g;
      return $host;
    }
  }
  return undef;
}

1;
__END__

=item * $response_code = $proto->loadcache($url,$localfile);

=item * ($response,$message) = $proto->loadcache($url,$localfile);

This method uses LWP::UserAgent::mirror to conditionally retrieve files
to fill local cache with WHITELIST and TLD names. The response code is the
result returned by the HTTP fetch and should be one of 200 or 304. At the
time this module was released the files were as follows:

  WHITE LIST URL
  http://spamassasin.googlecode.com/svn-history/r6/trunk/share/spamassassin/25_uribl.cf

and

  TLDLIST URL (include some known abusive tlds)
  http://george.surbl.org/three-level-tlds
  http://george.surbl.org/two-level-tlds

  input:	path/name/for/localfile
  return:	http response code,
		response message

In scalar context only the http response code is returned. In array context
the numeric response code and a related text message are returned.

  200	OK		file cached
  304	Not Modified	file is up-to-date

Any other response code indicates and error.

  Usage:
  $rv = URBL::Prepare->loadcache($url,$localfile);

=back

=cut

sub loadcache {
  my($bls,$url,$file) = @_;
  require LWP::UserAgent;
  my $ua = new LWP::UserAgent(
        timeout => 30
  );
  my $r = $ua->mirror($url,$file);
  return $r->code unless wantarray;
  return ($r->code,$r->message);
}

=head1 APPLICATION EXAMPLES

This example shows how to include URBL::Prepare in another module

  #!/usr/bin/perl
  package = Some::Package

  use vars qw(@ISA);
  require URBL::Prepare;

  @ISA = qw( URBL::Prepare );

  sub new {
    my $proto = shift;
    my $class = ref $proto || $proto || __PACKAGE__;
    my $methodptr = {
	....
    };
    bless $methodptr, $class;
  }
  ... package code ...
  1;

  ...end
......................

  #!/usr/bin/perl
  # my application
  #
  use Net::DNS::Dig;
  use Some::Package;

  my $dig = new Net::DNS::Dig;
  my $sp = new Some::Package;
  #
  # initialiaze URBL::Prepare
  #
  $sp->cachewhite($localwhitefiles);
  $sp->cachetlds($localtldfiles);

  # set multi.surbl.org bit mask
  #	2 = comes from SC
  #	4 = comes from WS
  #	8 = comes from PH
  #	16 = comes from OB (OB is deprecated as of 22 October 2012.)
  #	16 = comes from MW (MW active as of 1 May 2013.)
  #	32 = comes from AB
  #	64 = comes from JP

  # test as: surbl-org-permanent-test-point.com.multi.surbl.org

  my $mask = 0xDE;

    ... application ...
    ... generates   ...
    ... hostname    ...

  my $domain = $sp->urbldomain($hostname)

  my $response = $dig->for($hostname . 'multi.surbl.org')
	if $domain;	# if not whitelisted

  # if an answer is returned
  if ($domain && $response->{HEADER}->{ANCOUNT}) {
    # get packed ipV4 answer
    my $answer = $response->{ANSWER}->[0]->{RDATA}->[0];
    if ($mask & unpack("N",$answer)) {
	# answer is found in selected surbl list
    } else {
	# answer not found in selected surbl list
    }
  }
  # domain not found in surbl

  ...end

This is an example of a script file to keep the whitelist and tldlist
current. Run as a cron job daily.

  #!/usr/bin/perl
  #
  # cache refresh cron job
  #
  require URBL::Prepare;

  my $whiteurl =
  'http://spamassasin.googlecode.com/svn-history/r6/trunk/share/spamassassin/25_uribl.cf';

  my $tld2url = 'http://george.surbl.org/two-level-tlds';
  my $tld3url = 'http://george.surbl.org/three-level-tlds';

  my $cachedir	= './cache';
  my $lvl2file	= $cachedir .'/level2';
  my $lvl3file	= $cachedir .'/level3';
  my $whtfile	= $cachedir .'/white';

  mkdir $cachedir unless -d $cachedir;

  URBL::Prepare->loadcache($whiteurl,$whtfile);
  URBL::Prepare->loadcache($tld2url,$lvl2file);
  URBL::Prepare->loadcache($tld3url,$lvl3file);

=cut

=head1 AUTHOR

Michael Robinton E<lt>michael@bizsystems.comE<gt>

=head1 COPYRIGHT

    Copyright 2013-2014, Michael Robinton <michael@bizsystems.com>

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 See also:

L<LWP::Request>, L<Net::DNS::Dig>

=cut

1;
