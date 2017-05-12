#! /bin/false

# vim: set autoindent shiftwidth=4 tabstop=8:
# $Id: Worker.pm,v 1.23 2006/05/12 12:42:14 guido Exp $

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

package Test::Unit::GTestRunner::Worker;

use strict;

use constant DEBUG => 0;

use base qw (Test::Unit::TestRunner);

use Locale::TextDomain qw (Test-Unit-GTestRunner);
use Test::Unit::Loader;
use Storable qw (nfreeze);
use MIME::Base64 qw (encode_base64);
use IO::Handle;

sub new {
    my $class = shift;
    
    my $self = bless {}, $class;
    
    # We have to dup stdout to a new filehandle, and redirect it then
    # to stderr.  Otherwise, misbehaving test cases that print on
    # stdout, will disturb our communication with the parent.
    my $io = $self->{__pipe} = IO::Handle->new;
    unless ($io->fdopen (fileno STDOUT, 'w')) {
	$self->__sendWarning (__x ("Standard output cannot be "
				   . "duplicated: {err}.",
				   err => $!));
	$self->__sendMessage ("terminated");
	exit 1;
    }
    
    $io->autoflush (1);
    
    unless (tie *STDOUT, 'Test::Unit::GTestRunner::TiedHandle', 
	    sub { $self->__sendMessage (@_) }) {
	$self->__sendWarning (__x ("Standard output cannot be tied: {err}.",
				   err => $!));
    }
    
    unless (tie *STDERR, 'Test::Unit::GTestRunner::TiedHandle', 
	    sub { $self->__sendMessage (@_) }) {
	$self->__sendWarning (__x ("Standard error cannot be tied: {err}.",
				   err => $!));
    }
    
    return $self;
}

sub waitCommand {
    my $self = shift;
    
    return 1;
}

sub start {
    my ($self, @suite_names) = @_;
    
    my $result = $self->{__my_result} = $self->create_test_result;

    my @suites;
    my @selected_tests;
    
    foreach my $suite_name (@suite_names) {
	my @test_numbers;
	if ($suite_name =~ s/::([0-9\s,]+)$//) {
	    @test_numbers = split /\s*,\s*/, $1;
	}
	push @suites, $suite_name;
	push @selected_tests, \@test_numbers;
    }
    
    my $suite = eval { 
	package GTestRunnerSuite;
	use base qw (Test::Unit::TestSuite);
	*GTestRunnerSuite::include_tests = sub { @suites };
	
	package Test::Unit::GTestRunner;
	Test::Unit::Loader::load ('GTestRunnerSuite'); 
    };
    if ($@) {
	my $reply_queue = $self->{__my_reply_queue};
	
	$self->__sendMessage ("abort $@");
	
	exit 1;
    }
    
    my $count = 0;
    foreach my $test_numbers (@selected_tests) {
	if (@{$test_numbers}) {
	    # Ouch.  But the Test::Unit API gives us no other chance.
	    $suite->{_Tests}->[$count]->{_Tests} = 
		[@{$suite->{_Tests}->[$count]->{_Tests}}[@{$test_numbers}]];
	}
	++$count;
    }
    
    $result->add_listener ($self);
    $self->{__my_suite} = $suite;
    
    eval {
	$suite->run ($result, $self);
    };
    if ($@) {
	$self->__sendMessage ("warning $@");
    }
    
    $self->__sendMessage ("terminated");
    
    exit 0;
}

# These are callbacks from Test::Unit::Result.
sub start_test {
    my ($self, $test) = @_;
    
    my $name = $test->name;
    
    my $test_case = $test;
    $test_case =~ s/=.*//;
    
    $self->__sendMessage ("start ${test_case}::$name");
    
    return 1;
}

# These are callbacks from Test::Unit::Result.
sub end_test {
    my ($self, $test) = @_;
    
    my $name = $test->name;
    
    $self->__sendMessage ("end $name");
    
    return 1;
}

sub add_failure {
    my ($self, $test, $failure) = @_;
    
    my $name = $test->name;
    
    # FIXME: Any clean/cleaner way for this?
    my $packet = {
	package => $failure->{'-package'},
	file => $failure->file,
	line => $failure->line,
	text => $failure->text,
    };
    
    my $obj = encode_base64 nfreeze $packet;
    
    $self->__sendMessage ("failure $name $obj");
    
    return 1;
}

sub add_error {
    my ($self, $test, $failure) = @_;
    
    my $name = $test->name;
    
    # FIXME: Any clean/cleaner way for this?
    my $packet = {
	package => $failure->{'-package'},
	file => $failure->file,
	line => $failure->line,
	text => $failure->text,
    };
    
    # FIXME: This is definetely not the right way!
    # 		 It will break if the file contains more than one packages.
    if ($packet->{package} eq 'Error::subs') {
	$packet->{package} = $packet->{file};
	$packet->{package} =~ s/\//::/g;
	$packet->{package} =~ s/.pm//g;
    }
    
    my $obj = encode_base64 nfreeze $packet;
    
    $self->__sendMessage ("error $name $obj");
    
    return 1;
}

sub add_pass {
    my ($self, $test, $failure) = @_;
    
    my $name = $test->name;
    
    $self->__sendMessage ("success $name");
    
    return 1;
}

sub _print {
    my ($self, @args) = @_;
    
    print @args;
}

sub __sendMessage {
    my ($self, $message) = @_;
    
    my $length = 1 + length $message;
    $length = $length & 0xffff_ffff;
    $length = sprintf "%08x", $length;

    warn ">>> REPLY: $message\n" if DEBUG;

    $self->{__pipe}->print ("$length $message\n");
}

sub __sendWarning {
    my ($self, $warning) = @_;
    
    $self->__sendMessage ("warning $warning");
}

package Test::Unit::GTestRunner::TiedHandle;

use strict;

use Storable qw (nfreeze);
use MIME::Base64 qw (encode_base64);

sub TIEHANDLE {
    my ($class, $callback) = @_;
    
    bless { __callback => $callback }, $class;
}

sub WRITE {
    my ($self, $buffer, $length, $offset) = @_;
    
    my $string = substr $buffer, $length, $offset;
    
    $self->PRINT ($string) or return;
    
    return length $string;
}

sub PRINT {
    my ($self, @strings) = @_;

    return if $self->{__closed};

    my $encoded = encode_base64 join $,, @strings, $\;
    
    $self->{__callback}->("print $encoded");
}

sub PRINTF {
    my ($self, $fmt, @args) = @_;
    
    $self->PRINT (sprintf $fmt, @args);
}

sub CLOSE {
    shift->{__closed} = 1;
}

# POSIX stderr is read/write!
sub READ { return }
sub READLINE { return }
sub GETC { return }

sub UNTIE {}
sub DESTROY {}

sub BINMODE {}
sub OPEN {}
sub EOF {}
sub FILENO { 1 }
sub SEEK { return }
sub TELL { return }

1;

=head1 NAME

Test::Unit::GTestRunner::Worker - Worker class for GTestRunner

=head1 SYNOPSIS

 use Test::Unit::GTestRunner::Worker;

 Test::Unit::GTestRunner::Worker->new->start ($my_testcase_class);

=head1 DESCRIPTION

This class is not intended for direct usage.  Instead,
Test::Unit::GTestRunner(3pm) executes Perl code that uses
Test::Unit::GTestRunner::Worker(3pm), so that the testing is
executed in separate process.

Feedback about running tests is printed on standard output,
see the source for details of the protocol.

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
#tab-width: 8
#End:
