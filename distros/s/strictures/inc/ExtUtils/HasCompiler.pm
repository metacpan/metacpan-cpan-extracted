package ExtUtils::HasCompiler;
$ExtUtils::HasCompiler::VERSION = '0.013';
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/can_compile_loadable_object/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Config;
use Carp 'carp';
use File::Basename 'basename';
use File::Spec::Functions qw/catfile catdir/;
use File::Temp qw/tempdir tempfile/;

my $tempdir = tempdir(CLEANUP => 1);

my $loadable_object_format = <<'END';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_UNUSED_VAR
#define PERL_UNUSED_VAR(var)
#endif

XS(exported) {
#ifdef dVAR
	dVAR;
#endif
	dXSARGS;

	PERL_UNUSED_VAR(cv); /* -W */
	PERL_UNUSED_VAR(items); /* -W */

	XSRETURN_IV(42);
}

#ifndef XS_EXTERNAL
#define XS_EXTERNAL(foo) XS(foo)
#endif

/* we don't want to mess with .def files on mingw */
#if defined(WIN32) && defined(__GNUC__)
#  define EXPORT __declspec(dllexport)
#else
#  define EXPORT
#endif

EXPORT XS_EXTERNAL(boot_%s) {
#ifdef dVAR
	dVAR;
#endif
	dXSARGS;

	PERL_UNUSED_VAR(cv); /* -W */
	PERL_UNUSED_VAR(items); /* -W */

	newXS("%s::exported", exported, __FILE__);
}

END

my $counter = 1;
my %prelinking = map { $_ => 1 } qw/MSWin32 VMS aix/;

sub can_compile_loadable_object {
	my %args = @_;

	my $config = $args{config} || 'ExtUtils::HasCompiler::Config';
	return if not $config->get('usedl');

	my ($source_handle, $source_name) = tempfile(DIR => $tempdir, SUFFIX => '.c', UNLINK => 1);
	my $basename = basename($source_name, '.c');

	my $shortname = '_Loadable' . $counter++;
	my $package = "ExtUtils::HasCompiler::$shortname";
	printf $source_handle $loadable_object_format, $basename, $package or do { carp "Couldn't write to $source_name: $!"; return };
	close $source_handle or do { carp "Couldn't close $source_name: $!"; return };

	my $abs_basename = catfile($tempdir, $basename);
	my $object_file = $abs_basename . $config->get('_o');
	my $loadable_object = $abs_basename . '.' . $config->get('dlext');
	my $incdir = catdir($config->get('archlibexp'), 'CORE');

	my ($cc, $ccflags, $optimize, $cccdlflags, $ld, $ldflags, $lddlflags, $libperl, $perllibs) = map { $config->get($_) } qw/cc ccflags optimize cccdlflags ld ldflags lddlflags libperl perllibs/;

	if ($prelinking{$^O}) {
		require ExtUtils::Mksymlists;
		ExtUtils::Mksymlists::Mksymlists(NAME => $basename, FILE => $abs_basename, IMPORTS => {});
	}
	my @commands;
	if ($^O eq 'MSWin32' && $cc =~ /^cl/) {
		push @commands, qq{$cc $ccflags $cccdlflags $optimize /I "$incdir" /c $source_name /Fo$object_file};
		push @commands, qq{$ld $object_file $lddlflags $libperl $perllibs /out:$loadable_object /def:$abs_basename.def /pdb:$abs_basename.pdb};
	}
	elsif ($^O eq 'VMS') {
		# Mksymlists is only the beginning of the story.
		open my $opt_fh, '>>', "$abs_basename.opt" or do { carp "Couldn't append to '$abs_basename.opt'"; return };
		print $opt_fh "PerlShr/Share\n";
		close $opt_fh;

		my $incdirs = $ccflags =~ s{ /inc[^=]+ (?:=)+ (?:\()? ( [^\/\)]* ) }{}xi ? "$1,$incdir" : $incdir;
		push @commands, qq{$cc $ccflags $optimize /include=($incdirs) $cccdlflags $source_name /obj=$object_file};
		push @commands, qq{$ld $ldflags $lddlflags=$loadable_object $object_file,$abs_basename.opt/OPTIONS,${incdir}perlshr_attr.opt/OPTIONS' $perllibs};
	}
	else {
		my @extra;
		if ($^O eq 'MSWin32') {
			my $lib = '-l' . ($libperl =~ /lib([^.]+)\./)[0];
			push @extra, "$abs_basename.def", $lib, $perllibs;
		}
		elsif ($^O eq 'cygwin') {
			push @extra, catfile($incdir, $config->get('useshrplib') ? 'libperl.dll.a' : 'libperl.a');
		}
		elsif ($^O eq 'aix') {
			$lddlflags =~ s/\Q$(BASEEXT)\E/$abs_basename/;
			$lddlflags =~ s/\Q$(PERL_INC)\E/$incdir/;
		}
		elsif ($^O eq 'android') {
			push @extra, qq{"-L$incdir"}, '-lperl', $perllibs;
		}
		push @commands, qq{$cc $ccflags $optimize "-I$incdir" $cccdlflags -c $source_name -o $object_file};
		push @commands, qq{$cc $optimize $object_file -o $loadable_object $lddlflags @extra};
	}

	for my $command (@commands) {
		print "$command\n" if not $args{quiet};
		system $command and do { carp "Couldn't execute $command: $!"; return };
	}

	# Skip loading when cross-compiling
	return 1 if exists $args{skip_load} ? $args{skip_load} : $config->get('usecrosscompile');

	require DynaLoader;
	local @DynaLoader::dl_require_symbols = "boot_$basename";
	my $handle = DynaLoader::dl_load_file(File::Spec->rel2abs($loadable_object), 0);
	if ($handle) {
		my $symbol = DynaLoader::dl_find_symbol($handle, "boot_$basename") or do { carp "Couldn't find boot symbol for $basename"; return };
		my $compilet = DynaLoader::dl_install_xsub('__ANON__::__ANON__', $symbol, $source_name);
		my $ret = eval { $compilet->(); $package->exported } or carp $@;
		delete $ExtUtils::HasCompiler::{"$shortname\::"};
		eval { DynaLoader::dl_unload_file($handle) } or carp $@;
		return defined $ret && $ret == 42;
	}
	else {
		carp "Couldn't load $loadable_object: " . DynaLoader::dl_error();
		return;
	}
}

sub ExtUtils::HasCompiler::Config::get {
	my (undef, $key) = @_;
	return $ENV{uc $key} || $Config{$key};
}

1;

# ABSTRACT: Check for the presence of a compiler

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::HasCompiler - Check for the presence of a compiler

=head1 VERSION

version 0.013

=head1 DESCRIPTION

This module tries to check if the current system is capable of compiling, linking and loading an XS module.

B<Notice>: this is an early release, interface stability isn't guaranteed yet.

=head1 FUNCTIONS

=head2 can_compile_loadable_object(%opts)

This checks if the system can compile, link and load a perl loadable object. It may take the following options:

=over 4

=item * quiet

Do not output the executed compilation commands.

=item * config

An L<ExtUtils::Config|ExtUtils::Config> (compatible) object for configuration.

=item * skip_load

This causes can_compile_loadable_object to not try to load the generated object. This defaults to true on a cross-compiling perl.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
