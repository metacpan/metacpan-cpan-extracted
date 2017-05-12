package Tk::Pod::Search;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '5.16';

use Carp;
use Config qw(%Config);
use File::Spec;
use Tk::Frame;

Construct Tk::Widget 'PodSearch';
@ISA = 'Tk::Frame';

my $searchfull_history;

sub Populate {
    my ($cw, $args) = @_;

    my $Entry;
    eval {
	require Tk::HistEntry;
	$Entry = "HistEntry";
    };
    if ($@) {
	require Tk::BrowseEntry;
	$Entry = "BrowseEntry";
    }

    my $l = $cw->Scrolled('Listbox',-width=>40,-scrollbars=>$Tk::platform eq 'MSWin32'?'e':'w');
    require Tk::Pod::Styles;
    my $fontsize = Tk::Pod::Styles::standard_font_size($l);
    $l->configure(-font => "courier $fontsize");
    #xxx BrowseEntry V1.3 does not honour -label at creation time :-(
    #my $e = $cw->BrowseEntry(-labelPack=>[-side=>'left'],-label=>'foo',
	#-listcmd=> ['_logit', 'list'],
	#-browsecmd=> ['_logit', 'browse'],
	#);
    my $f = $cw->Frame;
    my $e = $f->$Entry();
    if ($e->can('history') && $searchfull_history) {
	$e->history($searchfull_history);
    }
    my $s = $f->Label();
    my $b = $f->Button(-text=>'OK',-command=>[\&_search,$e,$cw,$l]);

    $l->pack(-fill=>'both', -side=>'top',  -expand=>1);
    $f->pack(-fill => "x", -side => "top");
    $s->pack(-anchor => 'e', -side=>'left');
    $e->pack(-fill=>'x', -side=>'left', -expand=>1);
    $b->pack(-side => 'left');

    my $current_path = delete $args->{-currentpath};
    $cw->{RestrictPod} = undef;
    my $cb;
    if (defined $current_path && $current_path ne "") {
	$cb = $cw->Checkbutton(-variable => \$cw->{RestrictPod},
			       -text => "Restrict to $current_path",
			       -anchor => "w",
			       -onvalue => $current_path,
			       -offvalue => undef,
			      )->pack(-fill => "x",
				      -side => "top",
				     );
    }

    $cw->Advertise( 'entry'	=> $e->Subwidget('entry')   );
    $cw->Advertise( 'listbox'	=> $l->Subwidget('listbox') );
    $cw->Advertise( 'browse'	=> $e);
    $cw->Advertise( 'restrict'  => $cb) if $cb;

    $cw->Delegates(
		'focus' => $cw->Subwidget('entry'),
		);

    $cw->ConfigSpecs(
		-label =>	[{-text=>$s}, 'label',    'Label',    'Search:'],
		-indexdir =>	['PASSIVE',   'indexDir', 'IndexDir', undef],
		-command =>	['CALLBACK',  undef,      undef,      undef],
		-search =>	['METHOD',    'search',   'Search',   ""],
		'DEFAULT' =>	[ $cw ],
		);

    foreach (qw/Return space 1/) {
	$cw->Subwidget('listbox')->bind("<$_>", [\&_load_pod, $cw]);
    }
    $cw->Subwidget('entry')->bind('<Return>',[$b,'invoke']);

    undef;
}

sub addHistory {
    my ($w, $obj) = @_;

    my $entry_or_browse = $w->Subwidget('browse');
    if ($entry_or_browse->can('historyAdd')) {
	$entry_or_browse->historyAdd($obj);
	$searchfull_history = [ $entry_or_browse->history ];
    } else {
	$entry_or_browse->insert(0,$obj);
    }
}

sub _logit { print "logit=|", join('|',@_),"|\n"; }

sub search {
    my $cw = shift;
    my $e = $cw->Subwidget('entry');
    if (@_) {
	my $search = shift;
	$search = join(' ', @$search) if ref($search) eq 'ARRAY';
        $e->delete(0,'end');
        $e->insert(0,$search);
        return undef;
    } else {
	return $e->get;
    }
}

sub search_as_regexp {
    my $cw = shift;
    my $search = $cw->search;
    my @search = split ' ', $search;
    if (@search) {
	require Text::English;
	my $rx = join("|", map { quotemeta } Text::English::stem(@search));
	if (@search > 1) {
	    $rx = '(' . $rx . ')';
	}
	$rx;
    } else {
	'';
    }
}

sub _load_pod {
    my $l = shift;
    my $cw = shift;

    my $pod = pretty2path( $l->get(($l->curselection)[0]));

    $cw->Callback('-command', $pod, -searchterm => $cw->search_as_regexp());
}


sub _search {
    my $e = shift;
    my $w = shift;
    my $l = shift;

    my $find = ref $e eq 'Tk::BrowseEntry' ? $e->Subwidget("entry")->get : $e->get;
    $w->addHistory($find) if $find ne '';

    my %args;
    if ($w->{RestrictPod}) {
	$args{-restrictpod} = $w->{RestrictPod};
    }

    #xxx: always open/close DBM files???
    my $idx;
    eval {
        require Tk::Pod::Search_db;
	$idx = Tk::Pod::Search_db->new($w->{Configure}{-indexdir});
    };
    if ($@) {
	my $err = $@;
	$e->messageBox(-icon => 'error',
		       -title => 'perlindex error',
		       -message => <<EOF);
Can't create Tk::Pod::Search_db object:
Is perlindex (aka Text::English) installed
and did you run 'perlindex -index'?
EOF
	die $err;
    }
    my @raw_hits = $idx->searchWords($find, %args);
    if (@raw_hits) {
	$l->delete(0,'end');
	my @hits;
	my $max_length;
	for my $raw_hit (@raw_hits) {
	    my($module, $path) = split_path($raw_hit->{path});
	    push @hits, [$raw_hit->{termhits}, $raw_hit->{score}, $module, $path];
	    $max_length = length $module if !defined $max_length || length $module > $max_length;
	}
	my $need_termhits = $hits[0]->[0] > 1;
	for my $hit (@hits) {
	    my($termhits, $quality, $module, $path) = @$hit;
	    $l->insert('end', sprintf(($need_termhits ? "%d " : "") . "%6.3f  %-${max_length}s (%s)",
				      ($need_termhits ? $termhits : ()), $quality, $module, $path)
		      );
        }
	$l->see(0);
	$l->activate(0);
	$l->selectionSet(0);
	$l->focus;
    } else {
	my $msg = "No Pod documentation in Library matches: '$find'";
	$e->messageBox(-icon => "error",
		       -title => "No match",
		       -message => $msg);
	die $msg;
    }
}

# Converts  /where/ever/it/it/Mod/Sub/Name.pm
# to	    ("Mod/Sub/Name.pm", "/where/ever/it/is")
# .  Assumes that module subdirectories
# start with an upper case char. (xxx: Better solution
# when perlindex gives more infos.

# XXX Note that split_path is also used in Search_db.pm
sub split_path {
    my($path, $max_length) = @_;

    my @inc = sort { length($b) <=> length($a) } (@INC, $Config{scriptdir});
    for my $inc (@inc) {
	# XXX Nicer solution without hardcoded directory separators needed!
	if (index($path, "$inc/") >= 0) {
	    return (substr($path, length($inc)+1), $inc);
	}
	if ($^O eq 'MSWin32' && index($path, "$inc\\") >= 0) {
	    return (substr($path, length($inc)+1), $inc);
	}
    }

    # Rarely this fallback should be used:

    my($volume, $directories, $file) = File::Spec->splitpath($path);
    my @path = (File::Spec->splitdir($directories), $file);

    # Guess the separator point between path and module/script name
    my $path_i;
    for($path_i = $#path; $path_i >= 0; $path_i--) {
	if ($path[$path_i] ne '' && $path[$path_i] !~ /^[A-Z]/) {
	    last;
	}
    }

    # Scripts are usually lowercase, so the above logic does not work.
    # Fix it:
    if ($path_i == $#path) {
	$path_i--;
    }

    # Remove empty directories from the end (a relict from
    # splitpath/splitdir)
    my @dirs = @path[0 .. $path_i];
    while(@dirs && $dirs[-1] eq '') { pop @dirs }

    # Remove empty directories from the beginning (also a relict from
    # splitpath/splitdir)
    my @moddirs = @path[$path_i+1 .. $#path];
    while(@moddirs && $moddirs[0] eq '') { shift @moddirs }

    my($dirpart,$modpart) = (File::Spec->catpath($volume, File::Spec->catfile(@dirs), ''),
			     File::Spec->catfile(@moddirs));
    return ($modpart, $dirpart);
}

sub pretty2path {
    local($_) = shift;
    /([^\s]+) \s+\( (.*) \)/x;
    File::Spec->catfile($2, $1);
}

#$path = '/where/ever/it/is/Tk/Pod.pm';	print "orig|",$path, "|\n";
#$nice = path2pretty $path;		print "nice|",$nice, "|\n";
#$path =  pretty2path $nice;		print "path|",$path, "|\n";


1;
__END__

=head1 NAME

Tk::Pod::Search - Widget to access perlindex Pod full text index

=for section General Purpose Widget

=head1 SYNOPSIS

    use Tk::Pod::Search;
    ...
    $widget = $parent->PodSearch( ... );
    ...
    $widget->configure( -search => WORDS_TO_SEARCH );


=head1 DESCRIPTION

GUI interface to the full Pod text indexer B<perlindex>.

=head1 OPTIONS

=over 4

=item B<Class:> Search

=item B<Member:> search

=item B<Option:> -search

Expects a list of words (or a whitespace separated list).

=item B<Class:> undef

=item B<Member:> undef

=item B<Option:> -command

Defines a call back that is called when the use selects
a Pod file. It gets the full path name of the Pod file
as argument.

=back


=head1 METHODS

=over 4

=item I<$widget>->B<method1>I<(...,?...?)>

=back


=head1 SEE ALSO

L<Tk::Pod::Text>, L<tkpod>, L<perlindex>, L<Tk::Pod>, L<Tk::Pod::Search_db>

=head1 KEYWORDS

widget, tk, pod, search, full text

=head1 AUTHOR

Achim Bohnet <F<ach@mpe.mpg.de>>

Current maintainer is Slaven ReziE<0x0107> <F<slaven@rezic.de>>.

Copyright (c) 1997-1998 Achim Bohnet. All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

