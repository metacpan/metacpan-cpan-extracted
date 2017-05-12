package WebService::GData::Node;
use WebService::GData;
use base 'WebService::GData';

our $VERSION = 0.06;

my $attributes = [];

sub import {
    shift();
    my $package = shift() || caller;
    return if ( $package->isa(__PACKAGE__) || $package eq 'main' );
    
    
    WebService::GData->import;
    
    WebService::GData::install_in_package( ['set_meta'],
        sub { return \&set_meta; }, $package );

    #install this package in the inheritance chain
    #and create the default tag_name by lowering the last name of the package
    {
        no strict 'refs';
        push @{ $package . '::ISA' }, __PACKAGE__;
        my $pk = $package;
        $package =~ s/.*:://;
        *{ $pk . '::node_name' } = sub {
            return "\l$package";
          }
    }
}

sub set_meta {
    my %data    = @_;
    my $package = caller;
    return if ( $package eq __PACKAGE__ );
    {
        no strict 'refs';
        no warnings 'redefine';
        while ( my ( $sub, $val ) = each %data ) {
            *{ $package . '::' . $sub } = sub {
                return $val;
              }
        }

    }
}

sub __init {
    my ( $this, @args ) = @_;

    $this->{namespaces} = {};
    if ( ref( $args[0] ) eq 'HASH' ) {

        #accept a text tag but json feed uses $t tag so adapt
        #for compatibility
        if ( $args[0]->{'$t'} ) {
            $args[0]->{'text'} = $args[0]->{'$t'};
            delete $args[0]->{'$t'};
        }
        my %args = %{ $args[0] };
        foreach my $attr (keys %args) {
            my $val = delete $args{$attr};
            $attr =~ s/\$/:/;
            $args{$attr} = $val;
        }
        @args = %args;
    }

    $this->SUPER::__init(@args) if ( @args % 2 == 0 );
    $this->{_children} = [];
}

sub namespace_prefix { "" }

sub node_name { "" }

sub namespace_uri { "" }

sub extra_namespaces { }

sub attributes { $attributes }

sub is_parent { 1 }

sub namespaces {
    my ($this) = @_;
    $this->{namespaces};
}

sub text {
    my ($this,@args) = @_;
    $this->{text}= $args[0] if(@args);
    return $this->{text};  
}


sub child {
    my $this = shift;
    if ( @_ == 1 ) {
        my $child = shift;
        return $this
          if ( $this == $child );    #TODO:warn
        push @{ $this->{_children} }, $child;
        return $this;
    }
    return $this->{_children};
}

sub swap {
    my ( $this, $remove, $new ) = @_;
    my $i = 0;
    foreach my $child ( @{ $this->{_children} } ) {
        if ( $child == $remove ) {
            $this->{_children}->[$i] = $new;
        }
        $i++;
    }
}

sub __set {
    my ( $this, $func, @args ) = @_;
    my $called_func= $func;
        
    my @attrs = @{ $this->attributes };   
    
    if ( !grep /^$func$/, @attrs ) {
         foreach my $attr (@attrs){
            $func = $attr if($attr=~m/^.+?:$func$/);       
         }
    }
    
    if ( my ( $ns, $tag ) = $func =~ /^(.+?)_(.+)$/ ) {

        my $attr  = $ns . ':' . camelcase($tag);
        if ( grep /^$attr$/, @attrs ) {
            $func = $attr;
        }
    }
    my $camelize=camelcase($func);
    $this->{ $camelize } = @args == 1 ? $args[0] : \@args;

    _install_get_set(ref $this,$called_func,$camelize);

    return $this;
}

sub __get {
    my ( $this, $func ) = @_;
    my $called_func= $func;
     
    my @attrs = @{ $this->attributes };   
    if ( !grep /^$func$/, @attrs ) {
         foreach my $attr (@attrs){
            $func = $attr if($attr=~m/^.+?:$func$/);       
         }
    }
    if ( my ( $ns, $tag ) = $func =~ /^(.+?)_(.+)$/ ) {

        my $attr  = $ns . ':' . camelcase($tag);
        if ( grep /$attr/, @attrs ) {
            $func = $attr;
        }
    }
    my $camelize = camelcase($func);
    
    _install_get_set(ref $this,$called_func,$camelize);
   
    $this->{ $camelize };

}

private _install_get_set=>sub {
  my ($package,$called_func,$stored_attr)=@_;
  
 {    
        no strict 'refs';
        *{$package.'::'.$called_func}= sub {
            my ($this,@args) = @_;
            local *__ANON__=$called_func;
            if(@args>0){
                $this->{ $stored_attr } = @args == 1 ? $args[0] : \@args;   
                return $this;     
            }
            $this->{ $stored_attr };
        };
   }    
    
};

sub camelcase {
    my $str = shift;
    $str =~ s/_([a-z])/\U$1/g;
    return $str;
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::Node - Abstract class representing an xml node/tag

=head1 SYNOPSIS

   #your package should use the abstract Node package.
   #it will automaticly inherit from it.
   
   #Author.pm files:
   use WebService::GData::Node::Author;
   use WebService::GData::Node;
   
   1;
   
   #Name.pm
   use WebService::GData::Node::Name;
   use WebService::GData::Node;  
   
   1; 
   
   #Category.pm
   package WebService::GData::Node::Category;
   use WebService::GData::Node;

   set_meta(
        attributes=>['scheme','yt:term','label'],#default to []
        is_parent => 0, #default 1
        namespace_prefix => 'k', #default to ''
        namespace_uri    =>'http://wwww.k.org/2010',#default to ''
        tag_name  => 'category' # default to the package file name with the first letter in lower case,
        extra_namespaces=>{'yt'=>'http://...'} #set namespace at the attribute level here
   );

   1;

    #user code:
	use WebService::GData::Node::Name();  #avoid to inherit from it by not importing
	use WebService::GData::Node::Author();
	use WebService::GData::Node::Category();
		
    my $author   = new WebService::GData::Node::Author();
    my $name     = new WebService::GData::Node::Name(text=>'john doe');
    my $category = new WebService::GData::Node::Category(scheme=>'author','yt:term'=>'Author');
    
    #or coming from a json feed:
    my $category = new WebService::GData::Node::Category({scheme=>'author','yt$term'=>'Author'});
    
    
    
    $author->child($name)->child($category);
    
    $name->text;#john doe
    $category->scheme;#author;
    $category->scheme('compositor');
    $category->term('Media');
   


=head1 DESCRIPTION

I<inherits from L<WebService::GData>>

This package is an abstract class representing the information required to serialize a node object into xml or any other appropriate format.


You should subclass and set the meta information via the C<set_meta> function that will be installed in your package
 (see below for further explanation).
You can instantiate this class if you want... it will not throw any error but you won't be able to do much. 

A node is only the representation of one xml tag. Feed and Feed subclasses are the representation of an entire JSON response
or offers a subset.

See also:

=over

=item * L<WebService::GData::Node::AbstractEntity> - represent set of nodes

=item * L<WebService::GData::Serialize> - serialize into xml or other format

=back

=head2 CONSTRUCTOR

=head3 new

=over

Create an instance but you won't be able to do much as no meaningful meta data has been set. You should
inherit from this class.

B<Parameters>

=over 

=item C<args:Hash> (optional) - all the xml attributes can be set here. text nodes requires the "text" key.
or

=item C<args:HashRef> (optional) - all the node attributes can be set here. text nodes requires the "text" key and 
the '$t' key is also supported as an alias for 'text' for compatibily with the GData JSON responses.

=back

B<Returns> 

=over 

=item L<WebService::GData::Node>

=back


Example:

    use WebService::GData::Node;
	
    my $node   = new WebService::GData::Node(text=>'hi');
    
       $node->text();#hi;
       
   print WebService::GData::Serialize->to_xml($node);"<>hi<>"; #this is an abstract node!
	
=back

=head2 AUTOLOAD

=head3 __set/__get

The attributes setter/getters and the text method are generated on the fly.

=over

=item * you can use either hyphen base notation or camelCase notation.

=item * Attributes containing namespaces can be accessed by replacing ':' with
'_' or by just skipping the namespace prefix. yt:format attribute can be set/get via the yt_format method or format.
You should use the qualified attribute when setting it via the constructor.
Therefore, new Node(yt_format=>1) will not work but new Node('yt:format'=>1) and new Node({'yt$format'=>1}) will work.

Example:

    use WebService::GData::Node::FeedLink;
    
    my $feedlink = new WebService::GData::Node::FeedLink($link);
    
    $feedlink->countHint;
    
    #or
    $feedlink->count_hint;

=back

=head2 METHODS

=head3 child

=over

Set an other node child of the instance. It returns the instance so you can chain the calls.
You can not set the instance as a child of itself.
The child method checks against the memory slot of the object and will return the instance without setting the object 
if it appears to be the same.


B<Parameters>

=over

=item C<node:WebService::GData::Node> - a node instance inheriting from this class.

=back

B<Returns> 

=over 

=item C<instance:WebService::GData::Node> - you can chain the call

=back

Example:

    my $author   = new WebService::GData::Node::Author();
    my $name     = new WebService::GData::Node::Name(text=>'john doe');
    my $category = new WebService::GData::Node::Category(scheme=>'author',term=>'Author');
    
    $author->child($name)->child($category);
    
    #the same object can not be a child of itself. which makes sense.
    #it just silently returns the instance.
    $author->child($author);


=back

=head3 swap

=over

This method will put a new instance instead of an existing child.

B<Parameters>

=over

=item C<oldchild::WebService::GData::Node|WebService::GData::Collection> - the node to remove in the children collection

=item C<newchild::WebService::GData::Node|WebService::GData::Collection> - the node to put instead

=back

B<Returns> 

=over 

=item Cnone>

=back

Example:

    my $author   = new WebService::GData::Node::Author();
    my $name     = new WebService::GData::Node::Name(text=>'john doe');
    my $category = new WebService::GData::Node::Category(scheme=>'author',term=>'Author');
    
    $author->child($name)->child($category);
    
    my $newname = new WebService::GData::Node::Name(text=>'billy doe');
    $author->swap($name,$newname);
    
	   
=back

=head2 STATIC GETTER METHODS

The following methods are installed by default in the package subclassing this class.
You should set their value via the C<set_meta> method (see below).

=head3 namespace_prefix

=head3 namespace_uri

=head3 node_name

=head3 attributes

=head3 is_parent

=head3 extra_namespaces


=head2 INHERITANCE

The package will push itself in the inheritance chain automaticly when you use it so it is not necessary to explicitly
declare the inheritance. As a consequence though, every sub classes that are used will also automaticly set themself
 in the inheritance chain of the C<use>r. In order to avoid this behavior you should write:
 
    use WebService::GData::Node(); 
 
The following function will be accessible in the sub class.

=head3 set_meta

=over

Set the meta data of the node.

B<Parameters>

=over

=item C<args::Hash> 

=over 4

=item B<namespace_uri:Scalar> - the namespace uri. Most of the time a web url ...

=item B<namespace_prefix:Scalar> - the namespace name of the node, ie, yt:, media: ...

=item B<extra_namespaces:HashRef> - Node only supports namespaces at the node level. You can add extra namespaces here if set at the attribute level.
the key is the namespace_prefix and the value the namespace_uri.

=item B<node_name:Scalar>  - the name of the node it self, ie, category, author...

=item B<attributes:ArrayRef> - a list of the node attributes, ie, src, scheme... Default: []

=item B<is_parent:Int> - specify if the node can accept children, including text node. Default: 1 (true),0 if not.

=back

=back

B<Returns> install the methods in the package.

=over 

=item C<none>

=back

Example:

   #Category.pm
   package WebService::GData::Node::Category;
   use WebService::GData::Node;

   set_meta(
        attributes=>['scheme','yt:term','label'],#default to []
        is_parent => 0, #default 1
        namespace_prefix => 'k', #default to ''
        tag_name  => 'category' # default to the package file name with the first letter in lower case
   );

   1;
   
   use WebService::GData::Node::Category();
   
   my $category = new WebService::GData::Node::Category('yt:term'=>'term');
      $category->yt_term('youtube term');
      
	   
=back

=head2 IMPLEMENTED NODES

Many core nodes have already be implemented. You can look at their source directly to see their meta information.
Although you may use this class and subclasses to implement other tags, most of the time they will be wrapped in the Feed 
packages and the end user shall not interact directly with them.


For reference, below is a list of all the tags implemented so far with their meta information (when it overwrites the default settings).

    APP                         #app: namespace
        - Control
        - Draft
        - Edited
        
    Atom                        #atom: namespace
        - Author
        - Category              #attributes=>scheme term label
        - Content               #attributes=>src type
        - Entry                 #attributes => gd:etag
        - Feed                  #attributes => gd:etag
        - Generator             #attributes => version uri
        - Id
        - Link                  #attributes=>rel type href
        - Logo
        - Name
        - Summary
        - Title
        - Updated
        - Uri
        
    GD                           #gd: namespace
        - AditionalName          #attributes=> yomi
        - Agent
        - AttendeeStatus         #attributes=>value,is_parent=>0
        - attendeeType           #attributes=>value,is_parent=>0
        - City
        - Comments               #attributes=>rel
        - Country                #attributes=>code
        - Deleted                #is_parent=>0
        - Email                  #attributes=>address displayName label rel primary
        - EntryLink              #attributes=>href readOnly rel
        - EventStatus            #attributes=>value,is_parent=>0
        - ExtendedProperty       #attributes=>name value
        - FamilyName             #attributes=>yomi
        - FeedLink               #attributes=>rel href countHint,is_parent=>0
        - FormattedAddress
        - GivenName              #attributes=> yomi
        - Housename
        - Im                     #attributes=>address label rel protocol primary
        - Money                  #attributes=>amount currencyCode,is_parent=>0
        - Name
        - Neighborhood
        - Organization           #attributes=>label primary rel
        - OrgDepartment
        - OrgJobDescription
        - OrgName                #attributes=>yomi
        - OrgSymbol
        - OrgTitle
        - OriginalEvent          #attributes=>id href
        - PhoneNumber            #attributes=>label rel uri primary
        - Pobox
        - PostalAddress          #attributes=>label rel primary
        - Postcode
        - Rating                 #attributes=>min max numRaters average value rel,is_parent=>0
        - Recurrence
        - RecurrenceException    #attributes=>specialized
        - Region
        - Reminder               #attributes=>absoluteTime method days hours minutes,is_parent=>0
        - Resourceid
        - Street
        - StructuredPostalAddress #attributes=>rel mailClass usage label primary
        - Subregion
        - Transparency            #attributes=>value,is_parent=>0
        - Visibility              #attributes=>value,is_parent=>0
        - When                    #attributes=>endTime startTime valueString,is_parent=>0
        - Where                   #attributes=>label rel valueString
        - Who                     #attributes=>email rel valueString
       
    GeoRSS                      #georss: namespace
       - Where
       
    GML                         #gml: namespace
       - Point                  #tag_name=>'Point'
       - Pos
       
    Media                       #media: namespace
       - Category               #attributes=>scheme label
       - Content                #attributes=>url type medium isDefault expression duration,is_parent=>0
       - Credit                 #attributes=>role yt:type scheme
       - Description            #attributes=>type
       - Group
       - Keywords
       - Player                 #attributes=>url
       - Rating                 #attributes=>scheme country
       - Restriction            #attributes=>type relationship
       - Thumbnail              #attributes=>url height width time, is_parent=>0
       - Title                  #attributes=>type
       
    OpenSearch                  #openSearch: namespace
       - ItemsPerPage             
       - StartIndex                
       - TotalResults                 


=head2  CAVEATS

=over

=item * As the package push itself into your package when you use it, you must be aware when to change this behavior.

=item * All the methods installed in the package could conflict with a node name or its attributes.

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
