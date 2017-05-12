package Video::FindEvent::Field;

use base Video::FindEvent;
use strict;

sub findevents {
    my ($self, %args) = @_;

    #number of frames to skip between examining frames
    my $skipframes = 12;  
    my $vfps = $args->{'vfps'}; 
    my $dir = $self->{'args'}{'video'};
    my @files = ();
    if (-d $dir) {
	    opendir (DIR, $dir) || die __PACKAGE__ . ": can't open $dir: $!";
        print "processing directory $dir\n";
	    @files = readdir DIR;
    }
    elsif (-f $dir) {
        @files = ($dir);
    }		
    else {
        die __PACKAGE__ . ": don't know what to do with $dir";
    }

    my $framenumber = 0;
    my $lastframeplayed = 0;

    #for keeping state between events - this is a hashref containing your bits
    #open filehandle, array, whatever
    
    my @array = ();
    my $keepstate;
    my $file;
    if ($self->{'writefile'}) {
        my $file = $self->{'writefile'};
        my $FH;
        open $FH, ">$file.bdy";
        my $keepstate = {'eventhandle' => $FH,
                        };
    }

	foreach my $filename (@files) {
        next if $filename !~ /^.*\.jpg$/;
        $framenumber++;
        next if $framenumber % $skipframes;
	
        my $tmpxpm = "tempxpm.xpm";
        my $command = "convert -size 80x60 $dir/$filename $dir/$tmpxpm";
        system($command) and 
            die __PACKAGE__ . ": can't convert $dir/$filename to $dir/$tmpxpm";
		
        #careful: -ccp => 2 is true for only 80x60 under linux and openbsd
        my $picture = Image::Xpm->new(-file => "$dir/$tmpxpm",
                                      -cpp => 2   
                                     );


        if ( thisiswhatyouarelookingfor($picture) ) { 
            $keepstate = $self->foundevent($self, $time, $coolness, $probability, $boundary, $keepstate);
        }
	}
    close $keepstate{'eventhandle'};
}    

sub thisiswhatyouarelookingfor {
    ... cleverness goes here ...
}

1;
