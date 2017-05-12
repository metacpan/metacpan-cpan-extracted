# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2001,2004,2007,2008,2012,2015 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::Pod::Tree;

=head1 NAME

Tk::Pod::Tree - list Pod file hierarchy


=head1 SYNOPSIS

    use Tk::Pod::Tree;

    $parent->PodTree;

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name: B<-showcommand>

Specifies a callback for selecting a Pod module (Button-1 binding).

=item Name: B<-showcommand2>

Specifies a callback for selecting a Pod module in a different window
(Button-2 binding).

=item Name: B<-usecache>

True, if a cache of Pod modules should be created and used. The
default is true.

=back

=head1 DESCRIPTION

The B<Tk::Pod::Tree> widget shows all available Perl Pod documentation
in a tree.

=cut

use strict;
use vars qw($VERSION @ISA @POD %EXTRAPODDIR $ExtraFindPods);
$VERSION = '5.11';

use base 'Tk::Tree';

use File::Spec;

use Tk::Pod::FindPods;
use Tk::ItemStyle;
use Tk qw(Ev);

Construct Tk::Widget 'PodTree';

my $search_history;

use constant SEP => "/";

BEGIN { @POD = @INC }

BEGIN {  # Make a DEBUG constant very first thing...
  if(defined &DEBUG) {
  } elsif(($ENV{'TKPODDEBUG'} || '') =~ m/^(\d+)/) { # untaint
    my $debug = $1;
    *DEBUG = sub () { $debug };
  } else {
    *DEBUG = sub () {0};
  }
}

######################################################################
use Class::Struct;
struct '_PodEntry' => [
    'uri'  => "\$",
    'type' => "\$",
    'name' => "\$",
];
sub _PodEntry::create {
    my $e = shift->new;
    $e->uri(shift);
    $e;
}
sub _PodEntry::file {
    my $uri = shift->uri;
    local $^W = 0;
    ($uri =~ /^file:(.*)/)[0];
}
######################################################################

sub Dir {
    my $class = shift;
    unshift @POD, @_;
    $EXTRAPODDIR{$_} = 1 for (@_);
}

sub ClassInit {
    my ($class,$mw) = @_;
    $class->SUPER::ClassInit($mw);
    $mw->bind($class, '<3>', ['PostPopupMenu', Ev('X'), Ev('Y')]  )
	if $Tk::VERSION > 800.014;

    my $set_anchor_and_sel = sub {
	my($w, $ent) = @_;
	$w->anchorSet($ent);
	$w->selectionClear;
	$w->selectionSet($ent);
    };

    # Force callbacks to be treated as methods. This is done by putting
    # the $widget reference at the beginning of the Tk::Callback array
    my $inherited_cb = sub {
	my($w, $cb) = @_;
	if (UNIVERSAL::isa($cb, "Tk::Callback")) {
	    my $new_cb = bless [$w, @$cb], 'Tk::Callback';
	    $new_cb->Call;
	} else {
	    # XXX OK?
	    $cb->($w);
	}
    };

    # Add functionality to some callbacks:
    my $orig_home = $mw->bind($class, "<Home>");
    $mw->bind($class, "<Home>" => sub {
		  my $w = shift;
		  $inherited_cb->($w, $orig_home);
		  $set_anchor_and_sel->($w, ($w->infoChildren)[0]);
	      });
    my $orig_end = $mw->bind($class, "<End>");
    $mw->bind($class, "<End>" => sub {
		  my $w = shift;
		  $inherited_cb->($w, $orig_end);
		  # get last opened entry
		  my $last = ($w->infoChildren)[-1];
		  while ($w->getmode($last) eq "close" && $w->infoChildren($last)) {
		      $last = ($w->infoChildren($last))[-1];
		  }
		  $set_anchor_and_sel->($w, $last);
	      });
    my $orig_prior = $mw->bind($class, "<Prior>");
    $mw->bind($class, "<Prior>" => sub {
		  my $w = shift;
		  $inherited_cb->($w, $orig_prior);
		  my $ent = $w->nearest(10); # XXX why 10?
		  return if !defined $ent;
		  $set_anchor_and_sel->($w, $ent);
	      });
    my $orig_next = $mw->bind($class, "<Next>");
    $mw->bind($class, "<Next>" => sub {
		  my $w = shift;
		  $inherited_cb->($w, $orig_next);
		  my $ent = $w->nearest($w->height - 10); # XXX why 10?
		  return if !defined $ent;
		  $set_anchor_and_sel->($w, $ent);
	      });
}

sub Populate {
    my($w,$args) = @_;

    $args->{-separator} = SEP;

    my $show_command = sub {
	my($w, $cmd, $ent) = @_;

	my $data = $w->info('data', $ent);
	if ($data) {
	    $w->Callback($cmd, $w, $data);
	}
    };

    my $show_command_mouse = sub {
	my $w = shift;
	my $cmd = shift || '-showcommand';

	my $Ev = $w->XEvent;
	my $ent = $w->GetNearest($Ev->y, 1);
	return unless (defined $ent and length $ent);

	my @info = $w->info('item',$Ev->x, $Ev->y);
	if (defined $info[1] && $info[1] eq 'indicator') {
	    $w->Callback(-indicatorcmd => $ent, '<Arm>');
	    return;
	}

	$show_command->($w, $cmd, $ent);
    };

    my $show_command_key = sub {
	my $w = shift;
	my $cmd = shift || '-showcommand';

	my($ent) = $w->selectionGet;
	return unless (defined $ent and length $ent);

	if ($w->info('children', $ent)) {
	    $w->open($ent);
	}

	$show_command->($w, $cmd, $ent);
    };

    $w->bind("<1>" => sub { $show_command_mouse->(shift) });
    foreach (qw/space Return/) {
  	$w->bind("<$_>" => sub { $show_command_key->(shift) });
    }

    foreach (qw/2 Shift-1/) {
	$w->bind("<$_>" => sub { $show_command_mouse->(shift, '-showcommand2') });
    }

    $w->SUPER::Populate($args);

    $w->{Style} = {};
    $w->{Style}{'core'} = $w->ItemStyle('imagetext',
					-foreground => '#006000',
					-selectforeground => '#006000',
				       );
    $w->{Style}{'site'} = $w->ItemStyle('imagetext',
					-foreground => '#702000',
					-selectforeground => '#702000',
				       );
    $w->{Style}{'vendor'} = $w->ItemStyle('imagetext',
					  -foreground => '#856b48',
					  -selectforeground => '#856b48',
					 );
    $w->{Style}{'cpan'} = $w->ItemStyle('imagetext',
					-foreground => '#000080',
					-selectforeground => '#000080',
				       );
    $w->{Style}{'folder'} = $w->ItemStyle('imagetext',
					  -foreground => '#606060',
					  -selectforeground => '#606060',
					 );
    $w->{Style}{'script'} = $w->{Style}{'site'};
    $w->{Style}{'local dirs'} = $w->{Style}{'site'};

    my $m = $w->Menu(-tearoff => $Tk::platform ne 'MSWin32');
    eval { $w->menu($m) }; warn $@ if $@;
    $m->command(-label => 'Reload', -command => sub {
		    $w->toplevel->Busy(-recurse => 1);
		    eval {
			$w->Fill(-nocache => 1);
		    };
		    my $err = $@;
		    $w->toplevel->Unbusy(-recurse => 1);
		    die $err if $err;
		});
    $m->command(-label => 'Search...', -command => [$w, 'search_dialog']);

    $w->Component('Label' => 'UpdateLabel',
		  -text => "Updating..."
		 );

    $w->ConfigSpecs(
	-showcommand  => ['CALLBACK', undef, undef, undef],
	-showcommand2 => ['CALLBACK', undef, undef, undef],
	-usecache     => ['PASSIVE', undef, undef, 1],
    );
}

=head1 WIDGET METHODS

=over 4

=item I<$tree>-E<gt>B<Fill>(?I<-nocache =E<gt> 1>?, ?I<-forked =E<gt> 0|1>?, ?I<-fillcb =E<gt> ...>?)

Find Pod modules and fill the tree widget. If I<-nocache> is
specified, then no cache will be used for loading.

A cache of Pod modules is written unless the B<-usecache>
configuration option of the widget is set to false.

If C<-forked> is specified, then searching for Pods is done in the
background, if possible. Note that the default is currently
unspecified.

A callback may be specified with the C<-fillcb> option and will be
called after the tree is filled.

=cut

sub Fill {
    my $w = shift;
    my(%args) = @_;

    if ($w->{FillPid}) {
	warn "Forked filling currently running.\n";
	return;
    }

    $w->delete("all");
    delete $w->{Pods};
    $w->{Filled} = 0;

    my $forked = delete $args{-forked};
    if (!defined $forked) {
	$forked = 1; # by default we try -forked
    }
    if ($forked) {
	if (!eval { require Storable; 1 }) {
	    warn "Cannot fork, Storable is missing.\n";
	    $forked = 0;
	} elsif ($^O eq 'MSWin32' || $^O eq 'cygwin') {
	    warn "Cannot fork on Windows systems.\n";
	    $forked = 0;
	}
    }

    if ($forked) {
	require POSIX;
	my($rdr,$wtr);
	pipe($rdr,$wtr);
	$w->{FillPid} = fork;
	if (!defined $w->{FillPid}) {
	    warn "Cannot fork: $!";
	    # fall back to non-forked operation
	} elsif (!$w->{FillPid}) {
	    # child
	    close $rdr;
	    my $pods = $w->_FillFind(%args);
	    my $serialized = Storable::freeze($pods);
	    print $wtr $serialized
		or die "While writing to pipe: $!";
	    close $wtr
		or die "While closing pipe: $!";
	    POSIX::_exit(0);
	} else {
	    # parent
	    close $wtr;
	    $w->Subwidget('UpdateLabel')->place('-x' => 5, '-y' => 5);
	    $w->fileevent($rdr, 'readable',
			  sub {
			      local $/;
			      my $serialized = <$rdr>;
			      my $pods = Storable::thaw($serialized);
			      $w->_FillDone($pods, $args{'-fillcb'});
			      $w->fileevent($rdr, 'readable', '');
			      $w->Subwidget('UpdateLabel')->placeForget;
			      waitpid $w->{FillPid}, &POSIX::WNOHANG; # zombie reaping
			      $w->{FillPid} = undef;
			  });
	    return;
	}
    }

    # non-forked
    my $pods = $w->_FillFind(%args);
    $w->_FillDone($pods, $args{'-fillcb'});
}

sub _FillFind {
    my($w, %args) = @_;

    my $usecache = ($w->cget('-usecache') && !$args{'-nocache'});

    my $FindPods = Tk::Pod::FindPods->new;
    my $pods = $FindPods->pod_find(-categorized => 1,
				   -usecache => $usecache,
				  );

    if (keys %EXTRAPODDIR) {
	$ExtraFindPods = Tk::Pod::FindPods->new unless $ExtraFindPods;
	my $extra_pods = $ExtraFindPods->pod_find
	    (-categorized => 0,
	     -category => "local dirs",
	     -directories => [keys %EXTRAPODDIR],
	     -usecache => 0,
	    );
	while(my($k,$v) = each %$extra_pods) {
	    $pods->{$k} = $v;
	}
    }

    if ($w->cget('-usecache') && !$FindPods->has_cache) {
	$FindPods->WriteCache;
    }

    $pods;
}

sub _FillDone {
    my($w, $pods, $fillcb) = @_;

    my %category_seen;

    foreach (['perl',   'Perl language'],
	     ['pragma', 'Pragmata'],
	     ['mod',    'Modules'],
	     ['script', 'Scripts'],
	     keys(%$pods),
	    ) {
	my($category, $title) = (ref $_ ? @$_ : ($_, $_));
	next if $category_seen{$category};

	$w->add($category, -text => $title);

	my $hash = $pods->{$category};
	foreach my $pod (sort keys %$hash) {
	    my $treepath = $category . SEP . $pod;
	    (my $title = $pod) =~ s|/|::|g;
	    $w->_add_parents($treepath);

	    my $loc = $category =~ m{^(script|local dirs)$} ? $category : Tk::Pod::FindPods::module_location($hash->{$pod});
	    my $is = $w->{Style}{$loc};
	    my @entry_args = ($treepath,
			      -text => $title,
			      -data => _PodEntry->create($hash->{$pod}),
			      ($is ? (-style => $is) : ()),
			     );
	    if ($w->info('exists', $treepath)) {
		$w->entryconfigure(@entry_args);
	    } else {
		$w->add(@entry_args);
	    }
	}

	$category_seen{$category}++;
    }

    for(my $entry = ($w->info('children'))[0];
	   defined $entry && $entry ne "";
	   $entry = $w->info('next', $entry)) {
	if ($w->info('children', $entry) ||
	    $w->entrycget($entry, -text) eq 'perlfunc') {
	    $w->folderentry($entry);
	} else {
	    $w->entryconfigure($entry, -image => $w->Getimage("file"));
	    $w->hide('entry', $entry);
	}
    }

    $w->{Pods} = $pods;
    $w->{Filled}++;

    if ($fillcb) {
	$fillcb->();
    }
}

sub folderentry {
    my($w, $entry) = @_;
    $w->entryconfigure($entry, -image => $w->Getimage("folder"));
    $w->setmode($entry, 'open');
    if ($entry =~ m|/|) { # XXX SEP?
	$w->hide('entry', $entry);
    }
}

sub Filled { shift->{Filled} }

sub _add_parents {
    my($w, $entry) = @_;
    (my $parent = $entry) =~ s|/[^/]*$||; # XXX SEP?
    return if $parent eq '';
    do{warn "XXX Should not happen: $entry eq $parent";return} if $parent eq $entry;
    return if $w->info('exists', $parent);
    my @parent = split SEP, $parent;
    my $title = join "::", @parent[1..$#parent];
    $w->_add_parents($parent);
    $w->add($parent, -text => $title,
	    ($w->{Style}{'folder'} ? (-style => $w->{Style}{'folder'}) : ()));
}

sub _open_parents {
    my($w, $entry) = @_;
    (my $parent = $entry) =~ s|/[^/]+$||; # XXX SEP?
    return if $parent eq '' || $parent eq $entry;
    $w->_open_parents($parent);
    $w->open($parent);
}

=item I<$tree>-E<gt>B<SeePath>($path)

Move the anchor/selection and view to the given C<$path> and open
subtrees to make the C<$path> visible, if necessary.

=cut

sub SeePath {
    my($w,$path) = @_;
    my $fs_case_tolerant =
	($^O eq 'MSWin32' ||
	 $^O eq 'darwin' || # case_tolerant=0 here!
	 (File::Spec->can("case_tolerant") && File::Spec->case_tolerant)
	);
    if ($^O eq 'MSWin32') {
	$path =~ s/\\/\//g;
    }
    if ($fs_case_tolerant) {
	$path = lc $path;
    }
    DEBUG and warn "Call SeePath with $path\n";
    return if !$w->Filled; # not yet filled
    my $pods = $w->{Pods};
    return if !$pods;

    my $see_treepath = sub {
	my $treepath = shift;
	$w->open($treepath);
	$w->_open_parents($treepath);
	$w->anchorSet($treepath);
	$w->selectionClear;
	$w->selectionSet($treepath);
	$w->see($treepath);
    };

    foreach my $category (keys %$pods) {
	foreach my $pod (keys %{ $pods->{$category} }) {
	    my $podpath = $pods->{$category}->{$pod};
	    $podpath = lc $podpath if $fs_case_tolerant;
	    if ($path eq $podpath) {
		my $treepath = $category . SEP . $pod;
		$see_treepath->($treepath);
		return 1;
	    }
	}
    }
    DEBUG and warn "SeePath: cannot find $path in tree\n";
    0;
}

sub GetCurrentPodPath {
    my $w = shift;
    my $sel_entry = ($w->selectionGet)[0];
    if (defined $sel_entry) {
	my @c = split m{/}, $sel_entry;
	shift @c;
	my $pod = join "::", @c;
	return $pod;
    }
}

sub search_dialog {
    my($w) = @_;
    my $t = $w->Toplevel(-title => "Search");
    $t->transient($w);
    $t->Label(-text => "Search module:")->pack(-side => "left");
    my $term;

    my $Entry = 'Entry';
    eval {
	require Tk::HistEntry;
	Tk::HistEntry->VERSION(0.40);
	$Entry = "HistEntry";
    };

    my $e = $t->$Entry(-textvariable => \$term)->pack(-side => "left");
    if ($e->can('history') && $search_history) {
	$e->history($search_history);
    }
    $e->focus;
    $e->bind("<Escape>" => sub { $t->destroy });

    my $do_search = sub {
	if ($e->can('historyAdd')) {
	    $e->historyAdd($term);
	    $search_history = [ $e->history ];
	}
	$w->search($term);
    };

    $e->bind("<Return>" => $do_search);

    {
	my $f = $t->Frame->pack(-fill => "x");
	Tk::grid($f->Button(-text => "Search",
			    -command => $do_search,
			   ),
		 $f->Button(-text => "Close",
			    -command => sub { $t->destroy },
			   ),
		 -sticky => "ew");
    }
}

sub search {
    my($w, $rx) = @_;
    return if $rx eq '';
    my($entry) = ($w->info('selection'))[0];
    if (!defined $entry) {
	$entry = ($w->info('children'))[0];
	return if (!defined $entry);
    }
    my $wrapped = 0;
    while(1) {
	$entry = $w->info('next', $entry);
	if (!defined $entry) {
	    if ($wrapped) {
		$w->bell;
		return;
	    }
	    $wrapped++;
	    $entry = ($w->info('children'))[0];
	}
	my $text = $w->entrycget($entry, '-text');
	if ($text =~ /$rx/i) {
	    my $p = $entry;
	    while(1) {
		$p = $w->info('parent', $p);
		if (defined $p) {
		    $w->open($p);
		} else {
		    last;
		}
	    }
	    $w->selectionClear;
	    $w->selectionSet($entry);
	    $w->anchorSet($entry);
	    $w->see($entry);
	    return;
	}
    }
}

sub IndicatorCmd {
    my($w, $ent, $event) = @_;
    my $podentry = $w->entrycget($ent, "-data");
    my $file = $podentry && $podentry->file;
    my $type = $podentry && $podentry->type;

    # Dynamically create children for perlfunc entry
    if (defined $type && $type =~ /^func_/ && !$w->info('children', $ent)) {
	require Pod::Functions;

	my $add_func = sub {
	    my($ent, $func) = @_;
	    my $podentry = _PodEntry->new;
	    $podentry->type("func");
	    $podentry->name($func);
	    (my $safe_name = $func) =~ s{[^a-zA-Z]}{_}g;
	    $ent = $ent . SEP . $safe_name;
	    $w->add($ent, -text => $func, -data => $podentry,
		    -style => $w->{Style}{'core'});
	};

	if ($type eq 'func_alphabetically') {
	    my $last_func;
	    my @funcs = map { if (!defined $last_func || $last_func ne $_) {
		                  $last_func = $_;
				  ($_);
			      } else {
				  $last_func = $_;
				  ();
			      }
			    }
                        sort
		        map { @{ $Pod::Functions::Kinds{$_} } }
		        keys %Pod::Functions::Kinds;
	    for my $func (@funcs) {
		$add_func->($ent, $func);
	    }
	} else { # by category
	    for my $cat (sort keys %Pod::Functions::Kinds) {
		(my $safe_name = $cat) =~ s{[^a-zA-Z]}{_}g;
		my $ent = $ent . SEP . $safe_name;
		$w->add($ent, -text => $cat, -style => $w->{Style}{'folder'});
		my $funcs = $Pod::Functions::Kinds{$cat};
		for my $func (@$funcs) {
		    $add_func->($ent, $func);
		}
	    }
	}
    } elsif (defined $file && $file =~ /perlfunc\.pod$/ && !$w->info('children', $ent)) {
	my($treepath, $podentry);

	$treepath = $ent . SEP. "func_alphabetically";
	$podentry = _PodEntry->new;
	$podentry->type("func_alphabetically");
	$w->add($treepath, -text => "Alphabetically", -data => $podentry,
		-style => $w->{Style}{'folder'});
	$w->folderentry($treepath);

	$treepath = $ent . SEP. "func_by_category";
	$podentry = _PodEntry->new;
	$podentry->type("func_by_category");
	$w->add($treepath, -text => "By category", -data => $podentry,
		-style => $w->{Style}{'folder'});
	$w->folderentry($treepath);
    }
    $w->SUPER::IndicatorCmd($ent, $event);
}

1;

__END__

=back

=head1 SEE ALSO

L<Tk::Tree>, L<Tk::Pod>, L<tkpod>, L<Tk::Pod::FindPods>.

=head1 AUTHOR

Slaven ReziE<0x107> <F<slaven@rezic.de>>

Copyright (c) 2001,2004 Slaven ReziE<0x107>.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
