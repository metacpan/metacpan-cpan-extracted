package Zeal::Feed;

use 5.014000;
use strict;
use warnings;
use re '/s';

our $VERSION = '0.001001';

use parent qw/Class::Accessor::Fast/;
__PACKAGE__->mk_ro_accessors(qw/version/);

use Cwd qw/getcwd/;
use File::Spec::Functions qw/catfile rel2abs/;
use HTTP::Tiny;

use Archive::Tar;
use File::Slurp qw/read_file/;
use File::Which;
use XML::Rules;

sub new {
	my ($class, $url) = @_;
	$class->new_from_content(HTTP::Tiny->new->get($url)->{content});
}

sub new_from_file {
	my ($class, $file) = @_;
	$class->new_from_content(scalar read_file $file);
}

sub new_from_content {
	my ($class, $xml) = @_;
	my ($version, @urls) = @_;

	my $self = XML::Rules->parse(
		rules => {
			_default         => 'content',
			entry            => 'pass',
			url              => 'content array',
			'other-versions' => undef,
		},
		stripspaces => 3|4,
	)->($xml);
	bless $self, $class
}

sub urls {
	my ($self) = @_;
	@{$self->{url}}
}

sub url {
	my ($self) = @_;
	my @urls = $self->urls;
	$urls[int rand @urls]
}

sub _unpack_tar_to_dir {
	my ($file, $dir) = @_;
	$file = rel2abs $file;
	my $oldwd = getcwd;
	chdir $dir;
	my $tar = which 'tar' or which 'gtar';

	# uncoverable branch true
	# uncoverable condition false
	local $ENV{ZEAL_USE_INTERNAL_TAR} = 1 if $file =~ /gz$|bz2$/ && $^O eq 'solaris';

	if ($tar && !$ENV{ZEAL_USE_INTERNAL_TAR}) {
		my $arg = '-xf';
		$arg = '-xzf' if $file =~ /[.]t?gz$/;
		$arg = '-xjf' if $file =~ /[.]bz2$/;
		system $tar, $arg => $file
	} else {
		Archive::Tar->extract_archive($file);
	}
	chdir $oldwd;
}

sub download {
	my ($self, $path) = @_;
	my ($name) = $self->url =~ /([^\/])+$/;
	my $file = catfile $path, $name;
	HTTP::Tiny->new->mirror($self->url, $file);
	_unpack_tar_to_dir $file, $path;
	unlink $file;
}

1;
__END__

=encoding utf-8

=head1 NAME

Zeal::Feed - Class representing a Dash/Zeal documentation feed

=head1 SYNOPSIS

  use Zeal::Feed;
  my $feed = Zeal::Feed->new('http://example.com/feed.xml');
  say $feed->version; # 12.2.3
  say $feed->url;     # http://another.example.com/file.tar.gz

  # Download to /home/mgv/docsets/file.docset
  $feed->download('/home/mgv/docsets/');

=head1 DESCRIPTION

Dash is an offline API documentation browser. Zeal::Feed is a class
representing a Dash/Zeal documentation feed.

A documentation feed is an XML file describing a docset. It contains
the version of the docset and one or more URLs to a (typically
.tar.gz) archive of the docset.

Available methods:

=over

=item Zeal::Feed->B<new>(I<$url>)

Create a Zeal::Feed object from an HTTP URL.

=item Zeal::Feed->B<new_from_file>(I<$file>)

Create a Zeal::Feed object from a file.

=item Zeal::Feed->B<new_from_content>(I<$xml>)

Create a Zeal::Feed object from a string.

=item $feed->B<version>

The version of this feed.

=item $feed->B<urls>

A list of URLs to this docset.

=item $feed->B<url>

An URL to this docset, randomly chosen from the list returned by B<urls>.

=item $feed->B<download>(I<$path>)

Download and unpack the docset inside the I<$path> directory.

Uses the F<tar> binary for unpacking if availablem, L<Archive::Tar>
otherwise. You can set the ZEAL_USE_INTERNAL_TAR environment variable
to a true value to force the use of L<Archive::Tar>.

=back

=head1 ENVIRONMENT

=over

=item ZEAL_USE_INTERNAL_TAR

If true, B<download> will always use L<Archive::Tar>.

=back

=head1 SEE ALSO

L<Zeal>, L<http://kapeli.com/dash>, L<http://zealdocs.org>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
