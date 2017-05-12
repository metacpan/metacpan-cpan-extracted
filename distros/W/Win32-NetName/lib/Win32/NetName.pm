package Win32::NetName;

use File::Spec;
use Win32::API;
use Win32::Lanman;

use Win32::VolumeInformation qw( GetVolumeInformation );

use Exporter ();
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( GetUniversalName GetLocalName );

our $VERSION = 0.3;

Win32::API->Import('kernel32', 'GetDriveType', ['P'], 'N')
			or die "Win32::API->Import GetDriveType: $!";
			
sub GetLocalName{
	my $infile = $_[1];
	$infile = File::Spec->rel2abs($infile);
	$infile = File::Spec->canonpath($infile);
	return 0 if $infile =~ /^\w/;
	my($vol,$path,$file) = File::Spec->splitpath($infile);
	$vol =~ s/(\w+)/\U$1/; # uc machine name - should File::Spec do this?
	if( uc $1 eq Win32::NodeName() ){
		if( GetLocalPath(my $p, $infile) ){
    		$_[0] = $p;
    		return 1;
    	}else{
    		return 0;
    	}
	}
    for my $disk ('A'..'Z'){
    	$disk .= ':';
  		my $share;
   		Win32::Lanman::WNetGetConnection($disk,\$share);
  		if( uc $vol eq uc $share ){
  			my $outfile = File::Spec->catdir($disk,$path,$file);
  			$_[0] = $outfile;
  			return 1;
  		}
    }
    return 0;
}

sub GetLocalPath{
	my $infile = $_[1];
	$infile = File::Spec->rel2abs($infile);
	$infile = File::Spec->canonpath($infile);
	return 0 if $infile =~ /^\w/;
	my($vol,$path,$file) = File::Spec->splitpath($infile);
	$vol =~ s/(\w+)/\U$1/; # uc machine name - should File::Spec do this?
	my $node = $_[2] || Win32::NodeName();;
	return 0 unless GetDiskShares(my $n, $node);
	for my $s (@$n){
		if( uc "\\\\$node\\$s->{netname}" eq uc $vol ){
			my $outfile = File::Spec->catdir($s->{path}, $path, $file );
			$_[0] = $outfile;
			return 1;
		}
	}
	return 0;
}
 
sub GetUniversalName{
	my $infile = $_[1];
	$infile = File::Spec->rel2abs($infile);
	$infile = File::Spec->canonpath($infile);
	return 0 unless $infile =~ /^\w/;
	my($vol,$path,$file) = File::Spec->splitpath($infile);
	if( GetDriveType($vol) == 4 ){ # remote share
		my %info;
		if( Win32::Lanman::WNetGetUniversalName($infile, \%info)){
			$_[0] = $info{universalname};
			return 1;
		}else{
			return 0;
		}
    }else{ # local share
    	if( GetUniversalPaths(my $p, $infile ) ){
    		if( @$p ){
    			$_[0] = $p->[0];
    			return 1;
    		}
    	}
    }
    return 0;
}

sub GetUniversalPaths{
	my $infile = $_[1];
	my $node = $_[2] || Win32::NodeName();
	my @names;
	return 0 unless GetDiskShares(my $n, $node);
	

	my $compare = sub{ $_[0] eq $_[1] };
	my($vol,$path,$file) = File::Spec->splitpath($infile);
	my %info;
	if( GetVolumeInformation($vol,\%info) ){
		unless( $info{FS_CASE_SENSITIVE} ){
        	$compare = sub{ uc $_[0] eq uc $_[1] };
		}
	}else{
		return 0;
	}
	
	
	for my $s (@$n){
		my $path = $s->{path};
		if( $compare->($path,$infile) ){
			push @names, "\\\\$node\\$s->{netname}";
		}elsif( length $infile > length $path ){
			my $test = substr($infile,0,length $path);
			if( $compare->($test,$path) && substr($infile,length $path, 1) eq "\\" ){
				my @infile = File::Spec->splitdir($infile);
				my @test = File::Spec->splitdir($test);
				splice @infile, 0, scalar @test;
				my $dir = File::Spec->catdir("\\\\$node\\$s->{netname}",@infile);
				push @names, $dir;
			}
		}		
	}
	if(@names){
		$_[0] = \@names;
		return 1;
	}		
	return 0;
}

sub GetDiskShares{
	my $node = $_[1] || Win32::NodeName();
	my @stuff;
	my @info;
	if (Win32::Lanman::NetShareEnum("\\\\$node",\@stuff)) {
		for my $share (@stuff){
			if( $share->{type} == 0 ){
				push @info, $share;
			}
		}
		if(@info){
			$_[0] = \@info;
			return 1;
		}
	}
	return 0;
}

1;

__END__

=head1 NAME

Win32::NetName - A more universal way of obtaining the UNC names of local paths

=head1 SYNOPSIS

use Win32::NetName qw( GetUniversalName GetLocalName );

use Win32::Lanman;

if( GetUniversalName( my $unc, "c:/my/local/path/to/my/file" ) ){
	
	print $unc; # something like \\SERVER\share\path\to\file 
	
}else{

	print Win32::Lanman::GetLastError();
	# If there is no WNET error it may just be that there aren't any shares

}

if( GetLocalName( my $local, "\\\\server\\share\\path\\to\\file" ) ){

	print $local; # something like C:\my\local\path\to\file
	# If there is no WNET error it may just be that there isn't a local path

}else{

	print Win32::Lanman::GetLastError();

}

...

=head1 DESCRIPTION

The windows WNet API has a function, WNetGetUniversalName that takes a 
drive-based path for a network resource and returns an information structure 
that contains a more universal form of the name ie. a UNC path of the form 
\\SERVER\share\path\to\file.

However, this only works with networked drives that have been mapped to the 
local machine. It totally ignores shared folders on the local machine.

This module exports two functions, GetUniversalName and GetLocalName.

$success = GetUniversalName( $unc_name, $local_name );

GetUniversalName tries to find a UNC name for a local path. The UNC name is 
returned in $_[0]. If the drive of the path is local then it enumerates the 
shared folders on the machine. If it is a network path then it runs the 
WNetGetUniversalName API function.

$success = GetLocalName( $local_name, $unc_name );

GetLocalName tries to find the local path of a UNC name. If the node name of 
the UNC name is the local machine then it enumerates the shared folders on the 
machine. If it is any other machine then it enumerates through the used drive 
letters to find a match.

The module also contains but does not export;

$success = GetUniversalPaths( \@paths, $local_name );

On success, returns an array in $_[0] of UNC names of the local path (since a 
local path can be made available from more than one shared folder in its path 
or the same folder can be shared with multiple names).

$success = GetDiskShares( \@shares, [ $node ] );

On success, returns an array in $_[0] of NET_SHARE_INFO hashes. Unless $node is provided 
then the name of the local machine is used.

=over

=head1 SEE ALSO

http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wnet/wnet/windows_networking_functions.asp

L<Win32::Lanman> http://www.cpan.org/authors/id/J/JH/JHELBERG/

=head1 BUGS

Please report them!

Currently paths are case sensitive.

=head1 AUTHOR

Mark Southern (msouthern@exsar.com)

=head1 COPYRIGHT

Copyright (c) 2003, ExSAR Corporation. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut
