package Win32::Tracert::Statistics;
$Win32::Tracert::Statistics::VERSION = '0.011';
use strict;
use warnings;

use Object::Tiny qw (input);

# ABSTRACT: Permit access to some statistics from determined Win32::Tracert path

#redefine constuctor
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );
    # Extra checking and such
    die "You must define [input] attribute" if (! defined $self->input);
    die "Attending HASH REF and got something else ! \n" unless ref($self->input) eq "HASH";
    
    return $self;
}

sub average_responsetime_for{
    my ($self,$packet_sample)=@_;
    my $average_responsetime;
    my $number_of_excluded_values;
    
    foreach my $ipaddress (keys %{$self->input}){
        my %responsetime_sample=map {$_->{HOPID} => _rounding_value_to_1($_->{$packet_sample})} @{$self->input->{$ipaddress}{HOPS}};
        my @initial_responsetime_values=_list_responsetime_values(\%responsetime_sample);
        my @filtered_responsetime_values=_exclude_star_value(@initial_responsetime_values);
        my $sum_responsetime=0;
        map { $sum_responsetime+=$_ } @filtered_responsetime_values;
        $average_responsetime=_average_responsetime($sum_responsetime,scalar @filtered_responsetime_values);
        $number_of_excluded_values=_responsetime_values_excluded(scalar @initial_responsetime_values, scalar @filtered_responsetime_values);
    }
    return $average_responsetime, $number_of_excluded_values;
}

sub average_responsetime_global{
    my ($self)=@_;
    my %result;
    foreach my $packetsmp ($self->list_packet_samples){
        my ($result,$number_of_excluded_values)=$self->average_responsetime_for("$packetsmp");
        $result{$packetsmp}=[$result,$number_of_excluded_values];
    }
    my $total_sample=scalar $self->list_packet_samples;
    my $sum_responsetime=0;
    my $sum_of_excluded_values=0;
    map { $sum_responsetime+=$_->[0] ; $sum_of_excluded_values+=$_->[1] } values %result;
    my $average_responsetime=_average_responsetime($sum_responsetime,$total_sample);
    my $average_number_of_excluded_values=$sum_of_excluded_values / $total_sample;
    
    return $average_responsetime, $average_number_of_excluded_values;
}    

sub list_packet_samples{
    my ($self)=@_;
    my ($ipaddress) = keys %{$self->input};
    my @packetsmp_list=grep {$_ =~ /PACKET/} keys %{$self->input->{$ipaddress}{HOPS}[0]};
    return @packetsmp_list;
}

sub _list_responsetime_values{
    my $responsetime_hashref=shift;
    return values %$responsetime_hashref;
}

sub _exclude_star_value{
    my @values_to_check=@_;
    return grep {$_ ne '*'} @values_to_check;
}

sub _rounding_value_to_1{
    my $value=shift;
    my $rounded_value = $value eq '<1' ? 1 : $value;
    return $rounded_value;
}

sub _average_responsetime{
    my ($sum_of_values,$number_of_values)=@_;
    return $sum_of_values / $number_of_values;
}

sub _responsetime_values_excluded{
    my ($initial_values,$filtered_values)=@_;
    return $initial_values - $filtered_values;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Tracert::Statistics - Permit access to some statistics from determined Win32::Tracert path

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Win32::Tracert;
    use Win32::Tracert::Statistics;

    my $target = "127.0.0.1";
    my $route = Win32::Tracert->new(destination => "$target");
    my $result;
    my $number_of_excluded_values;
    
    if ($route->to_trace->found){
        my $statistic=Win32::Tracert::Statistics->new(input => $route->path);
        foreach my $packetsmp ($statistic->list_packet_samples){
            ($result,$number_of_excluded_values)=$statistic->average_responsetime_for("$packetsmp");
            print "$packetsmp: Average response time is $result with $number_of_excluded_values value(s) excluded\n";
        }
    }

=head2 Attributes

=over 1

=item *input

This attribute is used as argument before creating object.
It contain the result of path method from route object.
The result must be a hashtable and dereferenced

=back

=head1 METHODS

=head2 average_responsetime_for

This method take a packet sample name as argument and 
return a list of two value: 

=over 2

=item 1) average responsetime for selected packet sample,

=item 2) number of value exluded from calculated average responsetime,

=back

You can get packet samples list with S<list_packet_samples> method.

=head2 average_responsetime_global

This method return a list of two value: 

=over 2

=item 1) average responsetime from all packet samples,

=item 2) average number of exluded values from average responsetime calculated,

=back

=head2 list_packet_samples

This method return a list of named packet samples. 
By default on Win32 system, Tracert send 3 packets at each hop between source to destination.

Each value stored in packet sample named PACKET1_RT, PACKET2_RT, PACKET3_RT in Win32::Tracert::Parser object.

In order to offer, in the future, possibility to specify number of packet to send it is recommended to use this method. 

=head1 SEE ALSO

=begin :list



=end :list

* L<Win32::Tracert>
* L<Win32::Tracert::Parser>

=head1 AUTHOR

Sébastien Deseille <sebastien.deseille@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sébastien Deseille.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
