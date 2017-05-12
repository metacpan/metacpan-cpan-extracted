$Tk::Copy::Mac::VERSION = '1.3';

package Tk::Copy::Mac;

use File::Basename;
use File::Find;
use File::NCopy;
use Tk::widgets qw/CollapsableFrame LabEntry/;
use Tk::ProgressBar::Mac;

use base qw/Tk::Toplevel/;
use strict;

Construct Tk::Widget 'Copy';

sub Populate {

    # Create an instance of a Tk::Copy::Mac widget.

    my($self, $args) = @_;

    $self->withdraw;
    $self->SUPER::Populate($args);

    my $pb = $self->ProgressBar(qw/-width 300/)->pack;
    
    # Populate the top Frame of the ProgressBar.

    my $tf = $pb->Subwidget('tframe');
    my $tf_label = $tf->Label->pack(qw/-side left -anchor w/);
    $tf->Label(-textvariable => \$self->{file_count_string})->
	pack(qw/-side right -anchor e/);
    
    # Populate the right Frame of the ProgressBar.

    my $rf = $pb->Subwidget('rframe');
    $rf->Button(-text => 'Stop', -command => sub {
	$self->{tid}->cancel if defined $self->{tid};
	$self->{xt}->cancel if defined $self->{xt};
	$self->{'_stop'} = 1;
	$self->{ncopy}->{'_stop'} = 1 if defined $self->{ncopy};
	$self->Subwidget('tf_label')->
	    configure(-text => 'Stopping, please wait ... ');
    })->pack;
    
    # Populate the bottom Frame of the ProgressBar with a CollapsableFrame.

    my $bf = $pb->Subwidget('bframe');
    my $cf = $bf->CollapsableFrame(
        -height => 110,
        -width  => 400,
        -text   => 'Time Remaining:  ',
    );
    $cf->pack(qw/-fill x -expand 1/);
    my $cf_frame = $cf->Subwidget('colf');

    # Populate the CollapsableFrame with detail information.

    foreach my $item (
         ['Copying', \$self->{file}],
         ['From', \$self->{from}],
         ['To', \$self->{to}],
         ['Bytes Copied', \$self->{bytes_msg}],
        ) {
	my $l = $item->[0] . ':';
	my $le = $cf_frame->LabEntry(
            -label        => ' ' x (13 - length $l) . $l,
            -labelPack    => [qw/-side left -anchor w/],
            -labelFont    => '9x15bold',
            -relief       => 'flat',
            -state        => 'disabled',
            -textvariable => $item->[1],
	    -width        => 65,
        );
	$le->pack(qw/ -fill x -expand 1/);
    }

    # Public subwidgets and options.

    $self->Advertise('collapsableframe' => $cf);
    $self->Advertise('progressbar'      => $pb);
    $self->Advertise('tf_label'         => $tf_label);

    $self->ConfigSpecs(-bufsize => [qw/PASSIVE bufSize BufSize 2097152/]);

} # end Populate

sub copy {

    # Perform the copy, updating copy information on-the-fly.

    my($self, $from, $to) = @_;

    $self->deiconify;
    
    # Reset for a subsequent copy.

    $self->{'_stop'} = 0;
    $self->{from} = $from;
    $self->{to} = $to;
    $self->{file} = '';
    $self->{bytes_msg} = '';
    $self->{bytes} = 0;
    $self->{total_bytes} = 0;
    $self->Subwidget('collapsableframe')->configure(
        -text => 'Time Remaining:  ',
    );
    $self->Subwidget('progressbar')->reset;

    # Get total file and byte counts.  Scintillate the cursor.  We use
    # File::Find, which, unfortunately, is blocking.

    $self->{file_count} = 0;
    $self->{file_count_string} = 0;
    $self->{total_file_count} = 0;
    $self->{total_bytes} = 0;

    my $l = $self->Subwidget('tf_label');
    $l->configure(-text => 'Preparing to copy:  ');

    my $get_copy_stats = sub {
	return if $self->{'_stop'};
	return unless -f $_;
	$self->{file_count}++;
	$self->{file_count_string} = $self->{file_count};
	1 while $self->{file_count_string} =~ s/^(-?\d+)(\d{3})/$1,$2/;
	$self->{total_bytes} += -s $_;
	$self->update;
    };

    $self->{busy} = 0;
    $self->{cursor} = $self->cget(-cursor);

    $self->{tid} = $self->repeat(500 => [$self => 'busy']);

    find($get_copy_stats, $from);
    goto STOP if $self->{'_stop'};

    $self->{tid}->cancel;
    $self->unbusy;

    $self->{total_bytes_comma} = $self->{total_bytes};
    1 while $self->{total_bytes_comma} =~ s/^(-?\d+)(\d{3})/$1,$2/;
    $self->{total_bytes_format} = "%" . length($self->{total_bytes_comma})
	. "s of $self->{total_bytes_comma}";

    $l->configure(-text => 'Items remaining to be copied:  ');

    $self->{total_file_count} = $self->{file_count};
    1 while $self->{file_count_string} =~ s/^(-?\d+)(\d{3})/$1,$2/;
    $self->{filen} = 0;
    $self->{bytes} = 0;

    # Do the copy.  Create an NCopy instance and arrange for various
    # callbacks to update copy progress and keep Tk events flowing.

    $self->{ncopy} = File::NCopy->new(
        '-bufsize'          => $self->cget(-bufsize),			      
        '-precopycommand'   => [\&update_gui_pre_copy, $self],
        '-duringcopycommand'=> [\&update_gui_during_copy, $self],
        'force_write'       => 1,
        'preserve'          => 1,
        'recursive'         => 1,
    );

    # Initialize for data transfer rate and time remaining computations.
    #
    # xfer rate = (b1 - b0) / (t1 - t0)
    # time left = (total_bytes - b1) / rate

    $self->Subwidget('collapsableframe')->configure(-text =>
        "Time Remaining:  calculating");

    $self->{t0} = $self->{t1} = Tk::timeofday;
    $self->{b0} = $self->{b1} = 0;

    $self->{xt} = $self->repeat(5000 => sub {

        $self->{t1} = Tk::timeofday;
        $self->{b1} = $self->{bytes};
        my $rate = ($self->{b1} - $self->{b0}) / ($self->{t1} - $self->{t0});
	my $time = ($self->{total_bytes} - $self->{b1}) / $rate;
	my $text;
	if ($time < 5) {
	    $text = 'about 5 seconds';
	} elsif ($time < 60) {
	    $text = 'less than a minute';
	} elsif ($time < 3600) {
	    my $m = int(($time / 60) + 0.5);
	    $text = sprintf("about %d minutes", $m);
	    $text =~ s/.$// if $m == 1;
	} else {
	    my $h = $time / 3600;
	    $text = sprintf("about %.1f hours", $h);
	    $text =~ s/.$// if $h == 1;
	}
	$self->Subwidget('collapsableframe')->configure(
            -text => "Time Remaining:  $text");
	$self->idletasks;
	$self->{t0} = $self->{t1};
	$self->{b0} = $self->{b1};

    });	# end repeat

    $self->{ncopy}->{'_debug'} = 1;
    $self->{ncopy}->{'_stop'} = 0;

    $self->{ncopy}->copy($from, $to);

STOP:
    $self->{xt}->cancel if $self->{xt};
    $self->Subwidget('collapsableframe')->configure(
        -text => 'Time Remaining:  0',
    );

    $self->withdraw;

} # end copy

sub busy {

    my ($self) = @_;
    
    my $c  = ($self->{busy}++ % 2) ? 'crosshair' : 'diamond_cross';
    $self->Walk( sub {$_[0]->configure(-cursor => [$c, 'blue', 'green'])} );
    $self->idletasks;

} # end busy

sub unbusy {

    my ($self) = @_;
    
    $self->Walk( sub {$_[0]->configure(-cursor => $self->{cursor})} );
    $self->idletasks;

} # end unbusy

sub update_gui_pre_copy {

    my ($from, $to, $self) = @_;

    $self->{filen}++;
    $self->{file} = basename $from;
    $self->{file} .= ' : ';
    $self->{file_count}--;
    $self->{file_count_string} = $self->{file_count};
    1 while $self->{file_count_string} =~ s/^(-?\d+)(\d{3})/$1,$2/;
    $self->{file_bytes} = -s $from;
    $self->idletasks;

} # end update_gui_pre_copy

sub update_gui_during_copy {

    my ($from, $to, $bytes_written, $self) = @_;
  
    my ($f) = $self->{file}  =~ /(.*) : /;
    $self->{file_bytes} -= $bytes_written;
    my $b = $self->{file_bytes};
    1 while $b =~ s/^(-?\d+)(\d{3})/$1,$2/;
    $self->{file} = "$f : $b";

    $self->{bytes} += $bytes_written;
    $b = $self->{bytes};
    1 while $b =~ s/^(-?\d+)(\d{3})/$1,$2/;
    $self->{bytes_msg} = sprintf($self->{total_bytes_format}, $b);

    my $percent = $self->{bytes} / $self->{total_bytes} * 100;
    $percent = 100 if $percent > 100;
    $self->Subwidget('progressbar')->set($percent);
    $self->update;

} # end update_gui_during_copy

1;

__END__

=head1 NAME

Tk::Copy::Mac - simulate a Macintosh Classic copy dialog.

=head1 SYNOPSIS

 use Tk::Copy::Mac;
 $cd = $parent->Copy(-option => value);

=head1 DESCRIPTION

This widget simulates a Macintosh Classic copy dialog using
Tk::ProgressBar::Mac and CollapsableFrame widgets.

=head1 OPTIONS

The following option/value pairs are supported:

=over 4

=item B<-bufsize>

The copy buffer size in bytes (default is 2,097,152 bytes).
The value of this option can only be set during widget creation.

=back

=head1 METHODS

=over 4

=item B<copy(from, to)>

Copies 'from' to 'to'.

=back

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
Valid subwidget names are listed below.

=over 4

=item Name: progressbar, Class:  ProgressBar

  ProgressBar widget reference.

=item Name: collapsableframe, Class:  CollapsableFrame

  CollapsableFrame widget reference.

=back

=head1 EXAMPLE

 #!/usr/local/bin/perl -w
 use Tk;
 use Tk::Copy::Mac;
 use strict;

 die "Usage: copy.pl from to" unless $#ARGV == 1;

 my $mw = MainWindow->new;

 my $mc = $mw->Copy(-bufsize => 4 * 1_048_576);

 my $b = $mw->Button(
     -text    => "Push me to copy all files in '$ARGV[0]' to '$ARGV[1]'.",
     -command => sub {$mc->copy($ARGV[0],  $ARGV[1])},
 )->pack;
 $mw->Button(-text => 'Quit', -command => \&exit)->pack;

 $mc->Subwidget('collapsableframe')->open;

 MainLoop;

=head1 BUGS

There are two phases to a Copy operation.  First, we do a pre-scan
to compute a file count and total byte count using File::Find,
followed by the actual copy using File::NCopy.  The pre-scan phase is
blocking - we haven't made any changes to that core module to keep
Tk events flowing.

We don't verify that there is sufficient room in the destination for
the copy to succeed.

=head1 AUTHOR and COPYRIGHT

sol0@Lehigh.EDU

Copyright (C) 2000 - 2002, Stephen O. Lidie

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

Apple, CollapsableFrame, Copy, ProgressBar

=cut
