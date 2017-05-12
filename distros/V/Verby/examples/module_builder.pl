#!/usr/bin/perl

use strict;
use warnings;

use Verby::Step::Closure qw/step/;
use Verby::Dispatcher;

my $cfg = Verby::Config::Data->new;
%{ $cfg->data } = (
	untar_dir => "/tmp",
);

my $d = Verby::Dispatcher->new;
$d->config_hub($cfg);

foreach my $tarball (@ARGV){
	my $mkdir = step "Verby::Action::MkPath" => sub {
		my ( $self, $c ) = @_;
		$c->path($c->untar_dir);
	};
	$mkdir->provides_cxt(1);

	my $untar = step "Verby::Action::Untar" => sub {
		my ( $self, $c ) = @_;
		$c->tarball($tarball);
		$c->dest($c->untar_dir);
	}, sub {
		my ( $self, $c ) = @_;
		if ($c->exists("main_dir")) {
			$c->workdir($c->main_dir);
			$c->export("workdir");
		}
	};
	$untar->depends([ $mkdir ]);

	my $plscript = step "Verby::Action::BuildTool";
	$plscript->depends([ $untar ]);

	my $make = step "Verby::Action::Make";
	$make->depends([ $plscript ]);

	my $test = step "Verby::Action::Make" => sub {
		my ( $self, $c ) = @_;
		$c->target("test");
	};
	$test->depends([ $make ]);

	$d->add_step($test);
}

$d->do_all;

__END__

=pod

=head1 NAME

module_builder.pl - A simple demo that unpacks, builds and tests perl module
tarballs.

=head1 SYNOPSIS

	$ module_builder.pl My-Module-0.01.tar.gz Verby-0.01.tar.gz

=head1 DESCRIPTION

As this is not really a useful program, we'll look at how it's written, not how
it's used.

Foreach tarball given on the command line, several steps are created, all of
them L<Verby::Step::Closure> objects. Each step depends on the step before it.

=over 4

=item L<Verby::Action::MkPath>

First the context variable C<untar_dir> is created. This is where all the
tarballs will be unpacked to. Because we're so silly, C<untar_dir> is actually
set by L<Cwd/cwd>, so this is basically a no-op.

It has C<provide_cxt>, meaning that all it's dependant steps and it share a
common L<Verby::Context>, separate from other steps.

=item L<Verby::Action::Untar>

The next step is to unpack the tarball. The C<before> handler in
L<Verby::Step::Closure> will set the C<tarball> context variable to the
argument being processed, and the C<dest> context variable to the C<untar_dir>
context variable.

The C<after> handler sets the C<workdir> variable to the value of the
C<src_dir> variable, and exports C<workdir> so that it's accessible to
subsequent steps.

=item L<Verby::Action::BuildTool>

The next thing to do is run the C<Makefile.PL> file. We set C<workdir> to
C<src_dir> in the previous step, and that's all we need.

=item L<Verby::Action::Make>

After we've finished running C<Makefile.PL> we can run make(1) with no
arguments. This is exactly what this step does. It is also affected by the
previously exported C<workdir>.

=item L<Verby::Action::Make>

Now we run make(1) again, but this time with the C<test> target.

=back

=head1 ASYNC BEHAVIOR

Since most actions are asynchroneous, modules will be built in parallel. Isn't
that cool?

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
