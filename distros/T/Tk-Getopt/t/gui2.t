#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: gui2.t,v 1.8 2008/02/08 22:28:58 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	use Tk;
	use Tk::Dial;
	1;
    }) {
	print "1..0 # skip: no Test::More, Tk and/or Tk::Dial modules\n";
	exit;
    }
}

plan tests => 12;

use Tk::Getopt;

{
    # this is a non-working example, since Dial does not use -textvariable or
    # -variable :-(
    package MyOptions;
    use Tk::Getopt;
    use vars qw(@ISA);
    @ISA = qw(Tk::Getopt);

    sub _number_widget {
	my($self, $frame, $opt) = @_;
	my $v = $self->_varref($opt);
	$frame->Dial
	    (-min => $opt->[3]{'range'}[0],
	     -max => $opt->[3]{'range'}[1],
	     '-format' => '%' . ($opt->[1] =~ /f/ ? 'f' : 'd'),
#            -variable => $v,
	     -value => $$v,
	    );
    }
}

@ARGV = qw(--integer=12 --float=3.141592653);

my $dialbug = q{Note:
If you are using dial widgets, you cannot use undo or share more than one
options editor at one time.};

my @opttable =
  (['integer', '=i', undef, {'range' => [-10, 10],
			     'help' => $dialbug}],
   ['float', '=f', undef, {'range' => [-3, 5],
			   'help' => $dialbug}],
   ['defint', '=i', 50,
    {'range' => [0, 100],
     'widget' => sub { shift->Tk::Getopt::_number_widget(@_)},
    },
   ],
   ['numentry', '=i', 50,
    range => [0, 100],
    widget => sub { numentry_widget(@_) },
   ],
  );

my $opt = new MyOptions(-opttable => \@opttable);
isa_ok($opt, "MyOptions");
isa_ok($opt, "Tk::Getopt");
$opt->set_defaults;
if (!$opt->get_options) {
    die $opt->usage;
}

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

my $batch_mode = !!$ENV{BATCH};
my $timerlen = ($batch_mode ? 1000 : 60*1000);

use Tk;
my $top = eval { new MainWindow };
if (!$top) {
 SKIP: { skip "Cannot create MainWindow, probably no DISPLAY available", 12-2 }
    exit 0;
}
$top->after(100, sub {
		my $e = $opt->option_editor($top);
		$e->after($timerlen, sub { $e->destroy });
		$e->waitWindow;
		ok(1);
		&in_frame;
	    });
MainLoop;

sub in_frame {
    $top->Label(-text => 'Options editor in frame')->pack;
    my $e = $opt->option_editor($top, -toplevel => 'Frame')->pack;
    $e->after($timerlen, sub { $e->destroy });
    $e->waitWindow;
    ok(1);
    $top->destroy;
}

sub numentry_widget {
    my($self, $frame, $opt) = @_;
    my $NumEntry = "NumEntry";
    my $v_old = $self->_varref($opt); # old
    my $v = $self->varref($opt); # new
    is($v_old, $v, "varref and old _varref method return the same");
    my $range = $self->optextra($opt, "range");
    is($range->[0], 0, "Expexted lower range");
    is($range->[1], 100, "Expexted high range");
    ok(!defined $self->optextra($opt, "foodoesnotexist"), "Unexistent optextra argument");
    my @NumEntryArgs = (-minvalue => $range->[0],
			-maxvalue => $range->[1],
			-value => $$v,
		       );
    if (!eval { require Tk::NumEntry; 1 }) {
	diag "Tk::NumEntry not available, fallback to plain Tk::Entry";
	$NumEntry = "Entry";
	@NumEntryArgs = ();
    }

    $frame->$NumEntry(@NumEntryArgs,
		      -textvariable => $v,
		     );
}
