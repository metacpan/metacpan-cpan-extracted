package Video::FindEvent::Manual;

use vars qw($VERSION @EXPORT);
$VERSION = 0.01;
@EXPORT = qw(new configure findevents);

use base Video::FindEvent;

use strict;

use Video::Event::Manual;
use Term::ReadKey;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;
use XML::Simple;

$Data::Dumper::Purity = 1;
$Data::Dumper::Deepcopy = 1;

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, ref($class) || $class;

    foreach my $key (keys %$args) {
        $self->{$key} = $$args{$key};
    }
	
    $self->configure();
    return $self;
}    

sub configure {
    my ($self) = @_;
	$Data::Dumper::Purity = 1;
	$Data::Dumper::Deepcopy = 1;

    my $config = $self->{'config'};
	
    if (ref $self->{'config'} ne 'HASH') {
    	$config = XMLin($self->{'config'}, 
                        keyattr => 'key', 
                        forcearray => 0,
                        contentkey => '-command',
                        keeproot => 0,
                       );
    	$config = abusexml($config);
    }
	my ($systemkeys, $eventkeys) = getkeys($config);
	$self->{'eventkeys'} = $eventkeys;
	$self->{'QUIT'} = $$systemkeys{'quit'};
	$self->{'UNDO'} = $$systemkeys{'undo'};
	$self->{'UNDOENDPT'} = $$systemkeys{'undoendpt'};
    $self->{'TAG'} = $$systemkeys{'tag'};
    $self->{'TAGEDIT'} = $$systemkeys{'tagedit'};
    return 1;
}

sub findevents {
    my ($self, %args) = @_;

    #copy over global args from Video::Manip -- ew.
    foreach my $arg (keys %args) {
        if (not defined $self->{$arg}) {
            $self->{$arg} = $args{$arg};
        }
        else {
            print "not redefining argument $arg, $self->{$arg}, as $args{$arg}\n."
        }
    }

    my @events = ();	
    my @openevents = ();
    my $continue = 1;

    #XXX this should be global opt
    my $delay = 0.2; #sleep for 5th of second between busy wait for keypress

	#plaympeg($MPEGPLAYER, $MPEGPLAYEROPTIONS, $inputmpeg);
	presskeycont("any");
    my $intitaltime = [gettimeofday];

	while ($continue) {
        sleep($delay);
	    my $key = presskeycont("prompt", \@openevents);
	    my $eventtime = tv_interval($intitaltime);
        
        #probability the event happened
        my $probability = 1; 

        
        if ($key eq $self->{'QUIT'}) {

            while (scalar @openevents) {
                #X this code is pasted below
                my $event = pop @openevents;
                my $totaltime = $event->endtime($eventtime,$key);
                print "ending $event->{'name'} after $totaltime\n";
                print "endtime here is $event->{'endtime'}\n";
            }
            
	        my $event = Video::Event::Manual->new($eventtime, $self->{'eventkeys'}{$key}{'envl'}, $probability, $self->{'eventkeys'}{$key}{'type'}, $self->{'eventkeys'}{$key}{'name'});
            push @events, $event;
            $continue = 0;
        }
        elsif ($key eq $self->{'UNDO'}) {
            if (scalar @events) { 
                print "deleted event $events[-1]->{'name'}, $events[-1]->{'time'}\n";
                if (defined $events[-1]->{'type'}) {
                    pop @openevents if $events[-1]->{'type'} eq 'long';
                }
                pop @events; 
            } 
            else { print "no events to delete\n"; }
        }
        elsif ($key eq $self->{'UNDOENDPT'}) {
            if (scalar @events) {
                if (defined $events[-1]->{'type'}) {
                    if ($events[-1]->{'type'} eq 'long') {
                        push @openevents, $events[-1];
                    }
                }
                else {
                    print "endpoint not defined for non-long event; doing nothing\n";
                }
            }
            else { print "no events to delete\n"; }
        }
        elsif ($key =~ /[1-9]/ and scalar @openevents) {
            #XXX this is copied from above
            my $event = pop @openevents;
            my $totaltime = $event->endtime($eventtime,$key);
            print "ending $event->{'name'} at $event->{'endtime'} after $totaltime\n";
        }    
        
        elsif (defined $self->{'eventkeys'}{$key}) {
            my $name = $self->{'eventkeys'}{$key}{'name'};
	        my $event = Video::Event::Manual->new($eventtime, $self->{'eventkeys'}{$key}{'envl'}, $probability, $self->{'eventkeys'}{$key}{'type'}, $self->{'eventkeys'}{$key}{'name'});
	        push @events, $event;
    	    print $event->{'name'}." at ".$event->{'time'}."\n";
            if ($event->{'type'} eq "long") {
                push @openevents, $event ;
            }    
        }
        elsif ($key eq $self->{'TAG'} and scalar @events) {
            print $events[-1]->gettag();
            ReadMode 0;
            my $tag;
            $tag = ReadLine();
            chomp($tag);
            $events[-1]->tag($tag);
            ReadMode 4;
        }    
        elsif ($key eq $self->{'TAGEDIT'} and scalar @events) {
            #XXX edit tag
        }
            
	    else { print "unknown event $key\n"; }
	}
    $self->{'events'} = \@events;

    $self->{'algoid'} = 'defaultid' unless $self->{'algoid'};
    $self->{'progid'} = 99 unless $self->{'progid'};

    if ($self->{'writefile'} ne '') {
        my $file = $self->{'writefile'} . ".obj";
        open FH, ">$file";
        my $dump = Dumper(\@events);
        print FH "$dump\n";
        close FH;
        return 1;
    }
}

sub presskeycont {
    my ($display, $args) = @_;
    if ($display eq "any") { print "Press any key to continue.."; }
    ReadMode 4;
    if ($display eq "prompt") {
        foreach my $event (@$args) {
            print "[$event->{'name'}]";
        }
        print "> ";    
    }    
	my $key;
	while (not defined ($key = ReadKey(-1))) {sleep 0.2}
	ReadMode 0;
    if ($display eq "any") { print "\n"; }
    return $key;
}


sub plaympeg {
    my ($player, $options, $file) = @_;
	my $pid = fork;
	if (! $pid) { 
	    if (! system("$player $options $file")) {
	        printf("Could not open $file with $player\n");
	    }
        exit(0);
	}
}

sub insert {
	my ($id, $ratings) = @_;
	
	my $encoded = encode_base64($ratings);
	
	my $dbh = dbconnect();
	my $sql = "INSERT INTO ratings (id, ratings) values ('$id', '$encoded')";
	my $sth = $dbh->prepare($sql);
	$sth->execute() or warn "could not insert into ratings";
	print "done\n";
}

sub dbconnect { 
    my $dbname = 'manual';
    my $username = 'postgres';
    my $password = '';
    return DBI->connect("dbi:Pg:dbname=$dbname", $username, $password)
        or warn $DBI::errstr;
    return 0;
}

sub dbdisconnect {
    my ($dbh) = @_;
    $dbh->disconnect();
}


sub abusexml {
    # pay here for abuse of xml
    #
    # points are stored in tags that contain the x value in their name
    # this is bad xml but gives a nice data structure once we account for 
    #   xml not allowing numerical tags
    #
    # tags for x values can be prefixed with any non digit characters 
    #   (which are still valid xml)

    my ($xml) = @_;
    my %hash;

    foreach my $block (keys %$xml) {
        %hash = %{$$xml{$block}};
        foreach my $key (keys %{$$xml{$block}}) {

                foreach my $pt (keys %{$hash{$key}{'envl'}}) {
                    my $value = $hash{$key}{'envl'}{$pt};
                    delete $hash{$key}{'envl'}{$pt};
                    #match optional (actually, required for valid xml) tag
                    #followed by neg/pos int/float
                    #value cannot be negative -- take abs; this is a feature
                    $pt =~ /[A-Za-z]*(\-?[0-9]*\.?[0-9]*)/;
                    $hash{$key}{'envl'}{$1} = $value; 
                    
                }

        }
    }
    return \%hash;
}

sub getkeys {
    my ($keys) = @_;
    my %systemkeys;
    my %eventkeys;
    foreach my $key (keys %$keys) {
        if ($$keys{$key}{'type'} eq 'system') {
            $systemkeys{ $$keys{$key}{'name'} } = $key; 
        }
        else {
            $eventkeys{ $key } = $$keys{$key};
        }
    }
    if (not defined $systemkeys{'undo'} 
        or not defined $systemkeys{'quit'} 
        or not defined $systemkeys{'delete'}) {
        configerror();
    }
    return (\%systemkeys, \%eventkeys);
}

sub configerror {
    die "error in configuration file";
}

1;
