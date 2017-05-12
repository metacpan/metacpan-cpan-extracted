package Win32::Tracert::Parser;
$Win32::Tracert::Parser::VERSION = '0.011';
use strict;
use warnings;

use Object::Tiny qw (input);
use Net::hostent;
use Socket;

# ABSTRACT: Parser object used by method B<to_trace> in Win32::Tracert

sub to_parse{
    my $self=shift;
    my $tracert_outpout=$self->input;
    die "Attending ARRAY REF and got something else ! \n" unless ref($tracert_outpout) eq "ARRAY";
    
    my $tracert_result={};
    my $host_targeted;
    my $ip_targeted;

    LINE:
    foreach my $curline (@{$tracert_outpout}){
        #remove empty line
        next LINE if $curline =~ /^$/;
        next LINE if "$curline" !~ /(\w|\d)+/;
        
        #We looking for the target (NB: It is only sure with IP V4 Adress )
        #If we have DNS solving we record hostname and IP Adress
        #Else we keep only IP Adress
        if ($curline =~ /^\S+.*\[(?:\d{1,3}\.){3}\d{1,3}\]/) {
            ($host_targeted,$ip_targeted)=(split(/\s/, $curline))[-2..-1];
            $ip_targeted =~ s/(\[|\])//g;
            chomp $ip_targeted;
            #Data Structure initalization with first results
            $tracert_result->{"$ip_targeted"}={'IPADRESS' => "$ip_targeted", 'HOSTNAME' => "$host_targeted", 'HOPS' => []};
            next LINE;
        }
        elsif($curline =~ /^\S+.*\s(?:\d{1,3}\.){3}\d{1,3}\s/){
            $ip_targeted = $curline;
            $ip_targeted =~ s/.*?((?:\d{1,3}\.){3}\d{1,3}).*$/$1/;
            chomp $ip_targeted;
            #Data Structure initalization with first results
            $tracert_result->{"$ip_targeted"}={'IPADRESS' => "$ip_targeted", 'HOPS' => []};
            next LINE;
        }
        
        my $hop_data;
        #Working on HOPS to reach Target
        if ($curline =~ /^\s+\d+(?:\s+(?:\<1|\d+)\sms){3}\s+.*$/) {
            my $hop_ip;
            my $hop_host="N/A";
            #We split Hop result to create and feed our data structure
            my (undef, $hopnb, $p1_rt, $p1_ut, $p2_rt, $p2_ut, $p3_rt, $p3_ut, $hop_identity) = split(/\s+/,$curline,9);
            #If we have hostname and IP Adress we keep all else we have only IP Adress to keep
            if ($hop_identity =~ /.*\[(?:\d{1,3}\.){3}\d{1,3}\]/) {
                $hop_identity =~ s/(\[|\])//g;
                ($hop_host,$hop_ip)=split(/\s+/, $hop_identity);
            }
            elsif($hop_identity =~ /(?:\d{1,3}\.){3}\d{1,3}/){
                $hop_ip=$hop_identity;
                $hop_ip =~ s/\s//g;
            }
            else{
                die "Bad format $hop_identity\n";
            }
            #Cleaning IP data to be sure not to have carriage return
            chomp $hop_ip;
            
            #We store our data across hashtable reference
            $hop_data={'HOPID' => $hopnb,
                          'HOSTNAME' => $hop_host,
                          'IPADRESS' => $hop_ip,
                          'PACKET1_RT' => $p1_rt,
                          'PACKET2_RT' => $p2_rt,
                          'PACKET3_RT' => $p3_rt,
                           };
            #Each data record is store to table in ascending order 
            push @{$tracert_result->{"$ip_targeted"}->{'HOPS'}}, $hop_data;
            next LINE;
        }
        elsif ($curline =~ /^\s+\d+\s+(?:\*\s+){3}.*$/){
            my $hop_ip='N/A';
            my $hop_host='N/A';
            #We split Hop result to create and feed our data structure
            my (undef, $hopnb, $p1_rt, $p2_rt, $p3_rt, $hop_identity) = split(/\s+/,$curline,6);
            #We store our data across hashtable reference
            $hop_data={'HOPID' => $hopnb,
                          'HOSTNAME' => $hop_host,
                          'IPADRESS' => $hop_ip,
                          'PACKET1_RT' => $p1_rt,
                          'PACKET2_RT' => $p2_rt,
                          'PACKET3_RT' => $p3_rt,
                           };
            #Each data record is store to table in ascending order 
            push @{$tracert_result->{"$ip_targeted"}->{'HOPS'}}, $hop_data;
            next LINE;
        }
        elsif ($curline =~ /^\s+\d+\s+\*\s+(?:\s+(?:\<1|\d+)\sms){2}.*$/){
            my $hop_ip="NA";
            my $hop_host="NA";
            #We split Hop result to create and feed our data structure
            my (undef, $hopnb, $p1_rt, $p2_rt, $p2_ut, $p3_rt, $p3_ut, $hop_identity) = split(/\s+/,$curline,6);
            
            #If we have hostname and IP Adress we keep all else we have only IP Adress to keep
            if ($hop_identity =~ /.*\[(?:\d{1,3}\.){3}\d{1,3}\]/) {
                $hop_identity =~ s/(\[|\])//g;
                ($hop_host,$hop_ip)=split(/\s+/, $hop_identity);
            }
            elsif($hop_identity =~ /(?:\d{1,3}\.){3}\d{1,3}/){
                $hop_ip=$hop_identity;
                $hop_ip =~ s/\s//g;
            }
            else{
                die "Bad format $hop_identity\n";
            }
            #Cleaning IP data to be sure not to have carriage return
            chomp $hop_ip;
            #We store our data across hashtable reference
            $hop_data={'HOPID' => $hopnb,
                          'HOSTNAME' => $hop_host,
                          'IPADRESS' => $hop_ip,
                          'PACKET1_RT' => $p1_rt,
                          'PACKET2_RT' => $p2_rt,
                          'PACKET3_RT' => $p3_rt,
                           };
            #Each data record is store to table in ascending order 
            push @{$tracert_result->{"$ip_targeted"}->{'HOPS'}}, $hop_data;
            next LINE;
        }
    }
    return $tracert_result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Tracert::Parser - Parser object used by method B<to_trace> in Win32::Tracert

=head1 VERSION

version 0.011

=head1 AUTHOR

Sébastien Deseille <sebastien.deseille@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sébastien Deseille.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
