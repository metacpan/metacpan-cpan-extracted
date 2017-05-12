package threads::lite::list;

use strict;
use warnings;
use 5.010;
use experimental 'smartmatch';
use Exporter 5.57 qw/import/;

our @EXPORT_OK = qw/parallel_map parallel_grep/;

use threads::lite qw/self spawn receive receiveq/;
use constant DEFAULT_THREADS => 4;
use Carp qw/carp/;

our $VERSION = '0.034';
our $THREADS ||= DEFAULT_THREADS;

sub _mapper {
	my (undef, $filter) = receiveq('filter', qr//);
	my $continue = 1;
	while ($continue) {
		receive {
			when (@$_ == 4) {
				my ($manager, undef, $index, $value) = @$_;
				local $_ = $value;
				$manager->send(self, 'map', $index, $filter->());
			}
			when (['kill']) {
				$continue = 0;
			}
			default {
				carp sprintf "Received something unknown: (%s)\n", join ',', @$_;
			}
		};
	}
	return;
}

sub _receive_next {
	my $threads = shift;
	my ($thread, undef, $index, @value) = receiveq($threads, 'map', qr//, qr//);
	return ($thread, $index, @value);
}

sub new {
	my $class   = shift;
	my %options = (
		modules => [],
		threads => $THREADS,
		@_,
	);
	my @modules = ('threads::lite::list', @{ $options{modules} });
	my %threads = map { ($_->id => $_) } spawn({ modules => \@modules, monitor => 1, pool_size => $options{threads} }, 'threads::lite::list::_mapper');
	$_->send(filter => $options{code}) for values %threads;
	return bless \%threads, $class;
}

sub map {
	my ($self, @args) = @_;
	my $i = 0;
	my @ret;

	my $id      = self;
	my %threads = %{$self};
	for my $thread (values %threads) {
		last if $i == @args;
		$thread->send($id, 'map', $i, $args[$i]);
		$i++;
	}
	while ($i < @args) {
		my ($thread, $index, @value) = _receive_next([ values %threads ]);
		$ret[$index] = \@value;
		$thread->send($id, 'map', $i, $args[$i]);
		$i++;
	}
	while (%threads) {
		my ($thread, $index, @value) = _receive_next([ values %threads ]);
		$ret[$index] = \@value;
		delete $threads{ $thread->id };
	}

	return map { @{$_} } @ret;
}

sub grep {
	my ($self, @args) = @_;

	my @values = $self->map(@args);

	my @ret;
	for my $i (0..$#args) {
		push @ret, $args[$i] if $values[$i];
	}
	return @ret;
}

## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub parallel_map(&@) {
	my ($code, $options, @args) = @_;
	my $object = __PACKAGE__->new(($options ? %{$options} : ()), code => $code);
	return $object->map(@args);
}

sub parallel_grep(&@) {
	my ($code, $options, @args) = @_;
	my $object = __PACKAGE__->new(($options ? %{$options} : ()), code => $code);
	return $object->grep(@args);
}

sub DESTROY {
	my $self = shift;
	for my $thread (values %{$self}) {
		$thread->send('kill');
		receiveq('exit', qr//, $thread->id, undef);
		delete $self->{ $thread->id };
	}
	return;
}

1;

=head1 NAME

threads::lite::list - Threaded list utilities

=head1 VERSION

Version 0.034

=head1 SYNOPSIS

This module implements some parallel list utilities op top of threads::lite.

=head1 FUNCTIONS

=head2 parallel_map { block } $options, @elements

map a list using multiple threads. $options is a hashref whose keys are like in C<new>.

=head2 parallel_grep { block } $options, @elements

grep a list using multiple threads. $options is a hashref whose keys are like in C<new>.

=head1 CLASS METHODS

A parallel list processing object can be created if you want to reuse your filter with other arguments.

=head2 new(%options)

Create a new parallel list processing object. It takes three named arguments.

=over 2

=item * code

A reference to the piece of code that should be executed, or it's name. Note that if a name is given, it's containing module must be loaded using C<modules>.

=item * modules

Modules that must be loaded be for the mapping or grepping.

=item * threads

The number of threads you want to use to do the mapping. The default is currently 4, an arbitrary number that may change in the future.

=back

=head1 INSTANCE METHODS

=head2 map(@elements)

Map elements in a parallel manner.

=head2 grep(@elements)

Grep elements in a parallel manner.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

This is an early development release, and is expected to be buggy and incomplete.

Please report any bugs or feature requests to C<bug-threads-lite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=threads-lite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc threads::lite::list

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=threads-lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/threads-lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/threads-lite>

=item * Search CPAN

L<http://search.cpan.org/dist/threads-lite>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009, 2010 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
