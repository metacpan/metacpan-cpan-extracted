package LEOCHARRE::Dir::Lsutils;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);
use Exporter;
use Carp;
use LEOCHARRE::Debug;
use Cwd;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(
sort_by_stat sort_by_ctime sort_by_atime sort_by_mtime sort_by_size 
most_by_stat least_by_stat newest oldest smallest biggest);
%EXPORT_TAGS = ( all => \@EXPORT_OK );



sub sort_by_ctime { sort_by_stat( 10, @_ ) }
sub sort_by_atime { sort_by_stat(  8, @_ ) }
sub sort_by_mtime { sort_by_stat(  9, @_ ) }
sub sort_by_size  { sort_by_stat(  7, @_ ) }


sub sort_by_stat {
   my $stat_num = shift;
   ( grep { $stat_num == $_ } 0 .. 12 ) or confess("arg must be one of 0-12");

   my @list = _gotarray(@_);
   my $stat = _stats(@list);  

   my @sorted = sort { $stat->{$a}->[$stat_num] <=> $stat->{$b}->[$stat_num] } keys %$stat;
   
   wantarray ? @sorted : [@sorted];


   # 0 dev      device number of filesystem
   # 1 ino      inode number
   # 2 mode     file mode  (type and permissions)
   # 3 nlink    number of (hard) links to the file
   # 4 uid      numeric user ID of file’s owner
   # 5 gid      numeric group ID of file’s owner
   # 6 rdev     the device identifier (special files only)
   # 7 size     total size of file, in bytes
   # 8 atime    last access time in seconds since the epoch
   # 9 mtime    last modify time in seconds since the epoch
   # 10 ctime    inode change time in seconds since the epoch (*)
   # 11 blksize  preferred block size for file system I/O
   # 12 blocks   actual number of blocks allocated

}

sub _gotarray { # takes aref or list,returns list
   my @list;
   for (@_){
      ref $_ 
         and ( ref $_ eq 'ARRAY' or Carp::cluck('arg must be array ref') and return )
         and ( push @list, @{$_} )
         and next;
      push @list, $_;
   }
   @list;
}



sub _stats {   
   my %stat;
   for (@_){
      my @stat = stat($_) or (warn("Not on disk ? '$_'") and next);
      $stat{$_}=\@stat;
   }
   \%stat;
}




# oldest newest...
#
sub newest   {  most_by_stat( 10, @_) } # doing by ctime, inode time
sub oldest   { least_by_stat( 10, @_) }
sub biggest  {  most_by_stat(  7, @_) }
sub smallest { least_by_stat(  7, @_) }


sub most_by_stat {
   my $stat_num = shift;
   ( grep { $stat_num == $_ } 0 .. 12 ) or confess("arg must be one of 0-12");

   my $stat = _stats( _gotarray(@_) );   
   my @sorted = sort { $stat->{$b}->[$stat_num] <=> $stat->{$a}->[$stat_num] } keys %$stat;
   wantarray ? ( $sorted[0], $stat->{$sorted[0]}->[$stat_num] ) : $sorted[0];
}

sub least_by_stat {
   my $stat_num = shift;
   ( grep { $stat_num == $_ } 0 .. 12 ) or confess("arg must be one of 0-12");

   my $stat = _stats( _gotarray(@_) );   
   my @sorted = sort { $stat->{$a}->[$stat_num] <=> $stat->{$b}->[$stat_num] } keys %$stat;
   wantarray ? ( $sorted[0], $stat->{$sorted[0]}->[$stat_num] ) : $sorted[0];
}



1;

