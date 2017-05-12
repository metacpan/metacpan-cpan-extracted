package WordPress::API::MediaObject;
use base 'WordPress::Base::Data::MediaObject';
use base 'WordPress::Base::Content'; # this has encoding to 64 etc 
use base 'WordPress::Base::Object';
use strict;
no strict 'refs';
#use Smart::Comments '###';

#*{__id}   = \&url; # that way, save() will set it to this
#*{__get}  = \&getPage;
#*{__new}  = \&WordPress::XMLRPC::newMediaObject;
#*{__edit} = \&sorry;



sub url {
   my($self,$val) = @_;
   if(defined $val){
      $self->{url} = $val;
   }
 
   if( ! defined $self->{url} ){
      ### did not have url.. will load and upload
      $self->load_file or die;
      $self->upload or die($self->errstr);
   }


   return $self->{url};
}



# from disk
sub load_file {
   my $self = shift;
   my $abs = shift;

   ### has to reset url
   $self->{url} = undef;

   if (defined $abs){

      $self->abs_path($abs);
      $self->abs_path_resolve;   
      ### resolved
   }
   
   $self->abs_path or croak('must set abs_path()');

   ### got abs path
   my $data = WordPress::Base::Content::abs_path_to_media_object_data($self->abs_path)
      or $self->errstr('could not load data') 
      and return 0;
   
   #map{ printf STDERR "$_ %s\n", length($data->{$_}) } keys %$data; 

   $self->structure_data_set($data);


   ### set data
   return 1;

}


# same as save() ??
sub upload {
   my $self = shift;

   ### uploading..
   my $result = $self->newMediaObject($self->structure_data) or return;
   my $url = $result->{url};
   ### $url
   
   $self->url($url);
   return $url;
}








1;


__END__


=pod

=head1 NAME

WordPress::API::MediaObject

=head1 SYNOPSIS

use WordPress::API::MediaObject;

my $o = WordPress::API::MediaObject->new({
   proxy => 'http://site.com/xmlrpc.php',
   username => 'tito',
   password => 'yup',
});

$o->load_file('/path/to/media/file.jpg');

$o->upload;

$o->url;





=head1 METHODS

=head1 new()

arg is hash ref, keys are proxy, username, password
you can also pass server insetead, which is an XMLRPC::Simple object

=head2 load_file()

optional argument is abs path to media file
returns boolean
this is what encodes your file to bits, set the meme type, etc
if no argument is passed, abs_path() must have been set


=head2 bits()

returns the bits if you called load_file()

=head2 type()

returns mime type if you called load_file()

=head2 name()

returns filename if you called load_file()

=head2 abs_path()

returns the abs path of the media file

=head2 abs_path_resolve()

makes sure file is on disk

=head2 structure_data()

returns struct that will be sent to wordpress via xmlrpc, see WordPress::Base::Data::Object


=head2 upload(), save()

uploads the data 
returns url

=head2 url()

will return url via which object can be reached via http
call after upload()



=head1 SEE ALSO

WordPress::XMLRPC

=head1 AUTHOR

Leo Charre leocharre at cpan for org

=cut


