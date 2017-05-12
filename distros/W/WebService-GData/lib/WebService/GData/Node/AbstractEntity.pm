package WebService::GData::Node::AbstractEntity;
use WebService::GData 'private';
use base 'WebService::GData';

our $VERSION = 0.01_03;

sub __init {}


sub swap {
    my($this,$remove,$new)=@_;
    my $nodename = ref($remove);
    $this->_entity->swap($remove,$new);
    $nodename=~s/.*:://;
    $this->{"_\l$nodename"}=$new;
}

sub _entity {
    my $this = shift;
    if(@_==1){
        $this->{_entity}=shift;
    }
    return $this->{_entity};
    
}

sub __set {
    my ($this,$func,$val)= @_;
    my $public =$func;

    #all the wrapper methods store the original Node objects
    #by prefixing the tag name with _
    $func='_'.$func;
    if($this->{$func}){
       if(ref($this->{$func})){
           $this->{$func}->{text}=$val if(!ref $val);
           return $this->{$func};
       } 
       else {
           $this->{$func}=$val;
       }
       return;
    }
    my $code = $this->_entity->can($public);
    if($code){
        $code->($this,$val);
        return;
    }
    $this->_entity->__set($public,$val); 

 
}

sub __get {
    my ($this,$func)= @_;
 
  
   return $this->_entity->$func() if($this->_entity->can($func));
 
    my $public =$func;    
    $func='_'.$func;

    if($this->{$func} && ref($this->{$func})=~m/WebService/){
    	
    	return $this->{$func} if ref($this->{$func})=~m/array|collection/i;

        if(@{$this->{$func}->attributes}==0){

        	_install_get_set_text(ref $this,$public,$func);
             return $this->{$func}->{text} ? $this->{$func}->{text}:$this->{$func}; 
        }

        return $this->{$func}->{text}||$this->{$func};
        
    }

   
    return $this->_entity->$public() if($this->_entity->__get($public)); 
    return $this->_entity->{$public} if($this->_entity->{$public});
   
}


private _install_get_set_text=>sub {
  my ($package,$called_func,$stored_attr)=@_;
  
 {    
        no strict 'refs';
        *{$package.'::'.$called_func}= sub {
            my ($this,$text) = @_;
            local *__ANON__=$called_func;
            if($text){
                return $this->{ $stored_attr }->text($text);   
            }
            $this->{ $stored_attr }->text||$this->{ $stored_attr };
        };
   }    
    
};

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::Node::AbstractEntity - Abstract proxy class representing several xml nodes.

=head1 SYNOPSIS

   #your package should inherit from AbstractEntity.

   package WebService::GData::Node::AuthorEntity;
   use base 'WebService::GData::Node::AbstractEntity';
   
   use WebService::GData::Node::Author();
   use WebService::GData::Node::Uri();
   use WebService::GData::Node::Name();

   our $VERSION = 0.01_01;

   sub __init {
	    my ($this,$params) = @_;
        
        #the entity is the root node used
        
	    $this->_entity(new WebService::GData::Node::Author());
	    
	    #and its children:
	    $this->{_name}   = new WebService::GData::Node::Name($params->{name});
	    $this->{_uri}    = new WebService::GData::Node::Uri ($params->{uri});
	    
	    $this->_entity->child($this->{_name})->child($this->{_uri});
    }

    1;
		
    
    my $author   = new WebService::GData::Node::AuthorEntity();
       $author->name('john doe');
       $author->uri('http://youtube.com/johndoe');
    


=head1 DESCRIPTION

I<inherits from L<WebService::GData>>

This package is an abstract class used as a proxy to represent several nodes in one entity.
A node containing text node and attributes will require to access the data in such a manner:

   my $name   = new WebService::GData::Node::Name(text=>'john doe');
      $name->text;
      
If it does make sense at the node level and in an xml context, it does sound a bit unnatural when using nodes with children:

	    my $author = new WebService::GData::Node::Author();
	    my $name   = new WebService::GData::Node::Name(text=>'john doe');
	    $author->child($name);
	    
	    $author->name->text;#john doe
	    
In an xml context, attributes vs text node do make sense 
but less in a object oriented context that abstract the underlying xml structure: 

	    my $author = new WebService::GData::Node::AuthorEntity(name=>'john doe');
	       $author->name;#john doe
	       
This class serves as a proxy to redispatch the call for name to name->text or an attribute and therefore limit the xml node/object entity mismatch.
It is obviously a helper factory in combining multiple common nodes together in one entity.
This class should be inherited to offer a concrete entity representation.
The main container node should be store via the _entity method.
All other children should be stored in the instance by prefixing the tag name with an underscore.
All access to attributes or text node representation will be redispatched via __set and __get methods by following the above convention.

See also L<WebService::GData::Node>. 

=head2 IMPLEMENTED ENTITIY

Below is a list of implemented entities.


    AuthorEntity                #map author > name,uri
    PointEntity                 #map georss:where > gml:Point > gml:pos 
    Media::GroupEntity          #map all the nodes used in the media:group tag 

=head2  CAVEATS

=over

=item * Complex hierarchical node representation can be hard to implement.

=item * Node using both text node and attributes can not be mapped properly. 
        Providing an alias that makes more sense than C<text> is the only available solution.

=item * Does it really solves the/any problem?

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

