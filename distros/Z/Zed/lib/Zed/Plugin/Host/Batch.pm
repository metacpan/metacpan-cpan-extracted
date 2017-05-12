package Zed::Plugin::Host::Batch;
use strict;

use Zed::Config::Space;
use Zed::Output;
use Zed::Plugin;
use Zed::Config::Env;

=head1 SYNOPSIS

    batch space using regex
    ex:
        batch idc 2

=cut

invoke "batch" => sub {
    my( $group, $list, $batch, @ret, %group );

    ($group, $batch) = @_;

    $group = env('batch')->{$group};
    $group = qr/$group/||undef if $group;

    $list ||= usespace();
    $batch ||= 1;

    debug("group:", $group);
    debug("list:", $list);

    info("illegal batch($batch)") and return unless $batch > 0;
    info( "input list error" ) and return unless $list;

    my @host = space($list);
    info("no hosts in $list") and return unless @host;
    
    $batch = scalar @host * $batch if $batch > 0 && $batch < 1;

    map{$_ =~ $group; debug('grep:',$1);  push @{ $group{ $1 || undef} }, $_ }@host if $group;
    $group{all} = \@host unless keys %group;

    debug('groups:', \%group);

    while(keys %group)
    {
       my @group;
       map{
           my $value = $group{$_} ;
           push @group, splice @$value, 0, $batch; 
           delete $group{$_} unless @$value;
       }keys %group;
       push @ret, \@group;
    }
    

    debug("ret:", \@ret);

    return unless @ret;

    space_clean($list);
    for my $c(0..(scalar @ret - 1))
    {
        my( $key, $v ) = ($list.$c, $ret[$c]);
        space($key, $v);       
        info("add $key hosts[", scalar @$v, "] suc!");
    }
};
1;
