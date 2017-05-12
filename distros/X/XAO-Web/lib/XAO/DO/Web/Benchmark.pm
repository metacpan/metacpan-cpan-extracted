=head1 NAME

XAO::DO::Web::Benchmark - benchmarking helper

=head1 SYNOPSIS

  <%Benchmark mode='enter' tag='main'%>
  ....
  <%Benchmark mode='leave' tag='main'%>
  ...
  <%Benchmark mode='stats' tag='main'
    dprint
    template={'Count: <$COUNT$> Total: <$TOTAL$> Avg: <$AVERAGE$>'}
  %>
  ...
  <%Benchmark mode='stats'
    header.template='<ul>'
    template=       '<li>Tag: <$TAG/h$> Avg: <$AVERAGE$> Med: <$MEDIAN$></li>'
    footer.template='</ul>'
  %>

=head1 DESCRIPTION

Remembers timing at the given points during template processing and
reports on them later. The tag is required for 'enter' and 'leave'
modes.

System-wide benchmarking can also be controlled with 'system-start'
and 'system-stop' modes. With that all sub-templates are individually
benchmarked.  The tags are automatically build based on their 'path' or
'template' arguments.

Results can be retrieved using 'stats' mode. With a 'dprint' parameter
it will dump results using the dprint() call to be seen in the server
log typically. Given a template or a path the results can be included in
the rendered page.

=cut

###############################################################################
package XAO::DO::Web::Benchmark;
use warnings;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'Web::Action');

###############################################################################

sub display_enter ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    my $tag=$args->{'tag'} || throw $self "- no tag";
    $self->benchmark_enter($tag,$args->{'key'},$args->{'description'});
}

###############################################################################

sub display_leave ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    my $tag=$args->{'tag'} || throw $self "- no tag";
    $self->benchmark_leave($tag,$args->{'key'});
}

###############################################################################

sub display_system_start ($) {
    my $self = shift;
    $self->benchmark_start();
}

###############################################################################

sub display_system_stop ($) {
    my $self = shift;
    $self->benchmark_stop();
}

###############################################################################

sub data_stats ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    return { benchmarks => $self->benchmark_stats($args->{'tag'}) };
}

###############################################################################

sub display_stats ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $stats=$args->{'data'}->{'benchmarks'} || throw $self "- no 'data' (INTERNAL)";

    my @tags;
    my $orderby=$args->{'orderby'} || 'total';

    if($orderby eq 'total') {
        @tags=sort { $stats->{$b}->{'total'} <=> $stats->{$a}->{'total'} } keys %$stats;
    }
    elsif($orderby eq 'average') {
        @tags=sort { $stats->{$b}->{'average'} <=> $stats->{$a}->{'average'} } keys %$stats;
    }
    elsif($orderby eq 'median') {
        @tags=sort { $stats->{$b}->{'median'} <=> $stats->{$a}->{'median'} } keys %$stats;
    }
    elsif($orderby eq 'count') {
        @tags=sort { ($stats->{$b}->{'count'} <=> $stats->{$a}->{'count'}) || ($stats->{$b}->{'average'} <=> $stats->{$a}->{'average'}) } keys %$stats;
    }
    elsif($orderby eq 'tag') {
        @tags=sort { $a cmp $b } keys %$stats;
    }
    else {
        throw $self "- unknown orderby";
    }

    if($args->{'limit'} && scalar(@tags)>$args->{'limit'}) {
        splice(@tags,$args->{'limit'})
    }

    my $page=$self->object;

    $page->display($args,{
        path        => $args->{'header.path'},
        template    => $args->{'header.template'},
        TOTAL_ITEMS => scalar(@tags),
    }) if $args->{'header.path'} || defined $args->{'header.template'};

    foreach my $tag (@tags) {
        my $d=$stats->{$tag};

        next unless $d->{'count'};

        $page->display($args,{
            TAG         => $tag,
            COUNT       => $d->{'count'},
            AVERAGE     => $d->{'average'},
            MEDIAN      => $d->{'median'},
            TOTAL       => $d->{'total'},
            CACHEABLE   => $d->{'cacheable'} || 0,
            CACHE_FLAG  => $d->{'cache_flag'} || 0,
        }) if $args->{'path'} || defined $args->{'template'};

        if($args->{'dprint'} || $args->{'eprint'}) {
            my $str="BENCHMARK($tag): COUNT=$d->{'count'} AVERAGE=$d->{'average'} MEDIAN=$d->{'median'} TOTAL=$d->{'total'} CACHEABLE=$d->{'cacheable'} CACHE_FLAG=$d->{'cache_flag'}";
            dprint $str if $args->{'dprint'};
            eprint $str if $args->{'eprint'};
        }
    }

    $page->display($args,{
        path        => $args->{'footer.path'},
        template    => $args->{'footer.template'},
        TOTAL_ITEMS => scalar(@tags),
    }) if $args->{'footer.path'} || defined $args->{'footer.template'};
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2013 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
