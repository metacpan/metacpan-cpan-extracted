package Win32::Utilization;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
CPU_per
mem_per
drive_per	
);

our $VERSION = '0.01';



use Win32::API;
use Win32::DriveInfo;


sub mem_per{
my $func = Win32::API->new('kernel32', 'GlobalMemoryStatusEx', 'P', 'I');
if(not defined $func) {
        die "Can't import API GetTempPath: $!\n";
    }
my $struct= pack('L16', 64, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

$func->Call( $struct );

my (undef, $perc) = unpack('L*', $struct);

return $perc;
}

sub CPU_per{

	my $func = Win32::API->new('kernel32', 'GetSystemTimes', 'PPP', 'I');
        die "Can't import API GetSystemTimes: $!\n" if(!defined $func);
    
my $kernel = pack('LL', 0, 0);
my $idle = pack('LL', 0, 0);
my $users = pack('LL', 0, 0);
$func->Call( $idle, $kernel, $users);

my $kernel_prev = $kernel;
my $idle_prev = $idle;
my $users_prev = $users;

sleep 1;

	$func->Call( $idle, $kernel, $users);
	my $kernel_time = compare_time($kernel_prev, $kernel);
	my $idle_time = compare_time($idle_prev, $idle);
	my $users_time = compare_time($users_prev, $users);
	return  int(($kernel_time + $users_time - $idle_time )/($kernel_time +  $users_time )*100); 

}

sub drive_per{
				my (undef, undef, undef, undef, undef, $bytes, $free_bytes) = Win32::DriveInfo::DriveSpace(shift);

				return int(($bytes-$free_bytes)/$bytes*100);

}



sub combine_quad{
	my ($high, $low) = @_;
	return $high<<32 | $low;
}

sub compare_time{
	my ($prev, $cur) = @_;
	my $cur_time = combine_quad( unpack('LL', $cur) );
	my $prev_time = combine_quad( unpack('LL', $prev) );
	
	return $cur_time - $prev_time;
}

1;
__END__

=head1 NAME

Win32::Utilization - Perl extension for Win32 system utilization

=head1 SYNOPSIS

  use Win32::Utilization;
  
   my $cpu = CPU_per();
   my $mem = mem_per();
   my $c   = drive_per('c');

=head1 DESCRIPTION

There lacks a module to detect win32 system utilization in CPAN. I simply wrap some Windows API for easy using under perl.Note: it automatically export 3 funcations when using it, and all three return a 0-100 number to show utilization respectly. 

=head2 EXPORT

mem_per for mem
CPU_per for CPU
drive_per for hard disks



=head1 AUTHOR

xiaoyafeng: please mail to xyf@cpan.org for any issues.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by xiaoyafeng 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
