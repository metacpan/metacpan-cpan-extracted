# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright © 1997, 2000, 2001, 2003, 2008, 2016 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.cs.tu-berlin.de/~eserte/
#

package Tk::HistEntry;
require Tk;
use strict;
use vars qw($VERSION);

$VERSION = '0.44';

sub addBind {
    my $w = shift;

    $w->_entry->bind('<Up>'        => sub { $w->historyUp });
    $w->_entry->bind('<Control-p>' => sub { $w->historyUp });
    $w->_entry->bind('<Down>'      => sub { $w->historyDown });
    $w->_entry->bind('<Control-n>' => sub { $w->historyDown });

    $w->_entry->bind('<Meta-less>'    => sub { $w->historyBegin });
    $w->_entry->bind('<Alt-less>'     => sub { $w->historyBegin });
    $w->_entry->bind('<Meta-greater>' => sub { $w->historyEnd });
    $w->_entry->bind('<Alt-greater>'  => sub { $w->historyEnd });

    $w->_entry->bind('<Control-r>' => sub { $w->searchBack });
    $w->_entry->bind('<Control-s>' => sub { $w->searchForw });

    $w->_entry->bind('<Return>' => sub {
		 if ($w->cget(-command) || $w->cget(-auto)) {
		     $w->invoke;
		 }
	     });

    $w->_entry->bind('<Any-KeyPress>', sub {
			 my $e = $_[0]->XEvent;
			 $w->KeyPress($e->K, $e->s);
		     });
}

# XXX del:
#  sub _isdup {
#      my($w, $string) = @_;
#      foreach (@{ $w->privateData->{'history'} }) {
#  	return 1 if $_ eq $string;
#      }
#      0;
#  }

sub _update {
    my($w, $string) = @_;
    $w->_entry->delete(0, 'end');
    $w->_entry->insert('end', $string);
}

sub _entry {
    my $w = shift;
    $w->Subwidget('entry') ? $w->Subwidget('entry') : $w;
}

sub _listbox {
    my $w = shift;
    $w->Subwidget('slistbox') ? $w->Subwidget('slistbox') : $w;
}

sub _listbox_method {
    my $w = shift;
    my $meth = shift;
    if ($w->_has_listbox) {
	$w->_listbox->$meth(@_);
    }
}

sub _has_listbox { $_[0]->Subwidget('slistbox') }

sub historyAdd {
    my($w, $string, %args) = @_;

    $string = $w->_entry->get unless defined $string;
    return undef if !defined $string || $string eq '';

    my $history = $w->privateData->{'history'};
    if (!@$history or $string ne $history->[-1]) {
	my $spliced = 0;
	if (!$w->cget(-dup)) {
	    for(my $i = 0; $i<=$#$history; $i++) {
		if ($string eq $history->[$i]) {
		    splice @$history, $i, 1;
		    $spliced++;
		    last;
		}
	    }
	}

	push @$history, $string;
	if (defined $w->cget(-limit) &&
	    @$history > $w->cget(-limit)) {
	    shift @$history;
	}
	$w->privateData->{'historyindex'} = $#$history + 1;

	my @ret = $string;
	if ($args{-spliceinfo}) {
	    push @ret, $spliced;
	}
	return @ret;
    }
    undef;
}
# compatibility with Term::ReadLine
*addhistory = \&historyAdd;

sub historyUpdate {
    my $w = shift;
    $w->_update($w->privateData->{'history'}->[$w->privateData->{'historyindex'}]);
    $w->_entry->icursor('end'); # suggestion by Jason Smith <smithj4@rpi.edu>
    $w->_entry->xview('insert');
}

sub historyUp {
    my $w = shift;
    if ($w->privateData->{'historyindex'} > 0) {
        $w->privateData->{'historyindex'}--;
	$w->historyUpdate;
    } else {
	$w->_bell;
    }
}

sub historyDown {
    my $w = shift;
    if ($w->privateData->{'historyindex'} <= $#{$w->privateData->{'history'}}) {
	$w->privateData->{'historyindex'}++;
	$w->historyUpdate;
    } else {
	$w->_bell;
    }
}

sub historyBegin {
    my $w = shift;
    $w->privateData->{'historyindex'} = 0;
    $w->historyUpdate;
}

sub historyEnd {
    my $w = shift;
    $w->privateData->{'historyindex'} = $#{$w->privateData->{'history'}};
    $w->historyUpdate;
}

sub historySet {
    my($w, $index) = @_;
    my $i;
    my $history_ref = $w->privateData->{'history'};
    for($i = $#{ $history_ref }; $i >= 0; $i--) {
	if ($index eq $history_ref->[$i]) {
	    $w->privateData->{'historyindex'} = $i;
	    last;
	}
    }
}

sub historyReset {
    my $w = shift;
    $w->privateData->{'history'} = [];
    $w->privateData->{'historyindex'} = 0;
    $w->_listbox_method("delete", 0, "end");
}

sub historySave {
    my($w, $file) = @_;
    open(W, ">$file") or die "Can't save to file $file";
    print W join("\n", $w->history) . "\n";
    close W;
}

# XXX document
sub historyMergeFromFile {
    my($w, $file) = @_;
    if (open(W, "<$file")) {
	while(<W>) {
	    chomp;
	    $w->historyAdd($_);
	}
	close W;
    }
}

sub history {
    my($w, $history) = @_;
    if (defined $history) {
	$w->privateData->{'history'} = [ @$history ];
	$w->privateData->{'historyindex'} =
	  $#{$w->privateData->{'history'}} + 1;
    }
    @{ $w->privateData->{'history'} };
}

sub searchBack {
    my $w = shift;
    my $i = $w->privateData->{'historyindex'}-1;
    while ($i >= 0) {
	my $search = $w->_entry->get;
        if ($search eq substr($w->privateData->{'history'}->[$i], 0,
			      length($search))) {
	    $w->privateData->{'historyindex'} = $i;
	    $w->_update($w->privateData->{'history'}->[$w->privateData->{'historyindex'}]);
            return;
        }
        $i--;
    }
    $w->_bell;
}

sub searchForw {
    my $w = shift;
    my $i = $w->privateData->{'historyindex'}+1;
    while ($i <= $#{$w->privateData->{'history'}}) {
	my $search = $w->_entry->get;
        if ($search eq substr($w->privateData->{'history'}->[$i], 0,
			      length($search))) {
	    $w->privateData->{'historyindex'} = $i;
	    $w->_update($w->privateData->{'history'}->[$w->privateData->{'historyindex'}]);
            return;
        }
        $i++;
    }
    $w->_bell;
}

sub invoke {
    my($w, $string) = @_;
    $string = $w->_entry->get if !defined $string;
    return unless defined $string;
    my $added = defined $w->historyAdd($string);
    $w->Callback(-command => $w, $string, $added);
}

sub _bell {
    my $w = shift;
    return unless $w->cget(-bell);
    $w->bell;
}

sub KeyPress {
    my($w, $key, $state) = @_;
    my $e = $w->_entry;
    my(@history) = reverse $w->history;
    $w->{end} = $#history; # XXXXXXXX?
    return if ($key =~ /^Shift|^Control|^Left|^Right|^Home|^End/);
    return if ($state =~ /^Control-/);
    if ($key eq 'Tab') {
	# Tab doesn't trigger FocusOut event so clear selection
	$e->selection('clear');
	return;
    }
    return if (!$w->cget(-match));

    $e->update;
    my $cursor = $e->index('insert');

    if ($key eq 'BackSpace' or $key eq 'Delete') {
	$w->{start} = 0;
	$w->{end} = $#history;
	return;
    }

    my $text = $e->get;
    ###Grab test from entry upto cursor
    (my $typedtext = $text) =~ s/^(.{$cursor})(.*)/$1/;
    if ($2 ne "") {
	###text after cursor, do not use matching
	return;
    }

    if ($cursor == 0 || $text eq '') {
	###No text before cursor, reset list
	$w->{start} = 0;
	$w->{end} = $#history;
	$e->delete(0, 'end');
	$e->insert(0,'');
    } else {
	my $start = $w->{start};
	my $end = $w->{end};
	my ($newstart, $newend);

	###Locate start of matching & end of matching
	my $caseregex = ($w->cget(-case) ? "(?i)" : "");
	for (; $start <= $end; $start++) {
	    if ($history[$start] =~ /^$caseregex\Q$typedtext\E/) {
		$newstart = $start if (!defined $newstart);
		$newend = $start;
	    } else {
		last if (defined $newstart);
	    }
	}

	if (defined $newstart) {
	    $e->selection('clear');
	    $e->delete(0, 'end');
	    $e->insert(0, $history[$newstart]);
	    $e->selection('range',$cursor,'end');
	    $e->icursor($cursor);
	    $w->{start} = $newstart;
	    $w->{end} = $newend;
	} else {
	    $w->{end} = -1;
	}
    }
}

######################################################################

package Tk::HistEntry::Simple;
require Tk::Entry;
use vars qw(@ISA);
@ISA = qw(Tk::Derived Tk::Entry Tk::HistEntry);
#use base qw(Tk::Derived Tk::Entry Tk::HistEntry);
Construct Tk::Widget 'SimpleHistEntry';

sub CreateArgs {
    my($package, $parent, $args) = @_;
    $args->{-class} = "SimpleHistEntry" unless exists $args->{-class};
    $package->SUPER::CreateArgs($parent, $args);
}

sub Populate {
    my($w, $args) = @_;

    $w->historyReset;

    $w->SUPER::Populate($args);

    $w->Advertise(entry => $w);

    $w->{start} = 0;
    $w->{end} = 0;

    $w->addBind;

    $w->ConfigSpecs
      (-command => ['CALLBACK', 'command', 'Command', undef],
       -auto    => ['PASSIVE',  'auto',    'Auto',    0],
       -dup     => ['PASSIVE',  'dup',     'Dup',     1],
       -bell    => ['PASSIVE',  'bell',    'Bell',    1],
       -limit   => ['PASSIVE',  'limit',   'Limit',   undef],
       -match   => ['PASSIVE',  'match',   'Match',   0],
       -case    => ['PASSIVE',  'case',    'Case',    1],
       -history => ['METHOD'],
      );

    $w;
}


######################################################################
package Tk::HistEntry::Browse;
require Tk::BrowseEntry;
use vars qw(@ISA);
@ISA = qw(Tk::Derived Tk::BrowseEntry Tk::HistEntry);
#use base qw(Tk::Derived Tk::BrowseEntry Tk::HistEntry);
Construct Tk::Widget 'HistEntry';

sub CreateArgs {
    my($package, $parent, $args) = @_;
    $args->{-class} = "HistEntry" unless exists $args->{-class};
    $package->SUPER::CreateArgs($parent, $args);
}

sub Populate {
    my($w, $args) = @_;

    $w->historyReset;

    if ($Tk::VERSION >= 800) {
	$w->SUPER::Populate($args);
    } else {
	my $saveargs;
	foreach (qw(-auto -command -dup -bell -limit -match -case)) {
	    if (exists $args->{$_}) {
		$saveargs->{$_} = delete $args->{$_};
	    }
	}
	$w->SUPER::Populate($args);
	foreach (keys %$saveargs) {
	    $args->{$_} = $saveargs->{$_};
	}
    }

    $w->addBind;

    $w->{start} = 0;
    $w->{end} = 0;

    my $entry = $w->Subwidget('entry');

    $w->ConfigSpecs
      (-command => ['CALLBACK', 'command', 'Command', undef],
       -auto    => ['PASSIVE',  'auto',    'Auto',    0],
       -dup     => ['PASSIVE',  'dup',     'Dup',     1],
       -bell    => ['PASSIVE',  'bell',    'Bell',    1],
       -limit   => ['PASSIVE',  'limit',   'Limit',   undef],
       -match   => ['PASSIVE',  'match',   'Match',   0],
       -case    => ['PASSIVE',  'case',    'Case',    1],
       -history => ['METHOD'],
      );

## Delegation does not work with the new BrowseEntry --- it seems to me
## that delegation only works for composites, not for derivates
#    $w->Delegates('delete' => $entry,
#		  'get'    => $entry,
#		  'insert' => $entry,
#		 );

    $w;
}

sub delete { shift->Subwidget('entry')->delete(@_) }
sub get    { shift->Subwidget('entry')->get   (@_) }
sub insert { shift->Subwidget('entry')->insert(@_) }

sub historyAdd {
    my($w, $string) = @_;
    my($inserted, $spliced) = $w->SUPER::historyAdd($string, -spliceinfo => 1);
    if (defined $inserted) {
	if ($spliced) {
	    $w->history([ $w->SUPER::history ]);
	} else {
	    $w->_listbox_method("insert", 'end', $inserted);
	    # XXX Obeying -limit also for the array itself?
	    if (defined $w->cget(-limit) &&
		$w->_listbox_method("size") > $w->cget(-limit)) {
		$w->_listbox_method("delete", 0);
	    }
	}
	$w->_listbox_method("see", 'end');
	return $inserted;
    }
    undef;
}
*addhistory = \&historyAdd;

sub history {
    my($w, $history) = @_;
    if (defined $history) {
	$w->_listbox_method("delete", 0, 'end');
	$w->_listbox_method("insert", 'end', @$history);
	$w->_listbox_method("see", 'end');
    }
    $w->SUPER::history($history);
}

1;

=head1 NAME

Tk::HistEntry - Entry widget with history capability

=head1 SYNOPSIS

    use Tk::HistEntry;

    $hist1 = $top->HistEntry(-textvariable => \$var1);
    $hist2 = $top->SimpleHistEntry(-textvariable => \$var2);

=head1 DESCRIPTION

C<Tk::HistEntry> defines entry widgets with history capabilities. The widgets
come in two flavours:

=over 4

=item C<HistEntry> (in package C<Tk::HistEntry::Browse>) - with associated
browse entry

=item C<SimpleHistEntry> (in package C<Tk::HistEntry::Simple>) - plain widget
without browse entry

=back

The user may browse with the B<Up> and B<Down> keys through the history list.
New history entries may be added either manually by binding the
B<Return> key to B<historyAdd()> or
automatically by setting the B<-command> option.

=head1 OPTIONS

B<HistEntry> is an descendant of B<BrowseEntry> and thus supports all of its
standard options.

B<SimpleHistEntry> is an descendant of B<Entry> and supports all of the
B<Entry> options.

In addition, the widgets support following specific options:

=over 4

=item B<-textvariable> or B<-variable>

Variable which is tied to the HistEntry widget. Either B<-textvariable> (like
in Entry) or B<-variable> (like in BrowseEntry) may be used.

=item B<-command>

Specifies a callback, which is executed when the Return key was pressed or
the B<invoke> method is called. The callback reveives three arguments:
the reference to the HistEntry widget, the current textvariable value and
a boolean value, which tells whether the string was added to the history
list (e.g. duplicates and empty values are not added to the history list).

=item B<-dup>

Specifies whether duplicate entries are allowed in the history list. Defaults
to true.

=item B<-bell>

If set to true, rings the bell if the user tries to move off of the history
or if a search was not successful. Defaults to true.

=item B<-limit>

Limits the number of history entries. Defaults to unlimited.

=item B<-match>

Turns auto-completion on.

=item B<-case>

If set to true a true value, then be case sensitive on
auto-completion. Defaults to 1.

=back

=head1 METHODS

=over 4

=item B<historyAdd(>[I<string>]B<)>

Adds string (or the current textvariable value if not set) manually to the
history list. B<addhistory> is an alias for B<historyAdd>. Returns the
added string or undef if no addition was made.

=item B<invoke(>[I<string>]B<)>

Invokes the command specified with B<-command>.

=item B<history(>[I<arrayref>]B<)>

Without argument, returns the current history list. With argument (a
reference to an array), replaces the history list.

=item B<historySave(>I<file>B<)>

Save the history list to the named file.

=item B<historyMergeFromFile(>I<file>B<)>

Merge the history list from the named file to the end of the current
history list of the widget.

=item B<historyReset>

Remove all entries from the history list.

=back

=head1 KEY BINDINGS

=over 4

=item B<Up>, B<Control-p>

Selects the previous history entry.

=item B<Down>, B<Control-n>

Selects the next history entry.

=item B<Meta-E<lt>>, B<Alt-E<lt>>

Selects first entry.

=item B<Meta-E<gt>>, B<Alt-E<gt>>

Selects last entry.

=item B<Control-r>

The current content of the widget is searched backward in the history.

=item B<Control-s>

The current content of the widget is searched forward in the history.

=item B<Return>

If B<-command> is set, adds current content to the history list and
executes the associated callback.

=back

=head1 EXAMPLE

This is an simple example for Tk::HistEntry. More examples can be
found in the t and examples directories of the source distribution.

    use Tk;
    use Tk::HistEntry;

    $top = new MainWindow;
    $he = $top->HistEntry(-textvariable => \$foo,
                          -command => sub {
                              # automatically adds $foo to history
                              print STDERR "Do something with $foo\n";
                          })->pack;
    $b = $top->Button(-text => 'Do it',
                      -command => sub { $he->invoke })->pack;
    MainLoop;

If you like to not depend on the installation of Tk::HistEntry, you
can write something like this:

    $Entry = "Entry"; # default Entry widget
    eval {
        # try loading the module, otherwise $Entry is left to the value "Entry"
	require Tk::HistEntry;
	$Entry = "SimpleHistEntry";
    };
    $entry = $mw->$Entry(-textvariable => \$res)->pack;
    $entry->bind("<Return>" => sub {
                                   # check whether the historyAdd method is
		                   # known to the widget
		                   if ($entry->can('historyAdd')) {
				       $entry->historyAdd;
				   }
                               });

In this approach the history lives in an array variable. Here the
entry widget does not need to be permanent, that is, it is possible to
destroy the containing window and restore the history again:

    $Entry = "Entry";
    eval {
	require Tk::HistEntry;
        $Entry = "HistEntry";
    };
    $entry = $mw->$Entry(-textvariable => \$res)->pack;
    if ($entry->can('history') && @history) {
	$entry->history(\@history);
    }

    # Later, after clicking on a hypothetical "Ok" button:
    if ($res ne "" && $entry->can('historyAdd')) {
        $entry->historyAdd($res);
	@history = $entry->history;
    }


=head1 BUGS/TODO

 - C-s/C-r do not work as nice as in gnu readline
 - use -browsecmd from Tk::BrowseEntry
 - use Tie::Array if present

=head1 AUTHOR

Slaven Rezic <slaven@rezic.de>

=head1 CREDITS

Thanks for Jason Smith <smithj4@rpi.edu> and Benny Khoo
<kkhoo1@penang.intel.com> for their suggestions. The auto-completion
code is stolen from Tk::IntEntry by Dave Collins
<Dave.Collins@tiuk.ti.com>.

=head1 COPYRIGHT

Copyright (c) 1997, 2000, 2001, 2003, 2008, 2016 Slaven Rezic. All rights reserved.
This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
