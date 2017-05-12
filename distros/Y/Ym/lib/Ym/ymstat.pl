#!/usr/bin/perl -w

package Ym;

use strict;
use warnings;

use Ym;

sub TimeCycleStat {
  my ($tree) = @_;

  my %stat    = ();
  my $verbose = 0;

  sub myLookup;    # Function prototype definition for recursion calls.
                 # Determine value of definition ($opt) for specified object.
                 # If there is no clear definition, than we recursively look in templates.

  sub myLookup {
    my ($tree, $leaf, $opt, $tmpl_type) = @_;
    my $ret = 0;
    if (defined($leaf->{$opt})) {
      $ret = $leaf->{$opt};
    }
    else {
      if (defined($leaf->{'use'})) {
        my $template = $leaf->{'use'};
        if (!defined($tree->{$tmpl_type}->{$template})) {
          return $ret;
        }
        my $template_ref = $tree->{$tmpl_type}->{$template};
        $ret = myLookup($tree, $template_ref, $opt, $tmpl_type);
      }
    }
    return $ret;
  }

  sub CountK {
    my ($tree, $ref) = @_;

    unless (defined($tree->{'config'}->{'interval_length'})) {
      die "Error: 'interval_length' option is not defined in nagios.cfg\n";
    }
    my $interval_length = $tree->{'config'}->{'interval_length'};

    my $retry_field_name = '';
    my $tmpl_type        = '';

    if (defined($ref->{'service_description'})) {

      # Than it is a service
      $retry_field_name = 'retry_check_interval';
      $tmpl_type        = 'service_templates';
    }
    else {

      # This is a host
      $retry_field_name = 'retry_interval';
      $tmpl_type        = 'host_templates';
    }

    my $retry_interval =
      defined($ref->{$retry_field_name})
      ? $ref->{$retry_field_name}
      : myLookup($tree, $ref, $retry_field_name, $tmpl_type);

    my $max_attempts =
      defined($ref->{'max_check_attempts'})
      ? $ref->{'max_check_attempts'}
      : myLookup($tree, $ref, 'max_check_attempts', $tmpl_type);

    my $k = $retry_interval * $max_attempts * $interval_length;    # Value in seconds.

    return $k;
  }

  foreach my $h (keys %{$tree->{'hosts'}}) {
    ($verbose) && print "$h\n";

    my $href = $tree->{'hosts'}->{$h};
    my $k = CountK($tree, $href);

    push(@{$stat{$k}->{'hosts'}}, $h);

    foreach my $s (keys %{$href->{'services'}}) {
      ($verbose) && print "  $s\n";

      my $sref = $href->{'services'}->{$s};
      my $k = CountK($tree, $sref);

      #push(@{$stat{$k}->{'services'}}, "$h:$s");
      $stat{$k}->{'services'}->{$s}++;
    }
  }

  print Dumper \%stat;
}

1;
