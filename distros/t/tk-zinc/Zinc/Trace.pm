#
# Copyright (c) 1992-1994 The Regents of the University of California.
# Copyright (c) 1994 Sun Microsystems, Inc.
# Copyright (c) 1995-1999 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself, subject
# to additional disclaimer in Tk/license.terms due to partial
# derivation from Tk8.0 sources.
#
# Copyright (c) 2002 CENA, C.Mertz <mert@cena.fr> to trace all
# Tk::Zinc methods calls as well as the args in a human readable
# form. Updated by D.Etienne.
#
# This package overloads the Tk::Methods function in order to trace
# every Tk::Zinc method call in your application.
#
# This may be very usefull when your application segfaults and
# when you have no idea where this happens in your code.
#
# $Id: Trace.pm,v 1.13 2005/05/16 07:22:20 lecoanet Exp $
#
# To trap Tk::Zinc errors, use rather the Tk::Zinc::TraceErrors package.
#
# for using this file do some thing like :
# perl -MTk::Zinc::Trace myappli.pl

package Tk::Zinc::Trace;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

use vars qw( $ForReplay );

use Tk;
use strict;
use Tk::Zinc::TraceUtils;

my $WidgetMethodfunction;
my %moduleOptions;


BEGIN {
    if (defined $ZincTraceErrors::on && $ZincTraceErrors::on == 1) {
	print STDERR "Tk::Zinc::Trace: incompatible package Tk::Zinc::TraceErrors is already ".
	    "loaded (exit 1)\n";
	exit 1;
    }
    print "## Tk::Zinc::Trace ON\n";
    $ZincTrace::on = 1;
    require Getopt::Long;
    Getopt::Long::Configure('pass_through');
    Getopt::Long::GetOptions(\%moduleOptions, 'code');
    $ForReplay=1 if defined $moduleOptions{code} ;
    select STDOUT; $|=1; ## for flushing the trace output
    # save current Tk::Zinc::InitObject function; it will be invoked in
    # overloaded one (see below)
    use Tk;
    use Tk::Zinc;
    $WidgetMethodfunction = Tk::Zinc->can('WidgetMethod');
    
}

print "## following trace should be very close to a replay-script code\n" if $ForReplay;

my $ZincCounter= "";
my %ZincHash;

#sub Tk::Zinc {
#    print "CREATING Zinc : @_";
#    &$ZincCreationMethodfunction;
#}

sub Tk::Zinc::WidgetMethod {
    my ($zinc, $name, @args) = @_;
    if (defined $Tk::Zinc::Trace::off and $Tk::Zinc::Trace::off > 0) {
	return &$WidgetMethodfunction(@_) if $WidgetMethodfunction;
    }
    my ($package, $filename, $line) = caller(1);
    $package="" unless defined $package;
    $filename="" unless defined $filename;
    $line="" unless defined $line;
    my $widget;
    if (defined $ZincHash{$zinc}) {
	$widget = $ZincHash{$zinc};
    } elsif ($ZincCounter) {
	$ZincHash{$zinc} = '$zinc'.$ZincCounter;
	$widget = '$zinc'.$ZincCounter;
	$ZincCounter++;
    } else {
	$ZincHash{$zinc} = '$zinc';
	$widget = '$zinc';
	$ZincCounter=1; # for the next zinc
    }
    
    if ($ForReplay) {
	print "$widget->$name";
    } else {
	print "TRACE: $filename line $line $name";
    }

    &printList(@args);
    # invoke function possibly overloaded in other modules
    if (wantarray()) {
	my @res = &$WidgetMethodfunction(@_) if $WidgetMethodfunction;
	if ($ForReplay) {
	    print ";\n";
	} else {
	    print "  RETURNS ";
	    &printList (@res);
	    print "\n";
	}
	$zinc->update;
	return @res;
    } else {
	my $res = &$WidgetMethodfunction(@_) if $WidgetMethodfunction;
	if ($ForReplay) {
	    print ";\n";
	} else {
	    print "  RETURNS ";
	    &printItem ($res);
	    print "\n";
	}
	$zinc->update;
	return $res;
    }
}
    
1;


__END__

=head1 NAME

Tk::Zinc::Trace - A module to trace all Tk::Zinc method calls

=head1 SYNOPSIS

use Tk::Zinc::Trace;
$Tk::Zinc::Trace:ForReplay = 1;

or

perl -MTk::Zinc::Trace YourZincBasedScript.pl [--code]

=head1 DESCRIPTION

When loaded, this module overloads a Tk mechanism so that every
Tk::Zinc method call will be traced. Every call will also be followed by a
$zinc->update() so that the method call will be effectively treated.

This module can be very effective for debugging when Tk::Zinc
core dumps and you have no clue which method call can be responsible for. If
you just want to trace Tk::Zinc errors when calling a method you
should rather use the Tk::Zinc::TraceErrors module

The global variable $Tk::Zinc::Trace:off can be used to trace some specific blocks. If set to 1, traces are deactivated, if set to 0, traces are reactivated.
    
If the global variable $Tk::Zinc::Trace:ForReplay is set or if the --code
option is set in the second form, the printout will be very close to re-executable
code, like this:

 ## following trace should be very close to a replay-script code
 $zinc->configure(-relief => 'sunken', -borderwidth => 3,
		  -width => 700, -font => 10x20, -height => 600);
 $zinc->add('rectangle', 1, [10, 10, 100, 50],
	    -fillcolor => 'green', -filled => 1, -linewidth => 10,
	    -relief => 'roundridge', -linecolor => 'darkgreen');
 $zinc->add('text', 1, -font => -adobe-helvetica-bold-r-normal-*-120-*-*-*-*-*-* =>
	    -text => 'A filled rectangle with a "roundridge" relief border of 10 pixels.',
	    -anchor => 'nw', -position => [120, 20]);
 $zinc->add('track', 1, 6,
	    -labelformat => 'x82x60+0+0 x60a0^0^0 x32a0^0>1 a0a0>2>1 x32a0>3>1 a0a0^0>2',
	    -position => [20, 120], -speedvector => [40, -10], -speedvectormark => 1, -speedvectorticks => 1);
 $zinc->coords(4, [20, 120]);

    
If not (the default), the printout will be more informtative, giving
the following information:
    
=over 6

=item * the source filename where the method has been invoked

=item * the line number in the source file

=item * the TkZinc method name

=item * the list of arguments in a human-readable form

=item * the returned value

=back

The trace will look like:

 ## Tk::Zinc::Trace ON
 TRACE: /usr/lib/perl5/Tk/Widget.pm line 196 configure(-relief => 'sunken', -borderwidth => 3, -width => 700, -font => 10x20, -height => 600)  RETURNS undef
 TRACE: Perl/demos/demos/zinc_lib/items.pl line 21 add('rectangle', 1, [10, 10, 100, 50], -fillcolor => 'green', -filled => 1, -linewidth => 10, -relief => 'roundridge', -linecolor => 'darkgreen')  RETURNS 2
 TRACE: Perl/demos/demos/zinc_lib/items.pl line 25 add('text', 1, -font => -adobe-helvetica-bold-r-normal-*-120-*-*-*-*-*-* => -text => 'A filled rectangle with a "roundridge" relief border of 10 pixels.', -anchor => 'nw', -position => [120, 20])  RETURNS 3
 TRACE: Perl/demos/demos/zinc_lib/items.pl line 36 add('track', 1, 6, -labelformat => 'x82x60+0+0 x60a0^0^0 x32a0^0>1 a0a0>2>1 x32a0>3>1 a0a0^0>2', -position => [20, 120], -speedvector => [40, -10], -speedvectormark => 1, -speedvectorticks => 1)  RETURNS 4

=head1 AUTHOR

C.Mertz <mertz@cena.fr> and D.Etienne <etienne@cena.fr>

=head1 CAVEATS and BUGS

This module cannot be used when Tk::Zinc::TraceErrors is already in use.

As every Tk::Zinc method call is followed by an ->update call, this may
dramatically slowdown an application. The trade-off is between application
run-time and developper debug-time.

When using an output "code-like" they are still part of the output which is
not executable code. However, the ouptut could be easily and manually
edited to be executable perl code.

=head1 COPYRIGHT

See Tk::Zinc copyright; BSD

=head1 SEE ALSO

L<Tk::Zinc(3pm)>, L<Tk::Zinc::TraceErrors(3pm)>. L<Tk::Zinc::Debug(3pm)>.

=cut
