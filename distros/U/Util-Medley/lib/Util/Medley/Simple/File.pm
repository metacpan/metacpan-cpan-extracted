package Util::Medley::Simple::File;
$Util::Medley::Simple::File::VERSION = '0.061';
#
# Moose::Exporter exports everything into your namespace.  This
# approach allows for importing individual functions.
#

=head1 NAME

Util::Medley::Simple::File - an exporter module for Util::Medley::File

=head1 VERSION

version 0.061

=cut

use Modern::Perl;
use Util::Medley::File;

use Exporter::Easy (
    OK   => [qw(basename chdir chmod cp dirname fileType find findDirs findFiles getcwd mkdir mv parsePath read rmdir slurp touch trimExt unlink which write)],
    TAGS => [
        all => [qw(basename chdir chmod cp dirname fileType find findDirs findFiles getcwd mkdir mv parsePath read rmdir slurp touch trimExt unlink which write)],
    ]
);

my $file = Util::Medley::File->new;
 
sub basename {
    return $file->basename(@_);    
}        
     
sub chdir {
    return $file->chdir(@_);    
}        
     
sub chmod {
    return $file->chmod(@_);    
}        
     
sub cp {
    return $file->cp(@_);    
}        
     
sub dirname {
    return $file->dirname(@_);    
}        
     
sub fileType {
    return $file->fileType(@_);    
}        
     
sub find {
    return $file->find(@_);    
}        
     
sub findDirs {
    return $file->findDirs(@_);    
}        
     
sub findFiles {
    return $file->findFiles(@_);    
}        
     
sub getcwd {
    return $file->getcwd(@_);    
}        
     
sub mkdir {
    return $file->mkdir(@_);    
}        
     
sub mv {
    return $file->mv(@_);    
}        
     
sub parsePath {
    return $file->parsePath(@_);    
}        
     
sub read {
    return $file->read(@_);    
}        
     
sub rmdir {
    return $file->rmdir(@_);    
}        
     
sub slurp {
    return $file->slurp(@_);    
}        
     
sub touch {
    return $file->touch(@_);    
}        
     
sub trimExt {
    return $file->trimExt(@_);    
}        
     
sub unlink {
    return $file->unlink(@_);    
}        
     
sub which {
    return $file->which(@_);    
}        
     
sub write {
    return $file->write(@_);    
}        
    
1;
