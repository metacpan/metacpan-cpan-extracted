package tester;
#########################
# This module assist in testing the Tk dialog functions, by issuing
# button events and thus allowing the dialog to be seen "briefly".
#
# tester.pm - test harness for module Tk::DBI::LoginDialog
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#########################
use strict;
use warnings;

use Carp qw(cluck confess);     # only use stack backtrace within class
use Data::Dumper;
use Log::Log4perl qw/ :easy /;
use Tk;
use Test::More;

use constant TIMEOUT => (exists $ENV{TIMEOUT}) ? $ENV{TIMEOUT} : 250; # unit: ms

our $AUTOLOAD;

my %attribute = (
	cycle => 0,
	dummy => "IGNORE overidden dummy exit routine\n",
	log => get_logger(__FILE__),
	count => 0,
	timeout => TIMEOUT,
	top => undef,
);


sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or confess "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully−qualified portion

	unless (exists $self->{_permitted}->{$name} ) {
		confess "no attribute [$name] in class [$type]";
	}

	if (@_) {
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}
}


sub new {
	my ($class) = shift;
	my $self = { _permitted => \%attribute, %attribute };

	bless ($self, $class);

	my %args = @_;  # start processing any parameters passed
	my ($method,$value);
	while (($method, $value) = each %args) {

		confess "SYNTAX new(method => value, ...) value not specified"
			unless (defined $value);

		$self->log->debug("method [self->$method($value)]");

		$self->$method($value);
	}

	my $top; eval { $top = new MainWindow; };
	$self->{'top'} = $top;

	return $self;
}


sub tests {
	my $self = shift;
	my $n_tests = shift;

	if (Tk::Exists($self->{'top'})) {

		plan tests => $n_tests;

	} else {

		plan skip_all => 'No X server available';
	}
}


sub queue_button {
	my $self = shift;
	my ($o,$action,$timeout)=@_;

	my $cycle = ++$self->{'cycle'};
	my $label = "B_$action";

	$self->timeout($timeout)
		if (defined $timeout);

	$self->log->trace(sprintf "action [$action] timeout [%d]", $self->timeout);

	my $button = $o->Subwidget($label);

	$self->log->trace("queuing button labelled [$label]");

	$button->after($self->timeout, sub{ $button->invoke; });

	if ($action eq 'Login') {

		isa_ok($o->login(1), "DBI::db",		"login handle cycle $cycle"); 
		++$self->{'count'};

	} else {

		is($o->Show, $action,		"show $action cycle $cycle");
		++$self->{'count'};
	}

	is($o->cget('-pressed'), $action,	"pressed $action cycle $cycle"); 
	++$self->{'count'};

	return $button;
}


sub queue_login { 	# DO NOT USE; REDUNDANT!
	my $self = shift;
	my ($o,$action,$method)=@_; 
 
	my $button = $o->Subwidget("B_$action");

	$self->log->debug("about to queue action [$action]"); 
 
	$button->after(TIMEOUT, sub{ $button->invoke; }); 
 
	if ($method eq "s") { 
		is($o->Show, $action,			"show $action"); 
 
		is($o->cget('-pressed'), $action,	"pressed $action"); 
	} else { 
		isa_ok($o->login(1), "DBI::db",		"$action"); 
	} 
} 
 
 
sub dummy_exit {
	my $self = shift;
	my ($o)=@_; 

	$o->configure(-exit => sub { warn $self->dummy ; });
}


DESTROY {
        my $self = shift;

};

#END { }

1;

__END__


