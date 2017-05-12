package  perfSONAR_PS::DataModels::APIBuilder;
 
=head1 NAME

 perfSONAR_PS::DataModels::APIBuilder - builder utils to build binding perl objects collection
 
=head1 DESCRIPTION

      single call is here with several private ones
      the public call is:
      buildAPI(<top object name>, <top object>, <path>,<API root name>);
   
=head1 SYNOPSIS

      ###
      use   perfSONAR_PS::DataModels::DataModel  qw($message); 
      use  perfSONAR_PS::DataModels::APIBuilderqw(&buildAPI  $API_ROOT $TOP_DIR $DATATYPES_ROOT) ;
       
      $API_ROOT = 'perfSONAR_PS';
      $TOP_DIR = "/tmp/API/" .$API_ROOT;   
      $DATATYPES_ROOT = 'Datatypes';
       
      buildAPI('message', $message, '','' );
      ####
       
=cut 

=head1 API
 

 

=head2 Exported variables

  $API_ROOT  - name of the  API  ( empty string by default)
  $TOP_DIR  - top dirname of the API location( /tmp/API by default)
  $DATATYPES_ROOT - dirname for schema datamodel files
 
=cut



 use strict;
 use warnings;
  
 use IO::File;
 use File::Path;
 use Data::Dumper;
 use Log::Log4perl qw(get_logger);  
BEGIN {
 use Exporter ();
 our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
 use version; our $VERSION = qv('2.0');
        %EXPORT_TAGS = ();
        use base qw(Exporter);
        @EXPORT_OK     = qw( );
        @EXPORT_OK  =qw(  &buildAPI  &buildClass  $DATATYPES_ROOT $API_ROOT  $TOP_DIR $SCHEMA_VERSION $TEST_DIR);
}
our @EXPORT_OK;
our ( $API_ROOT,  $TOP_DIR, $DATATYPES_ROOT, $SCHEMA_VERSION, $TEST_DIR) = ('', '/tmp/API', 'Datatypes',  APIBuilder->VERSION, "$TOP_DIR/../");  
my %known_classes = ();
my %existed = (); 
my $logger = get_logger(  "APIBuilder" ); 
 
#
# prints second parameter ( string)  to multiple filehandles passed as arrayref 
#

sub printMulti {
     my ($fharr, $msg) = @_;
     foreach my $fh (@{$fharr}) {
        print $fh $msg;
     }
}
#
#  for new classname, path, root and ns will check if this package already exists and
#  then update path and root with appended classname and return root and path
#  where root is the API modules tree path and path is the directory pathname
#  without top dir name 
#
sub  _makeAPIPath {
     my ($classname, $path, $root,  $ns) = @_;
     my $classnameUP = ucfirst($classname);
     print "ROOT=   $API_ROOT\:\:$DATATYPES_ROOT\:\:$SCHEMA_VERSION\:\:$ns$root\:\:$classnameUP\n";
     unless ( $existed{"$API_ROOT\:\:$DATATYPES_ROOT\:\:$SCHEMA_VERSION\:\:$ns$root\:\:$classnameUP"} ) {
       $path  .= "/$classnameUP";
       $root  .=   "\:\:$classnameUP";
       $existed{ "$API_ROOT\:\:$DATATYPES_ROOT\:\:$SCHEMA_VERSION\:\:$ns$root" } =  $classname;
       $known_classes{$classname}{$ns} =   "$API_ROOT\:\:$DATATYPES_ROOT\:\:$SCHEMA_VERSION\:\:$ns$root"  ;
      }
      return ($root,  $path);  
   
}

=head2 buildAPI

   builds the whole API recursively
   
   accepts  four parameters
   - name of the root element - message by default
   - top hashref ( object to be built) 
   -   path ( empty by default )
   -   root API name ( empty by default )  
 
    
=cut
 
sub buildAPI {
       my ($name, $element, $path, $root, $parent ) = @_;
       my $ns = $element->{attrs}->{xmlns};
      
       ($root, $path) = _makeAPIPath($name, $path, $root,    $ns );
       
       if( $element && ref($element) eq 'HASH' &&  $element->{attrs} )  {
         
       if (ref($element->{elements}) eq 'ARRAY') {
         
          mkpath   ([ "$TOP_DIR/$DATATYPES_ROOT/$SCHEMA_VERSION/$ns/$path"  ], 1, 0755) ;
       }
       foreach my $el (@{$element->{elements}}) {
           if(ref($el) eq 'ARRAY') {
           
              if(ref($el->[1]) eq 'HASH' && $el->[1]->{attrs}) {
             
             buildAPI($el->[0],  $el->[1],  $path, $root,   $element ); 
         
          } elsif(ref($el->[1]) eq 'ARRAY') {
           
             foreach my $sub_el (@{$el->[1]}) {
                 if(ref($sub_el) eq 'HASH' && $sub_el->{attrs}) {  
                    buildAPI($el->[0],   $sub_el,   $path, $root, $element );
            } elsif(ref($sub_el) eq 'ARRAY' && scalar @{$sub_el} ==  1) {
                buildAPI($el->[0],   $sub_el->[0],   $path, $root,   $element  );  
                } else {
                $logger->error(" Malformed definition: name=" . $el->[0] . " Dump=" .  Dumper $sub_el);
            }
             } 
              }   
        }
            }     
       buildClass( "$TOP_DIR/$DATATYPES_ROOT/$SCHEMA_VERSION/$ns/$path", "$API_ROOT\:\:$DATATYPES_ROOT\:\:$SCHEMA_VERSION\:\:$ns$root" , $name, $element, $parent);      
      } 
      return;         
}
 
=head2 buildClass

   builds  single class on the filesystem and corresponded test file
   
   accepts  four parameters
     -   full  path to the class ( except for .pm extension)
     -   full  package  name  
     -   name of the   element 
     -   hashref with the element definition  
     -   hashref with parent definition if its not the root element

=cut

 sub  buildClass {
     my ($path, $root,   $name, $element, $parent ) = @_;
     my $className =   $root;
    
     my $fh = IO::File->new(  $path . ".pm","w+");
     $logger->error(" Failed to open file :" . $path . ".pm")  unless $fh;
    
#------------------------------------------------------------------------------
   my @elements =     grep(ref($_) eq 'ARRAY' && $_->[0] && $_->[1],   @{$element->{elements}});
  
   my @elementnodes = grep(ref($_->[1]),   @elements);
   my @textnodes =    grep($_->[1] eq 'text'  && !ref($_->[1]),  @elements);
 
   my $elements_names = @elementnodes?join (" " ,  map { $_->[0] }  @elementnodes):'';
   my $texts_names =  @textnodes?join (" " , map { $_->[0] } @textnodes):'';
   
   my @attributes =  grep(!/xmlns/, keys %{$element->{attrs}});
   my $attributes_names = @attributes?join " " , @attributes:'';
#--------------------------------------------------------------------------------  
   my %parent_sql = ();
   if($parent &&  ref($parent) eq 'HASH' && $parent->{sql}) {
       foreach my $table (keys %{$parent->{sql}}) {
           foreach my $field (keys %{$parent->{sql}->{$table}}) {
               my $value =  $parent->{sql}->{$table}->{$field}->{value};
           $value = [$value]  if ref($value) ne 'ARRAY';
           foreach my   $possible (@{$value}) {
              $parent_sql{$table}{$field}{$possible}++;
           }
       }
       }
   }  
   my %sql_pass =(); ### hash with pass through 
   my %sql_here =(); ### hash with sql to get here
  # preprocessing sql config    
   if($element->{sql}) {
       foreach my $table (keys %{$element->{sql}}) {
           foreach my $field (keys %{$element->{sql}->{$table}}) {
               my $value =  $element->{sql}->{$table}->{$field}->{value};
           unless($value) {
               $logger->error(" SQL config malformed for element=$name table=$table field=$field, but value is missied");
           return;
           } 
           my $condition = $element->{sql}->{$table}->{$field}->{if};
           my ($attr_name, $set) = $condition?$condition  =~ m/^(\w+):?(\w+)?$/:('','');
           my $cond_string = $condition && $set?" (\$self->$attr_name eq '$set') ":$condition?" (\$self->$attr_name)":'';
           
           $value = [$value]  if ref($value) ne 'ARRAY';
           
           foreach my   $possible (@{$value}) {
                next if %parent_sql && $parent_sql{$table}{$field} && !$parent_sql{$table}{$field}{$name};
           if($elements_names =~ /\b$possible\b/) {  #### if name of the possible element is among the members of this object the pass  it there
               $sql_pass{$possible}{$table}{$field} = $cond_string;
           } else {                                     ######  otherwise set it with some value ( text or attribute )
               $sql_here{$possible}{$table}{$field} = $cond_string;
           } 
               }
           }
       }
   }

#-------------------------------------------- build tests 

   buildTest(\@elementnodes,  \@attributes, $className, $name, $element);
   $logger->debug("\n...... List of Attributes:$attributes_names \n Texts: $texts_names \n Elements: $elements_names\n");
#----------------------------------------------
( my $version = $SCHEMA_VERSION ) =~ tr/_/./;
#--------------------------------------------
print  $fh <<EOA;
package  $className;
use strict;
use warnings;
use English qw( -no_match_vars);
use version; our \$VERSION = qv('$version');
=head1 NAME

 $className  - A base class, implements  '$name'  element from the perfSONAR_PS RelaxNG schema
  
=head1 DESCRIPTION

   Object representation of the $name element.
   Object fields are:
EOA
#------------------------------------------------------------------------------
map { print $fh   "    Scalar:     $_, \n"  }   @attributes ;
map { print $fh   "    Object reference:   " . $_->[0]  . " => type " . ref($_->[1]) . ",\n" }  @elements ;
   
  
   print $fh <<EOB;
   
   The constructor accepts only single parameter, it could be a hashref to parameters hash  or DOM with  '$name' element 
    
    
=head1 SYNOPSIS

              use $className;
          
          my \$el =  $className->new(\$DOM_Obj);
 
=head1   METHODS

=cut
 

use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Element qw(getElement);
use perfSONAR_PS::Datatypes::Namespace;
use perfSONAR_PS::Datatypes::NSMap;
use Readonly;
EOB
foreach my $el (@elementnodes) {
   foreach my $ns (keys %{$known_classes{$el->[0]}}) {
       print $fh  "use " . $known_classes{$el->[0]}{$ns} . ";\n"  if $known_classes{$el->[0]}{$ns}; 
   }
}


print  $fh <<EOC;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
EOC


 
print  $fh  "use fields qw(nsmap idmap refidmap $attributes_names $elements_names $texts_names ";
print $fh " text " if $element->{text}; 
print  $fh  ");\n";  
 
print  $fh  <<EOD;

$className->mk_accessors($className->show_fields('Public'));
  
=head2 new( )
   
      creates   object, accepts DOM with  element tree or hashref to the list of
      keyd parameters
EOD
map { print $fh   "         $_   => undef, \n"  }  @attributes ;
map { print $fh   "         " . $_->[0]  . " => " . ref($_->[1]) . ",\n"   }  @elementnodes;
print $fh "text => 'text'\n" if $element->{text};              
 
print  $fh  <<EOF;

=cut
Readonly::Scalar our \$COLUMN_SEPARATOR => ':';
Readonly::Scalar our \$CLASSPATH =>  '$className';
Readonly::Scalar our \$LOCALNAME => '$name';
            
sub new { 
    my \$that = shift;
    my \$param = shift;
 
    my \$logger  = get_logger( \$CLASSPATH ); 
    my \$class = ref(\$that) || \$that;
    my \$self =  fields::new(\$class );
    \$self->nsmap(perfSONAR_PS::Datatypes::NSMap->new()); 
EOF
   
print $fh "    \$self->nsmap->mapname( \$LOCALNAME, '" .   $element->{attrs}->{xmlns} . "');\n";
 
print $fh <<EOG;
    
    if(\$param) {
        if(blessed \$param && \$param->can('getName')  && (\$param->getName =~ m/\$LOCALNAME\$/xm) ) {
            return  \$self->fromDOM(\$param);  
          
        } elsif(ref(\$param) ne 'HASH')   {
            \$logger->error("ONLY hash ref accepted as param " . \$param ); 
            return;
        }
    if(\$param->{xml}) {
         my \$parser = XML::LibXML->new();
             my \$dom;
             eval {
                  my \$doc = \$parser->parse_string( \$param->{xml});
          \$dom = \$doc->getDocumentElement;
             };
             if(\$EVAL_ERROR) {
                 \$logger->error(" Failed to parse XML :" . \$param->{xml} . " \\n ERROR: \\n" . \$EVAL_ERROR);
                return;
             }
             return  \$self->fromDOM( \$dom );  
    } 
        \$logger->debug("Parsing parameters: " . (join " : ", keys \%{\$param}));
     
        no strict 'refs';
        foreach my \$param_key (keys \%{\$param}) {
            \$self->\$param_key( \$param->{\$param_key} ) if \$self->can(\$param_key);
        }  
        use strict;     
   
       \$logger->debug("Done ");     
    }  
    return \$self;
}

 
sub DESTROY {
    my \$self = shift;
    \$self->SUPER::DESTROY  if \$self->can("SUPER::DESTROY");
    return;
}
 
=head2   getDOM (\$) 
      
       accept parent DOM
       return $name object DOM, generated from object contents 
  
=cut 
 
sub getDOM {
    my \$self = shift;
    my \$parent = shift; 
    my \$logger  = get_logger( \$CLASSPATH ); 
    my \$$name = getElement({name =>   \$LOCALNAME, parent => \$parent , ns => [\$self->nsmap->mapname( \$LOCALNAME )],
                             attributes => [

EOG
#-------------------------------
 
 foreach my $attr (@attributes) {
      $logger->debug("_printConditional:: $attr = " . $element->{attrs}->{$attr});
      print $fh  _printConditional( $attr, $element->{attrs}->{$attr}, 'get');
 }
 print $fh   "                                           ],\n"; # end for attributes
 print $fh  _printConditional(  'text', $element->{text} , 'get') if ($element->{text} );
 
print $fh   "                         }); \n";
### deal with subelements 
###
###   each subel defined as [ name => obj  ] or [name => [obj]] or [name => [obj1,obj2]]  or    [name => [[obj1],[obj2]]]
### 
###                             just object    arrayref of objects  choice between two obj        chiice between two obj arrayref
###
foreach my $els (@elementnodes) {
    $logger->fatal(" What the heck: name=$name els=$els ") unless ref($els) eq 'ARRAY';
 
    my  $condition =  conditionParser($els->[2]);
    my $subname =  $els->[0];
    $condition->{logic} .= " && " if  $condition->{logic};
    if(ref($els->[1])    eq  'ARRAY') { 
        if(scalar @{$els->[1]} >  1 ) {     
            if(ref( $els->[1]->[0]) ne 'ARRAY') {
                printGetDOM($fh, $subname, $name,  $condition->{logic}); 
        } else {
            printGetArrayDom($fh, $subname, $name,  $condition->{logic});    
        }  
        } else {
            printGetArrayDom($fh, $subname, $name,  $condition->{logic});
        }
    } elsif(ref($els->[1])   eq  'HASH') {
        printGetDOM($fh, $subname, $name,  $condition->{logic});
    }  
}
if( $texts_names ) {
       print $fh  "   foreach my \$textnode (qw/$texts_names /) {\n";
       print $fh  "       if(\$self->{\$textnode}) { \n";
       print $fh  "            my  \$domtext  =  getElement({name =>   \$textnode, parent => \$$name , ns => [\$self->nsmap->mapname(\$LOCALNAME)],\n";
       print $fh  "                                          text => \$self->{\$textnode},\n";
       print $fh  "                                 });\n";
       print $fh  "            \$domtext?\$$name->appendChild(\$domtext):\$logger->error(\"Failed to append new text element \$textnode  to  $name   \");\n";
       print $fh  "        } \n";
       print $fh  "   } \n";
 }
 print $fh "    return \$$name;\n}\n";
  
foreach my  $el (@elementnodes) {
    my $subname = $el->[0];
   if(ref($el->[1]) eq 'ARRAY') { 
  
    print $fh <<EOH5;
  
=head2  add$subname()

    if any of subelements can be an arrray then this method will provide
    facility to add another element to the  array and will return ref to such array
    or just set the element to a new one
=cut

sub add\u$subname {
    my \$self = shift;
    my \$new = shift;
    my \$logger  = get_logger( \$CLASSPATH ); 
   
    \$self->$subname && ref(\$self->$subname) eq 'ARRAY'?push \@{\$self->$subname}, \$new:\$self->$subname([\$new]); 
    \$logger->debug("Added new to $subname"); 
    \$self->buildIdMap; ## rebuild index map 
    \$self->buildRefIdMap; ## rebuild ref index map  
    return \$self->$subname;
}

=head2  remove\u${subname}ById()

     remove specific element from the array of ${subname} elements by id ( if id is supported by this element )
     accepts single param - id - which is id attribute of the element
     if there is no array then it will return undef and warninig
     if it removed some id then \$id will be returned
     
=cut

sub remove\u${subname}ById {
    my \$self = shift;
    my \$id = shift;
    my \$logger  = get_logger( \$CLASSPATH ); 
    if(ref(\$self->$subname) eq 'ARRAY' && \$self->idmap->{$subname} &&  exists \$self->idmap->{$subname}{\$id}) { 
        \$self->$subname->\[\$self->idmap->{$subname}{\$id}\]->DESTROY; 
    my \@tmp =  grep { defined \$_ } \@{\$self->$subname};  
    \$self->$subname([\@tmp]);
    \$self->buildRefIdMap; ## rebuild ref index map  
    \$self->buildIdMap; ## rebuild index map 
    return \$id;
    } elsif(!ref(\$self->$subname)  || ref(\$self->$subname) ne 'ARRAY')  {
        \$logger->warn("Failed to remove  element because ${subname} not an array for non-existent id:\$id");  
    } else {
        \$logger->warn("Failed to remove element for non-existant id:\$id");  
    } 
    return;
}   
=head2  get\u${subname}ByMetadataIdRef()

     get specific object from the array of ${subname} elements by  MetadataIdRef( if  MetadataIdRef is supported by this element )
     accepts single param -  MetadataIdRef
     if there is no array then it will return just an object
     
=cut

sub get\u${subname}ByMetadataIdRef {
    my \$self = shift;
    my \$id = shift;
    my \$logger  = get_logger( \$CLASSPATH ); 
    if(ref(\$self->$subname) eq 'ARRAY' && \$self->refidmap->{$subname} && exists \$self->refidmap->{$subname}{\$id}) {
        my \$$subname = \$self->$subname->\[\$self->refidmap->{$subname}{\$id}\];
    return (\$$subname->can("metadataIdRef") &&   \$$subname->metadataIdRef eq  \$id)?\$$subname:undef; 
    } elsif(\$self->$subname && (!ref(\$self->$subname) || 
                                    (ref(\$self->$subname) ne 'ARRAY' &&
                                     blessed \$self->$subname && \$self->$subname->can("metadataIdRef") &&
                     \$self->$subname->metadataIdRef eq  \$id)))  {
        return \$self->$subname;
    }  
    \$logger->warn("Requested element for non-existent metadataIdRef:\$id"); 
    return;
    
}

=head2  get\u${subname}ById()

     get specific element from the array of ${subname} elements by id ( if id is supported by this element )
     accepts single param - id
     if there is no array then it will return just an object
     
=cut

sub get\u${subname}ById {
    my \$self = shift;
    my \$id = shift;
    my \$logger  = get_logger( \$CLASSPATH ); 
    if(ref(\$self->$subname) eq 'ARRAY' && \$self->idmap->{$subname} &&  exists \$self->idmap->{$subname}{\$id} ) {
        return \$self->$subname->\[\$self->idmap->{$subname}{\$id}\];
    } elsif(!ref(\$self->$subname) || ref(\$self->$subname) ne 'ARRAY')  {
        return \$self->$subname;
    }  
    \$logger->warn("Requested element for non-existent id:\$id"); 
    return;   
}
EOH5
}

}

print $fh <<EOH56;

=head2  querySQL ()

      depending on config  it will return some hash ref  to the initialized fields
    for example querySQL ()
    accepts one optional prameter - query hashref
    will return:
    { ip_name_src =>  'hepnrc1.hep.net' },}
    
=cut

sub  querySQL {
    my \$self = shift;
    my \$query = shift; ### undef at first and then will be hash ref
    my \$logger  = get_logger( \$CLASSPATH );
     
EOH56
    if($element->{sql}) {
      print $fh "    my \%defined_table = (";
      
      foreach my $table (keys %{$element->{sql}}) { 
           print $fh "  '$table' => [";
       foreach my $field (keys %{$element->{sql}->{$table}}) {   
         print $fh "  '$field', ";
       }
       print $fh " ], ";
      }
      print $fh " );\n";
    }
 
    foreach my  $subname (keys %sql_pass) {  
        foreach my $table (keys %{$sql_pass{$subname}}) {
        foreach my $entry (keys %{$sql_pass{$subname}{$table}}) { 
                print $fh "    \$query->{$table}{$entry}= [";
            foreach my $nss (keys %{ $known_classes{$subname}}) { 
                    print $fh "    '$known_classes{$subname}{$nss}',";
               }
           print $fh "    ];\n";
        }    
    }
    }
    foreach my  $subname (keys %sql_here) {  
        foreach my $table (keys %{$sql_here{$subname}}) {
        foreach my $entry (keys %{$sql_here{$subname}{$table}}) {
           
           print $fh "    \$query->{$table}{$entry}= [ '$className' ] if!(defined \$query->{$table}{$entry}) || ref(\$query->{$table}{$entry});\n";
        }    
    }
    }
if($elements_names)  {   
print $fh <<EOH78; 
    foreach my \$subname (qw/$elements_names/) {
        if(\$self->{\$subname} && (ref(\$self->{\$subname}) eq 'ARRAY' ||  blessed \$self->{\$subname}))   {
            my \@array = ref(\$self->{\$subname}) eq 'ARRAY'?\@{\$self->{\$subname}}:(\$self->{\$subname});
        foreach my \$el  (\@array) {
            if(blessed  \$el  &&  \$el->can("querySQL"))  {
                    \$el->querySQL(\$query);         
                    \$logger->debug("Quering $name  for subclass \$subname");
            } else {
                \$logger->error(" Failed for $name Unblessed member or querySQL is not implemented by subclass \$subname");
            }
        }  
        }
    }    
EOH78
}
    if(%sql_here)  {
        print $fh   "    eval { \n";
        print $fh   "        foreach my \$table  ( keys \%defined_table) {  \n";
        print $fh   "            foreach my \$entry (\@{\$defined_table{\$table}}) {  \n";
    print $fh   "                if(ref(\$query->{\$table}{\$entry}) eq 'ARRAY') {\n";
        print $fh   "                    foreach my \$classes (\@{\$query->{\$table}{\$entry}}) {  \n";
         print $fh  "                        if(\$classes && \$classes eq '$className' ) { \n";
        my $if_sub_cond = ' if    ';
        foreach my  $subname  (@attributes, 'text') {       
             if($sql_here{$subname})  {
                print $fh   getSQLSub($sql_here{$subname},   $subname, $if_sub_cond  ); 
            $if_sub_cond =  ' elsif ';
         }
        } 
    print $fh  "                         }\n";
        print $fh  "                     }\n";
        print $fh  "                 }\n";    
        print $fh  "             }\n";
    print $fh  "        }\n";
    print $fh  "    }; \n    if (\$EVAL_ERROR) { \$logger->logcroak(\" SQL query building is failed  here \" . \$EVAL_ERROR)};\n";
    }
    print $fh  "    return \$query;\n";
    print $fh  "}\n";
   

print $fh <<EOHH;

=head2 merge

      merge with another $name ( append + overwrite if exists )
      we can do it differently
      method #1:
         convert to dom both objects and then get resulted object from combined dom 
      method #2 default:
         through the introspection of the object

=cut


sub merge {
    my \$self = shift;
    my \$new_${name} = shift;
    my \$logger  = get_logger( \$CLASSPATH );  
    unless(\$new_${name} && blessed \$new_${name} && \$new_${name}->can("getDOM")) {
        \$logger->error(" Please supply defined object of $name  ");
        return;
    } 
    ### for each field ( element or attribute )
    ### merge elements, add if its arrayref and overwrite attribtues for the same elements
    ### merge only if namespace is the same  
    foreach my \$member_name (\$new_${name}->show_fields) {
        ### double check if   objects are the same
    if(\$self->can(\$member_name)) {
        my \$current_member  = \$self->{\$member_name};
        my \$new_member      =  \$new_${name}->{\$member_name};
        ###  check if both objects are defined
        if(\$current_member && \$new_member) {
            ### if  one of them array then just add another one
            if(blessed \$current_member && blessed \$new_member  && \$current_member->can("merge") 
               && ( \$current_member->nsmap->mapname(\$member_name) 
                eq  \$new_member->nsmap->mapname(\$member_name) ) ) {
               \$current_member->merge(\$new_member);
            \$self->{\$member_name} =  \$current_member;
            \$logger->debug("  Merged \$member_name , got" . \$current_member->asString);
            ### if its array then just push
            } elsif(ref(\$current_member) eq 'ARRAY'){
                 
           \$self->{\$member_name}=[\$current_member, \$new_member];
              
            \$logger->debug("  Pushed extra to \$member_name ");
            }  
        ## thats it, dont merge if new member is just a scalar
        } elsif( \$new_member) {
           \$self->{\$member_name} = \$new_member;
        }   
    } else {
        \$logger->error(" This field \$member_name,  found in supplied  $name  is not supported by $name class");
        return;
        }
    }
    return \$self;
} 
 
=head2  buildIdMap()

    if any of subelements has id then get a map of it in form of
    hashref to { element}{id} = index in array and store in the idmap field

=cut

sub  buildIdMap {
    my \$self = shift;
    my \$map = (); 
    my \$logger  = get_logger( \$CLASSPATH );
EOHH
   if( @elementnodes ) {
        print $fh  "    foreach my \$field (qw/$elements_names/) {\n";
    print $fh  "        my \@array = ref(\$self->{\$field}) eq 'ARRAY'?\@{\$self->{\$field}}:(\$self->{\$field});\n";
        print $fh  "        my \$i = 0;\n";
        print $fh  "        foreach my \$el ( \@array)  {\n";
    print $fh  "            if(\$el && blessed \$el && \$el->can(\"id\") &&  \$el->id)  { \n";
        print $fh  "                \$map->{\$field}{\$el->id} = \$i;   \n"; 
        print $fh  "            }\n"; 
    print $fh  "            \$i++;\n"; 
    print $fh  "        }\n";
    print $fh  "    }\n";
        print $fh  "    return \$self->idmap(\$map);\n";
     } else {
        print $fh  "    return;\n";
    }  
     print $fh  "}\n";
     
print $fh <<EOHH23;
=head2 buildrefIdMap ()

    if any of subelements has  metadataIdRef  then get a map of it in form of
    hashref to { element}{ metadataIdRef } = index in array and store in the idmap field

=cut

sub  buildRefIdMap {
    my \$self = shift;
    my \%map = (); 
    my \$logger  = get_logger( \$CLASSPATH );
EOHH23

   if( @elementnodes ) {
        print $fh  "    foreach my \$field (qw/$elements_names/) {\n";
    print $fh  "        my \@array = ref(\$self->{\$field}) eq 'ARRAY'?\@{\$self->{\$field}}:(\$self->{\$field});\n"; 
    print $fh  "        my \$i = 0;\n";
        print $fh  "        foreach my \$el ( \@array)  {\n";  
    print $fh  "            if(\$el && blessed \$el  && \$el->can(\"metadataIdRef\") &&  \$el->metadataIdRef )  { \n";
        print $fh  "                \$map{\$field}{\$el->metadataIdRef} = \$i;   \n";
        print $fh  "            }\n"; 
    print $fh  "            \$i++;\n"; 
    print $fh  "        }\n";
    print $fh  "    }\n";
        print $fh  "    return \$self->refidmap(\\\%map);\n";
     } else {
        print $fh  "    return;\n";
    }  
     print $fh  "}\n";
     
print $fh <<EOH1; 
=head2  asString()

   shortcut to get DOM and convert into the XML string
   returns XML string  representation of the  $name object

=cut

sub asString {
    my \$self = shift;
    my \$dom = \$self->getDOM();
    return \$dom->toString('1');
}

=head2 registerNamespaces ()

   will parse all subelements and register all namepspaces within the $name namespace

=cut

sub registerNamespaces {
    my \$self = shift;
    my \$logger  = get_logger( \$CLASSPATH );
    my \$nsids = shift;
    my \$local_nss = {reverse \%{\$self->nsmap->mapname}};
    unless(\$nsids) {
        \$nsids =  \$local_nss;
    }  else {
        \%{\$nsids} = ( \%{\$local_nss},  \%{\$nsids});
    }
EOH1
     if( @elementnodes ) {
        print $fh  "    foreach my \$field (qw/$elements_names/) {\n";
    
    print $fh  "        my \@array = ref(\$self->{\$field}) eq 'ARRAY'?\@{\$self->{\$field}}:(\$self->{\$field});\n";
        print $fh  "        foreach my \$el ( \@array)  {\n";
    print $fh  "            if(blessed \$el &&   \$el->can(\"registerNamespaces\") )  { \n";
    print $fh  "                my \$fromNSmap =  \$el->registerNamespaces(\$nsids); \n";
    print $fh  "                my \%ns_idmap =   \%{\$fromNSmap};  \n";
    print $fh  "                foreach my \$ns ( keys \%ns_idmap)  {\n";
    print $fh  "                      \$nsids->{\$ns}++\n";
    print $fh  "                }\n";
    print $fh  "            }\n";
        print $fh  "        }\n";  
    print $fh  "    }\n";
     }
        print $fh  "    return     \$nsids;\n";
    
       print $fh   "}\n"; 
       
       
print $fh <<EOH2;  
=head2  fromDOM (\$)
   
   accepts parent XML DOM   element   tree as parameter 
   returns $name  object

=cut

sub fromDOM {
    my \$self = shift;
    my \$logger  = get_logger( \$CLASSPATH ); 
    my \$dom = shift;
     
EOH2
  $logger->debug("  fromDOM for: name=$name ");
 foreach my $attr (@attributes) {
     print $fh  _printConditional($attr, $element->{attrs}->{$attr}, 'from');  
     print $fh "    \$logger->debug(\" Attribute $attr= \". \$self->$attr) if \$self->$attr; \n";
 }
 print $fh  _printConditional('text', $element->{text}, 'from') if ($element->{text}) ;
 if(@elements) {
    print $fh "    foreach my \$childnode (\$dom->childNodes) { \n";
    print $fh "        my  \$getname  = \$childnode->getName;\n";
    print $fh "        my (\$nsid, \$tagname) = split \$COLUMN_SEPARATOR,  \$getname; \n";
    print $fh "        unless(\$nsid && \$tagname) {   \n"; 
 ##   print $fh "           \$logger->warn(\" Undefined  tag=\$getname\");        \n";
    print $fh "            next;\n";         
    print $fh "        }\n";
    my $conditon_head =  '        if';
    foreach my $els (@elementnodes) {
       $logger->fatal("   What the heck: name=$name els=$els ") unless ref($els) eq 'ARRAY';
       my $subname =  $els->[0];
       my  $condition  =  conditionParser($els->[2]);
       $condition->{logic} .= " && " if  $condition->{logic};
       if(ref($els->[1])    eq  'ARRAY') { 
          if(scalar @{$els->[1]} >  1 )  {
         foreach my $choice (@{$els->[1]}) {
             if(ref($choice) ne  'ARRAY') { 
                 printFromDOM($fh, $subname, $choice,   'CHOICE', $conditon_head,   $condition->{logic});
                 $conditon_head = ' elsif';
          } elsif(scalar @{$choice} ==  1 ) {
             printFromDOM($fh, $subname, $choice->[0],   'ARRAY', $conditon_head,   $condition->{logic});
                 $conditon_head = ' elsif';
          } else {
            $logger->logdie(" Malformed element definition: name=$name subelement=$subname  ");
          } 
        }
      } else {
          printFromDOM($fh, $subname, $els->[1]->[0] ,   'ARRAY',$conditon_head,    $condition->{logic});
      }
        } elsif (ref($els->[1])    eq  'HASH') {
            printFromDOM($fh, $subname,$els->[1],   'HASH',$conditon_head,   $condition->{logic});
    }  
     $conditon_head = ' elsif';
    }
    if( @textnodes) {
        print $fh "$conditon_head (\$childnode->textContent && \$self->can(\"\$tagname\")) { \n";
        print $fh "           \$self->{\$tagname} =  \$childnode->textContent; ## text node \n";
        print $fh "        }  "; 
     
    }
    if(@elementnodes || @textnodes) {
       print $fh "     ###  \$dom->removeChild(\$childnode); ##remove processed element from the current DOM so subclass can deal with remaining elements\n";
    }
  
    print $fh "    }\n"; 
    print $fh "  \$self->buildIdMap;\n \$self->buildRefIdMap;\n \$self->registerNamespaces;\n  "; 
 }
 
    
 print $fh "\n return \$self;\n}\n"; 
 
print $fh <<EOJ;

 
 
=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007-2008, maxim\@fnal.gov

=cut 

1;
 
EOJ

close $fh; 
return; 
} 
#    auxiliary private function 
#    build test file for the class  
#
sub buildTest {
  my ($elementnodes, $attributes, $className, $name, $element) = @_; 
   mkpath   ([ "$TEST_DIR" ], 1, 0755);
   my $fhtest = IO::File->new( "$TEST_DIR$className.t" ,"w+");
    $logger->error(" Failed to open test suite file : $TEST_DIR$className.t")  unless $fhtest;
    
    print  $fhtest <<EOTA;
use warnings;
use strict;    
use Test::More 'no_plan';
use Data::Dumper;
use FreezeThaw qw(cmpStr);
use Log::Log4perl;
use_ok('$className');
use    $className;
EOTA

foreach my $el (@{$elementnodes}) {
   foreach my $ns (keys %{$known_classes{$el->[0]}}) {
       print $fhtest  "use " . $known_classes{$el->[0]}{$ns} . ";\n"  if $known_classes{$el->[0]}{$ns}; 
   }
}

    print $fhtest <<EOTB;
Log::Log4perl->init("$TOP_DIR/logger.conf"); 

my \$obj1 = undef;
#2
eval {
\$obj1 = $className->new({
EOTB

    map { print $fhtest   "  '$_' =>  'value_$_'," }   @{$attributes};
    print $fhtest "})\n};\n  ok( \$obj1  && \!\$EVAL_ERROR , \"Create object $className...\" . \$EVAL_ERROR);\n  \$EVAL_ERROR = undef; \n";

    print $fhtest "#3\n";
    print $fhtest " my \$ns  =  \$obj1->nsmap->mapname('$name');\n"; 
    print $fhtest " ok(\$ns  eq '". $element->{attrs}->{xmlns} . "', \"  mapname('$name')...  \");\n";
    my $testn = '4';
    foreach my $att (@{$attributes}) {
        print $fhtest "#$testn\n";
        print $fhtest " my \$$att  =  \$obj1->$att;\n"; 
        print $fhtest " ok(\$$att  eq 'value_$att', \" checking accessor  obj1->$att ...  \");\n";
        $testn++;
    }
    foreach my $subel (@{$elementnodes}) { 
        my $subel1 = (ref($subel->[1]) eq 'ARRAY')?
                      ((ref($subel->[1]->[0]) eq 'ARRAY')?$subel->[1]->[0]->[0]:$subel->[1]->[0]):
                                      ((ref($subel->[1]) eq 'HASH')?$subel->[1]:undef);
        next unless $subel1;
        print $fhtest "#$testn\n"; 
        my $subel_name = $subel->[0];
        print $fhtest " my  \$obj_$subel_name  = undef;\n";
        print $fhtest " eval {\n";
        print $fhtest "      \$obj_$subel_name  =  " . $known_classes{$subel_name}{$subel1->{attrs}->{xmlns}} ."->new({";
        map { print $fhtest   "  '$_' =>  'value$_'," if   $_ ne 'xmlns' &&   $subel1->{attrs}->{$_}}  keys %{$subel1->{attrs}};
        print $fhtest "});\n";
       (ref($subel->[1]) eq 'ARRAY' && $#{$subel->[1]} == 0)?print $fhtest "    \$obj1->add\u$subel_name(\$obj_$subel_name);\n":
                                                             print $fhtest "    \$obj1->$subel_name(\$obj_$subel_name);\n ";
    print $fhtest "  }; \n";
        print $fhtest " ok( \$obj_$subel_name && \!\$EVAL_ERROR , \"Create subelement object $subel_name and set it  ...\" . \$EVAL_ERROR);\n  \$EVAL_ERROR = undef; \n";
        $testn++; 
     
    }
    print $fhtest "#$testn\n"; 
    print $fhtest " my \$string = undef;\n";
    print $fhtest " eval {\n";
    print $fhtest "      \$string =  \$obj1->asString \n";
    print $fhtest " };\n";
    print $fhtest " ok(\$string   && \!\$EVAL_ERROR  , \"  Converting to string XML:   \$string \" . \$EVAL_ERROR);\n";
    print $fhtest " \$EVAL_ERROR = undef;\n"; 
    $testn++;
    print $fhtest "#$testn\n";  
    
    print $fhtest " my \$obj22 = undef; \n";
    print $fhtest " eval {\n";
    print $fhtest "    \$obj22   =   $className->new({xml => \$string});\n";
    print $fhtest " };\n";
    print $fhtest " ok( \$obj22  && \!\$EVAL_ERROR , \"  re-create object from XML string:  \".   \$EVAL_ERROR);\n";
    print $fhtest " \$EVAL_ERROR = undef;\n"; 
    $testn++;
    print $fhtest "#$testn\n";  
    print $fhtest " my \$dom1 = \$obj1->getDOM();\n";
    print $fhtest " my \$obj2 = undef; \n";
    print $fhtest " eval {\n";
    print $fhtest "    \$obj2   =   $className->new(\$dom1);\n";
    print $fhtest " };\n";
    print $fhtest " ok( \$obj2  && \!\$EVAL_ERROR , \"  re-create object from DOM XML:  \".   \$EVAL_ERROR);\n";
    print $fhtest " \$EVAL_ERROR = undef;\n"; 
    close $fhtest;
}


#
#   auxiliary private function 
#   prints part of getSQL which maps available entries on sql request hash 
#
sub getSQLSub {
    my ($sql_fields,   $subname,  $if_cond ) = @_;
    my $head_string = "                           $if_cond(\$self->$subname && ("; 
    my $add = ' ';
    foreach my $table (keys %{$sql_fields}) { 
       
        $head_string .= "$add( ";
        my @cond_string = ();
        foreach my $field (keys %{$sql_fields->{$table}}) { 
            my $cond = $sql_fields->{$table}{$field};
        $cond .= ' && ' if $cond;  
        push @cond_string, " ($cond\$entry eq '$field')";
        }
        $head_string .=  (join " or ", @cond_string) . ")"; 
         $add = ' || ';
      } 
      $head_string .=  " )) {\n";
        
     $head_string .=   "                                \$query->{\$table}{\$entry} =  \$self->$subname;\n"; 
     $head_string .=   "                                \$logger->debug(\" Got value for SQL query \$table.\$entry: \" . \$self->$subname);\n"; 
     $head_string .=   "                                last;  \n"; 
     $head_string .=   "                            }\n";
     return $head_string;
}
#
#   auxiliary private function 
#   printing fromDOM part
#
#
sub printFromDOM {
    my ($fh, $subname, $el,   $type, $conditon_head, $cond_string ) = @_;
    my  $subnameUP =  ucfirst($subname);
    $logger->debug("Building fromDOM: type=$type subname=$subname");
    print $fh "$conditon_head ($cond_string\$tagname eq  '$subname' && \$nsid eq '".  $el->{'attrs'}{'xmlns'}  . "' && \$self->can(\$tagname)) { \n";
    print $fh "           my \$element = undef;\n";
    print $fh "           eval {\n";
    print $fh "               \$element = " . $known_classes{$subname}{$el->{'attrs'}{'xmlns'}} . "->new(\$childnode) \n";
    print $fh "           };\n";
    print $fh "           if(\$EVAL_ERROR || !(\$element  && blessed \$element)) {\n";
    print $fh "               \$logger->error(\" Failed to load and add  $subnameUP : \" . \$dom->toString . \" error: \" . \$EVAL_ERROR);\n";
    print $fh "               return;\n";
    print $fh "           }\n";
    print $fh   (($type eq 'ARRAY')?"           (\$self->$subname && ref(\$self->$subname) eq 'ARRAY')?push \@{\$self->$subname}, \$element:\$self->$subname([\$element]);":
                       "           \$self->$subname(\$element)") . "; ### add another $subname  \n";
    print $fh "        } ";
}
#
#   auxiliary private function 
#   printing  getDom  part for arrayref members ( when its more then single instance of the sublelement )
#
sub printGetArrayDom { 
    my ($fh, $subname, $name, $logic) = @_;
       print $fh  "    if($logic\$self->$subname && ref(\$self->$subname) eq 'ARRAY' ) {\n";
       print $fh  "        foreach my \$subel (\@{\$self->$subname}) { \n";
       print $fh  "            if(blessed  \$subel  &&  \$subel->can(\"getDOM\")) { \n";
       print $fh  "                 my  \$subDOM =  \$subel->getDOM(\$$name);\n";
       print $fh  "                \$subDOM?\$$name->appendChild(\$subDOM):\$logger->error(\"Failed to append  $subname elements  with value: \" .  \$subDOM->toString ); \n";    
       print $fh  "            }\n";
       print $fh  "         }\n";
       print $fh  "    }\n";
}
#
#   auxiliary private function 
#   printing  getDom  part for singular  object members 
#
sub printGetDOM {
    my ($fh, $subname, $name, $cond_string) = @_;
    print $fh  "   if($cond_string\$self->$subname  && blessed \$self->$subname  && \$self->$subname->can(\"getDOM\")) {\n";
    print $fh  "        my  \$${subname}DOM = \$self->$subname->getDOM(\$$name);\n";
    print $fh  "       \$${subname}DOM?\$$name->appendChild(\$${subname}DOM):\$logger->error(\"Failed to append  $subname  with value: \" .  \$${subname}DOM->toString ); \n";    
    print $fh  "   }\n";
} 
#
#    auxiliary private function 
#    will parse conditional string and return  regexp and  logical condition
#    accepted parameter: $value is string to parse  
#    will return hashref to the resulted hash with keys: {condition  , logic =>  , regexp  }
#
sub conditionParser {
    my $value = shift;
    my $result = { condition => '', logic => '', regexp => ''};
    return $result  unless $value;
    $value  =~ s/^(scalar|enum|set|if|unless|exclude)\:?//;
    $result->{condition} = $1;
    my    @list  = split ",", $value   unless  $result->{condition} eq 'scalar';
    if(@list) {
        $result->{logic}  =  "(\$self->" . (join " && \$self->", @list) . ")";
        $result->{regexp} = " =~ m/(" . (join "|", @list) . ")\$/";
        if($result->{condition}  eq 'unless') {
            $result->{logic}  = "!".  $result->{logic};
    } elsif($result->{condition}  eq 'exclude') {
        $result->{regexp} =~ s/\=\~/\!\~/;
        }
    }
    return  $result;      
}
#
#   auxiliary private function 
#   analyze condition and return conditional string to be used in getDOM|fromDOM
#   accepted parameters: $key - [attribute | 'text'],  $value - condition to parse, $what -  ['get' | 'from']
#
#
sub _printConditional {
    my ($key, $value,$what) = @_;
    my $string = '';
  
    my $arrayref_signleft = ($key ne 'text')?"[":'';
    my $arrayref_signright = ($key ne 'text')?"]":''; 
   
    my $fromDomArg = ($key ne 'text')?"\$dom->getAttribute('$key')":"\$dom->textContent";
   
    my  $condition  = conditionParser($value);
    $logger->debug("$value Enum List:: " . ( join ":", map { " $_= " . $condition->{$_}} keys  %{$condition})) unless $condition->{condition}  eq 'scalar';
    
    if($condition->{condition}   eq 'scalar') { 
        $string =   $what eq 'get'?"                                               $arrayref_signleft'$key' =>  \$self->$key$arrayref_signright,\n":
                                 "    \$self->$key($fromDomArg) if($fromDomArg);\n";
    } elsif($condition->{condition}  =~ /^if|unless$/ &&  $condition->{logic}) {
        $string =  $what eq 'get'?"                                     $arrayref_signleft '$key' => (".$condition->{logic}."?\$self->$key:undef)$arrayref_signright,\n":
                                 "    \$self->$key($fromDomArg) if(" . $condition->{logic}. " && $fromDomArg);\n";   
    } elsif($condition->{condition} =~ /enum|set|exclude/ &&  $condition->{regexp}) {
          
        my $regexp  =  $what eq 'get'?"(\$self->$key   " . $condition->{regexp} . ")":"($fromDomArg  " . $condition->{regexp}  .")";
          
        $string     =   $what eq 'get'?"                                     $arrayref_signleft'$key' =>  ($regexp?\$self->$key:undef)$arrayref_signright,\n":
                                  "    \$self->$key($fromDomArg) if($fromDomArg && $regexp);\n";   
  
    } else {
        $logger->fatal("Malfromed , uknown condition=" . $condition->{condition} );
    }
    
    return $string;
}
  
 
1;
 
  
