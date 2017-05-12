package UMMF::Import::UMMFModel;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/06 };
our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Import::UMMFModel - Parses an ad-hoc metamodel description.

=head1 SYNOPSIS

  use UMMF::Import::UMMFModel;
  my $importer = UMMF::Import::UMMFModel->new('factory' => $factory);
  my $importer->import($metametamodel_desc);

=head1 DESCRIPTION

This package is used to generate a UML model from the UML metamodels and 
other metamodel definitions found in C<lib/ummf/model>.

The model can then be passed to UMMF::Export::Perl or other exporters.

This importer sends ModelElement construction events to a UMMF::Core::Builder
object during parsing.  The builder creates the ModelElement objects 
through a factory and connects them up after the are all instantiated.

=head1 USAGE

Basic syntax:

  Model "MyModel" {
    Package Bar {
      Primitive Integer;
      Primitive Float;
      Primitive String;

      Class ClassA {
        attr1 : Integer;
        attr2 : String[0..*] {unordered};
      }
      Class ClassB : ClassA {
        attr3 : ClassA;
      }
    }
  }

=head1 EXPORT

None exported.

=head1 TODO

Support MOF and UML 2.0 syntaxes.

=head1 NOTES

The MOF specifies interfaces to a MOF meta-meta-model with CORBA IDL.  Rather
that having to analyze the IDL to infer Associations; I first started with
this mini-language.  At some point however, maintaining the MetaMetaModel.spec
document will be more difficult as UML progesses.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/06

=head1 SEE ALSO

L<UMMF::Core::Factory|UMMF::Core::Factory>
L<UMMF::Core::Builder|UMMF::Core::Builder>

=head1 VERSION

$Revision: 1.4 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Import);

#######################################################################

use Carp qw(confess);
use Parse::RecDescent;
use UMMF::Core::Builder;
  
#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'debugGrammar'} ||= $ENV{UMMF_GRAMMAR_DEBUG};
  $self->{'debugGrammar'} ||= 0;

  $self->{'debugParser'} ||= $ENV{UMMF_PARSER_DEBUG};
  $self->{'debugParser'} ||= 0;

  $self->{'warnings'} = 0;

  $self;
}

#######################################################################
#######################################################################
# Meta-metamodel grammar
#######################################################################
#######################################################################



my $gram =
q{

unit : model end_of_unit
     | model_elements end_of_unit

model : 'Model' metaclass_ string '{' option_
	   { $::builder->begin_Model($item{metaclass_}, { 'name' => $item{string} }, $item{option_}) }
         model_elements
           { $::builder->end_Model }
        '}'

model_elements : package_element(s)

package_element : classifier
                | usage
                | generalization_block
		| association
		| package
		| ';'
	        | <error>

end_of_unit : /^\Z/


package : 'Package' metaclass_ Type '{' option_
            { $::builder->begin_Package($item{metaclass_}, { 'name' => $item{Type} }, $item{option_}); }
          package_element(s)
            { $::builder->end_Package; }
          '}'

classifier : MetaClass ClassName Types_ ';' option_
        { 
	  $DB::single = 0; 
	  $::builder->end_Classifier($item{MetaClass}, $item{ClassName}, $item{option_}, $item{Types_});
	}
           | MetaClass ClassName Types_ '{' option_
        { 
	  $DB::single = 0; 
	  $::builder->begin_Classifier($item{MetaClass}, $item{ClassName}, $item{option_}, $item{Types_});
	}
          classifier_element(s)
        { $::builder->end_Classifier; }
        '}'

Types_ : ':' Types { $return = $item{Types}; }
       |           { $return = [ ]; }

MetaClass : 'Class'
          | 'AssociationClass'
	  | 'Enumeration'
	  | 'Primitive'
          | 'Classifier' metaclass

metaclass : '<<metaclass>>' Name { $return = $item{Name}; }

metaclass_ : metaclass
           |                     { $return = $::default; }

ClassName : '/' Name '/'
              {
                # Signifies isAbstract = 'true'
                $return = { 'name' => $item{Name}, 'isAbstract' => 'true' };
              }
	  | Name
              { $return = { 'name' => $item{Name} }; }

classifier_element : attribute 
                   | association
	           | literal
	           | classifier
	           | ';'
                   | <error>


literal : literal_metaclass name ';'
             { $DB::single = 0; $::builder->add_Literal($item{literal_metaclass}, { 'name' => $item{name} } );}

literal_metaclass : 'Literal' metaclass { $return = $item{metaclass}; }
                  |                     { $return = $::default; }


generalization_block : ':' Types '{'
                  { $::builder->begin_Generalization_parent($item{Types}) }
                     package_element(s)
                  { $::builder->end_Generalization_parent }
                '}'

usage : '::' metaclass_ usage_paths ';'
               { $::builder->add_Usage($item{metaclass_}, $item{usage_paths}); }

attribute : attribute_metaclass attribute_ option_ ';'
              { 
	        $return = $::builder->add_Attribute($item{attribute_metaclass}, $item{attribute_}, $item{option_});
	      }

attribute_metaclass : 'Attribute' metaclass { $return = $item{metaclass}; }
                    |                       { $return = $::default; }

attribute_ : visibility attribute_decl stereotype_
             {
	      my $attr = {
		'name'         => $item{attribute_decl}[0],
		'type'         => $item{attribute_decl}[1],
		'multiplicity' => $item{attribute_decl}[2],
                'initialValue' => $item{attribute_decl}[3],
		'visibility'   => $item{visibility},
		'stereotype'   => $item{stereotype_},
	      };
              $return = $attr;
             }

attribute_decl : name ':' Type multiplicity_bracketed_ initialValue_
                   { $return = [ $item{name}, $item{Type}, $item{multiplicity_bracketed_}, $item{initialValue_} ] } 
               | name multiplicity_bracketed ':' Type initialValue_
                   { $return = [ $item{name}, $item{Type}, $item{multiplicity_bracketed}, $item{initialValue_} ] }

initialValue_ : '=' initialValue
                  { $return = $item{initialValue}; }
              |
                  { $return = $::default; }

initialValue : literalValue


association : '@' metaclass_ option_ association_
              {
		my $attr = {
		  'connection' => $item{association_}[0],
		  'name' => $item{association_}[1],
		  '.associationClass' => $item{association_}[2],
		};
		$return = $::builder->add_Association($item{metaclass_}, $attr, $item{option_});
	      }

association_ : '@' name association_ends
                 { $return = [ $item{association_ends}, $item{name} ]; }
             | '.' association_
                 {
	           $item[2][2] = '.';
		   $return = $item[2];
	         }
             | association_ends
                 { $return = [ $item{association_ends} ]; }


# There must be at least 2 assocation ends.
association_ends : association_end ',' association_end association_ends_3
                   { $return = [ $item[1], $item[3], @{$item[4]} ]; }
                 | <error>

association_ends_3 : ';'
                     { $return = [ ]; }
                 | ',' association_end association_ends_3
                     { $return = [ $item[2], @{$item[3]} ]; }
                 | <error>



association_end : navigable association_end__
                {
                  my $x = $item{association_end__};
                  $x->{'isNavigable'} = $item{navigable} || die(),
                  $return = $x;
                }
                | association_end__


association_end__ : aggregation visibility association_end_ option_
                  {
		    my $x = {
		      'name'         => $item[3][0],
		      'participant'  => $item[3][1],
		      'multiplicity' => $item[3][2],
		      'visibility'   => $item{visibility},
		      'ordering'     => $item{option_}{'ordering'},
		      'aggregation'  => $item{aggregation},
                      '.options'     => $item{option_},
		    };
		    # $::RD_TRACE = 1 if $x->{name} eq 'range' && $x->{'participant'} eq 'MultiplicityRange';
		    $return = $x;
		  }

association_end_ : end_name ':' Type multiplicity_or_bracketed_
                     { $return = [ $item{end_name}, $item{Type}, $item{multiplicity_or_bracketed_} ]; }
                 | ':' Type multiplicity_or_bracketed_
                     { $return = [ undef,           $item{Type}, $item{multiplicity_or_bracketed_} ]; }
                 | end_name multiplicity_or_bracketed_
                     { $return = [ $item{end_name}, '.',         $item{multiplicity_or_bracketed_} ]; }
                 | multiplicity_or_bracketed
                     { $return = [ undef,           '.',         $item{multiplicity_or_bracketed} ] }
                 | <error>

end_name : '/' name
             {
	      # What does '/' mean?  (as in p.2-113 '+/ownedElement')
	      #
	      # I think it means that the AssociationEnd is specified
	      # in a Generalization parent of the participant.
	      # 
	      # If so, then the Association can be dropped, because
	      # a Generalization implements it.
	      #
              # Actually, from reading the UML 2.0 Infrastructure,
              # it seems that '/' means isDerived is 'true'.
              #   -- kstephens@users.sourceforge.net 2003/10/17
              #
	     $return = "/$item{name}";
	     # print STDERR "parsed '$return'\n";
             } 
         | name
             { $return = $item{name}; }


navigable : '->'         { $return = 'true'; }


reference : '^' visibility reference_name multiplicity_bracketed_ '->' association_name '::' end_name option_ ';'
              {
                my $attr = {
                  'name' => $item{reference_name},
                  'visibility' => $item{visibility},
                  'scope' => $item{option_}{scope},
                  'multiplicity' => $item{multiplicity_bracketed_},
                  'changeablility' => $item{option_}{changeablity},
                  'association' => $item{association_name},
                  'end' => $item{end_name},
                };
                $return = $::builder->add_Reference($item{metaclass}, $attr, $item{option_});
              }

reference_name   : name
association_name : Name
end_name         : name


option_ : '{' options '}' { $return = $item{options}; }
        |                 { $return = { }; }


options : option options
            { 
              my $a = $item{option};
              my $b = $item{options};

              # Append subsets;
              push(@{$a->{'subset'} ||= [ ]}, @{$b->{'subset'} || []});
              delete $b->{'subset'};

              # Append taggedValues;
              push(@{$a->{'taggedValue'} ||= [ ]}, @{$b->{'taggedValue'} || []});
              delete $b->{'taggedValue'};

              # Override rest.
              %$a = ( %$a, %$b );

              $return = $a;
            }
        | option

option : option_sep
                       { $return = { }; }
       | 'ordered'     { $return = { 'ordering'       => $item[1]        }; }
# UML OrderingKind
       | 'unordered'   { $return = { 'ordering'       => $item[1]        }; }
# UML metamodel but not UML or MOF!
       | 'subset' name { $return = { 'subset'         => [ $item{name} ] }; }
       | 'union'       { $return = { 'isDerivedUnion' => 'true'          }; }
       | 'composite'   { $return = { 'isComposite'    => 'true'          }; }
# UML ChangeableKind
       | 'changeable'  { $return = { 'changability'   => $item[1]        }; }
       | 'frozen'      { $return = { 'changability'   => $item[1]        }; }
       | 'addOnly'     { $return = { 'changability'   => $item[1]        }; }
# UML ScopeKind
       | 'instance'    { $return = { 'scope'          => $item[1]        }; }
       | 'classifier'  { $return = { 'scope'          => $item[1]        }; }
# UML ParameterDirectionKind
       | 'in'          { $return = { 'direction'      => $item[1]        }; }
       | 'out'         { $return = { 'direction'      => $item[1]        }; }
       | 'inout'       { $return = { 'direction'      => $item[1]        }; }
       | 'return'      { $return = { 'direction'      => $item[1]        }; }
# MOF 1.4.1
       | 'unique'      { $return = { 'unique'         => 'true'          }; }
# UML TaggedValue
       | '<<taggedValue>>' taggedValue_name ':' taggedValue_value
           { 
             # UML 1.5 3.17.2 Notation
             $return = { 'taggedValue' => [ [ $item{taggedValue_name}, $item{taggedValue_value} ] ] };
           }

option_sep : ','
           | ';'

taggedValue_name : name_elem
                 | string

taggedValue_value : string
                  | integer
                  | real
                  | name_elem

multiplicity_bracketed : '[' multiplicity ']' { $return = $item[2]; }

multiplicity_bracketed_ : multiplicity_bracketed
                        | { $return = $::default; }

multiplicity_or_bracketed : multiplicity
                          | multiplicity_bracketed

multiplicity_or_bracketed_ : multiplicity_or_bracketed 
                           | { $return = $::default; }

multiplicity : multiplicity_ranges

multiplicity_ranges : multiplicity_range ',' multiplicity_ranges
                        { $return = $item[1] . ',' . $item[3]; }
                    | multiplicity_range

multiplicity_range : integer dotdot star 
                       { $return = $item[1] . '..*'; }
                   | integer dotdot integer
                       { $return = $item[1] . '..' . $item[3]; }
                   | star
                   | integer

stereotype_ : stereotype stereotype_    { $return = [ $item[1], @{$item[2]} ]; }
            | stereotype                { $return = [ $item[1] ]; }
            |                           { $return = [ ]; }


visibility : '+' { $return = 'public'; }
           | '-' { $return = 'private'; }
           | '#' { $return = 'protected'; }
           | '~' { # UML 1.5 3.25.2 Notation
                   $return = 'package'; 
                 }
           |     { $return = $::self->{'default'}{'visibility'} || 'private'; }


derived_ : '/' { $return = 'true'; }
         |     { $return = undef; }


aggregation : '<>'     { $return = 'aggregate' }
            | '<#>'    { $return = 'composite' }
            |          { $return = $::self->{'default'}{'aggregation'} || 'none'; }


Types : Type ',' Types
          { $return = [ $item[1], @{$item[3]} ]; }
      | Type 
          { $return = [ $item[1] ]; }

Type : name_path
         {
	   my @x = split(/::/, $item[1]);
	   for my $x ( @x ) {
	     unless ( $x eq '..'|| $x eq '.' ) {
	       $::self->warning("name element '$x' in '$item[1]' does not start with uppercase character")
	       unless $x =~ /^[A-Z_]/;
	     }
	   }
	   # $::RD_TRACE = 1 if $item[1] eq 'Namespace';
	   $return = $item[1];
	 }
     | string
        {
          my $x = $item[1];
          # $::self->warning("using string '$x' as Type name");
	  $return = $x;
        }


Name : name_elem
         { 
            $::self->warning("Name '$item[1]' does not start with uppercase character")
            unless $item[1] =~ /^[A-Z_]/;
            $return = $item[1];
         }
     | string


name : name_elem
         {
           $::self->warning("name '$item[1]' does not start with lowercase character")
           unless $item[1] =~ /^[a-z_]/;
           $return = $item[1];
         }
     | string


usage_paths : usage_path ',' usage_paths
                { $return = [ $item[1], @{$item[3]} ]; }
            | usage_path
                { $return = [ $item[1] ]; }
            | <error>


# LITERALS

  name_path    : /(([a-z_][a-z_0-9]*|\.\.|\.)(::([a-z_][a-z_0-9]*|\.\.|\.))*)/i
  usage_path   : /((([a-z_][a-z_0-9]*|\.\.|\.)::)*([a-z_][a-z_0-9]*|\*))/i
  name_elem    : /([a-z_][a-z_0-9]*)/i

  literalValue : string_token
               | real
               | integer
               | name { $return = '"' . $item{name} . '"'; }

  string_token : /"(([^\\]+|\\[\\"])*)"/ 

  string       : /"(([^\\]+|\\[\\"])*)"/
                   {
                     my $str = $1;
                     $str =~ s/\\\\(.)/$1/g;
                     $return = $str;
                   }

  real       : /([-+]?([0-9]+\.|[0-9]*\.[0-9]+)([eEgGfF][-+]?[0-9]+)?)/
  integer    : /[-+]?[0-9]+/
  star       : /\*/
  dotdot     : /\.\./
  dot        : /\./
  stereotype : /\<\<\w+\>\>/

};

#######################################################################


my $parser;
sub parser
{
  my ($self) = @_;
  
  return $parser if $parser;
  
  $self->message('Generating grammar:');

  local $::RD_ERRORS = 1;
  local $::RD_WARN = 1;
  local $::RD_HINT = 1;
  local $::RD_TRACE;
  $::RD_TRACE = $self->{'debugGrammar'} if $self->{'debugGrammar'};

  # $DB::single = 1;

  $parser = new Parse::RecDescent($gram) ||
  confess(code_error($@, $gram)) unless $parser;

  $self->message('Generating grammar: DONE');

  $parser;
}


#######################################################################


sub import_input
{
  my ($self, @args) = @_;

  # Get a ummfmodel file parser.
  my $parser = $self->parser;

  my $input = join("\n", @args);
  
  use UMMF;
  use Template;

  # Create a Template to handle conditionalities and includes
  $self->message('Parsing template:');

  my $template = {
	'INCLUDE_PATH' => [ UMMF->resource_path('model') ],
	'INTERPOLATE' => 1,
	'POST_CHOMP' => 1,
	'EVAL_PERL' => 1,
	'DEBUG' => 1,
        'ABSOLUTE' => 1,
	'RELATIVE' => 1,

#	'COMPILE_EXT'   => '.ttc',
#	'COMPILE_DIR'   => "/tmp/$ENV{USER}.ttc",
       };

  if ( $template->{'COMPILE_DIR'} ) {
    use File::Path;
    mkpath([ $template->{'COMPILE_DIR'} ], 1); 
  }  

  #print STDERR "UMMFModel: INCLUDE_PATH = @{$template->{INCLUDE_PATH}}\n";
  $Template::DEBUG = 1;
  # $DB::single = 1;
  $template = Template->new($template) || confess($Template::ERROR);

  # Set up template vars.
  #print STDERR 'input = ', $input, "\n";
  {
    my $vars = $self;
    my $output = '';
    # $DB::single = 1;
    $template->process(\$input, $vars, \$output);
    confess($Template::ERROR) if $Template::ERROR;
    $input = $output;
  }
  #print STDERR 'output = ', $input, "\n";

  $self->message('Parsing template: DONE');

  $self->message('Parsing model:');

  # Strip comments.
  $input =~ s@/\*(.*?)\*/@__fix_newlines_in_comment($1)@sge;

  # UGH!
  # $input =~ s@\<\>|\<\#\>|\{ordered\}@@sg;
  #$input =~ s@/([a-z]+)@$1@sgi;
  
  # print STDERR $input;

  # Begin parsing.
  local $::RD_ERRORS = 1;
  local $::RD_WARN = 1;
  local $::RD_HINT = 1;
  local $::RD_TRACE;
  $::RD_TRACE = $self->{'debugParser'} if $self->{'debugParser'};

  my $builder = $self->{'builder'} || UMMF::Core::Builder->new('factory' => $self->factory);

  # Set up external state variables.
  local $::self = $self;
  local $::builder = $builder;
  local $::default = $builder->_default_value;

  # Parse.
  # $DB::single = 1;
  $parser->model($input);

  $self->message('Parsing model: DONE');

  # Handle errors.
  my $errors = $parser->{'errors'};
  confess("UMMFModel parse errors occurred") if $errors && @$errors;

  #$DB::single = 1;

  # Return top-level model.
  my $model = $builder->model_top_level;

  $model;
}


sub __fix_newlines_in_comment
{
  my ($x) = @_;

  #print STDERR "COMMENT: '$x'\n";

  my $nl = 0;
  $x =~ s/\n/++ $nl/sge;
  $x = "\n" x $nl;

  #$DB::single = 1;

  $x;
}


#######################################################################


sub warning
{
  my ($self, @args) = @_;

  my $x = join('', @args);

  unless ( $self->{'.warning'}{$x} ++ ) {
    $self->message('Warning: ', $x);
    $self->{'warnings'} ++;
  }

  $self;
}


sub verbose
{
  my ($self, @args) = @_;

  $self->message(@args) if $self->{'verbose'};
}


sub message
{
  my ($self, @args) = @_;

  print STDERR 'UMMFModel: ', @args, "\n";

  $self;
}


sub code_error
{
  my ($error, $code) = @_;
  $error ||= $@;

  my $line = 0;
  my $c = $code;
  $c = join("\n",
	    map(sprintf("%-4d ", ++ $line) . $_,
		split("\n", $code, 99999),
		),
	    '',
	    );
  my $sep = '#-' x 10;
  $c = "$sep\n$c$sep\n";
  die "$c\nin code above:\n$error";
}


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

