package Video::Manip;

#XXX DataDumper has problems with strict
#use strict;

use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.01;
use base qw(Exporter);
@EXPORT = qw(new use extract);
@EXPORT_OK = qw(check getbdys buildcool match redefineenvl reconsevents selectframes);
%EXPORT_TAGS = ( all => [@EXPORT_OK] );

use Video::Event::Manual;
use Video::Function;
use Video::FindEvent::Manual;
use Data::Dumper;
use XML::Simple; #do this in findevent::manual or that here to avoid redundancy

sub new {
    my ($class, %args) = @_;

    my %options = (
        file => '',
        rawvideo => '',
        rawaudio => '',
        dovideo => '1',
        doaudio => '1',
        afps => '44100',
        vfps => '25',
        progid => '',
        writefile => '',      #write to file named
        writedb => '',        #write to db named
        progid => '',         #program id
        algoid => '',         #algorithm id
        genshell => '',       #generate shell script, don't actually copy frames
        actuallydo => '',     #copy appropriate frames; must specify sourcedir and destdir also
        sourcedir => '',      #copy video frames from
        destdir => '',        #copy video frames to

        resolution => '4',    #number of parts in a second
        desiredlength => '',  #0 gives longest possible
        verbose => '0',       #integer 0 (none) - 9 (all messages)
        );

    foreach my $option (keys %args) {
        warn __PACKAGE__ . ": unexpected: $option" 
            if (not defined $options{$option});
        die __PACKAGE__ . ": must specify value as $option => value"
            if (not $args{$option});
        $options{$option} = $args{$option};
    }

    my $self = bless \%options, ref($class) || $class;
    foreach my $key (keys %options) {
        $self->{$key} = $options{$key};
    }
    #erm.  
    $self->{'options'} = \%options;
    return $self;
}

sub check {
    # verify Video::FindEvent::* modules load without errors
    my ($self, $algorithms) = @_;
    ref($algorithms) eq 'HASH' 
        or die __PACKAGE__ . ": error in algorithms hash";
    foreach my $algo (keys %$algorithms) {
        my $module = "Video::FindEvent::" . $algo;
        check_h($module);
    }
    return 1;
}
    
sub check_h {
    my ($module) = @_;
    eval { "require $module"; } 
    #require $module
        or die __PACKAGE__ . ": problem with module $module";
    return 1;
}

    
sub use {
    my ($self, $algorithms) = @_;
    ref($algorithms) eq 'HASH' 
        or die __PACKAGE__ . ": error in algorithms hash";

    foreach my $algo (keys %$algorithms) {
        foreach my $option (keys %{$self->{'options'}}) {
            $$algorithms{$algo}{$option} = $self->{'options'}{$option}
                if ($self->{'options'}{$option});
        }
    
        #make sure all is good with module, then require it
        my $module = "Video::FindEvent::" . $algo;
        check_h($module);
        eval { eval "require $module" } or die __PACKAGE__ . ": poof";

        #build new module with options present in algorithms hash
        $self->{'algo'}{$algo} = $module->new($$algorithms{$algo});
        my $refcl = ref($self->{'algo'}{$algo});
        ref($self->{'algo'}{$algo}) 
            or die __PACKAGE__ . ": problem with module $module constructor";
    }    
    return 1;
}

sub findevents {
    my ($self, %args) = @_;

    #we only want to fork to run the event finding algorithms if we are
    #running more than one algorithm
    my $numberalgo = scalar values %{$self->{'algo'}};

    if ($numberalgo == 1) {
        foreach my $algo (values %{$self->{'algo'}}) {
        $algo->findevents(%args);
        }
    }
    else {
        foreach my $algo (values %{$self->{'algo'}}) {
            my $pid = fork;
            if (!$pid) {
                $algo->findevents(%args);
                exit 0;
            }
        }
    }
    return 1;
}

sub getbdys {
    my ($self) = @_;
    #X should not have to rebuild @events here
    my @events = $self->{'events'} ? @{$self->{'events'}} 
                                   : @{$self->reconsevents()};
    my @bdys;
    foreach my $event (sort { $a->{'time'} <=> $b->{'time'} } @events) {
        push @bdys, $event->{'time'};
    }
    my @sorted = sort { $a <=> $b } @bdys;
    return \@sorted;
}

sub buildcool {
    my ($self, $length, $searchterm, @tags) = @_;
    my @events = $self->{'events'} ? @{$self->{'events'}} 
                                   : @{$self->reconsevents()};
    my $last = $events[-1];
    unless ($length) {
        $length = $last->{'time'} if $last->{'time'};
        $length = $last->{'endtime'} if defined $last->{'endtime'};
    }
    
    my $resolution = $self->{'resolution'}; 
    my $desiredlength = $self->{'desiredlength'};

    my $cool = new Video::Function($resolution, $length);
    foreach my $event (@events) {
        if ($searchterm eq '-all') {
            $cool = $event->buildcool($cool, $length);
        }
        else {
            if ($event->matches($searchterm, @tags)) {
                $cool = $event->buildcool($cool, $length);
            }
        }
    }
    my $sum = $cool->sum();
    if ($self->{'verbose'} > 5) {
        print "sum: $sum\n";
        print "length: $length\n";
    }
    $desiredlength = $length unless $desiredlength;
    $cool->zero();
    $cool->compress($desiredlength, "simple");
    $cool->truncate();
    if ($self->{'verbose'} > 5) {
        print $cool->show();
    }
    return $cool;
}


sub extract {
    my ($self, $searchterm, @tag) = @_;
    my $length = 0; # means as long as necessary
    my $cool = $self->buildcool($length, $searchterm, @tag);

    #XXX these should be options
    my $dovideo = 1;
    my $doaudio = 0;

    $self->selectframes($cool, $dovideo, $doaudio, $self->{'vfps'}, $self->{'afps'});
    return 1;
}

sub match {
    my ($self, $event, $searchterm, @tags) = @_;
    return 1 unless $searchterm;
    return 1 unless @tags;
    my %hash = %$event;
    foreach my $key (keys %hash) {
        foreach my $tag (@tags) {
            if ($key eq $tag) {
                if ($searchterm eq $hash{$key}) {
                    return 1;
                }
                else {
                    return 0;
                }
            }
        }
    }
    return 0;
}

sub redefineenvl {
    #behaves like reconsevents, but reads in new config file
    my ($self, $newconfig) = @_;

    my @events = $self->{'events'} ? @{$self->{'events'}} 
                                   : @{$self->reconsevents()};
    my $config = XMLin($newconfig, 
                       keyattr => 'key',  
                       forcearray => 0,
                       contentkey => '-command',
                       keeproot => 0,
                      );
    $config = Video::FindEvent::Manual::abusexml($config);
    

    foreach my $event (@events) {
        #match event against $config and reset envelope
        foreach my $key (%$config) {
            if ($event->{'name'} eq $$config{$key}{'name'}) {
                $event->{'envelope'} = $$config{$key}{'envl'};
                #do we want to change other properties too?
            }
        }
    }
    return \@events;
}


sub reconsevents {
    #this should talk to the database too.
    my ($self) = @_;

    if ($self->{'writefile'} ne '') {
        my $data = "";
        my $eventarray = $self->{'writefile'} . ".obj";
        #? do we always want to check config file for new envelopes?
        open FH, "+<$eventarray" or die "can't open $eventarray: $!";
        while (<FH>) {
            $data .= $_;
        }
        $Data::Dump::Purity = 1;
        $Data::Dumper::Deepcopy = 1;
        my $ref = eval($data);
        $self->{'events'} = $ref if $ref;
        return $ref if $ref;
        die __PACKAGE__ . ": can't recons events";
    }
    if ($self->{'writedb'} ne '') {
        die __PACKAGE__ . ": sorry, not implemented.  Can't reconstruct events from database. Yet.";
    }

}

sub selectframes {
    #(this was compress.pl)
    #determine which frames to include in summary based on coolness function
    my ($self, $cool, $dovideo, $doaudio, $vfps, $afps) = @_;
    my $resolution = $cool->{'resolution'};
    my $length = $cool->{'length'};
    my $destdir = $self->{'destdir'};
    my $sourcedir = $self->{'sourcedir'};


    #add trailing / if necessary
    $sourcedir =~ s/(.*)/$1\// unless ($sourcedir =~ /^.*\/$/);
    $destdir =~ s/(.*)/$1\// unless ($destdir =~ /^.*\/$/);


    #number of video frames played in one second
    #used to calculate how many audio frames to play
    my $framecounter = 0;

    #counts total number of frames copied
    my $copiedframe = 0;

    #used to adjust volume over one second
    my $avecool = 0;  #over one second

    #XXX these should be options
    my $fileprefix = "frame";
    my $filesuffix = ".jpg";

    my $actuallydo = 0;
    $actuallydo = $self->{'actuallydo'} if $self->{'actuallydo'};
    my $genshell = 0;
    $genshell = $self->{'genshell'} if $self->{'genshell'};

    for (my $second=0; $second<$length; $second++) {
        $framecounter = 0;
        $avecool = 0;
        for (my $fraction=0; $fraction<1; $fraction+=(1/$resolution)) {
            my $vpnf = 0;
            $avecool = ${$cool->{'function'}}{$second+$fraction};
            for (my $vf=1; $vf<=($vfps/$resolution); $vf++) {
                #decide if we should play the next frame
                next if not defined ${$cool->{'function'}}{$second+$fraction};
                $vpnf += ${$cool->{'function'}}{$second+$fraction};
                if ($vpnf >= 1) {
                    my $framenumber = $second*$vfps +
                                      $fraction*$vfps +
                                      $vf;
                    $framenumber = sprintf("%09d", $framenumber);
                    $copiedframe = sprintf("%09d", $copiedframe);
                    my $infile = $fileprefix . $framenumber . $filesuffix;
                    my $outfile = $fileprefix . $copiedframe . $filesuffix;
                    my $command = "cp " . $sourcedir . $infile . " " . $destdir . $outfile;
                    system($command) if $actuallydo;
                    print "$command\n" if $genshell;
                    $vpnf--;
                    $framecounter++;
                    $copiedframe++;
                }
            }
        }
    }
}

1;
