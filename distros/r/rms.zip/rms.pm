package rms;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

bootstrap rms $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 Accessing Open VMS RMS indexed files from Perl

rms - Perl extension for accessing, searching, reading, writing RMS indexed
      files under Open VMS operating system.

=head1 SYNOPSIS

  use rms;


=head1 DESCRIPTION

This package is designed to be used with a minimum of effort, hence it 
may lacks some of the RMS functionalities. But trust my long 
experience, it will fit more than 80% of your usual needs.

=head1 AUTHOR

Jean-claude Tebbal (e-mail : jct@tebbal.demon.co.uk)

I live in England but I am French so if you are a French speaking person
feel free to send me your comments in French. 
If you are not French speaking send them in English and do not worry: I
read English easier than I write it :-)

I work on VMS systems since 1984 and I am using Perl since 1994 (I discovered
it by using Linux). While extensions for RDBMS are available since a long
time, I have been waiting for an interface to RMS indexed files. Knowing
that Heavens help those who are helping themselves, I built this extension.
To be faithful to the KISS principle (Keep It Small and Simple), I reduced
the extension to the main needs and froze some options:

When a file is accessed in read mode the read records are not locked.

When a file is accessed in write mode the located (rms::find) and read records
are locked until they are updated (rms::update), explicitely unlocked 
(rms::unlock), deleted (rms::delete) or when another record is read.

The buffers containing the records must be created before reading and will
not be null terminated after read ($size will be defining the record end).

The return value of the functions is the RMS status of the last RMS primitive
call in the function or the first faulty primitive call.

example: in open_read sys$open service is called and if faulty the RMS
status is returned; if ok the sys$connect service is called and RMS status
is returned if it is faulty; if ok the sys$rewind service is called and 
RMS status is returned if faulty; if ok the file access block and record
access block are updated ans the good RMS status is returned.

These status are important and MUST be tested, because if you go on after a
wrong status, the results may be unpredictable.

!!!!! A status is good if its value is odd !!!

You can get the message related to this status by doing : exit $status; in
your perl program.

You can test the record locking status with two concurrent users in write
access and determine in your programs what to do in such a case (error message,
program termination, wait and retry, ...)


If you want to be aware of any new version of this package, just mail
rms@tebbal.demon.co.uk

=head1 COPYRIGHTS

This package is released under the artistic licence terms. You can 
read these terms in the file copy.art in this distribution.


=head1 SEE ALSO

perl(1).

=head1 open_read

=head2 syntax

 rms::open_read($file,$fab, $rab)
 char $file
 int $fab
 int $rab

=head2 Description

   Function           : open_read                                          
                                                                           
   Description        : Opens an indexed file with read access; links the  
                        record accessblock to the file accessblock then  
                        resets the record pointers to the beginning of the 
                        file.                                              
                                                                           
   Input Parameters   : $file : Name of the file to be used.                
   Output Parameters  : $fab : File accessblock pointer 
                                this block contains the header       
                                information relative to the file         
                        $rab : Record accessblock pointer, 
                                this block contains the header    
                                information related to the record.       
   Return value       : RMS return status.                                 
                                                                           

  Initialize the FAB and RAB before opening and connecting a stream.    

=head1 open_write

=head2 Syntax 

 rms::open_write ($file, $fab, $rab)
 char $file
 int $fab
 int $rab

=head2 Description

   Function           : open_write                                   
                                                                           
   Description        : Opens an indexed file with all  access; links the  
                        record accessblock pointer to the file accessblock pointer then  
                        resets the record pointers to the beginning of the 
                        file.                                              
                                                                           
   Input Parameters   : $file : Name of the file to be used.             
   Output Parameters  : $fab : File accessblock pointer 
                                this block contains the header    
                                information relative to the file         
                        $rab : Record accessblock pointer, 
                                this block contains the header 
                                information related to the record.       
   Return value       : RMS return status.                                 
                                                                           

  Initialize the FAB and RAB before opening and connecting a stream.    

     

=head1 close

=head2 Syntax

 rms::close ($fab,$rab)
 int $fab
 int $rab

=head2 Description

   Function           : close                                        
                                                                          
   Description        : close file.                                       
                                                                          
   Input Parameters   : $rab: Record accessblock pointer 
                              this block contains info related 
                              to the record.                         
                      : $fab: File accessblock pointer 
                              this block contains the header    
                              information relative to the file      
   Return value       : RMS return status.                              
                                                                        

=head1 delete

=head2 Syntax

 rms::delete ($rab) 
 int $rab

=head2 Description

   Function           : delete                                          
                                                                        
   Description        : Delete the last record read or found.           
                                                                        
   Input Parameters   : $rab : Record accessblock pointer 
                               this block contains info related 
                               to the record.                         
                                                                        
   Output Parameters  : none                                            
                                                                        
   Return value       : Odd status if OK , even status if record not found 

=head1 find

=head2 Syntax

 rms::find ($rab, $key_val, $match)
 int $rab
 char $key_val
 char $match

=head2 Description

   Function           : find                                          
                                                                            
   Description        : Find an indexed record matching a specified value   
                        for the current index number.                       
                                                                            
   Input Parameters   : $rab : Record accessblock pointer 
                               this block contains all info    
                               related to the record.                     
                        $key_val: value of the key to find.                  
                        $match  :-"GE" all records whose key match this      
                                 value and the following records according  
                                 to the default sorting order of the key.   
                               :-"GT" the records matching this key are     
                                 excluded, but all the following  records   
                                 are valid (according to the default        
                                 sorting order).                            
                               :-"EQ" only exact matches are valid          
                                                                            
   Output Parameters  : none                                                
                                                                            
   Return value       : Odd status if record found even status if not found 

=head1 put_index

=head2 Syntax 

 rms::put_index($rab, $buffer, $size, $key_val) 
 int $rab
 char $buffer
 int $size
 char $key_val

=head2 Description

   Function           : put_index                                       
                                                                              
   Description        : Write in the file the contents of the                 
                        buffer.                                               
                                                                              
   Input Parameters   : $rab : Record accessblock pointer 
                               this block contains info related    
                               to the record.                               
                        $key_val: value of the key to insert.                
                                                                              
                        $buffer : It    contains the record to be written      
                                                                              
                        $size   : Size of buffer (note that it is not Null
						  terminated)
                                                                              
   Output Parameters  : none                                                  
                                                                              
   Return value       : Odd status if OK , even status if record not found    
                                                                              

=head1 put_seq

=head2 Syntax

 rms::put_seq ($rab, $buffer, $size)                                 
 int $rab
 char $buffer
 int $size

=head2 Description

   Function           : put_seq                                         
                                                                              
   Description        : Write an indexed file in a sequential way,            
                        ignoring the keys.                                    
                                                                              
   Input Parameters   : $rab : Record accessblock pointer 
                               this block contains info related    
                               to the record.                               
                        $buffer : Contains the record to be written            
                                                                              
                        $size   : Size of buffer (note that it is not Null
						  terminated)
                                                                              
   Output Parameters  : none                                                  
                                                                              
   Return value       : Odd status if OK , even status if an error occurs.    
                                                                              

=head1 read_seq

=head2 Syntax

 rms::read_seq ($rab, $buffer, $size)                                 
 int $rab
 char $buffer
 int $size

=head2 Description

   Function           : read_seq                                        
                                                                              
   Description        : Read an indexed file in a sequential order,           
                        ignoring the keys.                                    
                                                                              
   Input Parameters   : $rab : Record accessblock pointer 
                               this block contains info related    
                               to the record.                               
                                                                              
   Output Parameters  : $buffer : If OK contains at the end of the function    
                                  the read record.                             

                        $size   : Size of buffer (note that it is not Null
						  terminated)
                                                                              
                                                                              
   Return value       : Odd status if OK , even status if end of file         
                                                                              

=head1 sel_index

=head2 Syntax

 rms::sel_index ($rab, $key_size, $key_no)
 int $rab
 int $key_size
 int $key_no

=head2 Description

   Function           : sel_index                                    
                                                                           
   Description        : Select for an index file the number of the key     
                        which will be used for the next PUT, GET or FIND   
                        service.                                           
                                                                           
   Input Parameters   : $key_size: Size of the key                          
                        $key_no  : Number of the key selected               
                      : $rab  : Record accessblock pointer, 
                                this block contains the header 
                                information related to the record. 
   Return value       : RMS return status.                                 
                                                                           

=head1 unlock

=head2 Syntax

 rms::unlock ($rab) 
 int $rab

=head2 Description

   Function           : unlock                                          
                                                                              
   Description        : Unlock the last record read or found.                 
                                                                              
   Input Parameters   : rab : Record accessblock pointer 
                              this block contains info related    
                              to the record.                               
                                                                              
   Output Parameters  : none                                                  
                                                                              
   Return value       : Odd status if OK , even status if record not found    


=head1 update

=head2 Syntax

 rms::update ($rab, $buffer, $size) 
 int $rab
 char $buffer
 int $size

=head2 Description

   Function           : update                                          
                                                                              
   Description        : Replace the last read or found record with the        
                        buffer.                                               
                                                                              
   Input Parameters   : $rab : Record accessblock pointer 
                               this block contains info related    
                               to the record.                               
                                                                              
                        $buffer : It    contains the record to be updated      

                        $size   : Size of buffer (note that it is not Null
						  terminated)
                                                                              
   Output Parameters  : none                                                  
                                                                              
   Return value       : Odd status if OK , even status if record not found    
                                                                              


=cut
