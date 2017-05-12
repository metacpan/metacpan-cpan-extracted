package WWW::FreeProxy;

use Exporter;

our $VERSION = '0.04';
our @ISA = qw/Exporter/;
our @EXPORT = qw/fetch_proxies/;

BEGIN {
	foreach my $dir (@INC) {
		next unless -d ($dir . '/WWW/FreeProxy');
		opendir $dir, $dir . '/WWW/FreeProxy';
		map { eval { require "WWW/FreeProxy/$_" } } grep /\.pmc?$/, readdir $dir;
		closedir $dir;
	}
}

=head1 NAME

WWW::FreeProxy - fetch proxies from free proxy lists

=head1 SYNOPSIS

	use WWW::FreeProxy;
	
	fetch_proxies {
		# do whatever you need to do when new proxy is found
		my $proxy = shift;
		print "found new proxy: $proxy\n";
	};

=head1 OVERVIEW

When the module is included it searches for all WWW::FreeProxy::* modules in @INC and loads them as plugins. It means that you can add your own plugins as ./WWW/FreeProxy/YourPlugin.pm. After that any calls to fetch_proxies() will go through all loaded plugins and call fetch() from them to get more proxies.

=head1 PLUGIN FORMAT

	package WWW::FreeProxy::SamplePlugin;
	
	sub fetch {
		my ($self, $callback) = @_;
		# find some proxies
		&$callback($_) foreach @proxies;
	}

=head1 FUNCTIONS

=head2 plugins()

Lists all currently loaded plugins.

=cut

sub plugins() { grep s/::$//, keys %WWW::FreeProxy:: }

=head2 fetch_proxies(&)

Fetches proxies. In order to save memory proxies are not returned as a list, but are reported through a callback function one by one instead.

=cut

sub fetch_proxies(&) { 
	my $callback = shift;
	$_->fetch($callback) for grep s/^/WWW::FreeProxy::/, plugins;
}

1;

=head1 AUTHOR

Alexey Alexandrov, C<< <swined at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-freeproxy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FreeProxy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc WWW::FreeProxy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FreeProxy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FreeProxy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FreeProxy>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FreeProxy>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alexey Alexandrov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
