#!/usr/bin/perl
# Extract every iCalendar example of draft-ietf-calext-jscalendar-icalendar
# into a complete .ics file, for t/roundtrip.t's stability test.
#
#   perl tools/extract-icalendar-examples.pl DRAFT.txt testdata/jscalendar-icalendar-29
#
# The draft's examples leave things implicit (section 1.3.1): a bare list
# of properties is a VEVENT in a VCALENDAR, "..." stands for anything
# irrelevant (and any missing END lines), and mandatory properties may be
# left out.  This fills all of that in.  A VTODO gets no DTSTART: it is
# optional there, and adding one would change the example.
use strict;
use warnings;

my ($draft, $outdir) = @ARGV;
die "usage: $0 DRAFT.txt OUTDIR\n" unless $draft and $outdir;

open my $fh, '<', $draft or die "$draft: $!";
my @lines;
while (my $l = <$fh>) {
  $l =~ s/\r?\n\z//;
  next if $l =~ /\f/;
  next if $l =~ /^\S.*\[Page \d+\]\s*$/;       # page footer
  next if $l =~ /^Internet-Draft\s/;           # page header
  push @lines, $l;
}
close $fh;

mkdir $outdir unless -d $outdir;
my %count;
for (my $i = 0; $i < @lines; $i++) {
  next unless $lines[$i] =~ /^\s+--- iCalendar:\s*$/;
  my @ex;
  my $j = $i + 1;
  for (; $j < @lines; $j++) {
    last if $lines[$j] =~ /^\s+--- JSCalendar:\s*$/;
    last if $lines[$j] =~ /^\s+Figure \d+:/;
    last if $lines[$j] =~ /^\d+\.\d/;          # next section
    push @ex, $lines[$j];
  }
  # the figure this example belongs to
  my $fig;
  for (my $k = $j; $k < @lines; $k++) {
    if ($lines[$k] =~ /^\s+Figure (\d+):/) { $fig = $1; last }
  }
  next unless defined $fig;
  my @ics = complete(@ex);
  next unless @ics;
  my $name = sprintf('figure-%03d%s.ics', $fig, $count{$fig}++ ? "-$count{$fig}" : '');
  open my $out, '>', "$outdir/$name" or die "$outdir/$name: $!";
  print $out map { "$_\r\n" } @ics;
  close $out;
}

sub complete {
  # strip the example's indentation (most are indented 3, some 6)
  my @nonblank = grep { /\S/ } @_;
  my ($indent) = sort { $a <=> $b } map { /^( *)/; length $1 } @nonblank;
  my @in = map { substr($_, $indent) } @nonblank;
  # unfold, drop "..."
  my @props;
  for my $l (@in) {
    if ($l =~ /^ / and @props) { $props[-1] .= substr($l, 1); next }
    push @props, $l;
  }
  @props = grep { $_ ne '...' } @props;
  return () unless @props;

  my ($top) = map { /^BEGIN:(\S+)/i ? uc $1 : () } $props[0];
  $top //= '';
  if ($top ne 'VCALENDAR') {
    if (!$top or !grep { $top eq $_ } qw(VEVENT VTODO VJOURNAL VFREEBUSY VTIMEZONE)) {
      @props = ('BEGIN:VEVENT', @props, 'END:VEVENT');
    }
    @props = ('BEGIN:VCALENDAR', @props, 'END:VCALENDAR');
  }

  # walk the components: close what is left open, add what is mandatory
  my @out;
  my @stack;          # [name, {props seen}, index of its BEGIN in @out]
  my $close = sub {
    my $c = pop @stack;
    my ($name, $seen, $begin) = @$c;
    my @add;
    if ($name eq 'VCALENDAR') {
      # VERSION and PRODID go first, the way every calendar has them
      my @head;
      push @head, 'VERSION:2.0' unless $seen->{VERSION};
      push @head, 'PRODID:-//jscalendar-icalendar-29//example//EN' unless $seen->{PRODID};
      splice @out, $begin + 1, 0, @head;
      push @add, ('BEGIN:VEVENT', 'UID:example-implicit', 'DTSTAMP:20060102T030405Z',
                  'DTSTART:20060102T030405Z', 'END:VEVENT') unless $seen->{_children};
    }
    elsif ($name eq 'VEVENT' or $name eq 'VTODO') {
      push @add, 'UID:CC0A494A-6E07-4827-8294-0752DD1ECFA4' unless $seen->{UID};
      push @add, 'DTSTAMP:20060102T030405Z' unless $seen->{DTSTAMP};
      push @add, 'DTSTART:20060102T030405Z' unless $seen->{DTSTART} or $name eq 'VTODO';
    }
    elsif ($name eq 'VALARM') {
      push @add, 'ACTION:DISPLAY' unless $seen->{ACTION};
      push @add, 'TRIGGER:-PT5M' unless $seen->{TRIGGER};
      push @add, 'DESCRIPTION:alarm' unless $seen->{DESCRIPTION};
    }
    push @out, @add, "END:$name";
  };
  for my $p (@props) {
    my ($pname) = $p =~ /^([A-Za-z0-9-]+)/;
    $pname = uc($pname // '');
    if ($pname eq 'BEGIN') {
      my ($c) = $p =~ /^BEGIN:(\S+)/i;
      $stack[-1][1]{_children}++ if @stack and grep { uc $c eq $_ } qw(VEVENT VTODO VJOURNAL VFREEBUSY);
      push @out, $p;
      push @stack, [uc $c, {}, $#out];
      next;
    }
    if ($pname eq 'END') {
      my ($c) = $p =~ /^END:(\S+)/i;
      $close->() while @stack and $stack[-1][0] ne uc $c;
      $close->() if @stack;
      next;
    }
    $stack[-1][1]{$pname}++ if @stack;
    push @out, $p;
  }
  $close->() while @stack;
  return @out;
}
