package Video::Function;

use vars qw($VERSION @EXPORT);
$VERSION = 0.01;
@EXPORT = qw(new sum show zero compress truncate);

use strict;
use Math::Round qw(nearest_ceil nearest_floor nearest);

sub new {
    my ($class, $resolution, $length) = @_;
    my $self = bless {}, ref($class) || $class;
    $self->{'function'} = {};

    #number of divisions in a sec
    $self->{'resolution'} = $resolution if $resolution; 

    $self->{'length'} = $length || -1;

    return $self;
}

sub setlength {
    my ($self, $length) = @_;
    $self->{'length'} = $length if $length;
    return 1;
}

sub compress {
    my ($self, $desiredlength, $method) = @_;
    my $original = $self->{'function'};
    $self->{'desiredlength'} = $desiredlength;

    if ($desiredlength > $self->{'length'}) {
        my $multiplier = $desiredlength/$self->{'length'};
        $self->multiply($multiplier);
        print "warning: making coolness function longer, method is irrelevant\n";
    }

    if ($method eq "simple") {
        my $multiplier = $desiredlength / ($self->{'length'});
        $self->multiply($multiplier);
    }

    if ($method eq "cutoff") {
        my $cutoff = 0;
        my $delta = 0.1;
        while (($desiredlength < $self->sumsel($cutoff, "greater"))
          and ($cutoff <= 1)) {
            $cutoff += $delta;
        }
        my %function = %{$self->{'function'}};
        foreach my $point (keys %function) {
            if ($function{$point} < $cutoff) {
                $function{$point} = 0;
            }
        }
        %{$self->{'function'}} = %function;
    }
}

sub multiply {
    my ($self, $multiplier) = @_;
    my %function = %{$self->{'function'}};
    foreach my $point (keys %function) {
        $function{$point} *= $multiplier;
        if ($function{$point} > 1) {
            $function{$point} = 1;
        }
    }
    %{$self->{'function'}} = %function;
}

sub sum {
    my ($self) = @_;
    return $self->sumsel(0,"greater");
}

sub sumsel {
    my ($self, $cutoff, $sign) = @_;
    my $sum = 0;
    foreach my $value (values %{$self->{'function'}}) {
        if ($sign eq "greater") {
            if ($value >= $cutoff) {
                $sum += $value;
            }
        }
        if ($sign eq "less") {
            if ($value <= $cutoff) { 
                $sum += $value;
            }
        }
    }
    return $sum/$self->{'resolution'};
}

sub zero {
    my ($self) = @_;
    my $length = $self->{'length'};
    my $resolution = $self->{'resolution'};
    for (my $i=0; $i<$length; $i+=(1/$resolution)) {
        my $big = scalar keys %{$self->{'function'}};
        $i = nearest(1/$resolution, $i);
        unless (defined $self->{'function'}{$i}) {
            $self->{'function'}{$i} = 0;
        }    
    }
    return $self;
}

sub truncate {
    my ($self) = @_;
    my $length = $self->{'length'};
    foreach my $index (keys %{$self->{'function'}}) {
        if ($index < 0) {
            delete ${$self-{'function'}}{$index};
            print "truncated negative index\n";
        }
        if ($index > $length) {
            delete ${$self->{'function'}}{$index};
        }
    }
    return $self;
}

sub show {
    my ($self) = @_;
    my @unsorted = keys %{$self->{'function'}};
    my @sorted = sort {$a<=>$b} @unsorted;
    my $data = "";
    foreach my $key (@sorted) {
        $data .= sprintf("%3.2f \t %1.3f\n", $key, $self->{'function'}{$key});
    }
    return $data;
}

sub apply {
    my ($self, $time, $value) = @_;
    $time = nearest(1/($self->{'resolution'}), $time);
    if ($time < 0) { $time = 0; }
    $self->{'function'}{$time} = max($self->{'function'}{$time}, 
                                     $value
                                    );
}

sub applybunch {
    my ($self, $event) = @_;
    my $eventtime = $event->{'time'};
    my $zerooverride = $event->{'zerooverride'};

    $event->{'cool'} = 0 if not defined $event->{'cool'};
    #scale keypress (key between 1 and 9) to fit between 0 and 1
    $event->{'cool'} = ($event->{'cool'}/9) if $event->{'cool'} > 1;

    if (defined $event->{'type'}) {

    if ($event->{'type'} eq 'long') {
        if ( defined $event->{'endtime'} and
             defined $event->{'cool'}
           ) {
            my $numsteps = ($event->{'endtime'} - $eventtime) 
                           * $self->{'resolution'};
            foreach my $step (0 .. $numsteps) {
                $self->apply(nearest(1/$self->{'resolution'},
                                     $eventtime + ($step/$self->{'resolution'})
                                    ), 
                             $event->{'cool'}
                            );
            }    
            if (defined $event->{'envelope'}) {
                $self->fillin($event->{'time'}, $event->{'envelope'}, $event->{'zerooverride'}, $event->{'cool'}, -1);
                $self->fillin($event->{'endtime'}, $event->{'envelope'}, $event->{'zerooverride'}, $event->{'cool'}, 1);
            }    
        }
        else {
            die __PACKAGE__ . ": problem with long event, no endtime or no coolness, can't build coolness function";
        }
    }
    if ($event->{'type'} ne 'long') { 
        $self->fillin($event->{'time'}, $event->{'envelope'}, $event->{'zerooverride'}, $event->{'cool'});
    }


    }
    #if type not defined, then can't apply envelope because don't know how

}


sub fillin {
    my ($self, $eventtime, $points, $zerooverride, $scaleto, $direction) = @_;
    my $resolution = $self->{'resolution'};
    my @ordered = sort {$a <=> $b} (keys %$points);
    my $first = nearest_ceil(1/$resolution, $ordered[0] + $eventtime);
    my $last = nearest_floor(1/$resolution, $ordered[-1] + $eventtime);

    my $counter = $ordered[0];
    my $point   = $first;
    while ($point <= $last) {
        $counter += 1/($resolution);
        $point += 1/($resolution);

        my $prev = getprev($counter, @ordered);
        my %previous = ('time'  => $prev,
                        'value' => $$points{$prev},
                       );
        my $next = getnext($counter, @ordered);
        my %next = ('time'  => $next,
                    'value' => $$points{$next},
                   );
        my $value = interpolate($counter, \%previous, \%next);
        $value *= $scaleto if $scaleto;
        $point = nearest(1/$resolution, $point);
    
        if ($point >= 0) {
            $self->{'function'}{$point} = max($self->{'function'}{$point},
                                              $value,
                                              $zerooverride  
                                             );
        }
   
        
    }
}

sub interpolate {
    my ($point, $previous, $next) = @_;
    my $timeratio =   ( $point         - $$previous{'time'} ) 
                    / ( $$next{'time'} - $$previous{'time'} );
    my $mult = ( $$next{'value'} - $$previous{'value'} ) if $$next{'value'};
    $mult = $$previous{'value'} unless $$next{'value'};  #ew
    my $add =  ( $$previous{'value'} );
    return $timeratio * $mult + $add;
}


sub getnext {
    my ($point, @ordered) = @_;
    foreach my $compare (@ordered) {
        return $compare if $compare >= $point;
    }
    return -99999;
}

sub getprev {
    my ($point, @ordered) = @_;
    foreach my $compare (reverse @ordered) {
        return $compare if $compare < $point;
    }
    return -99999;
}

sub max {
    my ($first, $second, $zerooverride) = @_;
    return 0 if $zerooverride;
    return 0 if not $first and not $second;
    return $second if not $first;
    return $first if not $second;
    if ($first > $second) {return $first;}
    return $second;
}
1;
