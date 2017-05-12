#! /bin/false

# vim: tabstop=4
# $Id: Lister.pm,v 1.5 2006/05/12 12:42:14 guido Exp $

# Copyright (C) 2004-2006 Guido Flohr <guido@imperia.net>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software Foundation, 
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Test::Unit::GTestRunner::Lister;

use strict;

use Locale::TextDomain qw (Test-Unit-GTestRunner);
use Test::Unit::Loader;
use IO::Handle;

sub new {
	my $class = shift;

	my $self = bless {}, $class;

	return $self;
}

sub list {
	my ($self, @names) = @_;
	
	my @suites;
	
	my $output = "SUCCESS\n";
	
	my $io = $self->{__pipe} = IO::Handle->new;
	eval {
		# We have to dup stdout to a new filehandle, and redirect it then
		# to stderr.  Otherwise, misbehaving test cases that print on
		# stdout, will disturb our communication with the parent.
		unless ($io->fdopen (fileno STDOUT, 'w')) {
			die __x ("Standard output cannot be duplicated: {err}.",
					 err => $!) . "\n";
		}
		
		$io->autoflush (1);
		
		unless (close STDOUT) {
			die __x ("Standard output cannot be closed: {err}.",
					 err => $1) . "\n";
		}
		
		unless (open STDOUT, ">&STDERR") {
			die __x ("Standard output cannot be "
					 . "redirected to standard error: {err}.",
					 err => $!) . "\n";
		}
		
		foreach my $name (@names) {
			my $suite =	Test::Unit::Loader::load ($name);
			$self->__appendSuite (\$output, $suite, '');
		}
	};

	if ($@) {
		$output = "ERROR\n$@\n";
	}
	
	$io->print ($output);
	
	return 1;
}

sub __appendSuite {
	my ($self, $output, $suite, $indent) = @_;

	my $name = "$suite";
	$name =~ s/=.*//;
	my $is_single_test;
	my $type;

	if ($name eq 'Test::Unit::TestSuite') {
		$name = $suite->name;
		$name =~ s/^suite extracted from //;
		$type = '+';
	} elsif (exists $suite->{'Test::Unit::TestCase_name'}) {
		# Not very polite to use a private property, but the interface
		# gives no other chance.
		$name = $suite->{'Test::Unit::TestCase_name'};
		$is_single_test = 1;
		$type = '-';
	} else {
		$type = '+';
	}

	$$output .= "$indent$type$name\n";
	if ($suite->can ('tests')) {
		my $children = $suite->tests;
		
		foreach my $child (@$children) {
			$self->__appendSuite ($output, $child, $indent . ' ');
		}
	}

	return 1;
}

1;

=head1 NAME
Test::Unit::GTestRunner::Lister - Load and list test suites

=head1 SYNOPSIS

 use Test::Unit::GTestRunner::Lister;

 Test::Unit::GTestRunner::Worker->new->list (@suite_names);

=head1 DESCRIPTION

This class is not intended for direct usage.  Instead,
Test::Unit::GTestRunner(3pm) executes Perl code that uses
Test::Unit::GTestRunner::Lister(3pm), so that the test listing
executed in separate process.

=head1 AUTHOR

Copyright (C) 2004-2006, Guido Flohr E<lt>guido@imperia.netE<gt>, all
rights reserved.  See the source code for details.

This software is contributed to the Perl community by Imperia 
 (L<http://www.imperia.net/>).

=head1 ENVIRONMENT

The package is internationalized with libintl-perl, hence the 
environment variables "LANGUAGE", "LANG", "LC_MESSAGES", and
"LC_ALL" will influence the language in which messages are presented.

=head1 SEE ALSO

Test::Unit::GTestRunner(3pm), Test::Unit::TestRunner(3pm), 
Test::Unit(3pm), perl(1)

=cut

#Local Variables:
#mode: perl
#perl-indent-level: 4
#perl-continued-statement-offset: 4
#perl-continued-brace-offset: 0
#perl-brace-offset: -4
#perl-brace-imaginary-offset: 0
#perl-label-offset: -4
#cperl-indent-level: 4
#cperl-continued-statement-offset: 2
#tab-width: 4
#End:

__DATA__
