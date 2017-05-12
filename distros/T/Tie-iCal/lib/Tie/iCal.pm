package Tie::iCal;

use strict;
require Exporter;
our $VERSION = 0.15;
our @ISA     = qw(Exporter);

use Tie::File;

=head1 NAME

Tie::iCal - Tie iCal files to Perl hashes.

=head1 VERSION

This document describes version 0.14 released 1st September 2006.

=head1 SYNOPSIS

	use Tie::iCal;
	
	tie %my_events, 'Tie::iCal', "mycalendar.ics" or die "Failed to tie file!\n";
	tie %your_events, 'Tie::iCal', "yourcalendar.ics" or die "Failed to tie file!\n";
	
	$my_events{"A-NEW-UNIQUE-ID"} = [
		'VEVENT',
		{
			'SUMMARY' => 'Bastille Day Party',
			'DTSTAMP' => '19970714T170000Z',
			'DTEND' => '19970715T035959Z',
		}
	];
	
	tie %our_events, 'Tie::iCal', "ourcalendar.ics" or die "Failed to tie file!\n";
	
	# assuming %my_events and %your_events
	# have no common keys (unless that's your intention)
	#
	while (my($uid,$event) = each(%my_events)) {
		$our_events{$uid} = $event;	
	}
	while (my($uid,$event) = each(%your_events)) {
		$our_events{$uid} = $event;
	}
	
	untie %our_events;
	untie %your_events;
	untie %my_events;

=head1 DEPENDENCIES

	Tie::File

=head1 DESCRIPTION

Tie::iCal represents an RFC2445 iCalendar file as a Perl hash. Each key in the hash represents
an iCalendar component like VEVENT, VTODO or VJOURNAL. Each component in the file must have
a unique UID property as specified in the RFC 2445. A file containing non-unique UIDs can
be converted to have only unique UIDs (see samples/uniquify.pl).

The module makes very little effort in understanding what each iCalendar property means and concentrates
on the format of the iCalendar file only.

=head1 FILE LOCKING

The Tie::iCal object returned by tie can also be used to access the underlying Tie::File object.
This is accessable via the 'A' class variable.
This may be useful for file locking.

	my $ical = tie %events, 'Tie::iCal', "mycalendar.ics";
	$ical->{A}->flock;

=head1 DATES

The iCalendar specification uses a special format for dates. This module makes no effort in trying
to interpret dates in this format. You should look at the Date::ICal module that can convert between
Unix epoch dates and iCalendar date strings.

=cut

sub TIEHASH {
	my ($p, $f, %O) = @_;
	
	tie my @a, 'Tie::File', $f, recsep => "\r\n" or die "failed to open ical file\n";
	$O{A} = \@a; # file array
	$O{i} = 0;   # current file index for FIRSTKEY and NEXTKEY
	$O{C} = ();  # uid to index cache
	
	bless \%O => $p;
}

sub FETCH {
	my $self = shift;
	my $uid  = shift;
	
	my $index = $self->seekUid($uid);
	
	return defined $index ? $self->toHash($index) : undef;
}

sub EXISTS {
	my $self = shift;
	my $uid  = shift;
	
	my $index = $self->seekUid($uid);

	return defined $index ? 1 : 0;
}

sub FIRSTKEY {
	my $self = shift;
	
	$self->{i} = 0;
	for my $line (@{$self->{A}}) {
		if (substr($line, 0, 3) eq 'UID') {
			if ($self->unfold($self->{i}) =~ /^UID.*:(.*)$/) {
				$self->{C}->{$1} = $self->{i}; # cache in any case
				return $1;
			} else {
				warn("FIRSTKEY: discovered illegal UID property format, should be like UID;...:..., ignoring for now\n");
			}
		}
		$self->{i}++;
	}
}

sub NEXTKEY {
	my $self = shift;
	
 	# start search one line after the current point
 	my $start_idx = ++$self->{i};
 	for my $line (@{$self->{A}}[$start_idx .. (@{$self->{A}} - 1)]) {
 		if ($line =~ m/^UID/) {
			if ($self->unfold($self->{i}) =~ /^UID.*:(.*)$/) {
				$self->{C}->{$1} = $self->{i}; # cache in any case
				return $1;
			} else {
				warn("NEXTKEY: discovered illegal UID property format, should be like UID;...:..., ignoring for now\n");
			}
		}
		$self->{i}++;
	}
	return undef;
}

sub SCALAR {
	my $self = shift;
	
	my $count = 0;
	for my $line (@{$self->{A}}) {
		$count++ if substr($line, 0, 3) eq 'UID';
	}
	return $count;
}

sub ceil {
    return int($_[0]) + (int($_[0]) != $_[0]);
}

sub fold {
    my $MAXLENGTH = 75;
    my @A;
    foreach my $string (@_) {
        my @B = unpack("A$MAXLENGTH" x (&ceil(length($string)/$MAXLENGTH)), $string);
        push @A, $B[0], map { ' '.$_ } @B[1..$#B];
    }
    return @A;
}

sub STORE {
	my $self = shift;
	my $uid = shift;
	my $c = shift;
	
	die "event must be array!\n" if ref $c ne 'ARRAY';

	$self->DELETE($uid);
    
	push @{$self->{A}}, fold($self->toiCal($uid, $c));
}

sub DELETE {
	my $self = shift;
	my $uid  = shift;
	
	my $index = $self->seekUid($uid);
	
	return defined $index ? $self->removeComponent($index) : 0;
}

sub CLEAR {
	my $self  = shift;
	
	@{$self->{A}} = ();
}

sub DESTROY {
  my $self = shift;
  untie $self->{A};
}

sub debug {
	my $self = shift;
	print(STDERR shift, "\n") if $self->{debug};
}

sub unfold {
	my $self = shift;
	my $index = shift;
	
	my $result = ${$self->{A}}[$index];
	my $i = 1;
	until (${$self->{A}}[$index + $i] !~ /^ (.*)$/s) {
		$result .= $1;
		$i++;
	}
	$self->debug("unfolded index $index to $result");
	return $result;
}

sub seekUid {
	my $self = shift;
	my $uid  = shift;
	
	my $index;
	
	# check cache
	#
	if (exists $self->{C}->{$uid}) {
		$self->debug("found cached index for $uid, checking..");
		$index = $self->{C}->{$uid};
		if ($self->unfold($index) =~ /^UID.*:(.*)$/) {
			if ($1 eq $uid) {
				$self->debug("found key $uid in cache");
				return $index;
			} else {
				$self->debug("could not find key $uid in cache, deleting");
				delete $self->{C}->{$uid};
			}
		} else {
			warn("seekUid: discovered illegal UID property format, should be like UID;...:..., ignoring for now\n");
		}
	}
	
	# not in cache then lets search the file
	#
	$index = 0;
	for my $line (@{$self->{A}}) {
		if (substr($line, 0, 3) eq 'UID') {
			if ($self->unfold($index) =~ /^UID.*:(.*)$/) {
				$self->{C}->{$1} = $index; # cache in any case
				if ($1 eq $uid) {
					$self->debug("found key $uid");
					return $index;
				}
			} else {
				warn("discovered illegal UID property format, should be like UID;...:..., ignoring for now\n");
			}
		}
		$index++;
	}
	
	# doesn't exist!
	#
	return undef;	
}

sub removeComponent {
	my $self = shift;
	my $index = shift;
	
	my $i;
	$i = 0;	$i++ until ${$self->{A}}[$index - $i] =~ /^BEGIN:(\w+)$/; my $si = $index - $i;
	my $component = $1;
	$i = 0;	$i++ until ${$self->{A}}[$index + $i] =~ /^END:$component/; my $fi = $index + $i;
	$self->debug("component $component found between [$si, $fi]");
	
	splice @{$self->{A}}, $si, $fi - $si + 1;	
}

=head1 How Tie::iCal interprets iCal files

Tie::iCal interprets files by mapping iCal components into Perl hash keys and
iCal content lines into various Perl arrays and hashes.

=head2 Components

An iCal component such as VEVENT, VTODO or VJOURNAL maps to a hash key:-

	BEGIN:VEVENT
	UID:a_unique_uid
	NAME1:VALUE1
	..
	END:VEVENT

corresponds to

	$events{'a_unique_uid'} = ['VEVENT', {'NAME1' => 'VALUE1'}]

=head2 Subcomponents

An iCal subcomponent such as VALARM maps to a list of hash keys:-

	BEGIN:VALARM
	TRIGGER;VALUE=DURATION:-PT1S
	TRIGGER;VALUE=DURATION:-PT1S
	END:VALARM
	BEGIN:VALARM
	X-TIE-ICAL;VALUE=ANOTHER:HERE
	X-TIE-ICAL:HERE2
	X-TIE-ICAL-NAME:HERE2
	END:VALARM

corresponds to

	'VALARM' => [
		{
			'TRIGGER' => [
				[{'VALUE' => 'DURATION'},'-PT1S'],
				[{'VALUE' => 'DURATION'},'-PT1S']
			]
		},
		{
			'X-TIE-ICAL' => [
				[{'VALUE' => 'ANOTHER'},'HERE'],
				['HERE2']
			],
			'X-TIE-ICAL-NAME' => 'HERE2'
		}
	]

To see how individual content lines are formed see below.

=head2 Content Lines

Once unfolded, a content line may look like:-

    NAME;PARAM1=PVAL1;PARAM2=PVAL2;...:VALUE1,VALUE2,...

having an equivalent perl data structure like: -

    'NAME' => [{'PARAM1'=>'PVAL1', 'PARAM2'=>'PVAL2', ..}, 'VALUE1', 'VALUE2', ..]

or

    NAME:VALUE1,VALUE2,...

having an equivalent perl data structure like: -

    'NAME' => ['VALUE1', 'VALUE2', ..]

or

    NAME:VALUE

having an equivalent perl data structure like: -

    'NAME' => 'VALUE'

An blank value is mapped from

	NAME:

to 

	'NAME' => ''

Multiple contentlines with same name, i.e. FREEBUSY, ATTENDEE:-

    NAME;PARAM10=PVAL10;PARAM20=PVAL20;...:VALUE10,VALUE20,...
    NAME;PARAM11=PVAL11;PARAM21=PVAL21;...:VALUE11,VALUE21,...
    ...

having an equivalent perl data structure like: -

    'NAME' => [ 
        [{'PARAM10'=>'PVAL10', 'PARAM20'=>'PVAL20', ..}, 'VALUE10', 'VALUE20', ..],
        [{'PARAM11'=>'PVAL11', 'PARAM21'=>'PVAL21', ..}, 'VALUE11', 'VALUE21', ..],
        ...
    ]

or

    NAME:VALUE10,VALUE20,...
    NAME:VALUE11,VALUE21,...
    ...

having an equivalent perl data structure like: -

    'NAME' => [ 
        ['VALUE10', 'VALUE20', ..],
        ['VALUE11', 'VALUE21', ..],
        ...
    ]

or in a mixed form, i.e.

    NAME:VALUE10,VALUE20,...
    NAME;PARAM11=PVAL11;PARAM21=PVAL21:VALUE11,VALUE21,...
    NAME:VALUE12,VALUE22,...
    ...

having an equivalent perl data structure like: -

    'NAME' => [ 
        ['VALUE10', 'VALUE20', ..],
        [{'PARAM11'=>'PVAL11', 'PARAM21'=>'PVAL21', ..}, 'VALUE11', 'VALUE21', ..],
        ['VALUE12', 'VALUE22', ..],
        ...
    ]

=cut

sub toiCal {
	my $self = shift;
	my $uid = shift;
    my $c = shift;
    my $excludeComponent = shift;

	my @lines;
	my ($component, $e) = $excludeComponent ? (undef, $c) : @$c;
    push @lines, "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Numen Inest/NONSGML Tie::iCal $VERSION//EN", "BEGIN:$component", "UID:$uid" if ! $excludeComponent;
    foreach my $name (keys %$e) {
		if ($name eq 'RRULE') {
            if (ref($$e{$name}) ne 'HASH') {
                warn "RRULE property should be expressed as a hash, ignoring..\n";
            } else {
                my @rrule;
                foreach my $k (keys %{$$e{$name}}) {
                    push @rrule, ref(${$$e{$name}}{$k}) eq 'ARRAY' ? "$k=".join(',', @{${$$e{$name}}{$k}}) : "$k=".${$$e{$name}}{$k}; 
                }
                push @lines, "$name:".join(';',@rrule); 
            }
		} elsif (ref(\$$e{$name}) eq 'SCALAR') {
			push @lines, "$name:$$e{$name}";
		} elsif (ref($$e{$name}) eq 'ARRAY') {
			if (@{$$e{$name}} && !grep({ref($_) ne 'HASH'} @{$$e{$name}})) { # strict list of hashes => we have a subcomponent
				push @lines, "BEGIN:$name";
                foreach my $sc (@{$$e{$name}}) {
                    push @lines, $self->toiCal(undef, $sc, 1);
                }
                push @lines, "END:$name";
			} elsif (@{$$e{$name}} && !grep({ref($_) ne 'ARRAY'} @{$$e{$name}})) { # strict list of arrays => we have several content lines
                foreach my $cl (@{$$e{$name}}) {
    				if (ref(${$cl}[0]) eq 'HASH') { # we have params
						my ($params, @values) = @{$cl};
	    				push @lines, "$name;".join(";", map { "$_=$$params{$_}" } keys(%$params)).":".join(',',@values);
					} else { # we only have values
						push @lines, "$name:".join(',',@{$cl});
					}
                }
            } else {
				my ($params, @values) = @{$$e{$name}};
				push @lines, "$name;".join(";", map { "$_=$$params{$_}" } keys(%$params)).":".join(',',@values);
			}
		} else {
			warn "ignoring unimplemented ",ref(\${$e}{$name}),"  ->  ",$name."\n";
		}
	}
    push @lines, "END:$component", "END:VCALENDAR" if ! $excludeComponent;
	
	return @lines;
}

# taken from Text::ParseWords without single quote as quote char
# and keep flag
#
sub parse_line {
	# We will be testing undef strings
	no warnings;
	use re 'taint'; # if it's tainted, leave it as such

    my($delimiter, $line) = @_;
    my($word, @pieces);

    while (length($line)) {
		$line =~ s/^(["])								# a $quote
			((?:\\.|(?!\1)[^\\])*)						# and $quoted text
			\1											# followed by the same quote
			|											# --OR--
			^((?:\\.|[^\\"])*?) 						# an $unquoted text
			(\Z(?!\n)|(?-x:$delimiter)|(?!^)(?=["]))  
														# plus EOL, delimiter, or quote
		//xs or return;		# extended layout
		my($quote, $quoted, $unquoted, $delim) = ($1, $2, $3, $4);
		return() unless( defined($quote) || length($unquoted) || length($delim));

		$quoted = "$quote$quoted$quote";
        $word .= defined $quote ? $quoted : $unquoted;
 
        if (length($delim)) {
            push(@pieces, $word);
            undef $word;
        }
        if (!length($line)) {
            push(@pieces, $word);
		}
    }
    return(@pieces);
}

sub toHash {
	my $self = shift;
	my $index = shift;
	my $excludeComponent = shift;
	
	my $i;
	$i = 0;	$i++ until ${$self->{A}}[$index - $i] =~ /^BEGIN:(\w+)$/; my $si = $index - $i;
	my $component = $1;
	$i = 0;	$i++ until ${$self->{A}}[$index + $i] =~ /^END:$component/; my $fi = $index + $i;
	$self->debug("component $component found between [$si, $fi]");
	
	my %e;
	my $subComponent = '';
	for my $i ($si+1..$fi-1) {
		next if ${$self->{A}}[$i] =~ m/^UID/;
		if (${$self->{A}}[$i] =~ m/^\w+/) {
			my $contentLine = $self->unfold($i);
			if ($subComponent ne '') { # we are in a subcomponent
				$subComponent = '' if $contentLine =~ /^END:$subComponent$/;
				next;
			} elsif ($contentLine =~ /^BEGIN:(\w+)$/) { # we have found a subcomponent
				$subComponent = $1;
				push @{$e{$subComponent}}, $self->toHash($i, 1);
			} elsif ($contentLine =~ /^[\w-]+;.*$/s) { # we have params
				my ($nameAndParamString, @valueFragments) = &parse_line(':', $contentLine);
				my @values = &parse_line(',', join(':', @valueFragments));
				my ($name, @params) = &parse_line(';', $nameAndParamString);
				my %params = map { my ($p, $v) = split(/=/, $_); $p => $v } @params;
				if (exists $e{$name}) {
                    if (!(@{$e{$name}} && !grep({ref($_) ne 'ARRAY'} @{$e{$name}}))) { # not a strict list of arrays
                        $self->debug("found singleton data, converting to list..");
                        $e{$name} = [$e{$name}, [{%params}, @values]];
                    } else {
                        push @{$e{$name}}, [{%params}, @values];
                    }
                } else {
                    $e{$name} = [{%params}, @values];
                }
			} elsif ($contentLine =~ /^[\w-]+:.*$/s) { # we don't have params
				my ($name, @valueFragments) = &parse_line(':', $contentLine);
				my @values;
				if ($name eq 'RRULE') {
					my @params = &parse_line(';', join(':', @valueFragments));
					my %params = map { my ($p, $v) = split(/=/, $_); $p => $v =~ /,/ ? [split(/,/,$v)] : $v } @params;
					push @values, {%params};
				} else {
					@values = &parse_line(',', join(':', @valueFragments));
				}
				if (exists $e{$name}) {
                    if (!(ref($e{$name}) eq 'ARRAY' && @{$e{$name}} && !grep({ref($_) ne 'ARRAY'} @{$e{$name}}))) { # not a strict list of arrays
                        $self->debug("found singleton data, converting to list..");
                        $e{$name} = [$e{$name}, [@values]];
                    } else {
                        push @{$e{$name}}, [@values];
                    }
                } else {
					if (@values == 0) {
                    	$e{$name} = "";
					} elsif (@values == 1)  {
						$e{$name} = $values[0];
					} else {
						$e{$name} = [@values];
					}
                }
			} else { # what do we have?
				warn("discovered illegal property format, should be like NAME;...:..., ignoring for now\n");
			}
		}
	}
	
	return $excludeComponent ?  \%e : [$component, \%e] ;
}

=head1 BUGS

Property names are assumed not to be folded, i.e.

	DESCR
	 IPTION:blah blah..
     
RRULE property does not support parameters.

Property names that begin with UID can potentially confuse this module.

Subcomponents such as VALARM must exist after any UID property.

Deleting events individually may leave non-RFC2445 compliant empty VCALENDAR objects.

=head1 AUTHOR

Blair Sutton, <mailto:bsdz@cpan.org>, L<http://www.numeninest.com/>

=head1 COPYRIGHT

Copyright (c) 2006 Blair Sutton. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Tie::File>, L<Date::ICal>

=cut

1;