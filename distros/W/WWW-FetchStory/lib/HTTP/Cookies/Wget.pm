package HTTP::Cookies::Wget;
$HTTP::Cookies::Wget::VERSION = '0.2002';
use strict;

our @ISA=qw(HTTP::Cookies);
require HTTP::Cookies;

sub load
{
    my($self, $file) = @_;
    $file ||= $self->{'file'} || return;
    local(*FILE, $_);
    local $/ = "\n";  # make sure we got standard record separator
    my @cookies;
    open(FILE, $file) || return;

    # don't check for a header; not all export programs save one

    my $now = time() - $HTTP::Cookies::EPOCH_OFFSET;
    while (<FILE>) {
	next if /^\s*\#/;
	next if /^\s*$/;
	tr/\n\r//d;
	my($domain,$bool1,$path,$secure, $expires,$key,$val) = split(/\t/, $_);
	$secure = ($secure eq "TRUE");

	# Give expired cookies a fake maxage, because we want all cookies
	# including session cookies
	my $maxage = $expires-$now;
	if ($maxage < 0)
	{
	    $maxage = 9999999;
	}
	# Tweak the domain for livejournal cookies,
	# because it puts '.' in front of all of them
	# whether they need it or not, and this apparently confuses LWP
	if ($domain =~ /^\.([-\w]+\.livejournal\.com)$/)
	{
	    $domain = $1;
	}

	$self->set_cookie(undef,$key,$val,$path,$domain,undef,
			  0,$secure,$maxage, 0);
    }
    close(FILE);
    1;
}

sub save
{
    my($self, $file) = @_;
    $file ||= $self->{'file'} || return;
    local(*FILE, $_);
    open(FILE, ">$file") || return;

    # Use old, now broken link to the old cookie spec just in case something
    # else (not us!) requires the comment block exactly this way.
    print FILE <<EOT;
# Wget HTTP Cookie File
# http://www.netscape.com/newsref/std/cookie_spec.html
# This is a generated file!  Do not edit.

EOT

    my $now = time - $HTTP::Cookies::EPOCH_OFFSET;
    $self->scan(sub {
	my($version,$key,$val,$path,$domain,$port,
	   $path_spec,$secure,$expires,$discard,$rest) = @_;
	return if $discard && !$self->{ignore_discard};
	$expires = $expires ? $expires - $HTTP::Cookies::EPOCH_OFFSET : 0;
	return if $now > $expires;
	$secure = $secure ? "TRUE" : "FALSE";
	my $bool = $domain =~ /^\./ ? "TRUE" : "FALSE";
	print FILE join("\t", $domain, $bool, $path, $secure, $expires, $key, $val), "\n";
    });
    close(FILE);
    1;
}

1;
__END__

=head1 NAME

HTTP::Cookies::Wget - access to Wget cookies files

=head1 VERSION

version 0.2002

=head1 SYNOPSIS

 use LWP;
 use HTTP::Cookies::Wget;
 $cookie_jar = HTTP::Cookies::Wget->new(
   file => "c:/program files/netscape/users/ZombieCharity/cookies.txt",
 );
 my $browser = LWP::UserAgent->new;
 $browser->cookie_jar( $cookie_jar );

=head1 DESCRIPTION

This is a subclass of C<HTTP::Cookies> that reads (and optionally
writes) Wget/Mozilla cookie files.

See the documentation for L<HTTP::Cookies>.

=head1 CAVEATS

Please note that the Wget/Mozilla cookie file format can't store
all the information available in the Set-Cookie2 headers, so you will
probably lose some information if you save in this format.

At time of writing, this module seems to work fine with Mozilla      
Phoenix/Firebird.

=head1 SEE ALSO

L<HTTP::Cookies::Netscape>

=head1 COPYRIGHT

Copyright 2002-2003 Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
