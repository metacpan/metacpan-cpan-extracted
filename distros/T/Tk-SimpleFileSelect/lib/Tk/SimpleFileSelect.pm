package Tk::SimpleFileSelect;

use strict;
use warnings;
use Carp;
use Tk qw(Ev);
use base qw(Tk::Toplevel);
use Tk::widgets qw(LabEntry Button Frame Listbox Scrollbar);
use File::Basename;
use Tk::Listbox;
use Tk::Button;
use Tk::Dialog;
use Tk::DialogBox;
use Tk::Toplevel;
use Tk::LabEntry;
use Cwd;

our $VERSION = 1.29;
our @EXPORT_OK = qw(glob_to_re);

Construct Tk::Widget 'SimpleFileSelect';

sub Cancel {
    my ($cw) = @_;
    $cw->withdraw;
    $cw->{Selected} = '';
}

sub Open {
    my ($cw) = @_;
    
    my $entry = $cw->Subwidget('file_entry')->get;
    my $path = $cw->{'Configure'}{'-directory'};
    
    if (defined $entry and length($entry)) {
        if ( -d "$path/$entry" ) {
            $cw->directory( "$path/$entry" );
        } else {
            $cw->{Selected} = '';
            $cw->{Selected} = "$path/$entry";
        }
    }
}

sub Populate {
    my ($w, $args) = @_;
    $w->SUPER::Populate($args);

    $w->ConfigSpecs(
        '-font'             => ['CHILDREN',undef,undef,'*-helvetica-medium-r-*-*-12-*'],
        '-width'            => [ ['dir_list'], undef, undef, 30 ],
        '-height'           => [ ['dir_list'], undef, undef, 14 ],
        '-directory'        => [ 'METHOD', undef, undef, '.' ],
        '-initialdir'       => '-directory',
        '-files'            => [ 'PASSIVE', undef,undef,1 ],
        '-selectedfile'     => [ 'PASSIVE', undef,undef,''],
        '-dotfiles'         => [ 'PASSIVE', undef,undef,0 ],
        '-filter'           => [ 'METHOD',  undef, undef, undef ],
        '-accept'           => [ 'CALLBACK',undef,undef, undef ],
        '-create'           => [ 'PASSIVE', undef, undef, 0 ],
        '-acceptlabel'      => [ 'PASSIVE', undef, undef, 'Accept' ],
        '-initialtext'      => [ 'PASSIVE', undef, undef, '' ],
        'DEFAULT'           => [ 'dir_list' ],
    );

    $w->protocol('WM_DELETE_WINDOW' => ['Cancel', $w ]);
    $w->{'reread'} = 0;
    
    my $l = $w->Component( Label => 'entry_label',-text => 'File Name: ');
    $l->grid( -column => 1, -row => 3, -padx => 5, -pady => 5 );
    
    my $e = $w->Component(Entry => 'file_entry', -textvariable=>\$w->{Configure}{-initialtext});
    $e->grid(-column => 2, -columnspan => 1, -padx => 5, -pady => 5, -row => 3, -sticky => 'e,w' );
    $e->bind('<Return>' => [$w => 'Open', Ev(['getSelected'])]);
    
    my $lb = $w->Component(
        ScrlListbox => 'dir_list',
        -scrollbars => 'se',
        #-width => \$w->{Configure}{-width}, # Can't set -width to `SCALAR(0x34dca94)'
        #-height => \$w->{Configure}{-height},
    );
    
    $lb->Subwidget('yscrollbar')->configure(-width=>10);
    $lb->Subwidget('xscrollbar')->configure(-width=>10);
    $lb->grid(-column => 2, -row => 1, -rowspan => 2, -padx => 5, -pady => 5, -sticky => 'nsew');
    $lb->bind('<Double-Button-1>' => [$w => 'Open', Ev(['getSelected'])]);
    $lb->bind('<Button-1>', sub { ($w->{Configure}{-initialtext}=$lb->get($lb->curselection)) });
    
    my $b = $w->Button(-textvariable => \$w->{'Configure'}{'-acceptlabel'}, -underline => 0,-command => [$w => 'Open', Ev(['getSelected']) ]);
    $b->grid(-column=>1,-row=>1,-padx=>5,-pady=>5,-sticky=>'sew');
    $b = $w->Button( -text => 'Cancel', -underline => 0, -command => [ 'Cancel', $w ]);
    $b->grid( -column => 1, -row => 2, -padx => 5, -pady => 5, -sticky => 'new' );
    
    $w->bind( '<Alt-c>', [$w => 'Cancel', $w]);
    $w->bind( '<Escape>', [$w => 'Cancel', $w]);
    $w->Subwidget('file_entry')->focus;
    $w->eventAdd( '<<Accept>>', '<Alt-a>');
    $w->bind('<<Accept>>', [$w => 'Open', Ev(['getSelected']) ]);
    $w->Delegates(DEFAULT => 'dir_list');
    
    return $w;
}

sub translate {
    my ($bs,$ch) = @_;
    return "\\$ch" if (length $bs);
    return '.*'  if ($ch eq '*');
    return '.'   if ($ch eq '?');
    return "\\."  if ($ch eq '.');
    return "\\/" if ($ch eq '/');
    return "\\\\" if ($ch eq '\\');
    return $ch;
}

sub glob_to_re {
    my $regex = shift;
    $regex =~ s/(\\?)(.)/&translate($1,$2)/ge;
    return sub { shift =~ /^${regex}$/ };
}

sub filter {
    my ($cw,$val) = @_;
    
    my $var = \$cw->{Configure}{'-filter'};
    
    if (@_ > 1 || !defined($$var)) {
        
        $val = '*' unless defined $val;
        $$var = $val;
        $cw->{'match'} = glob_to_re($val)  unless defined $cw->{'match'};
        
        unless ($cw->{'reread'}++) {
            $cw->Busy;
            if( ( $cw->cget( '-connected' ) ) =~ /1/ ) {
                $cw->afterIdle(['rereadRemote',$cw,$cw->cget('-directory')])
            } else {
                $cw->afterIdle(['reread',$cw,$cw->cget('-directory')]);
            }
        }
        
    }
    return $$var;
}

sub defaultextension {
    my ($cw,$val) = @_;
    if (@_ > 1) {
        $val = ".$val" if ($val !~ /^\./);
        $cw->filter("*$val");
    } else {
        $val = $cw->filter;
        my ($ext) = $val =~ /(\.[^\.]*)$/;
        return $ext;
    }
}

sub directory {
    my ($cw,$dir) = @_;
    
    my $var = \$cw->{Configure}{'-directory'};
    
    if (@_ > 1 && defined $dir) {
        
        if (substr($dir,0,1) eq '~') {
            if (substr($dir,1,1) eq '/') {
                $dir = $ENV{'HOME'} . substr($dir,1);
            } else {
                my ($uid,$rest) = ($dir =~ m#^~([^/]+)(/.*$)#);
                $dir = (getpwnam($uid))[7] . $rest;
            }
        }
        
        $dir =~ s#([^/\\])[\\/]+$#$1#;
        
        if (-d $dir) {
            unless (Tk::tainting()) {
                
                my $pwd = Cwd::getcwd();
                if (chdir( (defined($dir) ? $dir : '') ) ) {
                    my $new = Cwd::getcwd();
                    if ($new) {
                        $dir = $new;
                    } else {
                        carp "Cannot getcwd in '$dir'";
                    }
                    chdir($pwd) || carp "Cannot chdir($pwd) : $!";
                    $cw->{Configure}{'-directory'} = $dir;
                    $cw->configure(-title=>$dir);
                } else {
                    $cw->BackTrace("Cannot chdir($dir) :$!");
                }
                
            }
            
            $$var = $dir;
            unless ($cw->{'reread'}++) {
                $cw->Busy;
                $cw->afterIdle(['reread',$cw]);
            }
        }
        
    }
    return $$var;
}



sub reread {
    my ($w) = @_;
    
    my $dir = $w->cget('-directory');

    if (defined $dir) {
        if (!defined $w->cget('-filter') or $w->cget('-filter') eq '') {
            $w->configure('-filter', '*');
        }
        
        my $dl = $w->Subwidget('dir_list');
        $dl->delete(0, 'end');
        
        local *DIR;
        my $h;
        if (opendir(DIR, $dir)) {
            my $file = $w->cget('-selectedfile');
            my $seen = 0;
            my $accept = $w->cget('-accept');
            
            foreach my $f (sort(readdir(DIR))) {
                next if ($f eq '.');
                next if $f =~ /^\.[^\.]/ and ! $w->{Configure}{-dotfiles} ;
                my $path = "$dir/$f";
                if (-d $path) {
                    $dl->insert('end', $f.'/');
                } elsif ($w->cget('-files')) {
                    if (&{$w->{match}}($f)) {
                        if (!defined($accept) || $accept->Call($path)) {
                            $seen = $dl->index('end') 
                            if ($file && $f eq $file);
                            $dl->insert('end', $f);
                        }
                    }
                }
            }
            
            closedir(DIR);
            
            if ($seen) {
                $dl->selectionSet($seen);
                $dl->see($seen);
            } else {
                $w->configure(-selectedfile => '') 
                unless $w->cget('-create');
            }
        }
        
        $w->{DirectoryString} = $dir . '/' . $w->cget('-filter');
        $w->{'reread'} = 0;
        $w->Unbusy;
    }
}

sub Error {
    my $cw  = shift;
    my $msg = shift;
    my $dlg = $cw->Subwidget('dialog');
    $dlg->configure(-text => $msg);
    $dlg->Show;
}

sub Show {
    my ($cw,@args) = @_;
    $cw->Popup;
    my $accel = lc(substr $cw->cget('-acceptlabel'),0,1);
    $cw->eventAdd('<<Accept>>', "\<Alt-$accel\>");
    $cw->waitVariable(\$cw->{Selected});
    $cw->withdraw;
    return $cw->{Selected};
}

1;

__END__

=encoding utf8

=head1 NAME

  Tk::SimpleFileSelect - Easy-to-Use File Selection Widget

=head1 SYNOPSIS

  use Tk::SimpleFileSelect;

  my $fs = $mw->SimpleFileSelect();
  my $file = $fs->Show();          # Returns selected file's path name.

=head2 Options

=over 4

=item -font

Font to display in the directory list and file name entry.  The
default is "C<*-helvetica-medium-r-*-*-12-*.>"

=item -width

Width directory listing in average width units of the widget font.
The default is C<30>.

=item -height

Height in lines of the directory listing.  The default is C<14>.

=item -directory

=item -initialdir

Name of initial directory to display.  The default is C<'.'>
(current directory).

=item -files

If non-zero, display files as well as directories.  The default
is C<1> (display files).

=item -dotfiles

If non-zero, display files that begin with C<'.'>.  The default is C<0>.
(Don't display hidden files.)

=item -acceptlabel

Alternate text of the "Accept" button.  The first character is
underlined to correspond with an Alt-accelerator constructed from the
first letter of the label.

=item -filter

Display only files matching this pattern.  The default is
C<"*"> (all files).

=item -initialtext

Text to appear in the entry box when the widget is opened.

=back

=head1 DESCRIPTION

Tk::SimpleFileSelect is an easy-to-use file selection widget based on
L<Tk::FileSelect>.  Unlike a L<Tk::FileSelect> widget, Tk::SimpleFileSelect
does not attempt to verify that a file exists.  A Tk::SimpleFileSelect
dialog returns the complete pathname of the selected file.  The
calling program is responsible for file validation and operations.

Clicking on an item in the List box selects the item and displays the
text in the Entry box.  Double clicking on a directory or entering its
name in the Entry box changes to that directory.

Pressing Escape, C<Alt-C>, or clicking the Cancel button closes the 
dialog and returns an empty string.

The C<Show()> method causes the Tk::SimpleFileSelect to wait until a
file is selected in the List box, a file name is entered
in the text entry widget, or the, "Cancel," button is clicked.

Closing the dialog withdraws its window from the display.  The widget
must be deleted explicitly.  The C<Show()> method can open a
Tk::SimpleFileSelect object that has already been created.

The return value of C<Show()> is the pathname of a file selected in the
List box, or the path of the filename in the text entry, or an empty
string.

=head1 ADVERTISED SUBWIDGETS

None.

=head1 COPYRIGHT

Copyright © 2001-2020 Robert Kiesling, rkies@cpan.org.

Alexander Becker has served as a co-maintainer since version 0.69.

Licensed under the same terms as Perl. Refer to the file "Artistic".

=head1 SEE ALSO

L<Tk/getOpenFile>, L<Tk>, perl(1).

=cut
