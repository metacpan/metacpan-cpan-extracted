package URL::Grab;

use 5.008;
use strict;
use warnings;
require Carp;
require LWP::UserAgent;

use Carp qw/carp/;
use LWP::UserAgent;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

(our $VERSION) = '$Revision: 1.4 $' =~ /([\d.]+)/;

sub new {
	my $class = shift;
	my $args = shift;
	my $self = { };

	$self->{retries} = $args->{retries} || 0;
	$self->{ua} = LWP::UserAgent->new(agent => "URL::Grab $VERSION");
	$self->{ua}->{timeout} = $args->{timeout} || 30;
	
	bless($self, $class);
	return $self;
}

sub grab_single {
	my $self = shift;
	my $url = shift;

	my $retval;
	if($url =~ /^https?:\/\// || $url =~ /^ftp:\/\//) {
		my $res = $self->{ua}->get($url);
		my $retries = 0;
		while($self->{retries} >= $retries) {
			if($res->is_success()) {
				return { $url => $res->content() };
			}
			$retries++;
		}
	} else {
		if($url =~ /^file:\/\// || $url =~ /^\//) {
			my $tmp_url = $url;
			$tmp_url =~ s/^file://;
			if(-f $tmp_url) {
				my $res;
				open(FH, $tmp_url);
				$res .= $_ while(<FH>);
				close(FH);
				return { $url => $res };
			} else {
				carp "No such file or directory";
			}
		} else {
			carp "Unknown transport protocol";
			return undef;
		}
	}
	return undef;
}

sub grab {
	my $self = shift;
	my @urls;
	while(my $arg = shift) {
		if(ref $arg eq 'ARRAY') { push @urls, $_ foreach(@{$arg});
		} else { push @urls, $arg; }
	}
	$self->{retval}->{$_} = $self->grab_single($_) foreach (@urls);
	return $self->{retval};
}

sub grab_failover {
	my $self = shift;
	my @urls;

	while (my $arg = shift) {
		push @urls, $arg;
	}

	foreach my $url (@urls) {
		my $content = $self->grab_single($url);
		return $content if $content;
	}
}

sub grab_mirrorlist {
	my $self = shift;
	my @urls;
	while(my $arg = shift) {
		push @urls, $arg;
	}
	foreach my $mirror (@urls) {
		if(ref $mirror eq 'SCALAR' || ref \$mirror eq 'SCALAR') {
			$self->{retval} = $self->grab_single($mirror)
		}
		$self->{retval} = $self->grab_failover(@{$mirror}) if ref $mirror eq 'ARRAY';
	}
	return $self->{retval};
}

1;
__END__
=head1 NAME

URL::Grab - Perl extension for blah blah blah

=head1 SYNOPSIS

  use URL::Grab;
  my $cnt_hsh;

  # IMPORTANT note (see also #32434):
  # Please note, that URL::Grab doesn't return you the content itself as a
  # scalar, but instead, returns a hash-reference. The keys of the
  # hash are the URLs.

  $cnt_hsh = $urlgrabber->grab('http://google.at');

  # The content then is available in $cnt_hsh->{'http://google.at'}->{'http://google.at'}.
  # Sorry, this is a design issue, that cannot be changed any more :-)
  # If you are fetching only one URL, you would better use grab_single!

  $cnt_hsh = $urlgrabber->grab(qw(http://google.at));
  $cnt_hsh = $urlgrabber->grab([ qw(http://google.at http://asdf.org) ]);
  $cnt_hsh = $urlgrabber->grab([ qw(http://google.at http://asdf.org) ], 'http://perl.com');

  $cnt_hsh = $urlgrabber->grab_mirrorlist(
    'http://linux.duke.edu/projects/yum/',
    [qw(http://www.netfilter.org http://www.at.netfilter.org)]
  );

  # Please note, the following example will return only *one* hash-reference - it will use the
  # first that works!!!
  $cnt_hsh = $urlgrabber->grab_mirrorlist([qw(
     http://www.netfilter.org http://www.at.netfilter.org
  )]);

  $cnt_hsh = $urlgrabber->grab_mirrorlist([qw(
    ftp://linux-kernel.at/packages/yum.conf2
    http://filelister.linux-kernel.at/downloads/packages/yum.conf
  )]);

  $cnt_hsh = $urlgrabber->grab_mirrorlist(
    'ftp://linux-kernel.at/packages/yum.conf'
  );

  $cnt_hsh = $urlgrabber->grab_mirrorlist([qw(
    /etc/yum.conf
    ftp://linux-kernel.at/packages/yum.conf
  )]);

=head1 DESCRIPTION

URL::Grab is a perl module that drastically simplifies the fetching of files
from within a local source (eg. local filesystem) and/or remote sources
(eg. http, ftp). It is designed to be used in programs that need common (but
not necessarily simple) url-fetching features. It is extremely simple to drop
into an existing program and provides a clean interface to protocol-independant
file-access. Best of all, URL::Grab takes care of all those pesky
file-fetching details, and lets you focus on whatever it is that your program
is written to do!

=head2 EXPORT

None by default.

=head1 SEE ALSO

LWP::UserAgent

Project mailinglist:
	http://lists.linux-kernel.at/wwsympa.fcgi/info/url-grab

Project website:
	http://projects.linux-kernel.at/URL-Grab/

=head1 AUTHOR

Oliver Falk, E<lt>oliver@linux-kernel.atE<gt>

=head1 THANKS

Gary Krueger E<lt>gkrueger@browsermedia.comE<gt> for pointing out some issues
 - #32434
 - #32433

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Oliver Falk E<lt>oliver@linux-kernel.atE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
