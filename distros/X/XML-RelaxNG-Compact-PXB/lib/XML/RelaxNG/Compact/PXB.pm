package  XML::RelaxNG::Compact::PXB;

use strict;
use warnings;
use English qw( -no_match_vars);
use version; our $VERSION = '0.15';


=head1 NAME

XML::RelaxNG::Compact::PXB  -   create perl XML (RelaxNG Compact) data binding API

=head1 VERSION

Version 0.15

=head1 DESCRIPTION


The instance of this class is capable of generating the API tree of the perl objects
based on  XML (RelaxNG compact) schema described  as perl data structures. If you have bunch
of XML schemes ( and able to convert them into RelaxNG Compact ) and hate to waste your time
by writing DOM tree walking code then this module may help you. Of course POD will be created automatically as well.
Also, it will build the tests suit automatically as well and provide perltidy and perlcritic 
config files for you to assure the absence of problems in your API. The L<Perl::Critic> test will
be performed as part of the tests suit.

See L<XML::RelaxNG::Compact::DataModel> for more details and examples.

=head1 SYNOPSIS

 
      ###
      use    XML::RelaxNG::Compact::PXB;
     
      # express your schema 
     
      my $subelement =  {  'attrs'  => {value => 'scalar', type => 'scalar', port => 'scalar',  xmlns => 'nsid2'},
                                                   elements => [],
                                                   text => 'unless:value',
                    };
      my $model = = {  'attrs'  => {id => 'scalar', type => 'scalar', xmlns => 'nsid'},
                  elements => [
                                [subelement => $subelement ]
                              ],
                 };
      # define Namespace registry for your schemes
      
      my $nsreg = { 'nsid' => 'http://nsid/URI',  'nsid2' => 'http://nsid2/URI'};
      
      # create API builder with your desired parameters 
      #
      my $api_builder =   XML::RelaxNG::Compact::PXB->new({ 
                                            top_dir         =>   "/topdir/",
                                            nsregistry      => $nsreg,
                                            datatypes_root  =>   "Datatypes,
					    project_root    => 'API,
                                            schema_version  =>   "1.0",
                                            test_dir        =>   "t",
					    footer => POD::Credentials->new({author=> 'Author Name', 
				     						license=> ' This stuff is for free !',
									        copyright => 'Copyright (c) 2011, by me'});

      #### this call will build everything - API,tests, helper modules
      #### where  name parameter is the name of your root element  - "nsid:mymodel"
      #
      #   it will create versioned API under /topdir/API/Datatypes/v1_0/nsid/ for nsid namespace prefix
      #  and /topdir/API/Datatypes/v1_0/nsid2/ for nsid2 namespace prefix
      #
      
      $api_builder->buildAPI({name => 'mymodel', element => $model});
      
     
      #### this call will build only test suit
      ####
      $api_builder->buildTests({name => 'mymodel', element => $model});

      ####

      #### this call will build only Helper modules under /topdir/API/Datatypes/v1_0/ -  
      #### namespace prefix mapping, basic element operations
      ####
      
      $api_builder->buildHelpers();

      ####

=head1 METHODS

=cut

use IO::File;
use File::Path;
use Data::Dumper;
use FindBin;
use Carp;
use POD::Credentials;
use Class::Accessor::Fast;
use Class::Fields;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(debug top_dir datatypes_root project_root schema_version test_dir footer nsregistry 
              _schema_version_dir  _TESTS  _fh _fhtest  _path  _root _known_class _existed DEBUG);
XML::RelaxNG::Compact::PXB->mk_accessors(XML::RelaxNG::Compact::PXB->show_fields('Public'),'_fh', '_fhtest', '_TESTS');

=head2 new({})

creates new object, accepts reference to hash as parameters container  
where keys are:

=over

=item

B<DEBUG> - set it to something defined to provide extra logging

=item

B<top_dir> - full pathname to the api root dir, for example test files will be placed as top_dir/test_dir
B<Default:> C<current directory>

=item 

B<nsregistry> - reference to the hash with {ns_prefix => ns_URI} pairs, it will be built into the Element class
B<Default:> just XSD and XSI namespaces

=item

B<datatypes_root> - name of the generated datatypes directory
B<Default:> I<XMLTypes>

=item

B<project_root> - name of the API project directory, all packages will have naming beginning with this one
B<Default:> I<API>, with B<datatypes_root> default value every package will have API::XMLTYpes:: pre-fix


=item

B<schema_version> - version identifier for your XML schema
B<Default:> I<1.0>

=item

B<test_dir> - name for the test suit files ( relative to the <top_dir>)
B<Default:>  I<t>

=item

B<footer> - container of  the object - L<POD::Credentials>, used for printing POD footer with  SEE ALSO, AUTHOR, COPYRIGHT, LICENSE 


=back


Possible ways to call B<new()>:

  ### with defaults
  $api_builder =   XML::RelaxNG::Compact::PXB->new();

  ## passes hashref with explicit   parameters, for the next example:
  ## api will be created at /root/XMLTypes/v1_0/
  ## and tests files under - /root/t
  
  $api_builder =   XML::RelaxNG::Compact::PXB->new({
                                            top_dir =>   "/root/",
                                            datatypes_root =>   "XMLTypes",
                                            nsregistry => { 'nsid' => 'nsURI'},
					    project_root => 'API,
                                            schema_version =>   "1.0",
                                            test_dir =>   "t",
                                            footer => POD::Credentials->new({author=> 'Joe Doe'}),
                                            });


=cut

#  XSD/XSI namespaces

our $XSD_NS = {'xsd'=>"http://www.w3.org/2001/XMLSchema",
               'xsi' => "http://www.w3.org/2001/XMLSchema-instance",
              };

sub new {
    my ( $that, $param ) = @_;
    my $class = ref($that) || $that;
    my $self = fields::new($class);
    # setting defaults
    
    $self->top_dir("$FindBin::Bin");
    $self->datatypes_root("XMLTypes");
    $self->project_root("API");
    $self->schema_version("1.0");
    $self->footer(POD::Credentials->new());
    $self->DEBUG(-1);
    $self->test_dir("/t");
    ### private fields initialization
    $self->{_known_class} ={}; ## namespace/element specific lookup table for already created classes
    $self->{_existed}={};   ## general lookup table for already created classes
    $self->{_path} = []; ## container for current directory path
    if ($param  && ref($param) ne 'HASH') {
        croak("ONLY hash ref accepted as param and not: " . Dumper $param );
    }
    map {$self->{$_} = $param->{$_} if $self->can($_) && $param->{$_} } keys %{$param};   ###
    (my $version = $self->schema_version) =~ s/v//i;
    $self->schema_version(qv("$version"));
    $version =~ s/\./_/g;
    $self->{_schema_version_dir} = "v$version"; 
    ##$self->test_dir($self->top_dir . "/" . $self->test_dir);
    if($self->nsregistry && ref($self->nsregistry) eq 'HASH') {
        $self->nsregistry({%{$self->nsregistry}, %{$XSD_NS}});
    } else {
        $self->nsregistry($XSD_NS);
    }
    $self->footer->end_module(1);
    $self->footer->see_also(' Automatically generated by L<XML::RelaxNG::Compact::PXB> ') unless $self->footer->see_also;
    return $self;
}


#                       private function
#
#  for new classname, path, root and ns will check if this package already exists and
#  then update path and root with appended classname a
#  where root is the API modules tree path and path is the directory pathname
#  without top dir name
#

sub  _makeAPIPath {
    my ($self, $classname,  $ns) = @_;
    my $classnameUP = ucfirst($classname);
    print "MakePath:  ::$ns  packagepath=" . $self->_packagePath .
          "  classnameUP=$classnameUP\n" if $self->DEBUG > 1;
    push @{$self->{_path}}, $classnameUP;
    my $classname_tmp = $self->project_root . "::" . 
                        $self->datatypes_root . "::" .  
		        $self->{_schema_version_dir} . "::$ns" . 
		        $self->_packagePath;
    unless ( $self->{_existed}->{$classname_tmp} ) {
        $self->{_existed}->{$classname_tmp} =  $classname;
        $self->{_known_class}->{$classname}{$ns} = $classname_tmp;       
    }
    return $self;
}


#
#     private function
#
#  return package path for the current _path array

sub  _packagePath {
    my ($self) = @_;
    my $path = '::';
    if(@{$self->{_path}}) {
        $path .= join '::', @{$self->{_path}};
    } else {
        $path = '';
    }
    return $path; 
}

#
#     private function
#
#  return dirnames path for the current _path array

sub  _dirPath {
    my ($self) = @_;
    my $path = '/';
    if(@{$self->{_path}}) {
        $path .= join '/', @{$self->{_path}};
    } else {
        $path = '';
    }
    return $path;
}

=head2 buildAPI()

builds XML binding API recursively
accepts hashref with keys:

=over

=item

 name - scalar, name of the root element - undef by default

=item

 element - reference to the hash representing the RelaxNG Compact schema, empty hash ref by default

=item

 parent - optional scalar parameter, reference to the hash with definition of the parent element, its C<undef> for the root element

=back

returns $self

=cut

sub buildAPI {
    my ($self, $param) = @_;
    my $name = $param->{name};
    my $element =  $param->{element};
    my $parent  =  $param->{parent};
    $self->_printHelpers unless $parent;
    
    my  $ns = $element->{attrs}->{xmlns};
    croak(" Malformed definition: something is  missing name=$name  ns=$ns  element=" .  Dumper $element) 
        unless $name && $ns && $element;  
    $self->_makeAPIPath($name,  $ns);
    if($element && ref($element) eq 'HASH' &&  $element->{attrs})  {
        if(ref($element->{elements}) eq 'ARRAY' && !$self->_TESTS) {
            mkpath([$self->top_dir . "/" . $self->project_root . "/". $self->datatypes_root .  "/"  . 
	            $self->{_schema_version_dir} . "/$ns". $self->_dirPath], 1, 0755);
        }
        ###  
        foreach my $el (@{$element->{elements}}) {
            if(ref($el) eq 'ARRAY') {
                if(ref($el->[1]) eq 'HASH' && $el->[1]->{attrs}) {
                    $self->buildAPI({name => $el->[0], element => $el->[1], parent => $element}); 
                } elsif(ref($el->[1]) eq 'ARRAY') {
                    foreach my $sub_el (@{$el->[1]}) { ### if right part is arrayref - means choice between elements
                        next unless $sub_el;
			if(ref($sub_el) eq 'HASH' && $sub_el->{attrs}) { # choice between single elements
                            $self->buildAPI({name => $el->[0],  element => $sub_el, parent => $element});
                        } elsif(ref($sub_el) eq 'ARRAY' && scalar @{$sub_el} == 1) {  # choice between multiple
                            $self->buildAPI({name => $el->[0],  element => $sub_el->[0], parent => $element});
                        } else {
                            croak(" Malformed definition: name=" . $el->[0] .
			          " sub_el Dump=" . Dumper($sub_el) . " el Dump=" . Dumper  $el);
                        }
                    }
                }
            }
        } 
        $self->buildClass($name, $element, $parent) if defined $self->_dirPath && defined $self->_packagePath;
        # if empty directory was created, then remove it
        my $child_dir =  $self->top_dir ."/". $self->project_root . "/". $self->datatypes_root . "/" . 
                        $self->{_schema_version_dir} . "/$ns". $self->_dirPath;
        rmdir $child_dir  if( -d   $child_dir); 
        pop @{$self->{_path}} if  defined $self->_dirPath && defined $self->_packagePath;   
    } else {
        croak("Malformed definition: ended up in non element");
    }  
    return $self;
}

=head2 buildHelpers

  shortcut to build Helper classes only, no arguments
  returns $self

=cut

sub buildHelpers {
     my ($self) = @_;
     $self->_printHelpers();
     return $self;
}

=head2 buildAM

 prints accessors and mutators for the passed reference to array of names
 returns $self

=cut

sub buildAM {
    my ($self, $arr_names) = @_;
    croak(" Only array ref parameter accepted" . Dumper $arr_names)  
        unless ref($arr_names) eq 'ARRAY';
    foreach my $name (@{$arr_names}) {
        $self->sayIt(qq"

\=head2 get_$name

 accessor  for $name, assumes hash based class

\=cut

sub get_$name {
    my(\$self) = \@_;
    return \$self->{$name};
}

\=head2 set_$name

mutator for $name, assumes hash based class

\=cut

sub set_$name {
    my(\$self,\$value) = \@_;
    if(\$value) {
        \$self->{$name} = \$value;
    }
    return   \$self->{$name};
}
");
    }
    return $self;
}

=head2 buildTests

 shortcut to build test files  only, no arguments
 returns $self


=cut

sub buildTests {
     my  $self  = shift;
     $self->_TESTS(1);
     $self->buildAPI(@_);
     return $self;
}

=head2 buildClass

builds  single class on the filesystem and corresponded test file
accepts position bounded parameters:

=over

=item

name of the   element

=item

hashref with the element definition

=item

hashref with parent definition if its not the root element

=back

returns $self

=cut

 sub  buildClass {
    my ($self, $name, $element, $parent) = @_;
    # current path
    my $ns = $element->{attrs}->{xmlns};
    my $path = $self->top_dir ."/".  $self->project_root . "/". $self->datatypes_root . "/" . 
               $self->{_schema_version_dir} . "/$ns" .  $self->_dirPath;
    # current classname
    my $root =  $self->project_root . "::". $self->datatypes_root . "::" . 
                $self->{_schema_version_dir}  . "::$ns".  $self->_packagePath;
    my $className =   $root;

#--------------------------- some preparatory work here, lists of element names, attributes, text elements -----------
    my @elements =     grep(ref($_) eq 'ARRAY' && $_->[0] && $_->[1], @{$element->{elements}});
    my @elementnodes = grep(ref($_->[1]), @elements);
    my @textnodes =    grep($_->[1] eq 'text'  && !ref($_->[1]), @elements);
    my $elements_names = @elementnodes?join (" " ,  map { $_->[0] } @elementnodes):'';
    my $texts_names =  @textnodes?join (" " , map { $_->[0] } @textnodes):'';
    my @attributes =  grep(!/xmlns/, keys %{$element->{attrs}});
    my $attributes_names = @attributes?join " " , @attributes:'';
#--------------------------------------------------------------------------------
    my %parent_sql = ();
    # parsing SQL mapping config for parent  element if it exists to allow propagation of the conditions from the previous layer
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
    my %sql_pass =(); ### hash with pass through, means this is not  the last element in the tree
    my %sql_here =(); ### hash with sql to map here - tree leaf
    # preprocessing sql config if   it exists for this element
    if($element->{sql}) {
        foreach my $table (keys %{$element->{sql}}) {
            foreach my $field (keys %{$element->{sql}->{$table}}) {
                my $value =  $element->{sql}->{$table}->{$field}->{value};
                unless($value) {
                    croak(" SQL config malformed for element=$name table=$table field=$field, but value is missied");
                }
                my $condition = $element->{sql}->{$table}->{$field}->{if};
		my ($attr_name, $set, $cond_string) = ('','','');
		if($condition) {
		    my @conditions_arr = ();
		    my @conditions = (ref $condition eq ref [])?@{$condition}:($condition);
		    foreach my $cond (@conditions) {
                        ($attr_name, $set) =  split(':', $cond);
                        push  @conditions_arr, ($set?" (\$self->get_$attr_name eq '$set') ":" (\$self->get_$attr_name) ");
                    }
		    $cond_string = '(' . join(' || ', @conditions_arr) . ')' if(@conditions_arr);
		}  
                $value = [$value]  if ref($value) ne 'ARRAY';

                foreach my   $possible (@{$value}) {
                    next if %parent_sql && $parent_sql{$table}{$field} && !$parent_sql{$table}{$field}{$name};
                    if($elements_names =~ /\b$possible\b/) {  #### if name of the $possible element is among the members of this object then pass  it there
                        $sql_pass{$possible}{$table}{$field} = $cond_string;
                    } else {                                     ######  otherwise set it with some value here ( text or attribute )
                        $sql_here{$possible}{$table}{$field} = $cond_string;
                    }
                }
            }
        }
    }
    #-------------------------------------------- build tests
    $self->buildTest(\@elementnodes,  \@attributes, $className, $name, $element);
    # return if TESTS is set - only test files should be built
    return if($self->_TESTS);

    $self->_fh(IO::File->new($path . ".pm","w+"));
    croak(" Failed to open file :" . $path . ".pm")  unless $self->_fh;

    print("\n Classname: $path ...  Attributes: $attributes_names \n Elements: $elements_names\n") if $self->DEBUG > 0;
    print(" Config:" . Dumper $element) if $self->DEBUG>2;
#----------------------------------------------
    my $version = $self->schema_version;
#--------------------------------------------
#
#    the actual package generator starts here
#
    $self->sayIt(qq/package  $className;

use strict;
use warnings;
use utf8;
use English qw(-no_match_vars);
use version; our \$VERSION = '$version';

\=head1 NAME

$className  -  this is data binding class for  '$name'  element from the XML schema namespace $ns

\=head1 DESCRIPTION

Object representation of the $name element of the $ns XML namespace.
Object fields are:

/);

#------------------------------------------------------------------------------
#  printing attributes
    map { $self->sayIt("    Scalar:     $_,")  }   @attributes ;
#
#   printing elements
#
    map { $self->sayIt("    Object reference:   " . $_->[0]  . " => type " . ref($_->[1]) . ",") }  @elements ;


    $self->sayIt(qq/

The constructor accepts only single parameter, it could be a hashref with keyd  parameters hash  or DOM of the  '$name' element
Alternative way to create this object is to pass hashref to this hash: { xml => <xml string> }
Please remember that namespace prefix is used as namespace id for mapping which not how it was intended by XML standard. The consequence of that
is if you serve some XML on one end of the webservices pipeline then the same namespace prefixes MUST be used on the one for the same namespace URNs.
This constraint can be fixed in the future releases.

Note: this class utilizes L<Log::Log4perl> module, see corresponded docs on CPAN.

\=head1 SYNOPSIS

          use $className;
          use Log::Log4perl qw(:easy);

          Log::Log4perl->easy_init();

          my \$el =  $className->new(\$DOM_Obj);

          my \$xml_string = \$el->asString();

          my \$el2 = $className->new({xml => \$xml_string});


          see more available methods below


\=head1   METHODS

\=cut


use XML::LibXML;
use Scalar::Util qw(blessed);
use Log::Log4perl qw(get_logger);
use Readonly;
    /);

####printing  namespace specific helper classes
    my $localized_path =  $self->project_root . "::" . $self->datatypes_root . "::" . $self->{_schema_version_dir};
    $self->sayIt("use $localized_path\::Element qw(getElement);");
    $self->sayIt("use $localized_path\::NSMap;");

    foreach my $el (@elementnodes) {
        foreach my $ns (keys %{$self->{_known_class}->{$el->[0]}}) {
            $self->sayIt("use " . $self->{_known_class}->{$el->[0]}{$ns} . ";")  
	        if $self->{_known_class}->{$el->[0]}{$ns};
        }
    }

    $self->saying("use fields qw(nsmap idmap LOGGER $attributes_names $elements_names $texts_names");
    $self->saying(" text ") if $element->{text};
    $self->sayIt(");");
    $self->sayIt(qq/

\=head2 new({})

 creates   object, accepts DOM with element's tree or hashref to the list of
 keyed parameters:
/);

    map {$self->sayIt("         $_   => undef,")}  @attributes ;
    map {$self->sayIt("         " . $_->[0]  . " => " . ref($_->[1]) . ",")}  @elementnodes;

    $self->sayIt(" text => 'text'") if $element->{text};

    $self->sayIt(qq/
returns: \$self

\=cut

Readonly::Scalar our \$COLUMN_SEPARATOR => ':';
Readonly::Scalar our \$CLASSPATH =>  '$className';
Readonly::Scalar our \$LOCALNAME => '$name';

sub new {
    my (\$that, \$param) = \@_;
    my \$class = ref(\$that) || \$that;
    my \$self =  fields::new(\$class );
    \$self->set_LOGGER(get_logger(\$CLASSPATH));
    \$self->set_nsmap($localized_path\::NSMap->new());
    \$self->get_nsmap->mapname(\$LOCALNAME, '$ns');
/);

#### printing the rest of constructor
    $self->sayIt(qq"
    if(\$param) {
        if(blessed \$param && \$param->can('getName')  && (\$param->getName =~ m/\$LOCALNAME\$/xm) ) {
            return  \$self->fromDOM(\$param);
        } elsif(ref(\$param) ne 'HASH')   {
            \$self->get_LOGGER->logdie(\"ONLY hash ref accepted as param \" . \$param );
            return;
        }
        if(\$param->{xml}) {
            my \$parser = XML::LibXML->new();
	    \$parser->expand_xinclude(1);
            my \$dom;
            eval {
                my \$doc = \$parser->parse_string(\$param->{xml});
                \$dom = \$doc->getDocumentElement;
            };
            if(\$EVAL_ERROR) {
                \$self->get_LOGGER->logdie(\" Failed to parse XML :\" . \$param->{xml} . \" \\n ERROR: \\n\" . \$EVAL_ERROR);
                return;
            }
            return  \$self->fromDOM(\$dom);
        }
        \$self->get_LOGGER->debug(\"Parsing parameters: \" . (join ' : ', keys \%{\$param}));

        foreach my \$param_key (keys \%{\$param}) {
            \$self->{\$param_key} = \$param->{\$param_key} if \$self->can(\"get_\$param_key\");
        }
        \$self->get_LOGGER->debug(\"Done\");
    }
    return \$self;
}

\=head2   getDOM (\$parent)

 accepts parent DOM  serializes current object into the DOM, attaches it to the parent DOM tree and
 returns $name object DOM

\=cut

sub getDOM {
    my (\$self, \$parent) = \@_;
    my \$$name;
    eval { 
        my \@nss;    
        unless(\$parent) {
            my \$nsses = \$self->registerNamespaces(); 
            \@nss = map {\$_  if(\$_ && \$_  ne  \$self->get_nsmap->mapname( \$LOCALNAME ))}  keys \%{\$nsses};
            push(\@nss,  \$self->get_nsmap->mapname( \$LOCALNAME ));
        } 
        push  \@nss, \$self->get_nsmap->mapname( \$LOCALNAME ) unless  \@nss;
        \$$name = getElement({name =>   \$LOCALNAME, 
	                      parent => \$parent,
			      ns  =>    \\\@nss,
                              attributes => [
");

#------------------------------- generate serialization for each attribute

    foreach my $attr (@attributes) {
        print("_printConditional:: $attr = " . $element->{attrs}->{$attr})  if $self->DEBUG> 2;
        $self->sayIt($self->_printConditional($attr, $element->{attrs}->{$attr}, 'get'));
    }
    $self->sayIt("                                               ],"); # end for attributes
    $self->sayIt($self->_printConditional('text', $element->{text} , 'get')) if ($element->{text});

    $self->sayIt("                               });");
    $self->sayIt("        };");
    $self->sayIt("    if(\$EVAL_ERROR) {");
    $self->sayIt("         \$self->get_LOGGER->logdie(\" Failed at creating DOM: \$EVAL_ERROR\");");
    $self->sayIt("    }");

### deal with subelements
###
###   each sub-element can be defined as some complex type where:
###                    [ name => obj ]           -   just object
###              or    [name => [obj]]           -   arrayref of objects
###              or    [name => [obj1,obj2]]     -   choice between two obj
###              or    [name => [[obj1],[obj2]]] -   choice between two obj arrayref
###
    foreach my $els (@elementnodes) {
        croak(" Malformed elements declaration: name=$name  and this thingy: els=$els must be an ARRAY ref ") 
	    unless ref($els) eq 'ARRAY';

        my  $condition =  _conditionParser($els->[2]);
        my $subname =  $els->[0];
        $condition->{logic} .= " && " if  $condition->{logic};
        if(ref($els->[1])  eq  'ARRAY') {
            if(scalar @{$els->[1]} >  1 ) {
                if(ref( $els->[1]->[0]) ne 'ARRAY') {
                    $self->_printGetDOM($subname, $name,  $condition->{logic});
                } else {
                    $self->_printGetArrayDom($subname, $name,  $condition->{logic});
                }
            } else {
                $self->_printGetArrayDom($subname, $name,  $condition->{logic});
            }
        } elsif(ref($els->[1]) eq  'HASH') {
            $self->_printGetDOM($subname, $name,  $condition->{logic});
        }
    }
    if($texts_names) {
        $self->sayIt(qq!

    foreach my \$textnode (qw/$texts_names/) {
        if(\$self->{\$textnode}) {
            my  \$domtext  =  getElement({name => \$textnode,
                                          parent => \$$name,
                                          ns => [\$self->get_nsmap->mapname(\$LOCALNAME)],
                                          text => \$self->{\$textnode},
                              });
           \$domtext?\$$name->appendChild(\$domtext):
	             \$self->get_LOGGER->logdie("Failed to append new text element \$textnode to $name");
        }
    }
        !);
    }
    $self->sayIt("      return \$$name;\n}");

### print accessors/mutators for all element nodes and attributes ( careless about the type of the element )
    $self->buildAM(['LOGGER', 'nsmap', 'idmap', 'text',   @attributes, 
                       map { $_->[0] } @elementnodes, @textnodes]);

###  next building various element related methods
    foreach my  $el (@elementnodes) {
        my $subname = $el->[0];
        if(ref($el->[1]) eq 'ARRAY') {
            $self->sayIt(qq/

\=head2  add\u${subname}()

 if any of subelements can be an array then this method will provide
 facility to add another element to the  array and will return ref to such array
 or just set the element to a new one, if element has and 'id' attribute then it will
 create idmap  
 
 Accepts:  obj
 Returns: arrayref of objects

\=cut

sub add\u${subname} {
    my (\$self,\$new) = \@_;

    \$self->get_$subname && ref(\$self->get_$subname) eq 'ARRAY'?push \@{\$self->get_$subname}, \$new:
                                                                 \$self->set_$subname([\$new]);
    \$self->get_LOGGER->debug("Added new to $subname");
    \$self->buildIdMap; ## rebuild index map
    return \$self->get_$subname;
}

\=head2  remove\u${subname}ById()

 removes specific element from the array of ${subname} elements by id ( if id is supported by this element )
 Accepts:  single param - id - which is id attribute of the element
 
 if there is no array then it will return undef and warning
 if it removed some id then \$id will be returned

\=cut

sub remove\u${subname}ById {
    my (\$self, \$id) = \@_;
    if(ref(\$self->get_$subname) eq 'ARRAY' && \$self->get_idmap->{$subname} &&  
       exists \$self->get_idmap->{$subname}{\$id}) {
        undef \$self->get_$subname->\[\$self->get_idmap->{$subname}{\$id}\];
        my \@tmp =  grep { defined \$_ } \@{\$self->get_$subname};
        \$self->set_$subname([\@tmp]);
        \$self->buildIdMap; ## rebuild index map
        return \$id;
    } elsif(!ref(\$self->get_$subname)  || ref(\$self->get_$subname) ne 'ARRAY')  {
        \$self->get_LOGGER->warn("Failed to remove  element because ${subname} not an array for non-existent id:\$id");
    } else {
        \$self->get_LOGGER->warn("Failed to remove element for non-existent id:\$id");
    }
    return;
}

\=head2  get\u${subname}ById()

 get specific element from the array of ${subname} elements by id ( if id is supported by this element )
 Accepts single param - id
 
 if there is no array then it will return just an object

\=cut

sub get\u${subname}ById {
    my (\$self, \$id) = \@_;

    if(ref(\$self->get_$subname) eq 'ARRAY' && \$self->get_idmap->{$subname} && 
       exists \$self->get_idmap->{$subname}{\$id} ) {
        return \$self->get_$subname->\[\$self->get_idmap->{$subname}{\$id}\];
    } elsif(!ref(\$self->get_$subname) || ref(\$self->get_$subname) ne 'ARRAY')  {
        return \$self->get_$subname;
    }
    \$self->get_LOGGER->warn("Requested element for non-existent id:\$id");
    return;
}
            /);
        }
    }
    $self->sayIt(qq/

\=head2  querySQL ()

 depending on SQL mapping declaration it will return some hash ref  to the  declared fields
 for example querySQL ()
 
 Accepts one optional parameter - query hashref, it will fill this hashref
 
 will return:    
    { <table_name1> =>  {<field name1> => <value>, ...},...}

\=cut

sub  querySQL {
    my (\$self, \$query) = \@_;
/);
#   print hash with mapped fields for this class
#
    if($element->{sql}) {
        $self->saying("     my \%defined_table = (");
        foreach my $table (keys %{$element->{sql}}) {
            $self->saying(" '$table' => [");
            foreach my $field (keys %{$element->{sql}->{$table}}) {
                $self->saying("   '$field', ");
            }
            $self->saying(" ], ");
        }
        $self->sayIt(" );");
    }
#  add current class into the declarative path of the sql field mapped down the tree
    foreach my  $subname (keys %sql_pass) {
        foreach my $table (keys %{$sql_pass{$subname}}) {
            foreach my $entry (keys %{$sql_pass{$subname}{$table}}) {
                $self->saying("     \$query->{$table}{$entry}= [");
                foreach my $nss (keys %{ $self->{_known_class}->{$subname}}) {
                    $self->saying("     '". $self->{_known_class}->{$subname}{$nss} . "',");
               }
               $self->sayIt("     ];");
            }
        }
    }
  #  set sql for fields  which mapped here
    foreach my  $subname (keys %sql_here) {
        foreach my $table (keys %{$sql_here{$subname}}) {
            foreach my $entry (keys %{$sql_here{$subname}{$table}}) {
                $self->sayIt("     \$query->{$table}{$entry}= [ '$className' ] if!(defined \$query->{$table}{$entry}) || ref(\$query->{$table}{$entry});");
            }
        }
    }
    if($elements_names)  {
         $self->sayIt(qq!
    foreach my \$subname (qw/$elements_names/) {
        if(\$self->{\$subname} && (ref(\$self->{\$subname}) eq 'ARRAY' ||  blessed \$self->{\$subname})) {
            my \@array = ref(\$self->{\$subname}) eq 'ARRAY'?\@{\$self->{\$subname}}:(\$self->{\$subname});
            foreach my \$el (\@array) {
                if(blessed \$el && \$el->can('querySQL'))  {
                    \$el->querySQL(\$query);
                    \$self->get_LOGGER->debug("Querying $name  for subclass \$subname");
                } else {
                    \$self->get_LOGGER->logdie("Failed for $name Unblessed member or querySQL is not implemented by subclass \$subname");
                }
           }
        }
    }
         !);
    }
    if(%sql_here)  {
        $self->sayIt(qq/
    eval {
        foreach my \$table  ( keys \%defined_table) {
            foreach my \$entry (\@{\$defined_table{\$table}}) {
                if(ref(\$query->{\$table}{\$entry}) eq 'ARRAY') {
                    foreach my \$classes (\@{\$query->{\$table}{\$entry}}) {
                         if(\$classes && \$classes eq '$className') {
        /);

        my $if_sub_cond = ' if    ';
        foreach my  $subname  (@attributes, 'text') {
            if($sql_here{$subname})  {
                $self->sayIt(_getSQLSub($sql_here{$subname}, $subname, $if_sub_cond));
                $if_sub_cond =  ' elsif ';
            }
        }
        $self->sayIt(qq/
                         }
                     }
                 }
             }
        }
    };
    if(\$EVAL_ERROR) {
            \$self->get_LOGGER->logdie("SQL query building is failed  here " . \$EVAL_ERROR);
    }

        /);
    }
    $self->sayIt("    return \$query;");
    $self->sayIt("}");
    $self->sayIt(qq/

\=head2  buildIdMap()

 if any of subelements has id then get a map of it in form of
 hashref to { element}{id} = index in array and store in the idmap field

\=cut

sub  buildIdMap {
    my \$self = shift;
    my \%map = ();
    /);
    if( @elementnodes ) {
        $self->sayIt(qq"
    foreach my \$field (qw/$elements_names/) {
        my \@array = ref(\$self->{\$field}) eq 'ARRAY'?\@{\$self->{\$field}}:(\$self->{\$field});
        my \$i = 0;
        foreach my \$el (\@array)  {
            if(\$el && blessed \$el && \$el->can('get_id') &&  \$el->get_id)  {
                \$map{\$field}{\$el->get_id} = \$i;
            }
            \$i++;
        }
    }
    return \$self->set_idmap(\\\%map);
        ");

     } else {
        $self->sayIt("    return;");
    }
    $self->sayIt("}");  
    $self->sayIt(qq/
\=head2  asString()

 shortcut to get DOM and convert into the XML string
 returns nicely formatted XML string  representation of the  $name object

\=cut

sub asString {
    my \$self = shift;
    my \$dom = \$self->getDOM();
    return \$dom->toString('1');
}

\=head2 registerNamespaces ()

 will parse all subelements
 returns reference to hash with namespace prefixes
 
 most parsers are expecting to see namespace registration info in the document root element declaration

\=cut

sub registerNamespaces {
    my (\$self, \$nsids) = \@_;
    my \$local_nss = {reverse \%{\$self->get_nsmap->mapname}};
    unless(\$nsids) {
        \$nsids = \$local_nss;
    }  else {
        \%{\$nsids} = (\%{\$local_nss}, \%{\$nsids});
    }
/);

    if( @elementnodes ) {
        $self->sayIt(qq"
    foreach my \$field (qw/$elements_names/) {
        my \@array = ref(\$self->{\$field}) eq 'ARRAY'?\@{\$self->{\$field}}:(\$self->{\$field});
        foreach my \$el (\@array) {
            if(blessed \$el &&  \$el->can('registerNamespaces') ) {
                my \$fromNSmap = \$el->registerNamespaces(\$nsids);
                my \%ns_idmap = \%{\$fromNSmap};
                foreach my \$ns (keys \%ns_idmap)  {
                    \$nsids->{\$ns}++;
                }
            }
        }
    }
");
    }
    $self->sayIt("    return \$nsids;");
    $self->sayIt("}");
    $self->sayIt(qq/

\=head2  fromDOM (\$)

 accepts parent XML DOM  element  tree as parameter
 returns $name  object

\=cut

sub fromDOM {
    my (\$self, \$dom) = \@_;
/);
    print("  fromDOM for: name=$name ") if $self->DEBUG>2;
    foreach my $attr (@attributes) {
        print("  fromDOM for:  "  . Dumper $element->{attrs}) if $self->DEBUG>2;
        $self->sayIt($self->_printConditional($attr, $element->{attrs}->{$attr}, 'set'));
        $self->sayIt("    \$self->get_LOGGER->debug(\"Attribute $attr= \". \$self->get_$attr) if \$self->get_$attr;");
    }
    $self->sayIt($self->_printConditional('text', $element->{text}, 'set')) 
        if ($element->{text});
    if(@elements) {
        $self->sayIt(qq/    foreach my \$childnode (\$dom->childNodes) {
        my  \$getname  = \$childnode->getName;
        my (\$nsid, \$tagname) = split \$COLUMN_SEPARATOR, \$getname;
        next unless(\$nsid && \$tagname);
	my \$element;
	/);
        my $conditon_head =  '     if';
        foreach my $els (@elementnodes) {
            croak("Element must be an array ref here: name=$name els=$els") 
	        unless ref($els) eq 'ARRAY';
	    print "fromDOM subelement: " . Dumper $els if $self->DEBUG > 3;
            my $subname =  $els->[0];
            my  $condition  =  _conditionParser($els->[2]);
            $condition->{logic} .= " && " if  $condition->{logic};
	    print " fromDOM choice sub_subelement: " . Dumper  $els->[1]  if $self->DEBUG > 3;
            if(ref($els->[1]) eq  'ARRAY') {
                if(scalar @{$els->[1]} >  1)  {
                    foreach my $choice (@{$els->[1]}) {
		   
                        if(ref($choice) ne  'ARRAY') {
                            $self->_printFromDOM($subname, $choice, 'CHOICE', $conditon_head, $condition->{logic});
                            $conditon_head = '     elsif';
                        } elsif(scalar @{$choice} ==  1 ) {
                            $self->_printFromDOM($subname, $choice->[0], 'ARRAY', $conditon_head, $condition->{logic});
                            $conditon_head = '     elsif';
                        } else {
                            croak(" Malformed element definition: name=$name subelement=$subname");
                        }
                    }
                } else {
		    my $sub_el =  ref $els->[1]->[0] eq 'ARRAY'?$els->[1]->[0]->[0]:$els->[1]->[0];		    
		    print " fromDOM 0 from sub_subelement: " . Dumper  $els->[1]->[0]  if $self->DEBUG > 3;
                    $self->_printFromDOM($subname,  $sub_el, 'ARRAY',$conditon_head, $condition->{logic});
                }
            } elsif (ref($els->[1])  eq  'HASH') {
                $self->_printFromDOM($subname,$els->[1], 'HASH',$conditon_head, $condition->{logic});
            }
            $conditon_head = '     elsif';
        }
        if(@textnodes) {
            $self->sayIt(" $conditon_head (\$childnode->textContent && \$self->can(\"get_\$tagname\")) {");
            $self->sayIt("            \$self->{\$tagname} =  \$childnode->textContent; ## text node");
            $self->sayIt("        }");
        }
#        if(@elementnodes || @textnodes) {
#            $self->sayIt("       \$dom->removeChild(\$childnode); 
##               remove processed element from the current DOM so subclass can deal with remaining elements\n";
#        }
        $self->sayIt("    }");
        $self->sayIt("    \$self->buildIdMap;\n    \$self->registerNamespaces;");
    }
    $self->sayIt("    return \$self;\n}");
    $self->sayIt($self->footer->asString());
    $self->_fh->close;
    return;
}
#
#   internal call to create perlcritic and perltidy configs
#
sub _placeCritidy {
    my ($self) = @_;
    my $basename =  $self->top_dir . '/' . $self->test_dir . '/conf';
    unless( -e  "$basename/perltidyrc") {
        $self->_fh(IO::File->new( "$basename/perltidyrc",'w+'));
        $self->sayIt(qq{# PBP .perltidyrc file

-i=4	# Indent level is 4 cols
-ci=4	# Continuation indent is 4 cols
-st	# Output to STDOUT
-b	# backup original to .bak and modify file in-place
-se	# Errors to STDERR
-vt=0	# Maximal vertical tightness
-cti=0  # No extra indentation for closing brackets
-pt=1	# Medium parenthesis tightness
-lp	# line up parentheses, brackets, and non-BLOCK braces
-bt=1	# Medium brace tightness
-ce	# cuddled else; use this style: '\} else \{'
-bar	# opening brace always on right, even for long clauses
-sbt=1  # Medium square bracket tightness
-bbt=1  # Medium block brace tightness  
-nolq	# dont outdent long quoted strings (default) 
-nsfs	# No space before semicolons
-nolq	# Don't outdent long quoted strings
-wbb="% + - * / x != == >= <= =~ !~ < > | & >= < = **= += *= &= <<= && += -= /= |= >>= ||= .= %= ^= x="
            # Break before all operators
        });
    }
    unless( -e  "$basename/perlcritic") {
        $self->_fh(IO::File->new("$basename/perlcritic",'w+'));
        $self->sayIt(qq{
    severity = 2
    only = 1
    theme = (pbp + core + bugs + readability)
    ## layout according to the supplied perltidy
    [CodeLayout::RequireTidyCode]
    perltidyrc =  $basename/perltidyrc
    #--------------------------------------------------------------
    # I think these are really important, so always load them

    [TestingAndDebugging::RequireUseStrict]
    severity = 5

    [TestingAndDebugging::RequireUseWarnings]
    severity = 5
    
    [Variables::ProhibitLocalVars]
    severity = 5
    #--------------------------------------------------------------
    # I think these are less important, so only load when asked

    [Variables::ProhibitPackageVars]
    severity = 1

    [ControlStructures::ProhibitPostfixControls]
    allow = if unless
    severity = 2

    
    #--------------------------------------------------------------
    # I do not agree with these at all or their 
    # presence may create more worse than good
    # or they depend on the personal taste and not reason

    [-NamingConventions::ProhibitMixedCaseVars]
    [-NamingConventions::ProhibitMixedCaseSubs]
    [-ControlStructures::ProhibitUnlessBlocks]
    [-Documentation::RequirePodSections]
    [-Documentation::RequirePodAtEnd]
    [-TestingAndDebugging::ProhibitNoStrict]
    [-Subroutines::ProhibitExcessComplexity]
    [-Miscellanea::RequireRcsKeywords]
    [-ValuesAndExpressions::ProhibitNoisyQuotes]
    [-ValuesAndExpressions::ProhibitInterpolationOfLiterals]
    [-CodeLayout::ProhibitParensWithBuiltins]
    [-CodeLayout::ProhibitTrailingWhitespace] 
    #--------------------------------------------------------------
       });
    }
    return;
}

=head2  buildTest

 auxiliary method
 it builds test file for current class
 accepts:

       reference to array with elements,
       reference to array with attributes,
       class name
       name of the package
       element name
 returns: nothing

=cut

sub buildTest {
    my ($self, $elementnodes, $attributes, $className, $name, $element) = @_;
    
    my $relative_path = $self->top_dir . '/'.  $self->test_dir;
    mkpath ([  $relative_path  ], 1, 0755);
    mkpath ([  "$relative_path/conf"], 1, 0755);
    print "Creating perlcritic and perltidyrc config files ... " if $self->DEBUG > 0;
    $self->_placeCritidy();
    print " Creating simple test.pl file " if $self->DEBUG > 0;
    unless(-e  $self->top_dir . "/test.pl") {
        $self->_fh(IO::File->new( $self->top_dir . "/test.pl" ,"w+"));
        $self->sayIt(qq{use strict;
use warnings;

use Test::Harness;
 
use FindBin qw(\$Bin);   
BEGIN \{
   unshift \@INC, "\$Bin" ; 
   unshift \@INC, "\$Bin/../";  
\};

if (\$ARGV[0] && \$ARGV[0] eq '-v') \{
  \$Test::Harness::Verbose = 1;
  shift \@ARGV;
\}

Test::Harness::runtests(<\$Bin/t/*.t>);
}); 
    }
    print " Creating test suit... " if $self->DEBUG > 0;
    (my $test_filename = $className) =~ s/(\w)\:\:(\w)/$1\_\_$2/g;
    $self->_fh(IO::File->new("$relative_path/$test_filename.t" ,"w+"));
    croak(" Failed to open test suite file: $! $relative_path/$test_filename.t")  
        unless $self->_fh;
    my $test_number = 2;  
    my $ns = $element->{attrs}->{xmlns};
    $self->sayIt(qq/

use warnings;
use strict;
use Test::More;
use Data::Dumper;  
use FindBin qw(\$Bin); 
use Log::Log4perl qw(:easy :levels); 
use English qw( -no_match_vars);
/);
    $self->sayIt('use Test::Perl::Critic (-severity => 3, -verbose => 4,  -profile => "$Bin/conf/perlcritic");');
    $self->sayIt(qq/

## see BEGIN block at the bottom for the number of tests and use_ok package check
Log::Log4perl->easy_init(\$ERROR);   
/);
    my @element_names = map {$_->[0]}  @{$elementnodes};
    foreach my $el (@element_names) {
        foreach my $ns (keys %{$self->{_known_class}->{$el}}) {
	    if($self->{_known_class}->{$el}{$ns}) {
                $self->sayIt("use_ok '" . $self->{_known_class}->{$el}{$ns} . "';");
		$self->sayIt("#", $test_number++);
            }
        }
    }
    $self->sayIt("#", $test_number++);  
    $self->sayIt('critic_ok("$Bin/../' .  $self->project_root . "/" . $self->datatypes_root . "/" . 
                 $self->{_schema_version_dir} . "/$ns" .  
		 $self->_dirPath . '.pm", "perl critic have not found any problems") 
	         or diag(" perl critic found problems ");');
   
    my $accessors =   'get_nsmap get_idmap ' . join(' ',  map{"get_$_"}  @{$attributes}, @element_names);     
    $self->sayIt("#", $test_number++);
    $self->sayIt("can_ok($className->new(), qw/$accessors/);");     
    $self->sayIt(qq/

my \$obj1 = undef;

#$test_number
eval {
    \$obj1 = $className->new({
    /);

    map {$self->saying("  '$_' =>  'value_$_',")} @{$attributes};
    $self->sayIt("    })\n};\nok(\$obj1 && !\$EVAL_ERROR, \"Create object $className...\") or diag(\$EVAL_ERROR);\n undef \$EVAL_ERROR;");
    $self->sayIt('#', ++$test_number);
    $self->sayIt("my \$ns  =  \$obj1->get_nsmap->mapname('$name');");
    $self->sayIt("ok(\$ns eq '". $element->{attrs}->{xmlns} . "', \"  mapname('$name')...  \");");

    foreach my $att (@{$attributes}) {
        $self->sayIt('#', ++$test_number);
        $self->sayIt("my \$$att  =  \$obj1->get_$att;");
        $self->sayIt("ok(\$$att eq 'value_$att', \"Checking accessor  obj1->get_$att ...  \") or diag(' Accessor test failed ');");
    }
    foreach my $subel (@{$elementnodes}) {
        my $subel1 = (ref($subel->[1]) eq 'ARRAY')?
                      ((ref($subel->[1]->[0]) eq 'ARRAY')?$subel->[1]->[0]->[0]:$subel->[1]->[0]):
                                      ((ref($subel->[1]) eq 'HASH')?$subel->[1]:undef);
        next unless $subel1;
        $self->sayIt('#', ++$test_number);
        my $subel_name = $subel->[0];
        $self->sayIt("my \$obj_$subel_name;");
        $self->sayIt('eval {');
        $self->saying("    \$obj_$subel_name = " . $self->{_known_class}->{$subel_name}{$subel1->{attrs}->{xmlns}} ."->new({");
        map { $self->saying("  '$_' =>  'value$_',") if $_ ne 'xmlns' &&   $subel1->{attrs}->{$_}}  keys %{$subel1->{attrs}};
        $self->sayIt('    });');
        (ref($subel->[1]) eq 'ARRAY' && $#{$subel->[1]} == 0)?$self->sayIt("    \$obj1->add\u$subel_name(\$obj_$subel_name);"):
                                                                  $self->sayIt("    \$obj1->set_$subel_name(\$obj_$subel_name);");
        $self->sayIt('};');
        $self->sayIt("ok(\$obj_$subel_name && \!\$EVAL_ERROR, \"Create subelement object $subel_name and set it\") or diag(\$EVAL_ERROR);");
        $self->sayIt('undef $EVAL_ERROR;');
    }
    $self->sayIt('#', ++$test_number);
    $self->sayIt('my $string;');
    $self->sayIt('eval {');
    $self->sayIt('    $string = $obj1->asString');
    $self->sayIt('};');
    $self->sayIt('ok($string && !$EVAL_ERROR, "Converting to XML string: $string") or diag($EVAL_ERROR);');
    $self->sayIt('undef $EVAL_ERROR;');
    $self->sayIt('#', ++$test_number);
    $self->sayIt('my $obj22;');
    $self->sayIt('eval {');
    $self->sayIt("    \$obj22 = $className->new({xml => \$string});");
    $self->sayIt('};');
    $self->sayIt('ok($obj22 && !$EVAL_ERROR, "Re-create object from XML string: ") or diag($EVAL_ERROR);');
    $self->sayIt('undef $EVAL_ERROR;');
    $self->sayIt('#', ++$test_number);
    $self->sayIt('my $dom1 = $obj1->getDOM();');
    $self->sayIt('my $obj2;');
    $self->sayIt('eval {');
    $self->sayIt("     \$obj2 = $className->new(\$dom1);");
    $self->sayIt('};');
    $self->sayIt('ok($obj2 && !$EVAL_ERROR, "Re-create object from DOM XML: ") or diag($EVAL_ERROR);');
    $self->sayIt('undef $EVAL_ERROR;');
    $self->sayIt(qq!

BEGIN {

   plan tests =>  $test_number;
   use_ok  '$className';
  
}

1;
    !);
    $self->_fh->close;
}
#
#   auxiliary private function ( extracted from the build_class )
#   printing  getDom  part for arrayref members ( when its more than  a single instance of the sub-element )
#
#    accepts: $fh - filehandle where it prints to
#             $subname - current sub-element name
#             $name - name of the current element - will be used as parent DOM object identifier for recursive call
#             $logic - conditional logic parsed by _conditionParser
#
sub _printGetArrayDom {
    my ($self, $subname, $name, $logic) = @_;
    $self->sayIt(qq/
    if($logic\$self->get_$subname && ref(\$self->get_$subname) eq 'ARRAY') {
        foreach my \$subel (\@{\$self->get_$subname}) {
            if(blessed \$subel && \$subel->can("getDOM")) {
                my \$subDOM = \$subel->getDOM(\$$name);
                \$subDOM?\$$name->appendChild(\$subDOM):\$self->get_LOGGER->logdie("Failed to append  $subname element  with value:" .  \$subDOM->toString);
            }
        }
    }
/);
}
#
#   auxiliary private function ( extracted from the build_class )
#   printing  getDom  part for singular  object members
#
#    accepts:
#             $subname - current sub-element name
#             $name - name of the current element - will be used as parent DOM object identifier for recursive call
#             $cond_string - conditional logic parsed by _conditionParser reference to the sql_fields hash with mapped sql fields
#
sub _printGetDOM {
    my ($self, $subname, $name, $cond_string) = @_;
    $self->sayIt(qq/
    if($cond_string\$self->get_$subname && blessed \$self->get_$subname && \$self->get_$subname->can("getDOM")) {
        my \$${subname}DOM = \$self->get_$subname->getDOM(\$$name);
        \$${subname}DOM?\$$name->appendChild(\$${subname}DOM):\$self->get_LOGGER->logdie("Failed to append  $subname element with value:" .  \$${subname}DOM->toString);
    }
/);
}
#
#    auxiliary private function
#    will parse conditional string and return  regexp and  logical condition
#    accepted parameter: $value is a  string to parse where EBNF declaration is:
#       value =  ('scalar'| 'enum'|'set'|'if'|'unless'|'exclude') ':' (string ( ','  string)*)
#    will return hashref with  the resulted hash with keys:
#       {condition  => <left part of the ':'>,
#        logic => <if statement conditional expression>,
#        regexp => <matching regexp for the  enumerated list on the right part of ':'> }
#

sub _conditionParser {
    my $value = shift;
    my $result = { condition => '', logic => '', regexp => ''};
    return $result  unless $value;
    $value  =~ s/^(scalar|enum|set|if|unless|exclude)\:?//;
    $result->{condition} = $1;
    my @list  = split ",", $value  unless $result->{condition} eq 'scalar';
    if(@list) {
        $result->{logic}  =  "(\$self->get_" . (join " && \$self->get_", @list) . ")";
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
#   auxiliary private function ( extracted from the build_class )
#   analyze condition and return conditional string to be used in getDOM|fromDOM printing calls
#   accepted parameters: $key - [<attribute name> | 'text'],
#                        $value - condition to parse by _conditionParser,
#                        $what -  ['get' | 'from'] - to distinguish fromDom and getDOM
#
#
#
sub  _printConditional {
    my ($self, $key, $value,$what) = @_;
    my $string;

    my $arrayref_signleft = ($key ne 'text')?"[":'';
    my $arrayref_signright = ($key ne 'text')?"]":'';

    my $fromDomArg = ($key ne 'text')?"\$dom->getAttribute('$key')":"\$dom->textContent";

    my  $condition  = _conditionParser($value);
    print("$value Enum List:: " . ( join ":", map { " $_= " . $condition->{$_}} keys  %{$condition})) 
        if $self->DEBUG > 0 && !$condition->{condition}  eq 'scalar';

    if($condition->{condition}   eq 'scalar') {
        $string =   $what eq 'get'?
	                "                                                     $arrayref_signleft'$key' =>  \$self->$what\_$key$arrayref_signright,\n":
                        "    \$self->$what\_$key($fromDomArg) if($fromDomArg);\n";
    } elsif($condition->{condition}  =~ /^if|unless$/ &&  $condition->{logic}) {
        $string =  $what eq 'get'?
	               "                                           $arrayref_signleft '$key' => (".$condition->{logic}."?\$self->$what\_$key:undef)$arrayref_signright,\n":
                       "    \$self->$what\_$key($fromDomArg) if(" . $condition->{logic}. " && $fromDomArg);\n";
    } elsif($condition->{condition} =~ /enum|set|exclude/ &&  $condition->{regexp}) {

        my $regexp  =  $what eq 'get'?
	                    "(\$self->$what\_$key   " . $condition->{regexp} . ")":
			    "($fromDomArg  " . $condition->{regexp}  .")";

        $string =  $what eq 'get'?
	           "                                           $arrayref_signleft'$key' =>  ($regexp?\$self->$what\_$key:undef)$arrayref_signright,\n":
                   "    \$self->$what\_$key($fromDomArg) if($fromDomArg && $regexp);\n";
    } else {
        croak("Malformed , unknown condition=" . $condition->{condition} );
    }
    return $string;
}
#
#   auxiliary private function ( extracted from the build_class )
#   returns string with value setting statements for mapped sql fields
#
#    accepts: reference to the sql_fields hash with mapped sql fields
#             name of the sub-element
#             string with 'if' or 'elsif' statement depending on the function call order
#
sub _getSQLSub {
    my ($sql_fields, $subname, $if_cond) = @_;
    my $head_string = "                           $if_cond(\$self->get_$subname && (";
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
    $head_string .=   "                                \$query->{\$table}{\$entry} =  \$self->get_$subname;\n";
    $head_string .=   "                                \$self->get_LOGGER->debug(\" Got value for SQL query \$table.\$entry: \" . \$self->get_$subname);\n";
    $head_string .=   "                                last;  \n";
    $head_string .=   "                            }\n";
    return $head_string;
}
#
#   auxiliary private function ( extracted from the build_class )
#   prints fromDOM part
#
#   accepts: $fh - filehandle where it prints to
#            $subname - found sub-element name
#            $el - reference to hash with found sb-element declaration
#            $type - enumeration of 'HASH' 'ARRAY' 'CHOICE' - where ARRAY is treated differently
#            $condition_head - 'if' or 'elsif'
#            $cond_string - parsed by _conditionParser conditional logic
#
sub _printFromDOM {
    my ($self, $subname, $el, $type, $conditon_head, $cond_string) = @_;
    my  $subnameUP =  ucfirst($subname);
    my $ns = $el->{'attrs'}{'xmlns'};
    print "Building fromDOM: type=$type subname=$subname   head=$conditon_head  string=$cond_string ns=$ns  class=" . $self->{_known_class}->{$subname}{ $ns } ."\n" 
        if $self->DEBUG > 2;
    $self->sayIt("   $conditon_head ($cond_string\$tagname eq  '$subname' && \$nsid eq '".  $el->{'attrs'}{'xmlns'}  ."' && \$self->can(\"get_\$tagname\")) {");
    $self->sayIt("                eval {");
    $self->sayIt("                    \$element = " . $self->{_known_class}->{$subname}{$el->{'attrs'}{'xmlns'}} . "->new(\$childnode)");
    $self->sayIt("                };");
    $self->sayIt("                if(\$EVAL_ERROR || !(\$element  && blessed \$element)) {");
    $self->sayIt("                    \$self->get_LOGGER->logdie(\" Failed to load and add  $subnameUP : \" . \$dom->toString . \" error: \" . \$EVAL_ERROR);");
    $self->sayIt("                     return;");
    $self->sayIt("                }");
    $self->sayIt((($type eq 'ARRAY')?"               (\$self->get_$subname && ref(\$self->get_$subname) eq 'ARRAY')?push \@{\$self->get_$subname}, \$element:
                                                                                                        \$self->set_$subname([\$element]);":
                       "              \$self->set_$subname(\$element)") . "; ### add another $subname  ");
    $self->sayIt("            } ");
}

=head2 saying

 prints string into the  file handler without new line

=cut

sub saying {
    my($self, @string) = @_;
    croak("Filehandle must be set") unless $self->_fh && $self->_fh->isa('IO::File');
    $self->_fh->print(join '', @string);
}

=head2 sayIt

 prints string into the   file handler with new line added

=cut

sub sayIt {
    my($self, @string) = @_;
    $self->saying(@string);
    $self->_fh->print("\n");
}


#
# _printHelpers - prints  <datatypes_root>::Element - basic marshalling into DOM from perl obj
#                         <datatypes_root>::NSMap - mapping element names on the namespace prefixes
#                          <datatypes_root>::NamespaceRegistry - registry for namespace prefix => namespace
#
#  these modules are helpers utilized by the XML API
#

sub _printHelpers {
    my ($self) = @_;
    my $root_package =  $self->project_root . '::' .  $self->datatypes_root . '::' . $self->{_schema_version_dir};
    mkpath   ([$self->top_dir . '/' . $self->project_root . '/' . 
               $self->datatypes_root . '/' .  $self->{_schema_version_dir} ], 1, 0755);
    $self->_fh(IO::File->new($self->top_dir .  "/" . $self->project_root . '/' . 
                             $self->datatypes_root . "/" .  $self->{_schema_version_dir} ."/Element.pm" ,"w+"));
    croak("Failed to open Element.pm file") 
        unless  $self->_fh;
    my $registry_string;   
    foreach my $prefix (keys %{$self->nsregistry}) {
        $registry_string .= " '$prefix' => '" . $self->nsregistry->{$prefix} . "',\n";
    }
    # define packages
    my $element_package = "$root_package\:\:Element";
    my $nsmap_package = "$root_package\:\:NSMap";
    my $version = $self->schema_version; 

##########   printing Element.pm

    $self->sayIt(qq/package $element_package;
use strict;
use warnings;
use version;our \$VERSION = qw("$version");
use base 'Exporter';

\=head1 NAME

$element_package -  static class for basic element manipulations

\=head1 DESCRIPTION

it exports only single call - getElement which allows to create XML DOM out of perl object
This module was automatically build by L<XML::RelaxNG::Compact::PXB>.

\=cut

our \@EXPORT_OK   = qw(\&getElement);

use Readonly;
use Scalar::Util qw(blessed);
use XML::LibXML;
use Log::Log4perl qw(get_logger);
use Data::Dumper;
Readonly::Scalar our \$CLASSPATH =>  '$element_package';
Readonly::Hash   our %NSREGISTRY => ($registry_string);

our \$LOGGER = get_logger(\$CLASSPATH);

\=head1 METHODS

\=head2    getElement ()

 create   element from some data struct and return it as DOM
 accepts 1 parameter - hashref to hash of keyd parameters

 where:
 
  'name' =>  name of the element
 
  'ns' => [ namespace id1, namespace id2 ...] array ref
 
  'parent' => parent DOM if provided ( element will be created in context of the parent),
 
  'attributes' =>  arrayref to the array of attributes pairs,
                   where to get i-th attribute one has to  \$attr->[i]->[0] for  name  and  \$attr->[i]->[1]  for value
 
  'text' => <CDATA>

 creates  new   element, returns this element

\=back

\=cut

sub  getElement {
    my \$param = shift;
    my \$data;
    unless(\$param && ref(\$param) eq 'HASH' &&  \$param->{name}) {
       \$LOGGER->logdie(" Need single hashref parameter as { name => '',  parent => DOM_obj, attributes => [], text => ''} with at least name key defined");
    }
    my \$name =   \$param->{name};
    my \$attrs =  \$param->{attributes};
    my \$text =   \$param->{text};
    my \$nss =    \$param->{ns}; ## reference to array ref with ns prefixes for this element
   
    if(\$param->{parent} && blessed(\$param->{parent}) && \$param->{parent}->isa('XML::LibXML::Document')) {
        \$data =  \$param->{parent}->createElement(\$name);
    } else {
        \$data =  XML::LibXML::Element->new(\$name);
    }
    ## validation of the namespace prefixes  registered
    if(\$nss)  {
        foreach my \$ns (\@{\$nss}) {
            next unless \$ns;
            unless(\$NSREGISTRY{\$ns}) {
     	 	\$LOGGER->error("Attempted to create element with un-supported namespace prefix"); 
     	    }
            \$data->setNamespace(\$NSREGISTRY{\$ns}, \$ns, 1);
        }
    } else {
        \$LOGGER->error("Attempted to create element without namespace");
    }
    if((\$attrs && ref(\$attrs) eq 'ARRAY') || \$text) {
        if(\$attrs && ref(\$attrs) eq 'ARRAY') {
            foreach my \$attr (\@{\$attrs}) {
        	if(\$attr->[0] && \$attr->[1]) {
        	    unless(ref(\$attr->[1]))   {
        		\$data->setAttribute(\$attr->[0], \$attr->[1]);
        	    } else {
        		\$LOGGER->warn("Attempted to create ".\$attr->[0]." with this: ".\$attr->[1]." dump:" . sub { Dumper(\$attr->[1])});
        	    }
        	}
            }
        }
        if(\$text)  {
            unless(ref(\$text)) {
        	my \$text_el = XML::LibXML::Text->new(\$text);
        	\$data->appendChild(\$text_el);
            }  else {
        	\$LOGGER->warn(" Attempted to create text with non scalar: \$text dump:" . sub {Dumper(\$text)});
            }
        }
    } else {
        \$LOGGER->warn(" Attempted to create empty element with name \$name, failed to do so, will return undef ");
    }
    return \$data;
}
/);

    $self->sayIt($self->footer->asString());
    $self->_fh(IO::File->new($self->top_dir .  "/" . $self->project_root .  "/" . 
                             $self->datatypes_root  . "/" .  $self->{_schema_version_dir} . "/NSMap.pm" ,"w+"));
    croak(" Failed to open NSMap.pm file") 
        unless  $self->_fh;
    $self->sayIt(qq/package   $nsmap_package;

use strict;
use warnings;
use version;our \$VERSION = qv("$version");

\=head1 NAME

$nsmap_package - element names to namespace prefix mapper

\=head1 DESCRIPTION

this class designed to map element localname to registered namespace, the object of this
class is supposed to be member of the each PXB binded object in order to allow propagation of the
registered namespaces throughout the API

\=head1 SYNOPSIS

        use $nsmap_package;
	
	my \$nsmap =  $nsmap_package->new();
	\$nsmap->mapname(\$ELEMENT_LOCALNAME, 'ns_prefix');

\=head1 METHODS

\=head2 new({})

 new  - constructor, accepts single parameter - hashref with the hash of:
 
 <element_name> =>  <URI>,..., <element_name> =>  <URI>  #  mapped element on ns hashref
 
 the namespace registry track relation between namespace URI and used prefix

\=cut

use Data::Dumper;
use Readonly;
use Log::Log4perl qw(get_logger);
use fields qw(nsmap);

Readonly::Scalar our \$CLASSPATH => '$nsmap_package';
our \$LOGGER =  get_logger(\$CLASSPATH);

sub new {
    my (\$class, \$param) = \@_;
    \$class = ref(\$class) || \$class;
    my \$self = fields::new(\$class);
    if (\$param) {
        unless( ref(\$param) eq 'HASH') {
            \$LOGGER->logdie("ONLY hash ref accepted as param and not: " . Dumper \$param );
        }  
        foreach my \$key (keys \%{\$param}) {
            \$self->mapname(\$key => \$param->{\$key});
        }
    } else {
        \$self->{nsmap} = {}; 
    }
    return \$self;
}

\=head2 mapname()

    maps localname on the prefix
    accepts:
        with single parameter ( element name ) it will return
       namespace prefix  and with two parameters it will map  namespace prefix
    to specific element name
    and without parameters it will return the whole namespaces hashref

\=cut

sub mapname {
    my (\$self, \$element, \$nsid) = \@_;
    if (\$element && \$nsid) {
        \$self->{nsmap}->{\$element} = \$nsid;
    return \$self;
    } elsif(\$element && \$self->{nsmap}->{\$element} && !\$nsid) {
        return \$self->{nsmap}->{\$element};
    } elsif(!\$nsid && !\$element) {
        return \$self->{nsmap};
    }
    return;
}

/);

 $self->buildAM([qw/nsmap/]);
 $self->sayIt($self->footer->asString());

}

=head1 AUTHOR

Maxim Grigoriev (FNAL), maxim_at_fnal_dot_gov

=head1 LICENSE

You should have received a copy of the Fermitools license
with this software.  If not, see <http://fermitools.fnal.gov/about/terms.html>

=head1  COPYRIGHT

Copyright(c) 2007-2011, Fermi Research Alliance (FRA)

=cut
 

1;
