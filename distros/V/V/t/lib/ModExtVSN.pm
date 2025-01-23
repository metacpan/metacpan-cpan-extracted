#!/usr/bin/perl

# Cut down and tidied copy from Module::Extract::VERSION-1.117
# to catch $VERSION inside single quotes

require v5.10;

package ModExtVSN;

use strict;
use warnings;
no  warnings;

use Carp qw(carp);

# This is the correct version vvv
our $VERSION = '1.25';

=encoding utf8

=head1 NAME

Module::Extract::VERSION - Extract a module version safely

=head1 SYNOPSIS

	use Module::Extract::VERSION;

	my $version   # just the version
		= Module::Extract::VERSION->parse_version_safely( $file );

	my @version_info # extra info
		= Module::Extract::VERSION->parse_version_safely( $file );

=cut

sub parse_version_safely {
    my ($class, $file) = @_;

    local $/ = "\n";
    local $_;    # don't mess with the $_ in the map calling this

    my $fh;
    unless (open $fh, "<", $file) {
	carp ("Could not open file [$file]: $!\n");
	return;
	}

    my $in_pod = 0;
    my ($sigil, $var, $version, $line_number, $rhs);
    while (<$fh>) {
	$line_number++;
	chomp;
	$in_pod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $in_pod;
	next if $in_pod || /^\s*#/;

	# package NAMESPACE VERSION  <-- we handle that
	# package NAMESPACE VERSION BLOCK

	next unless /
			(?<sigil>
				[\$*]
			)
			(?<var>
				(?<package>
					[\w\:\']*
				)
				\b
				VERSION
			)
			\b
			.*?
			\=
			(?<rhs>
				.*
			)
			/x
	    || m/
			\b package \s+
			(?<package> \w[\w\:\']* ) \s+
			(?<rhs> \S+ ) \s* [;{]
			/x;
	($sigil, $var, $rhs) = @+{qw(sigil var rhs)};

	if ($sigil) {
	    $version = $class->_eval_version ($_, @+{qw(sigil var rhs)});
	    }
	else {
	    $version = $class->_eval_version ($_, '$', 'VERSION', qq('$rhs'));
	    }

	last;
	}
    $line_number = undef if eof ($fh) && !defined ($version);
    close $fh;

    return wantarray
	? ($sigil, $var, $version, $file, $line_number)
	: $version;
    }

sub _eval_version {
    my ($class, $line, $sigil, $var, $rhs) = @_;

    require Safe;
    require version;
    local $^W = 0;

    my $s = Safe->new;

    if (defined $Devel::Cover::VERSION) {
	$s->share_from ('main', ['&Devel::Cover::use_file']);
	}
    # These lines should be ignored vvv
    $s->reval ('$VERSION = ' . $rhs);
    my $version = $s->reval ('$VERSION');

    return $version;
    }

1;
