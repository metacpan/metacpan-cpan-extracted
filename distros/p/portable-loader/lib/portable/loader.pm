use 5.008008;
use strict;
use warnings;

package portable::loader;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Module::Pluggable (
	search_path => ['portable::loader'],
	sub_name    => '_plugins',
	require     => 1,
);

use portable::lib;

my @loaders;
{
	sub loaders {
		my $me = shift;
		($me->_plugins, @loaders);
	}
	sub add_loader {
		my $me = shift;
		push @loaders, @_;
	}
}

sub _croak {
	my $me = shift;
	my ($msg, @args) = @_;
	require Carp;
	Carp::croak(sprintf($msg, @args));
}

sub _read {
	my $me = shift;
	my ($collection) = @_;
	for my $loader ($me->loaders) {
		my ($fn, $loaded) = $loader->load($collection);
		return ($fn, $loaded) if $loaded;
	}
	$me->_croak('Could not load portable collection %s', $collection);
}

my $i = 0;
sub _mint_prefix {
	++$i;
	my $me = shift;
	my ($collection) = @_;
	"portable::collection::Collection$i";
}

sub load {
	require MooX::Press;
	'MooX::Press'->VERSION('0.011');
	my $me = shift;
	my ($collection, %opts) = @_;
	my ($fn, $loaded) = $me->_read($collection);
	if ($portable::INC{$fn}) {
		return $portable::INC{$fn};
	}
	%opts = (%$loaded, %opts);
	$opts{prefix} ||= $me->_mint_prefix($collection);
	$opts{factory_package} ||= $opts{prefix};
	$opts{caller} ||= caller;
	'MooX::Press'->import(%opts);
	($portable::INC{$fn} = $opts{factory_package} || $opts{caller});
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

portable::loader - load classes and roles which can be moved around your namespace

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=portable-loader>.

=head1 SEE ALSO

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

