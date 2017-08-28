#!/usr/bin/perl
package ios_get_interfaces;
use 5.006001;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ('all' => [ qw(new get_info make_report)]);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
our @EXPORT = qw();
our $VERSION ='1.7';
my ($class, $this, $router);
sub new(){
        $class = shift or die $!;
        $router = shift or die $!;
        $this = {name=>$router->{name}, showrun_file=>$router->{showrun_file}, csv=>$router->{csv}};
        bless $this,$class;
        return $this;
}
##################################################
sub get_info(){
    $this = shift or die $!;
    my @interfaces;
    open F, $this->{showrun_file} or die "Can't find showrun file\n";
    my@f = <F>;
    my ($interface, $address, $description, @split1, @split2, @split3);
    close F;
    foreach (@f){
        chomp $_;
        $_ =~ s/\cM//g;
        $_ =~ s/\r//g;
        if (/^interface/ .. /^!/){
            if ($_ =~ /^interface/){
                @split1 = split " ", $_;
                $interface = $split1[1];
                $description = '';
                $address = '';
            }
            if ($_ =~ /^ description/){
                $description = $_;
                $description =~ s/^ description //;
            }
            if (($_ =~ /^ ip address/) or ($_ =~ /^ no ip address/) or ($_ =~ /^ ip unnumbered/)){
                @split2 = split " ", $_;
                $address = "$split2[2]-->$split2[3]" if $split2[3];
                $address =~ s/\s//g;
                $address = "No IPv4 address-->No netmask" if !$split2[3];
                $this->{"Interface_".$interface."-->"} = "$address-->No description\n" if !$description;
                $this->{"Interface_".$interface."-->"} = "$address-->$description\n" if $description;
            }
        }
    }
    foreach my$int (sort keys %{$this}){
        push @interfaces, $this->{name}."-->".$int.$this->{$int} if $int =~ /^Interface/;
    }
    return \@interfaces;
}
###################################################
sub make_report(){
    $this = shift or die $!;
    open CSV, ">$this->{csv}" or die "Can't find csv file\n";
    print CSV "Name;Interface;IPv4 Address;Netmask;Description\n";
    foreach my$int (sort keys %{$this}){
        my $intclean = $int;
        $intclean =~ s/^Interface_//;
        $intclean =~ s/-->/;/g;
        $this->{$int} =~ s/-->/;/g;
        print CSV $this->{name}.";".$intclean.$this->{$int} if $int =~ /^Interface/;
    }
    close CSV;
}
return 1;
__END__

=head1 NAME

ios get interfaces - Get interfaces info from cisco ios configuration file.

=head1 SYNOPSIS

use strict;

use warnings;

use ios_get_interfaces;

my%info = (name => "router_a", showrun_file => "show_running_config.txt", csv=>"router_a.csv");

my$router = ios_get_interfaces->new(\%info);

my$interfaces = $router->get_info();

print @{$interfaces};

$router->make_report();

=head1 DESCRIPTION


Get interfaces info from cisco ios configuration file


=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Cladi, E<lt>cladi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Cladi Di Domenico

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
