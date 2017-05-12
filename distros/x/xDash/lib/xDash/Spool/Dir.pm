package xDash::Spool::Dir;
# Copyright 2005 Jerzy Wachowiak

use strict;
use warnings;
use vars qw( $VERSION );
use Carp;

$VERSION = '1.00';

# PUBLIC METHODS (convention: capital first letter)

sub new {

    my $class = shift;
    my $self = {};
    $self->{VERSION} = $VERSION;
    bless ( $self, $class );
    return $self
}

sub SetDirPath {

#Contract: 
#	[1] Passing through spool path  
#       [2] Method can suceeds when path formal argument is passed

    my $self = shift;

    $self->{dir_path} = shift;
    unless ( defined( $self->{dir_path} ) ){
	croak 'xDash: Missing directory path in the Spool->SetParameters()'
    }
    return 1
}

sub Connect { 

#Contract: 
#	[1] if undef returned, the connection is regarded as established
#	[2] if hash returned eg { error_code => 1, error => 'TEST' }
#	 error_code and error are logged in the ErrorLogger;

    my $self = shift;

    opendir( SPOOL, $self->{dir_path} ) or 
     return { 
    		error_code => 1,
		error => "Can not open spool directory ($!)"
    	    };
    closedir SPOOL;
    return
}

sub Check {

#Contract: 
#	[1] No input parameters  
#       [2] If method suceeds a list of threads is returned
#	 (if nothing in the spool -> empty list)
#	[3] If error occours, an error hash is returned

    my $self = shift;

    opendir( SPOOL, $self->{dir_path} ) or 
     return { 
    		error_code => 1,
		error => "Can not open spool directory ($!)"
    	    };
     
    my ( $thread, @threads );
    while ( defined( $thread = readdir SPOOL ) ){
	next if $thread =~ m/^\.\.?$/;
	push( @threads, $thread )
    }		

    closedir SPOOL;
    return { threads => \@threads }
}

sub Fetch {

#Contract: 
#	[1] Thread from spool as an input parameter  
#       [2] If method suceeds a hash with only body of the thread is returned
#	 (if nothing empty string '')
#	[3] If error occours, an error hash is returned
	
    my $self = shift;	
    my $thread = shift;
    
    open(MESSAGE, '< '.$self->{dir_path}."/$thread") or 
     return { 
    	    error_code => 1,
	    error => "Can not open file $thread ($!)"
	    };
    undef $/;
    my $body = <MESSAGE>;
    defined ( $body ) or $body = '';
    my $result = { body => $body };
    close MESSAGE;
    return $result
}

sub Remove {

#Contract: 
#	[1] Thread from spool as an input parameter  
#       [2] If method suceeds undef is returned
#	[3] If error occours,an error hash is returned
	
    my $self = shift;	
    my $thread = shift;
    
    unlink( $self->{dir_path}."/$thread" ) or 
     return { 
    	    error_code => 0,
	    error => "Can not remove file $thread ($!)"
	    };
    return
}

sub Disconnect { return }
#Contract: 
#	No implementation needed for Dir.pm
#	No return value check in the xDash::Sender

1;
__END__
######################## User Documentation ##################

=pod

=head1 NAME

xDash::Spool::Dir - Base class for Spool

=head1 SYNOPSIS

 package Spool;
 # Test settings:
 #use base xDash::Spool::Dummy;
 #sub SetParameters { shift->SUPER::SetParameters( 
 # event_limit => 10, mean_interoccurence_time => 1 )

 # Change if you have your own implemantation or 
 # Comment out the test settings above and uncomment the 1.&3.line below.
 use base xDash::Spool::Dir;
 # Do not forget to create spool directory, if xDash::Spool::Dir is used.
 sub SetParameters { shift->SUPER::SetDirPath( '/home/xdash/sender/spool' ) }

=head1 DESCRIPTION

=head2 USAGE

The module is developed in the object orientated way. It can be used as the 
base class for spool using file system, which has to implement a 
fixed set of methods, called by the derived class C<Spool>. 
C<Spool> is hard coded in the C<xDash::Sender> (driver pattern).
A file dropped in a specified directory is sent along the integration 
chain. File name is taken as the thread and file content as the job.
The file is removed from the directory only if a job 
confirmation comes back from the Archivist.
By deriving from the class, as the way of passing arguments, 
you have to implement explicit methods listed below .
The synopsis above is an example of the client script generated 
by the F<xdscr> after debugging.

=head2 METHODS

=over

=item SetDirPath( $directory_path )

Sets the directory, which is monitored for new files, to 
$directory_path.

=back

=head1 BUGS

Any suggestions for improvement are welcomed!

If a bug is detected or nonconforming behavior, 
please send an error report to <jwach@cpan.org>.

=head1 COPYRIGHT

Copyright 2005 Jerzy Wachowiak <jwach@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the terms of the Apache 2.0 license attached to the module.

=head1 SEE ALSO

=over

=item L<xDash::Sender>

=back

=cut
