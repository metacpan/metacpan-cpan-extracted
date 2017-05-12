package WebService::GData::Serialize;
use WebService::GData;
use base 'WebService::GData';

our $VERSION = 0.01_01;


sub __set {
  my($package,$func,@args)=@_;
  
  $func=~s/to_|as_//;
  
  $package= q[WebService::GData::Serialize::]."\U$func";
  { no strict 'refs';
  eval "use $package;" if(!@{$package.'::ISA'});
  }
  
  $func = $package->can('encode');

  $func->(@args) if($func);

}




"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::Serialize - Factory class that loads the proper serialize package

=head1 SYNOPSIS


    #the code below will load WebService::GData::Serialize::XML;
    #and call its encode function
    
    my $xml= WebService::GData::Serialize->to_xml(@args);
    
    #or 
    
    my $xml = WebService::GData::Serialize->as_xml(@args);  
    
    #or 
    
    my $xml = WebService::GData::Serialize->xml(@args);   
    
    #a json format might be added
    #load behind the scene: WebService::GData::Serialize::JSON
    my $json = WebService::GData::Serialize->to_json(@args);       
   



=head1 DESCRIPTION

I<inherits from L<WebService::GData>>

This package is a simple helper factory class that will load a serializer package and calls its C<encode> function.
Concrete serializer class should inherit from L<WebService::GData::Serialize::AbstractSerializer> and 
implement the encode function.

See also L<WebService::GData::Serialize::AbstractSerializer>.


=head2 AUTOLOAD

=head3 __set

=over

This function will be called when an undefined function on this package is used.
It will load the corresponding serializer package. It follows the following format:

=over

=item *The function can be suffixed with to_ or as_. It will look for the serializer package name specified after the prefix.

=item *The function is change into uppercase, therefore,the name can be either uppercase letters (as the real serializer package name) or lowercase letters.

=item *The function must be used in a __set context. You have to specify arguments.

=back

B<Parameters>

=over 

=item C<args:*> Whatever the underlying serializer package requires as arguments

=back

B<Returns> 

=over 

=item L<serialized_data:*> Although the return value shall certainly be raw scalar data, it depends on the serializer package. 

=back


Example:

    see SYNOPSYS
	
=back


=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
