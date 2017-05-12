#$Id: SAX.pm 505 2008-06-27 22:53:18Z rick $
package iCal::Parser::SAX;
use strict;

use base qw(XML::SAX::Base);
use iCal::Parser;
use IO::File;
use IO::String;
use DateTime;

# Get version from subversion url of tag or branch.
our $VERSION= do {(q$URL: svn+ssh://xpc/var/lib/svn/rick/perl/ical/iCal-Parser-SAX/tags/1.09/lib/iCal/Parser/SAX.pm $=~ m$.*/(?:tags|branches)/([^/ 	]+)$)[0]||'0.1'};

our %NAMES=('X-WR-RELCALID'=>'id', 'X-WR-CALNAME'=>'name',
	    'X-WR-CALDESC'=>'description');
sub new {
    my($class,%options)=@_;
    my $handler=delete $options{Handler};
    my $self=XML::SAX::Base->new($handler ? (Handler=>$handler) : ());
    $self=bless $self,$class;
    $self->{no_escape}=delete $options{no_escape};
    $self->{_calparser}=iCal::Parser->new(%options);
    return $self;
}
sub _parse_characterstream {
    shift->_parse_fh(@_);
}
sub _parse_bytestream {
    shift->_parse_fh(@_);
}
sub _parse_systemid {
    my ($self, $sysid, $options) = @_;
    $self->_parse_fh(__systemid_to_fh($sysid));
}
sub _parse_string {
    my ($self, $str, $options) = @_;

    $self->_parse_fh(IO::String->new($str));
}
sub _parse_fh {
    my($self,$fh,$options)=@_;

    return $self->parse_hash($self->{_calparser}->parse($fh));
}
sub parse_uris {
    my $self=shift;

    foreach my $uri (@_) {
	$self->{_calparser}->parse(__systemid_to_fh($uri));
    }
    return $self->parse_hash($self->{_calparser}->calendar);
}
sub __systemid_to_fh {
    my $sysid=shift;
    if($sysid =~ m{^(http|ftp|https)://}) {
	eval {require LWP::UserAgent;};
	die "LWP required for $sysid\n" if $@;
	my $req=HTTP::Request->new(GET => $sysid);
	my $ua=LWP::UserAgent->new;
	$ua->agent(__PACKAGE__);
	my $res=$ua->request($req);
	unless($res->is_success) {
	    die "Can't read $sysid\n";
	}
	return IO::String->new($res->content);
    } else {
	return IO::File->new($sysid,'r') or die "Can't open $sysid, $!\n";
    }
}
sub parse_hash {
    my($self,$hash)=@_;

    $self->SUPER::start_document;
    $self->start('ical');
    foreach my $cal (@{ $hash->{cals} }) {
	$self->start('calendar',{ map {
	    ($NAMES{$_}||lc $_)=>$cal->{$_}
	} keys %$cal });
	$self->end('calendar');
    }
    $self->process_events($hash);

    if(scalar @{$hash->{todos}}) {
	$self->start('todos');
	map {$self->process_component($_,'todo')} @{ $hash->{todos} };
	$self->end('todos');
    }
    $self->end('ical');
    $self->SUPER::end_document;
}
sub process_events {
    my($self,$hash)=@_;
    my $events=$hash->{events};
    return unless $events;
    my $cals=$hash->{cals};

    $self->start('events');
    my @years=sort { $a <=> $b } keys %$events;
    foreach my $y (@years) {
	$self->start('year',{year=>$y});
	my $year=$events->{$y};
	#fill in missing months from start->end
	my @months=sort { $a <=> $b } keys %$year;
	my $sm= $months[0];
	my $se= $months[-1];

	foreach my $m ($sm .. $se) {
	    my $month=$year->{$m};
	    my $d1=DateTime->new(year=>$y,month=>$m,day=>1);
	    warn $d1->ymd, " ---\n" if $self->{debug};
	    $self->start('month', {month=>$m});
	    my $week=$d1->week_number;
	    $self->start('week',{week=>$week});
	    #pad beggining of week
	    my $dow=$d1->day_of_week;
	    for($d1->subtract(days=>$d1->day_of_week-1);$d1->day_of_week!=$dow;
		$d1->add(days=>1)) {
		$self->process_day($d1,$self->day($d1,$events));
	    }
	    for(;$d1->month == $m;$d1->add(days=>1)) {
		if($d1->week != $week) {
		    $self->end('week',{week=>$week});
		    $week=$d1->week;
		    $self->start('week',{week=>$week});
		}
		$self->process_day($d1,$self->day($d1,$events));
	    }
	    #pad end of month
	    for(;$d1->day_of_week != 1;$d1->add(days=>1)) {
		$self->process_day($d1,$self->day($d1,$events));
	    }
	    $self->end('week');
	    $self->end('month');
	}
	$self->end('year');
    }
    $self->end('events');
}
sub day {
    my($self,$d,$events)=@_;
    my($yr,$mo);
    return unless $yr=$events->{$d->year};
    return unless $mo=$yr->{$d->month};
    return $mo->{$d->day};
}
sub process_day {
    my($self,$d,$day)=@_;
    #warn $d->ymd,"\n" if $self->{debug};

    # figure out max# conflicting appointments. and output in xml
    # makes html generation of weekly/daily calendar easier
    my @events=();
    my $conflict=0;
    if($day) {
	@events=sort by_type_time values %$day;
	my @a=(); #event span
	foreach my $e (@events) {
	    if($e->{allday}) {
		push @a,undef;
		next;
	    }
	    #if an event ends at e.g., 9am and another starts
	    #at 9, intersect will generate an overlap.
	    #so, subtract 1 sec from the end of each event
	    ## unless start == end
	    ## note start > end is an error!
	    my $end=$e->{DTSTART}->compare($e->{DTEND}) < 0
	    ? $e->{DTEND}->clone->subtract(seconds=>1) : $e->{DTEND};
	    push @a, DateTime::Span->from_datetimes
	    (start=>$e->{DTSTART}, end=>$end);
	}
	my @overlap=(0);
	# each conflict adds one to the count of conflicts for the event
	# it conflicts with
	foreach my $i (1..$#a) {
	    my $span=$a[$i];
	    $overlap[$i]=0;
	    next unless $span;
	    foreach my $j (0..$i-1) {
		next unless $a[$j];
		$overlap[$i]=$overlap[$j]+1 if $span->intersects($a[$j]);
	    }
	    $events[$i]->{'conflict-number'}=$overlap[$i] if $overlap[$i];
	}
	map { $conflict = $_ if $_ > $conflict } @overlap;
    }
    $self->start('day',{date=>$d->ymd,
			$conflict ? (conflict=>$conflict) : ()});
    map {$self->process_component($_,'event')} @events;
    $self->end('day');
}
sub by_type_time {		# For sorting lists of events
  # Two events on the same day?  All day events come first
  return -1 if $a->{allday} && !$b->{allday};
  return  1 if $b->{allday} && !$a->{allday};

  # If they're both all day events, sort by summary text
  return $a->{SUMMARY} cmp $b->{SUMMARY} if $a->{allday} && $b->{allday};

  # Otherwise, sort by start time
  return $a->{DTSTART} <=> $b->{DTSTART};
}
sub process_component {
    my($self,$ee,$type)=@_;
    my %attrs=();
    # pull out attributes before generic processing
    # of key/value pairs into elements
    #clone in case event processed more than once
    my %e=%$ee;
    $attrs{uid}=delete $e{UID} if $e{UID};
    $attrs{idref}=delete $e{idref} if $e{idref};
    $attrs{'all-day'}=delete $e{allday} if $e{allday};
    # used in xslt stylesheet to figure out which
    # overlapping event this is
    $attrs{'conflict-number'}=delete $e{'conflict-number'}
    if $e{'conflict-number'};

    $self->start($type,%attrs);
    while(my($k,$v)=each(%e)) {
	if(ref $v eq 'ARRAY') {
	    my $list=$k . 's';
	    $self->start($list,count=>scalar @$v);
	    map {$self->process_component($_,$k)} @$v;
	    $self->end($list);
	} elsif(ref $v eq 'HASH') {
	    $self->process_component($v,$k);
	} else {
	    $self->text_element($k,$v);
	}
    }
    $self->end($type);
}
sub start {
    my $self=shift;
    $self->SUPER::start_element($self->make_element(@_));
}
sub end {
    my $self=shift;
    $self->SUPER::end_element($self->make_element(@_));
}
sub make_element {
    my $self=shift;
    my $n=lc shift;
    my %a=ref $_[0] ? %{$_[0]} : @_;
    my %h=(Name=>"$n");
    return \%h unless %a;
    while(my($k,$v) = each %a) {
	$h{Attributes}->{"{}$k"} = {Name=>$k, Value=>escape($v,$self->{no_escape})};
    }
    return \%h;
}
sub escape {
    my $text=shift;
    my $no_escape=shift;
    return '' unless $text;
    unless($no_escape) {
	$text=~s/&/\&amp;/go;
	$text=~s/"/\&quot;/go;
	$text=~s/'/&#39;/go;
    }
    $text=~s/</&lt;/go;
    $text=~s/\\n/&#10;/go;
    $text=~s/\\//go;
    return $text;
}
sub text_element {
    my($self, $n, $v, %a)=@_;
    $self->start($n, %a);
    if($v) {
	my $text=escape($v,$self->{no_escape});
	$self->SUPER::characters({Data=>$text});
    }
    $self->end($n);
}
1;
__END__

=head1 NAME

iCal::Parser::SAX - Generate SAX events from an iCalendar

=head1 SYNOPSIS

  use iCal::Parser::SAX;
  my $parser=iCal::Parser::SAX->new(Handler=>SAXHandler,%args);
  $parser->parse_uri($file);
  $parser->parse_uris(@files);

=head1 DESCRIPTION

This module uses L<iCal::Parser> to generates SAX events
for the calendar contents.

The xml document generated is designed
for creating monthly calendars with weeks beginning on monday
(e.g., by passing the output through an xsl styleheet).

The basic structure of the generated document (if output through
a simple output handler like C<XML::SAX::Writer>), is as follows:

  <ical>
    <calendars>
     <calendar id="cal-id" index="n" name="..." description="..."/>
    </calendars>
    <events>
     <year year="YYYY">
       <month month="[1-12]">
         <week week="n">
           <day date="YYYY-MM-DD">
             <event uid="event-id" idref="cal-id" [all-day="1"]>
               <!-- ... -->
             </event>
           </day>
         </week>
       </month>
    </events>
    <todos>
      <todo idref="cal-id" uid="...">
        <!--- ... -->
      </todo>
    </todos>
  </ical>

Along with basics, such as converting calendar attributes
to lowercase elements (e.g., a C<DTSTART> attribute in the input
would generate a sax event like C<element({Name=>'dtstart'})>),
a number of other processes occur:

=over 4

=item *

C<day> elements are are generated for each date within the months
from the first month in the input to the last, even if there are no
calendar events on that day. This guarantees a complete calendar month
for further processing. If there is an overlap between two or more
events, the attribute C<conflict>, containing the number of concurrent
overlaps, is added to the element.

=item *

If the beginning or end of the month does not start on a monday,
or end on a sunday, the days from the previous (next) month month
are duplicated within the first (last) week of the current month,
including duplicate copies of any calendar events occuring on those
days. This allows for displaying a monthly calendar the same way
a program such as Apple's iCal would, with calendar events
showing up if they fall within the overlapping days in the first
or last week of a monthly calendar.

=back

=head1 METHODS

Along with the standard SAX parsing methods C<parse_uri>, C<parse_file>, etc.),
the following methods are supported.

=head2 new(%args)

Create a new SAX parser. All arguments other than C<Handler> and
C<no_escape> are passed to L<iCal::Parser>.

=head3 Arguments

=over 4

=item Handler

The SAX handler.

=item no_escape

If not set, quotes, ampersands and apostrophes are converted to entites.
In any case E<lt> is converted to an entity, C<\\n> is converted to
the return entity and double backslashes (C<\\>) are removed.

=back

=head2 parse_uris(@uris)

Pass all the input uris to C<iCal::Parser> and generate
a combined output calendar.


=head2 parse_hash($hash)

Parse the hash returned from L<iCal::Parser::calendar> directly.

=head1 AUTHOR

Rick Frankel, cpan@rickster.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<iCal::Parser>, L<XML::SAX::Base>
