package Tk::More;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '5.09';

use Tk qw(Ev);
use Tk::Derived;
use Tk::Frame;
@ISA = qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'More';

sub Populate {
    my ($cw, $args) = @_;

    require Tk::ROText;
    require Tk::LabEntry;

    $cw->SUPER::Populate($args);

    my $Entry = 'LabEntry';
    my @Entry_args;
    if (eval { die "Not yet";
	       require Tk::HistEntry;
	       Tk::HistEntry->VERSION(0.37);
	       1;
	   }) {
	$Entry = 'HistEntry';
    } else {
	@Entry_args = (-labelPack=>[-side =>'left']);
    }

    my $search;
    my $e = $cw->$Entry(
		@Entry_args,
		-textvariable => \$search,
		-relief => 'flat',
		-state => 'disabled',
		)->pack(-side=>'bottom', -fill => 'x', -expand=>'no');
    $cw->Advertise('searchentry' => $e);

    my $t = $cw->ROText(-cursor=>undef)->pack(-fill => 'both' , -expand => 'yes');
    $cw->Advertise('text' => $t);
    $t->tagConfigure('search', -foreground => 'red');

    # reorder bindings: private widget bindings first
    $t->bindtags([$t, grep { $_ ne $t->PathName } $t->bindtags]);

    $t->bind('<Key-slash>',    [$cw, 'Search', 'Next']);
    $t->bind('<Key-question>', [$cw, 'Search', 'Prev']);
    $t->bind('<Key-n>',        [$cw, 'ShowMatch', 'Next']);
    $t->bind('<Key-N>',        [$cw, 'ShowMatch', 'Prev']);

    $t->bind('<Key-g>', $t->bind(ref($t),'<Control-Home>'));
    $t->bind('<Key-G>', $t->bind(ref($t),'<Control-End>'));
    $t->bind('<Home>',  $t->bind('<Key-g>'));
    $t->bind('<End>',   $t->bind('<Key-G>'));

    $t->bind('<Key-j>', [$cw, 'scroll', $t,  1, 'line']);
    $t->bind('<Down>',  [$cw, 'scroll', $t,  1, 'line']);
    $t->bind('<Key-k>', [$cw, 'scroll', $t, -1, 'line']);
    $t->bind('<Up>',    [$cw, 'scroll', $t, -1, 'line']);

    $t->bind('<Key-f>', [$cw, 'scroll', $t,  1, 'page']);
    $t->bind('<Next>',  [$cw, 'scroll', $t,  1, 'page']);
    $t->bind('<Key-b>', [$cw, 'scroll', $t, -1, 'page']);
    $t->bind('<Prior>', [$cw, 'scroll', $t, -1, 'page']);

    $t->bind('<Right>', [sub {
		 return if ($_[1] =~ /(Alt|Meta)-/);
		 $t->xview('scroll',  1, 'units'); Tk->break;
	     }, Ev('s')]);
    $t->bind('<Left>',  [sub {
		 return if ($_[1] =~ /(Alt|Meta)-/);
		 $t->xview('scroll', -1, 'units'); Tk->break;
	     }, Ev('s')]);

    $t->bind('<Return>', ['yview', 'scroll',  1, 'units']);
    $t->bind('<Key-d>',  [$cw, 'scroll', $t,  1, 'halfpage']);
    $t->bind('<Key-u>',  [$cw, 'scroll', $t, -1, 'halfpage']);

    $t->bind('<Key-h>', sub { $cw->Callback(-helpcommand => $t) });

    $e->bind('<Return>',[$cw, 'SearchText']);
    $e->bind('<Escape>',[$cw, 'SearchTextEscape']);

    foreach my $mod (qw(Alt Meta)) {
	foreach my $key (qw(n N g G j k f b d u h)) {
	    $t->bind("<$mod-Key-$key>" => \&Tk::NoOp);
	}
    }

    # This was formerly possible, but is now invalid:
    delete $args->{-font} if !defined $args->{-font};

    $cw->Delegates('DEFAULT'   => $t,
		   'Search'    => 'SELF',
		   'ShowMatch' => 'SELF',
		   'Load'      => 'SELF',
		   'LoadFH'    => 'SELF',
		   'AddQuitBindings' => 'SELF',
		  );

    $cw->{DIRECTION} = "Next";

    $cw->ConfigSpecs(
		-insertofftime => [$t, qw(insertOffTime OffTime         0)], # no blinking
		-insertwidth   => [$t, qw(insertWidth   InsertWidth     0)], # invisible
		-padx          => [$t, qw(padX          Pad            5p)],
		-pady          => [$t, qw(padY          Pad            5p)],
		-searchcase    => ['PASSIVE', 'searchCase', 'SearchCase', 1],
		-helpcommand   => ['CALLBACK', undef, undef, undef],
		-background    => ['PASSIVE'],# XXX ignore -background, so optionAdd works.... still decide
		-font	       => [$t, 'fixedFont', 'FixedFont', 'Courier 10'],
		'DEFAULT'      => [$t]
		);

    $cw;
}


sub Search {
    my ($cw, $direction) = @_;
    $cw->{DIRECTION} = $direction;
    my $e = $cw->Subwidget('searchentry');
    $e->configure(-label => 'Search ' . ($direction eq 'Next'?'forward:':'backward:') );
    $e->configure(-relief=>'sunken',-state=>'normal');
    $e->selectionRange(0, "end");
    $e->focus;
}

sub SearchText {
    my ($cw, %args) = @_;
    my($t, $e) = ($cw->Subwidget('text'), $cw->Subwidget('searchentry'));
    $cw->{DIRECTION} = $args{-direction} if $args{-direction};
    my $searchterm;
    if (defined $args{-searchterm}) {
	$searchterm = $args{-searchterm};
	$ {$e->cget('-textvariable')} = $searchterm;
    } else {
	$e->historyAdd if ($e->can('historyAdd'));
	$searchterm = $e->get;
    }
    unless ($cw->search_text($t, $searchterm, 'search') ) {
	$cw->bell unless $args{-quiet};
    }
    $e->configure(-label=>'');
    $t->see('@0,0');
    $cw->ShowMatch($cw->{DIRECTION}, -firsttime => 1) unless $args{-onlymatch};
    $t->focus;
    $e->configure(-relief=>'flat', -state=>'disabled');
}

sub SearchTextEscape {
    my ($cw, %args) = @_;
    my($t, $e) = ($cw->Subwidget('text'), $cw->Subwidget('searchentry'));
    $e->configure(-label=>'');
    $t->focus;
    $e->configure(-relief=>'flat', -state=>'disabled');
}

sub ShowMatch {
    my ($cw, $method, %args) = @_;
    my $firsttime = $args{-firsttime};

    my $t = $cw->Subwidget('text');
    if ($cw->{DIRECTION} ne 'Next') {
	$method = 'Next' if $method eq 'Prev';
	$method = 'Prev' if $method eq 'Next';
    }
    my $cur = (($method eq 'Prev' && !$firsttime) ||
	       ($method eq 'Next' &&  $firsttime)
	       ? $t->index('@0,0')
	       : $t->index('@0,'.$t->height));
    $method = "tag". $method . "range"; # $method: Next or Prev
    my @ins = $t->$method('search',$cur);
    unless (@ins) {
	# hack: Maybe the search was not performed yet? (e.g. after loading
	# a new page but with the same search term)
	my $e = $cw->Subwidget('searchentry');
	if (!defined $ {$e->cget('-textvariable')}) {
	    return;
	}
	$cw->SearchText(-searchterm => $ {$e->cget('-textvariable')},
			-onlymatch => 1);
	@ins = $t->$method('search',$cur);
	return if !@ins;
    }
    @ins = reverse @ins unless $method eq 'tagNextrange';
    $t->see($ins[0]);
    $ins[0];
}

# Load copied from TextUndo (xxx yy marks changes)
sub Load
{
 my ($text,$file,%args) = @_;
 if (open(FILE,"<$file"))
  {
   $text->LoadFH(\*FILE,%args);
   close(FILE);
  }
 else
  {
   $text->messageBox(-message => "Cannot open $file: $!\n");
   die;
  }
}

sub LoadFH
{
 my ($text,$fh,%args) = @_;
 my $encoding = delete $args{-encoding};
 die "Unhandled arguments: " . join(" ", %args) if %args;
 if ($encoding)
  {
   binmode $fh, ":encoding($encoding)";
  }
 $text->MainWindow->Busy;
 $text->delete('1.0','end');
 #yy delete $text->{UNDO};
 while (<$fh>)
  {
   $text->insert('end',$_);
  }
 #yy $text->{FILE} = $file;
 $text->markSet('insert', '@1,0');
 $text->MainWindow->Unbusy;
}

# search_text copied from demo search.pl (modified)
sub search_text {

    # The utility procedure below searches for all instances of a given
    # string in a text widget and applies a given tag to each instance found.
    # Arguments:
    #
    # w -       The window in which to search.  Must be a text widget.
    # string -  string to search for.  The search is done
    #           using exact matching only;  no special characters.
    # tag -     Tag to apply to each instance of a matching string.

    my($w, $t, $string, $tag) = @_;

    return unless length($string);

    $w->tag('remove',  $tag, qw/0.0 end/);
    my($current, $length, $found) = ('1.0', 0, 0);

    my $insert = $w->index('insert');
    my @search_args = ('-regexp');
    push @search_args, '-nocase' unless ($w->cget('-searchcase'));
    eval {
	while (1) {
	    $current = $w->search(@search_args, -count => \$length, '--', $string, $current, 'end');
	    last if not $current;
	    $found = 1;
	    $w->tag('add', $tag, $current, "$current + $length char");
	    $current = $w->index("$current + $length char");
	}
	$w->markSet('insert', $insert);
    };
    if ($@) {
	$w->messageBox(-icon => "error",
		       -message => $@,
		      );
    }
    $found;
} # end search_text

sub scroll {
    my($w,$t,$no,$unit) = @_;
    if ($unit =~ /^line/) {
	$t->yview('scroll', $no, 'units');
    } else {
	my($y1,$y2) = $t->yview;
	my $amount;
	if ($unit =~ /^halfpage/) {
	    $amount = ($y2-$y1)/2;
	} elsif ($unit =~ /^page/) {
#  	    if ($no == -1) {
#  		# loop until top-most line is invisible
#  		my $inx = $t->index('@0,0');
#  my $i=0;
#  		while ($t->bbox($inx)) {
#  		    $t->yviewScroll(-1,'units');
#  		    last if ($i++>1000);
#  		}
#  		goto XXX;
#  	    }
	    $amount = ($y2-$y1);
	} else {
	    die "Unknown unit $unit";
	}
#warn "$y1 $y2 $amount";
	$y1 += ($no * $amount);
	if ($no > 0) {
	    $y1 = 1.0 if ($y1 > 1.0);
	} else {
	    $y1 = 0.0 if ($y1 < 0.0);
	}
	$t->yviewMoveto($y1);
    }
    #XXX:
    Tk->break;
}

sub AddQuitBindings {
    my($more) = @_;
    $more->bind("<q>" => sub { $more->toplevel->destroy });
    $more->bind("<Control-q>" => sub { $more->toplevel->destroy });
}

#package Tk::More::Status;
#
## Implement status bar
#

1;

__END__

=head1 NAME

Tk::More - a 'more' or 'less' like text widget

=head1 SYNOPSIS

    use Tk::More;

    $more = $parent->More(...text widget options ...);
    $more->Load(FILENAME);

=head1 DESCRIPTION

B<Tk::More> is a readonly text widget with additional key bindings as
found in UNI* command line tools C<more> or C<less>. As in C<more> an
additional status/command line is added at the bottom.

=head1 ADDITIONAL BINDINGS

=over 4

=item Key-g or Home

goto beginning of file

=item Key-G or End

goto end of file

=item Key-f or Next

forward screen

=item Key-b or Prior

backward screen

=item Key-k or Up

up one line

=item Key-j or Down

down one line

=item Key-/

search forward

=item Key-?

search backward

=item Key-n

find next match

=item Key-N

find previous match

=item Key-u

up half screen

=item Key-d

down half screen

=item Key-Return

down one line

=item Key-h

invoke help window

=back

=head1 OPTIONS

=over

=item Name:     B<fixedFont>

=item Class:    B<FixedFont>

=item Switch:   B<-font>

Set the font of the viewer widget. This is by default a fixed font.

=item Name:     B<searchCase>

=item Class:    B<SearchCase>

=item Switch:   B<-searchcase>

Set if searching should be done case-insensitive. Defaults to true.

=item Switch:   B<-helpcommand>

Sets the command for the "h" (help) key.

=back

=head1 METHODS

=over

=item Load($file, %args)

Load I<$file> into the widget. I<%args> may be one of the following

=over

=item -encoding => I<$encoding>

Assume the encoding of the file to be I<$encoding>. If none is given,
then assume no encoding (which is equivalent to iso-8859-1).

=back

=item AddQuitBindings

Convenience method to add the bindinds Key-q and Control-Key-q to
close the Toplevel window containing this More widget.

=back

=head1 BUGS

Besides that most of more bindings are not implemented. This bugs
me most (high to low priority):

* better status line implementation

* Cursor movement: up/down move displayed area regardless where
  insert cursor is

* add History, Load, Search (also as popup menu)

=head1 SEE ALSO

L<Tk::ROText|Tk::ROText>, L<more(1)>, L<tkmore>, L<less(1)>

=head1 AUTHOR

Achim Bohnet <F<ach@mpe.mpg.de>>

Currently maintained by Slaven Rezic <F<slaven@rezic.de>>.

Copyright (c) 1997-1998 Achim Bohnet. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
