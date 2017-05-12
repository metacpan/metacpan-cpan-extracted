package inc::dtRdrBuilder::PodCoverage;

# Copyright (C) 2007 by Eric Wilhelm and OSoft, Inc.
# License: perl

# fix podcoverage

use warnings;
use strict;
use Carp;

# this is sort of a MB wishlist item
sub ACTION_testpodcoverage {
  my $self = shift;

  package Module::Build::doTestPodCoverage;
  # uh, Test::Pod::Coverage import is cruel
  eval q{use Test::Pod::Coverage 1.00 (); 1}
    or die "The 'testpodcoverage' action requires ",
           "Test::Pod::Coverage version 1.00";

  local @INC = @INC; unshift(@INC, 'lib');

  my @args;
  # TODO if something (like $p->{pod_coverage_class} or ???)
  if(1) {
    # XXX Pod::Coverage can't check code that doesn't compile! (e.g. Win32)
    #@args = ({coverage_class => 'Pod::Coverage::PodDriven'});
    @args = ({coverage_class => 'inc::dtRdrBuilder::AlsoPodCoverage'});
  }

  # I guess? why bother with depending on docs?
  my @files = @{$self->args->{ARGV}};
  @files = do {my $f = $self->_find_file_by_type('pm',  'lib');
    keys %$f} unless(@files);

  s#^lib[\\/]*## for(@files);

  Test::Builder->new->plan('no_plan');
  foreach my $file (@files) {
    my $package = $file;
    $package =~ s#/+#::#g;
    $package =~ s/\.pm$//;
    Test::Pod::Coverage::pod_coverage_ok($package, @args);
  }
}

package Pod::Coverage::PodDriven;
$INC{'Pod/Coverage/PodDriven.pm'} = __FILE__; # slap Test::Pod::Coverage

use base 'Pod::Coverage';

sub _get_pods {
    my $self = shift;

    my $package = $self->{package};

    print "getting pod location for '$package'\n" if $self->TRACE_ALL;
    $self->{pod_from} ||= Pod::Find::pod_where( { -inc => 1 }, $package );

    my $pod_from = $self->{pod_from};
    unless ($pod_from) {
        $self->{why_unrated} = "couldn't find pod";
        return;
    }

    print "parsing '$pod_from'\n" if $self->TRACE_ALL;
    my $pod = Pod::Coverage::PodDriven::Extractor->new;
    $pod->parse_from_file( $pod_from, '/dev/null' );

    #warn "identifiers: @{$pod->{identifiers}}";
    if($pod->{directives}) {
      foreach my $dir (qw(trustme private)) {
        $pod->{directives}{$dir} or next;
        $self->{$dir} ||= [];
        push(@{$self->{$dir}}, @{$pod->{directives}{$dir}});
      }
    }
    return $pod->{identifiers} || [];
}

package Pod::Coverage::PodDriven::Extractor;

use base 'Pod::Parser';

use constant debug => 0;
# extract subnames from a pod stream
sub command {
    my $self = shift;
    my ($command, $text, $line_num) = @_;
    if ($command eq 'item' || $command =~ /^head(?:2|3|4)/) {
        # take a closer look
        my @pods = ($text =~ /\s*([^\s\|,\/]+)/g);

        foreach my $pod (@pods) {
            warn "Considering: '$pod'\n" if debug;

            # it's dressed up like a method cal
            $pod =~ /-E<\s*gt\s*>(.*)/  and $pod = $1;
            $pod =~ /->(.*)/            and $pod = $1;
            # it's wrapped in a pod style B<>
            $pod =~ s/[A-Z]<//g;
            $pod =~ s/>//g;
            # has arguments, or a semicolon
            $pod =~ /(\w+)\s*[;\(]/   and $pod = $1;

            warn "Adding: '$pod'\n" if debug;
            push @{$self->{identifiers}}, $pod;
        }
    }
    elsif(($command eq 'for') and ($text =~ s/^podcoverage_(\w+)\s*//)) {
      my $directive = $1;
      warn "directive $directive for $text" if debug;
      $self->{directives} ||= {};
      $self->{directives}{$directive} ||= [];
      push(@{$self->{directives}{$directive}},
        map({"^$_\$"} split(/\s/, $text)));
    }
}

# vi:ts=2:sw=2:et:sta
1;
