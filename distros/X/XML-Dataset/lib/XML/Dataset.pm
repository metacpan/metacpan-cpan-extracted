package XML::Dataset;

#-------------------------------------------------------------------------------
#   Module  : XML::Dataset
#
#   Purpose : Extracts XML into Datasets based upon a text profile markup
#             language
#-------------------------------------------------------------------------------
use strict;
use warnings;

use XML::LibXML::Reader;
use Data::Alias;

our $VERSION = '0.006';
our @ISA     = qw(Exporter);
our @EXPORT  = qw(parse_using_profile);

#-------------------------------------------------------------------------------
#   Call the _run method if the module was called as a script
#-------------------------------------------------------------------------------
__PACKAGE__->_run(qw ( Parameter1 Parameter2 )) unless caller();

#-------------------------------------------------------------------------------
#   Constructor
#
#   Object constructor parameters are passed directly to the object
#-------------------------------------------------------------------------------
sub new {
   my $class = shift;
   my $self  = {@_};

   # bless REF, CLASSNAME
   bless $self, $class;

   # return object
   return $self;
}

#-------------------------------------------------------------------------------
#   Subroutine : _process_record
#
#   Input      : $nodeName, $nodeValue, $record
#
#   Purpose    : Stores node information based on the profile
#-------------------------------------------------------------------------------
sub _process_record {
   my ( $self, $nodeName, $nodeValue, $record ) = @_;

   #-------------------------------------------------------------------------------
   #  If a 'name' entry is defined we want to use a custom name, replace
   #  the key name accordingly
   #-------------------------------------------------------------------------------
   my $name = defined $record->{name} ? $record->{name} : $nodeName;

   #-------------------------------------------------------------------------------
   #  If a 'prefix' entry is defined we want to prefix with a custom value, update
   #  the key name accordingly
   #-------------------------------------------------------------------------------
   $name = defined $record->{prefix} ? $record->{prefix} . ${name} : $name;

   #-------------------------------------------------------------------------------
   #  If a process declaration is made, pass the current value through the
   #  corresponding process filter prior to storing the value
   #-------------------------------------------------------------------------------
   if ( defined $record->{process} ) {

      # Check for the required process method in the main namespace
      if ( main->can("$record->{process}") ) {
         no strict "refs";    ## no critic
         $nodeValue = &{"main\::$record->{process}"}($nodeValue);
      }
      else {
         die("could not find method $record->{process} for processing");
      }
   }

   #-------------------------------------------------------------------------------
   #  If there is a dataset value
   #-------------------------------------------------------------------------------
   if ( defined $record->{dataset} ) {

      #-------------------------------------------------------------------------------
      #  If we are going to clobber an existing value or if the dataset does not
      #  already exist, create a new dataset
      #-------------------------------------------------------------------------------
      if (  ( !defined $self->{current_data}->{ $record->{dataset} } )
         || ( exists $self->{current_data}->{ $record->{dataset} }->{$name} ) ) {

         #-------------------------------------------------------------------------------
         #  Create a named hashref - $temporary_hash
         #-------------------------------------------------------------------------------
         my $temporary_hash = {};

         #-------------------------------------------------------------------------------
         #  Copy the existing external references if applicable to $temporary_hash
         #-------------------------------------------------------------------------------
         for my $external_reference ( @{ $self->{__EXTERNAL_REFERENCES__} } ) {
            if ( defined $self->{current_data}->{ $record->{dataset} }->{$external_reference} ) {
               $temporary_hash->{$external_reference} =
                 $self->{current_data}->{ $record->{dataset} }->{$external_reference};
            }
         }

         #-------------------------------------------------------------------------------
         #  Dispatch Dataset if required
         #-------------------------------------------------------------------------------
         if ( ( defined $self->{dispatch} ) && ( defined $self->{current_data}->{ $record->{dataset} } ) ) {
            $self->_dispatch_dataset( $record->{dataset} );
         }

         #-------------------------------------------------------------------------------
         #  Push the $temporary_hash on to the datastructure
         #-------------------------------------------------------------------------------
         push @{ $self->{data_structure}->{ $record->{dataset} } }, $temporary_hash;

         #-------------------------------------------------------------------------------
         #  Update the current reference with the $temporary_hash pointer
         #-------------------------------------------------------------------------------
         $self->{current_data}->{ $record->{dataset} } = $temporary_hash;
      }

      #-------------------------------------------------------------------------------
      #  Store the data within the dataset
      #-------------------------------------------------------------------------------
      $self->{current_data}->{ $record->{dataset} }->{$name} = $nodeValue;
   }

   #-------------------------------------------------------------------------------
   #  Store external data
   #-------------------------------------------------------------------------------
   elsif ( defined $record->{external_dataset} ) {

      # If the external doesn't exist, create it with a default value
      if ( !defined $self->{external_data}->{ $record->{external_dataset} }->{$name} ) {
         push @{ $self->{external_data}->{ $record->{external_dataset} }->{$name} }, '';
      }

      # If the value exists and the last entry has a value which is not '', create a new holder
      elsif ( ( defined $self->{external_data}->{ $record->{external_dataset} }->{$name}[-1] )
         && ( $self->{external_data}->{ $record->{external_dataset} }->{$name}[-1] ne '' ) ) {
         push @{ $self->{external_data}->{ $record->{external_dataset} }->{$name} }, '';
      }

      # Store the data
      $self->{external_data}->{ $record->{external_dataset} }->{$name}[-1] = $nodeValue;
   }
}

#-------------------------------------------------------------------------------
#   Subroutine : _dispatch_all
#
#   Purpose    : Dispatches all datasets or all remaining datasets
#-------------------------------------------------------------------------------
sub _dispatch_all {
   my $self = shift;
   if ( defined $self->{dispatch} ) {
      for my $dataset ( keys %{ $self->{data_structure} } ) {
         $self->_dispatch_dataset( $dataset, 1 );
      }
   }
}

#-------------------------------------------------------------------------------
#   Subroutine : _dispatch_dataset
#
#   Input      : $self, $dataset, $flush
#
#   Purpose    : Dispatches a dataset
#-------------------------------------------------------------------------------
# Closures used to isolate $dispatch_counter ( equivalent to state )
{
   my $dispatch_counter = {};

   sub _dispatch_dataset {
      my ( $self, $dataset, $flush ) = @_;

      # Increase the counter
      $dispatch_counter->{$dataset}++;

      my $counter_trigger = 0;
      if (  ( defined $self->{dispatch}->{$dataset}->{counter} )
         || ( defined $self->{dispatch}->{__generic__}->{counter} ) ) {
         $counter_trigger =
           defined $self->{dispatch}->{$dataset}->{counter}
           ? $self->{dispatch}->{$dataset}->{counter}
           : $self->{dispatch}->{__generic__}->{counter};
      }
      else {
         # Alert
      }

      my $counter_coderef;
      if (  ( defined $self->{dispatch}->{$dataset}->{coderef} )
         || ( defined $self->{dispatch}->{__generic__}->{coderef} ) ) {
         $counter_coderef =
           defined $self->{dispatch}->{$dataset}->{coderef}
           ? $self->{dispatch}->{$dataset}->{coderef}
           : $self->{dispatch}->{__generic__}->{coderef};
         if ( ref($counter_coderef) ne 'CODE' ) {

            # Alert
         }
      }
      else {
         # Alert
      }

      if ( defined $self->{data_structure}->{$dataset} ) {
         if ( ( scalar( @{ $self->{data_structure}->{$dataset} } ) >= $counter_trigger ) || ( defined $flush ) ) {

            # Call the CODEREF with the Payload
            &{$counter_coderef}( { $dataset => $self->{data_structure}->{$dataset} } );

            # Delete the processed entries
            delete $self->{data_structure}->{$dataset};
         }
      }
   }
}

sub _logging_clobber_external_information {
   my %args = @_;
}

sub _log_xml_attribute_not_defined_in_profile {
   warn "missing profile entry for attribute name=$_[0]->{name} depth=$_[0]->{depth}";
}

sub _log_xml_element_not_defined_in_profile {
   warn "missing profile entry for element name=$_[0]->{name} depth=$_[0]->{depth}";
}

#-------------------------------------------------------------------------------
#   Subroutine : _process_data
#
#   Input      : $data = Perl Structure, $profile = Text Profile
#
#   Output     : Perl Structure
#
#   Purpose    : Processes perl structures based on input profiles
#-------------------------------------------------------------------------------
sub _process_data {
   my $self = shift;
   my $node = shift;

   #-------------------------------------------------------------------------------
   #  Dispatch Table - Based on perl reference type
   #-------------------------------------------------------------------------------
   my $xml_dispatch_table = {
      0 => sub {    # XML_READER_TYPE_NONE

         #-------------------------------------------------------------------------------
         # Process all nodes in the document
         #-------------------------------------------------------------------------------
         while ( $node->read ) {

            #-------------------------------------------------------------------------------
            # Process data
            #-------------------------------------------------------------------------------
            $self->_process_data($node);
         }

      },
      1 => sub {    # XML_READER_TYPE_ELEMENT

         #-------------------------------------------------------------------------------
         # Store the previous nodeName if applicable
         #-------------------------------------------------------------------------------
         $self->{_previous_key} = defined $self->{_current_key} ? $self->{_current_key} : '';

         #-------------------------------------------------------------------------------
         #  Store the current nodeName
         #-------------------------------------------------------------------------------
         $self->{_current_key} = $node->name;

         if ( $#{ $self->{_profiles} } >= $node->depth ) {
            $self->{_profile} = $self->{_profiles}[ $node->depth - 1 ];
         }

         #-------------------------------------------------------------------------------
         #  Compare the key against the profile
         #-------------------------------------------------------------------------------
         if ( defined $self->{_profile}->{ $self->{_current_key} } ) {

            # Update the profile to the current_key
            $self->{_profile} = $self->{_profile}->{ $self->{_current_key} };

            # Store the updated profile
            $self->{_profiles}[ $node->depth ] = $self->{_profile};

            #-------------------------------------------------------------------------------
            #  If the key exists and has an __NEW_EXTERNAL_VALUE_HOLDER__ element, configure
            #  external holders
            #-------------------------------------------------------------------------------
            if ( defined $self->{_profile}->{__NEW_EXTERNAL_VALUE_HOLDER__} ) {

               #-------------------------------------------------------------------------------
               #  Process all External Values
               #-------------------------------------------------------------------------------
               for my $dataset ( @{ $self->{_profile}->{__NEW_EXTERNAL_VALUE_HOLDER__}->{__record__} } ) {
                  my ( $ext_dataset, $ext_name ) = %{$dataset};

                  push @{ $self->{external_data}->{$ext_dataset}->{$ext_name} }, '';
               }

            }

            #-------------------------------------------------------------------------------
            #  If the key exists and has an __IGNORE__ element, ignore and move to the
            #  next record
            #-------------------------------------------------------------------------------
            if ( defined $self->{_profile}->{'__IGNORE__'} ) {
            }

            #-------------------------------------------------------------------------------
            #  Otherwise continue
            #-------------------------------------------------------------------------------
            else {

               #-------------------------------------------------------------------------------
               #  Check for a new dataset marker
               #-------------------------------------------------------------------------------
               if ( defined $self->{_profile}->{__NEW_DATASET__} ) {
                  for my $dataset ( @{ $self->{_profile}->{__NEW_DATASET__} } ) {

                     #-------------------------------------------------------------------------------
                     #  Dispatch Dataset if required
                     #-------------------------------------------------------------------------------
                     if ( ( defined $self->{dispatch} ) && ( defined $self->{current_data}->{$dataset} ) ) {
                        $self->_dispatch_dataset($dataset);
                     }

                     #-------------------------------------------------------------------------------
                     #  Create a named hashref
                     #-------------------------------------------------------------------------------
                     my $temporary_hash = {};

                     #-------------------------------------------------------------------------------
                     # Push on to the datastructure
                     #-------------------------------------------------------------------------------
                     push @{ $self->{data_structure}->{$dataset} }, $temporary_hash;

                     #-------------------------------------------------------------------------------
                     #  Update the current reference with the same pointer
                     #-------------------------------------------------------------------------------
                     $self->{current_data}->{$dataset} = $temporary_hash;
                  }
               }

               #-------------------------------------------------------------------------------
               #  Check for an __EXTERNAL_VALUE__
               #-------------------------------------------------------------------------------
               if ( defined $self->{_profile}->{__EXTERNAL_VALUE__} ) {

                  #-------------------------------------------------------------------------------
                  #  Initialise default holder for external values
                  #-------------------------------------------------------------------------------
                  $self->{__EXTERNAL_REFERENCES__} = [];

                  #-------------------------------------------------------------------------------
                  #  Process all External Values
                  #-------------------------------------------------------------------------------
                  for my $dataset ( @{ $self->{_profile}->{__EXTERNAL_VALUE__} } ) {

                     #-------------------------------------------------------------------------------
                     #  Seperate the record
                     #-------------------------------------------------------------------------------
                     my ( $ext_dataset, $ext_name, $forward_dataset, $forward_name ) = split( ':', $dataset );

                     #-------------------------------------------------------------------------------
                     #  Use the supplied forwarding name if available, otherwise use the original name
                     #-------------------------------------------------------------------------------
                     if ( !defined $forward_name ) { $forward_name = $ext_name }

                     #-------------------------------------------------------------------------------
                     #  Store the external values within the object, if we encounter a clobber
                     #  situation where a new dataset is created to prevent data being overwritten
                     #  this list will provide a corresponding reference to the external values
                     #  to copy
                     #-------------------------------------------------------------------------------
                     push @{ $self->{__EXTERNAL_REFERENCES__} }, $forward_name;

                     #-------------------------------------------------------------------------------
                     #  If we've encountered the external data before we've created a dataset holder,
                     #  or the external data already exists in the dataset, create a new dataset
                     #-------------------------------------------------------------------------------
                     if (  ( !defined $self->{current_data}->{$forward_dataset} )
                        || ( defined $self->{current_data}->{$forward_dataset}->{$forward_name} ) ) {

                        #-------------------------------------------------------------------------------
                        #  Create a named hashref
                        #-------------------------------------------------------------------------------
                        my $temporary_hash = {};

                        #-------------------------------------------------------------------------------
                        # Push on to the datastructure
                        #-------------------------------------------------------------------------------
                        push @{ $self->{data_structure}->{$forward_dataset} }, $temporary_hash;

                        #-------------------------------------------------------------------------------
                        #  Update the current reference with the same pointer
                        #-------------------------------------------------------------------------------
                        $self->{current_data}->{$forward_dataset} = $temporary_hash;
                     }

                     #-------------------------------------------------------------------------------
                     #  Verify that the external data does not already exist within the dataset,
                     #  If it doesn't store accordingly
                     #-------------------------------------------------------------------------------
                     if ( !defined $self->{current_data}->{$forward_dataset}->{$forward_name} ) {

                        #-------------------------------------------------------------------------------
                        #  Check for scenarios where we are using external data before the external
                        #  data has been processed...
                        #-------------------------------------------------------------------------------
                        if ( !defined $self->{external_data}->{$ext_dataset}->{$ext_name} ) {

                           die(
                              "An attempt has been made to use external data before that data has been processed, this can result in invalid datasets.  See the __NEW_EXTERNAL_VALUE_HOLDER__ profile option within the perldoc - $ext_dataset $ext_name"
                           );
                        }

                        #-------------------------------------------------------------------------------
                        #  alias through Data::Alias  ... example taken from
                        #  http://stackoverflow.com/questions/12514234/alias-a-hash-element-in-perl
                        #-------------------------------------------------------------------------------
                        alias $self->{current_data}->{$forward_dataset}->{$forward_name} =
                          $self->{external_data}->{$ext_dataset}->{$ext_name}[-1];
                     }
                  }
               }
            }

            #-------------------------------------------------------------------------------
            #  Process attributes if they exist, these will always be key/value pairs
            #-------------------------------------------------------------------------------
            if ( $node->hasAttributes ) {
               while ( $node->moveToNextAttribute ) {

                  #-------------------------------------------------------------------------------
                  #  If the key exists and has an __IGNORE__ element, ignore and move to the
                  #  next record
                  #-------------------------------------------------------------------------------
                  if ( defined $self->{_profile}->{ $node->name }->{'__IGNORE__'} ) {
                  }

                  #-------------------------------------------------------------------------------
                  # If the attribute is defined in the profile, process
                  #-------------------------------------------------------------------------------
                  elsif ( defined $self->{_profile}->{ $node->name }->{__record__} ) {
                     for my $record ( @{ $self->{_profile}->{ $node->name }->{__record__} } ) {
                        $self->_process_record( $node->name, $node->value, $record );
                     }
                  }

                  #-------------------------------------------------------------------------------
                  # Alert if the XML Attribute is not defined according to object parameters
                  #-------------------------------------------------------------------------------
                  else {
                     if ( $self->{warn_missing_profile_entry} ) {
                        _log_xml_attribute_not_defined_in_profile(
                           {
                              name  => $node->name,
                              depth => $node->depth,
                           }
                        );
                     }
                  }
               }
            }
         }

         #-------------------------------------------------------------------------------
         #  Otherwise the element is not defined in the profile, warn or die depending
         #  on the constructor options
         #-------------------------------------------------------------------------------
         else {


            if ( $self->{warn_missing_profile_entry} ) {
               _log_xml_element_not_defined_in_profile(
                  {
                     name  => $node->name,
                     depth => $node->depth,
                  }
               );
            }

            # Skip to the next node
            $node->next;

         }
      },
      2 => sub {    # XML_READER_TYPE_ATTRIBUTE
                    # Not needed as attributes are processed within Elements
      },
      3 => sub {    # XML_READER_TYPE_TEXT
         if ( defined $self->{_profile}->{__record__} ) {
            for my $record ( @{ $self->{_profile}->{__record__} } ) {
               $self->_process_record( $self->{_current_key}, $node->value, $record );
            }
         }
      },
      4  => sub { },
      5  => sub { },
      6  => sub { },
      7  => sub { },
      8  => sub { },
      9  => sub { },
      10 => sub { },
      11 => sub { },
      12 => sub { },
      13 => sub { },
      14 => sub { },
      15 => sub { },
      16 => sub { },
      17 => sub { },
   };

   # Call the dispatch table with the node type
   &{ $xml_dispatch_table->{ $node->nodeType } };
}

#-------------------------------------------------------------------------------
#   Subroutine : parse_using_profile
#
#   Input      : $data = Perl Structure, $profile = Text Profile
#
#   Output     : Perl Structure
#
#   Purpose    : Processes perl structures based on input profiles
#-------------------------------------------------------------------------------
sub parse_using_profile {
   my ( $xml, $profile, %options ) = @_;

   #-------------------------------------------------------------------------------
   #  Create an internal XML::Dataset object
   #-------------------------------------------------------------------------------
   my $self = XML::Dataset->new( %options );

   #-------------------------------------------------------------------------------
   #  Create an XML::LibXML::Reader Parser object
   #-------------------------------------------------------------------------------
   my $doc = XML::LibXML::Reader->new( string => $xml );

   #-------------------------------------------------------------------------------
   #  Convert the simplified profile to a perl based profile
   #  Store the profile and process
   #-------------------------------------------------------------------------------
   $self->{_profile} = $self->_expand_profile($profile);
   $self->_process_data($doc);

   #-------------------------------------------------------------------------------
   #  Delete any __external_value__ keys
   #-------------------------------------------------------------------------------
   for my $key ( keys %{ $self->{data_structure} } ) {
      if ( $key =~ m/__external_value__/ ) {
         delete $self->{data_structure}->{$key};
      }
   }

   #-------------------------------------------------------------------------------
   #  If called with a dispatch logic, dispatch any remaining entries
   #-------------------------------------------------------------------------------
   if ( defined $self->{dispatch} ) {
      $self->_dispatch_all;
   }

   else {
      my $data_structure = $self->{data_structure};

      #-------------------------------------------------------------------------------
      #  Return the data structure to the caller
      #-------------------------------------------------------------------------------
      return $self->{data_structure};
   }

}

#-------------------------------------------------------------------------------
#   Subroutine : _expand_profile
#
#   Input      : $profile_input = Text Profile
#
#   Output     : Perl Structure
#
#   Purpose    : Turns a simple profile into a perl based structure
#-------------------------------------------------------------------------------
sub _expand_profile {
   my ( $self, $profile_input ) = @_;

   #-------------------------------------------------------------------------------
   #  Holder for the complex_profile
   #-------------------------------------------------------------------------------
   my $complex_profile          = {};
   my $complex_profile_history  = [ \$complex_profile ];
   my $current_profile_position = ${ $complex_profile_history->[-1] };

   #-------------------------------------------------------------------------------
   #  Starting indentation
   #-------------------------------------------------------------------------------
   my $indentation;
   my $previous_indentation;
   my $indentation_history = [];

   #-------------------------------------------------------------------------------
   #  Capture tokens based on carriage returns
   #-------------------------------------------------------------------------------
   my @tokens = split( "\n", $profile_input );

   #-------------------------------------------------------------------------------
   #  Process all tokens
   #-------------------------------------------------------------------------------
   for my $token (@tokens) {

      #-------------------------------------------------------------------------------
      #  If the does not contain an empty entry, or whitespace only, continue
      #-------------------------------------------------------------------------------
      if ( $token !~ m/^(\s+)?$/ ) {

         #-------------------------------------------------------------------------------
         #  Capture the token data and indentation ( if available )
         #-------------------------------------------------------------------------------
         my $token_data;

         if ( $token =~ m/^(\s+)(.*)/ ) {
            $indentation = length($1);
            $token_data  = $2;
         }
         elsif ( $token =~ m/(.*)/ ) {
            $indentation = 0;
            $token_data  = $1;
         }

         #-------------------------------------------------------------------------------
         #  Capture the previous indentation, if the previous indentation is not
         #  available, mark the previous_indentation as 0
         #-------------------------------------------------------------------------------
         $previous_indentation = ( scalar( @{$indentation_history} ) > 0 ) ? $indentation_history->[-1] : 0;

         #-------------------------------------------------------------------------------
         #  If the indentation has increased, store the indentation in the history
         #-------------------------------------------------------------------------------
         if ( $indentation > $previous_indentation ) {
            push @{$indentation_history}, $indentation;
         }

         #-------------------------------------------------------------------------------
         #  Otherwise if the indentation has decreased
         #-------------------------------------------------------------------------------
         elsif ( $previous_indentation > $indentation ) {
            while ( $previous_indentation > $indentation ) {
               pop @{$indentation_history};
               $previous_indentation = $indentation_history->[-1];
               pop @{$complex_profile_history};
               $current_profile_position = ${ $complex_profile_history->[-1] };
            }
         }

         #-------------------------------------------------------------------------------
         #  Process if the token contains an equals
         #-------------------------------------------------------------------------------
         if ( $token_data =~ m/=/ ) {

            #-------------------------------------------------------------------------------
            #  Seperate the key and record holder based on the equal
            #-------------------------------------------------------------------------------
            my ( $key, $record_holder ) = split( '=', $token_data );

            #-------------------------------------------------------------------------------
            #  Remove any whitespace from the key and record_holder <-- address with common
            #-------------------------------------------------------------------------------
            $key =~ s/^\s+//g;
            $key =~ s/\s+$//g;
            $record_holder =~ s/^\s+//g;
            $record_holder =~ s/\s+$//g;

            #-------------------------------------------------------------------------------
            #  Check for __IGNORE__, place the corresponding marker if required and
            #  move to the next record
            #-------------------------------------------------------------------------------
            if ( $record_holder =~ m/__IGNORE__/ ) {
               $current_profile_position->{$key}{'__IGNORE__'} = 1;
               next;
            }

            #-------------------------------------------------------------------------------
            #  Seperate unprocessed records from the record_holder using whitespace as
            #  the seperator
            #-------------------------------------------------------------------------------
            my @records_unprocessed = split( /\s+/, $record_holder );

            #-------------------------------------------------------------------------------
            #  If there is a marker for a __NEW_DATASET__ store the corresponding dataset
            #  names against the marker
            #-------------------------------------------------------------------------------
            if ( $key =~ m/__NEW_DATASET__/ ) {
               $current_profile_position->{__NEW_DATASET__} = \@records_unprocessed;
            }

            #-------------------------------------------------------------------------------
            #  If there is a marker for a __EXTERNAL_VALUE__ store the corresponding dataset
            #  names against the marker
            #-------------------------------------------------------------------------------
            elsif ( $key =~ m/__EXTERNAL_VALUE__/ ) {
               $current_profile_position->{__EXTERNAL_VALUE__} = \@records_unprocessed;
            }

            #-------------------------------------------------------------------------------
            #  Otherwise treat as unprocessed records
            #-------------------------------------------------------------------------------
            else {
               for my $record_unprocessed (@records_unprocessed) {

                  #-------------------------------------------------------------------------------
                  #  Initialise a hash_ref store
                  #-------------------------------------------------------------------------------
                  my $hash_ref = {};

                  #-------------------------------------------------------------------------------
                  #  For each record ( seperated by , ) store key value pair in hash_ref
                  #  ( where key values are seperated by : )
                  #-------------------------------------------------------------------------------
                  for my $record ( split( ',', $record_unprocessed ) ) {
                     my ( $record_key, $record_value ) = split( ':', $record );

                     #-------------------------------------------------------------------------------
                     #  Store the item in the profile
                     #-------------------------------------------------------------------------------
                     $hash_ref->{$record_key} = $record_value;
                  }

                  #-------------------------------------------------------------------------------
                  #  Push the hash_ref onto the profile
                  #-------------------------------------------------------------------------------
                  push( @{ $current_profile_position->{$key}->{__record__} }, $hash_ref );
               }
            }
         }

         #-------------------------------------------------------------------------------
         #  Otherwise treat the record as a structural marker
         #-------------------------------------------------------------------------------
         else {
            # Initialise the new token as an anonymous hash
            $current_profile_position->{$token_data} = {};

            # Push the new position on to the stack
            push( @{$complex_profile_history}, \$current_profile_position->{$token_data} );

            # Update the current position
            $current_profile_position = ${ $complex_profile_history->[-1] };
         }

      }

      #-------------------------------------------------------------------------------
      #  Incompatible markers holder
      #-------------------------------------------------------------------------------
      else {
      }

   }
   return $complex_profile;
}

#-------------------------------------------------------------------------------
#   Subroutine : run
#
#   Purpose    : Testing subroutine
#-------------------------------------------------------------------------------
sub _run {
   my $example_data = qq(<?xml version="1.0"?>
<catalog>
   <lowest shop="Regents Street">
      <book id="bk101">
         <author>Gambardella, Matthew</author>
         <title>XML Developer's Guide</title>
         <genre>Computer</genre>
         <price>44.95</price>
         <publish_date>2000-10-01</publish_date>
         <description>An in-depth look at creating applications 
         with XML.</description>
      </book>
      <book id="bk102">
         <author>Ralls, Kim</author>
         <title>Midnight Rain</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2000-12-16</publish_date>
         <description>A former architect battles corporate zombies, 
         an evil sorceress, and her own childhood to become queen 
         of the world.</description>
      </book>
      <book id="bk103">
         <author>Corets, Eva</author>
         <title>Maeve Ascendant</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2000-11-17</publish_date>
         <description>After the collapse of a nanotechnology 
         society in England, the young survivors lay the 
         foundation for a new society.</description>
      </book>
      <book id="bk104">
         <author>Corets, Eva</author>
         <title>Oberon's Legacy</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2001-03-10</publish_date>
         <description>In post-apocalypse England, the mysterious 
         agent known only as Oberon helps to create a new life 
         for the inhabitants of London. Sequel to Maeve 
         Ascendant.</description>
      </book>
      <book id="bk105">
         <author>Corets, Eva</author>
         <title>The Sundered Grail</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2001-09-10</publish_date>
         <description>The two daughters of Maeve, half-sisters, 
         battle one another for control of England. Sequel to 
         Oberon's Legacy.</description>
      </book>
      <book id="bk106">
         <author>Randall, Cynthia</author>
         <title>Lover Birds</title>
         <genre>Romance</genre>
         <price>4.95</price>
         <publish_date>2000-09-02</publish_date>
         <description>When Carla meets Paul at an ornithology 
         conference, tempers fly as feathers get ruffled.</description>
      </book>
      <book id="bk107">
         <author>Thurman, Paula</author>
         <title>Splish Splash</title>
         <genre>Romance</genre>
         <price>4.95</price>
         <publish_date>2000-11-02</publish_date>
         <description>A deep sea diver finds true love twenty 
         thousand leagues beneath the sea.</description>
      </book>
      <book id="bk108">
         <author>Knorr, Stefan</author>
         <title>Creepy Crawlies</title>
         <genre>Horror</genre>
         <price>4.95</price>
         <publish_date>2000-12-06</publish_date>
         <description>An anthology of horror stories about roaches,
         centipedes, scorpions  and other insects.</description>
      </book>
      <book id="bk109">
         <author>Kress, Peter</author>
         <title>Paradox Lost</title>
         <genre>Science Fiction</genre>
         <price>6.95</price>
         <publish_date>2000-11-02</publish_date>
         <description>After an inadvertant trip through a Heisenberg
         Uncertainty Device, James Salway discovers the problems 
         of being quantum.</description>
      </book>
      <book id="bk110">
         <author>O'Brien, Tim</author>
         <title>Microsoft .NET: The Programming Bible</title>
         <genre>Computer</genre>
         <price>36.95</price>
         <publish_date>2000-12-09</publish_date>
         <description>Microsoft's .NET initiative is explored in 
         detail in this deep programmer's reference.</description>
      </book>
      <book id="bk111">
         <author>O'Brien, Tim</author>
         <title>MSXML3: A Comprehensive Guide</title>
         <genre>Computer</genre>
         <price>36.95</price>
         <publish_date>2000-12-01</publish_date>
         <description>The Microsoft MSXML3 parser is covered in 
         detail, with attention to XML DOM interfaces, XSLT processing, 
         SAX and more.</description>
      </book>
      <book id="bk112">
         <author>Galos, Mike</author>
         <title>Visual Studio 7: A Comprehensive Guide</title>
         <genre>Computer</genre>
         <price>49.95</price>
         <publish_date>2001-04-16</publish_date>
         <description>Microsoft Visual Studio 7 is explored in depth,
         looking at how Visual Basic, Visual C++, C#, and ASP+ are 
         integrated into a comprehensive development 
         environment.</description>
      </book>
   </lowest>
</catalog>
);

   my $profile = qq(
   catalog
      lowest
      __NEW_EXTERNAL_VALUE_HOLDER__ = __external_value__1:number
         number = external_dataset:__external_value__1
         book
           __NEW_DATASET__ = 1 2
           id     = dataset:1,name:custom_id
           author = dataset:1 dataset:2
           title  = dataset:1 dataset:2
           genre  = dataset:1
           price  = dataset:1
           publish_date = dataset:1
           description  = dataset:1
           __EXTERNAL_VALUE__ = __external_value__1:number:1
);

   use Data::Dumper;
   print Dumper( parse_using_profile( $example_data, $profile ) );
}

1;

# ABSTRACT: Extracts XML into Perl Datasets based upon a simple text profile markup language

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Dataset - Extracts XML into Perl Datasets based upon a simple text profile markup language

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use XML::Dataset;
  use Data::Printer;

  my $example_data = qq(<?xml version="1.0"?>
  <catalog>
     <shop number="1">
        <book id="bk101">
           <author>Gambardella, Matthew</author>
           <title>XML Developer's Guide</title>
           <genre>Computer</genre>
           <price>44.95</price>
           <publish_date>2000-10-01</publish_date>
           <description>An in-depth look at creating applications 
           with XML.</description>
        </book>
        <book id="bk102">
           <author>Ralls, Kim</author>
           <title>Midnight Rain</title>
           <genre>Fantasy</genre>
           <price>5.95</price>
           <publish_date>2000-12-16</publish_date>
           <description>A former architect battles corporate zombies, 
           an evil sorceress, and her own childhood to become queen 
           of the world.</description>
        </book>
     </shop>
     <shop number="2">
        <book id="bk103">
           <author>Corets, Eva</author>
           <title>Maeve Ascendant</title>
           <genre>Fantasy</genre>
           <price>5.95</price>
           <publish_date>2000-11-17</publish_date>
           <description>After the collapse of a nanotechnology 
           society in England, the young survivors lay the 
           foundation for a new society.</description>
        </book>
        <book id="bk104">
           <author>Corets, Eva</author>
           <title>Oberon's Legacy</title>
           <genre>Fantasy</genre>
           <price>5.95</price>
           <publish_date>2001-03-10</publish_date>
           <description>In post-apocalypse England, the mysterious 
           agent known only as Oberon helps to create a new life 
           for the inhabitants of London. Sequel to Maeve 
           Ascendant.</description>
        </book>
     </shop>
  </catalog>
  );

  my $profile = qq(
     catalog
        shop
           book
             author = dataset:title_and_author
             title  = dataset:title_and_author
  );

  # Capture the output
  my $output = parse_using_profile( $example_data, $profile ); 

  # Print using Data::Printer
  p $output;

=head1 DESCRIPTION

Provides a simple means of parsing XML to return a selection of information based on a
markup profile describing the XML structure and how the structure relates to a logical grouping of information ( a dataset ).

=head1 METHODS

=head2 parse_using_profile

Parses XML based upon a profile.

  Input: XML<string>, Profile<string>

=head1 RATIONALE

I often found myself developing, adjusting and manipulating perl code using a variety of packages to extract 
XML sources into logical groupings that were relevant to the underline data as opposed to a perl structure of an entire XML source.

As well as the initial time in developing an appropriate construct to parse the source data, any future changes to the XML output 
involved additional changes to the code base.  

I wanted a simplified solution, one where I can leverage a simple markup language that I could operate on to provide the context
of interest with the necessary manipulation of data where desired.

I investigated a number of options available in the perl community to simplify the overall
process.  Whilst many excellent options are available, I did not find an option that provided
the level of simplicity that I desired.  This module is a result of the effort to fulfill this requirement.

=head1 EXAMPLES

=head2 Example 1 - Simple Dataset Extraction

=head3 Overview

The following example shows the extraction of the title and author
information from the example XML document into a dataset called title_and_author.

The XML::Dataset profile follows a similar structure to the XML with elements
indented to depict the relationship between entities.

Information that needs to be captured from within an element ( or an attribute ) is 
referenced using the <value> = dataset:<dataset_name> syntax.

=head3 Code

  use XML::Dataset;
  use Data::Printer;

  my $example_data = qq(<?xml version="1.0"?>
  <catalog>
     <shop number="1">
        <book id="bk101">
           <author>Gambardella, Matthew</author>
           <title>XML Developer's Guide</title>
           <genre>Computer</genre>
           <price>44.95</price>
           <publish_date>2000-10-01</publish_date>
           <description>An in-depth look at creating applications 
           with XML.</description>
        </book>
        <book id="bk102">
           <author>Ralls, Kim</author>
           <title>Midnight Rain</title>
           <genre>Fantasy</genre>
           <price>5.95</price>
           <publish_date>2000-12-16</publish_date>
           <description>A former architect battles corporate zombies, 
           an evil sorceress, and her own childhood to become queen 
           of the world.</description>
        </book>
     </shop>
     <shop number="2">
        <book id="bk103">
           <author>Corets, Eva</author>
           <title>Maeve Ascendant</title>
           <genre>Fantasy</genre>
           <price>5.95</price>
           <publish_date>2000-11-17</publish_date>
           <description>After the collapse of a nanotechnology 
           society in England, the young survivors lay the 
           foundation for a new society.</description>
        </book>
        <book id="bk104">
           <author>Corets, Eva</author>
           <title>Oberon's Legacy</title>
           <genre>Fantasy</genre>
           <price>5.95</price>
           <publish_date>2001-03-10</publish_date>
           <description>In post-apocalypse England, the mysterious 
           agent known only as Oberon helps to create a new life 
           for the inhabitants of London. Sequel to Maeve 
           Ascendant.</description>
        </book>
     </shop>
  </catalog>
  );

  my $profile = qq(
     catalog
        shop
           book
             author = dataset:title_and_author
             title  = dataset:title_and_author
  );

  # Capture the output
  my $output = parse_using_profile( $example_data, $profile ); 

  # Print using Data::Printer
  p $output;

=head3 Output

  \ {
      title_and_author   [
          [0] {
              author   "Gambardella, Matthew",
              title    "XML Developer's Guide"
          },
          [1] {
              author   "Ralls, Kim",
              title    "Midnight Rain"
          },
          [2] {
              author   "Corets, Eva",
              title    "Maeve Ascendant"
          },
          [3] {
              author   "Corets, Eva",
              title    "Oberon's Legacy"
          }
      ]
  }

=head2 Example 2 - Working With Multiple Datasets

=head3 Overview

This example builds upon the previous to facilitate an additional dataset of
title_and_genre.  As per the example profile, multiple datasets can be specified
through a space seperated list as per 'title' which is used for both title_and_author
and title_and_genre.

=head3 Updated Profile Code

  my $profile = qq(
     catalog
        shop
           book
             author = dataset:title_and_author
             title  = dataset:title_and_author dataset:title_and_genre
             genre  = dataset:title_and_genre
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              author   "Gambardella, Matthew",
              title    "XML Developer's Guide"
          },
          [1] {
              author   "Ralls, Kim",
              title    "Midnight Rain"
          },
          [2] {
              author   "Corets, Eva",
              title    "Maeve Ascendant"
          },
          [3] {
              author   "Corets, Eva",
              title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              genre   "Computer",
              title   "XML Developer's Guide"
          },
          [1] {
              genre   "Fantasy",
              title   "Midnight Rain"
          },
          [2] {
              genre   "Fantasy",
              title   "Maeve Ascendant"
          },
          [3] {
              genre   "Fantasy",
              title   "Oberon's Legacy"
          }
      ]
  }

=head2 Example 3 - Handling XML Attributes

=head3 Overview

XML Attributes are treated in the profile as a sub level key/value in the profile.  The
following example depicts the inclusion of the attribute 'id' in the returned datasets. Note
how id is indented under book and on the same level as author, title, genre etc.

=head3 Updated Profile Code

  my $profile = qq(
     catalog
        shop
           book
             id     = dataset:title_and_author dataset:title_and_genre
             author = dataset:title_and_author
             title  = dataset:title_and_author dataset:title_and_genre
             genre  = dataset:title_and_genre
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              author   "Gambardella, Matthew",
              id       "bk101",
              title    "XML Developer's Guide"
          },
          [1] {
              author   "Ralls, Kim",
              id       "bk102",
              title    "Midnight Rain"
          },
          [2] {
              author   "Corets, Eva",
              id       "bk103",
              title    "Maeve Ascendant"
          },
          [3] {
              author   "Corets, Eva",
              id       "bk104",
              title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              genre   "Computer",
              id      "bk101",
              title   "XML Developer's Guide"
          },
          [1] {
              genre   "Fantasy",
              id      "bk102",
              title   "Midnight Rain"
          },
          [2] {
              genre   "Fantasy",
              id      "bk103",
              title   "Maeve Ascendant"
          },
          [3] {
              genre   "Fantasy",
              id      "bk104",
              title   "Oberon's Legacy"
          }
      ]
  }

=head2 Example 4 - Using higher level data across datasets

=head3 Overview

Information that is available at a higher level to that of the specified dataset information can
be referenced and included in datasets using a combination of the external_dataset and __EXTERNAL_VALUE__ markers.  

The external_dataset marker informs the parser to store the information for later use.  It follows the format
of external_dataset:<target> where <target> is a reference name that identifies the external store.

The __EXTERNAL_VALUE__ marker informs the parser to reference a value that is or will be stored externally.  It 
follows the format of __EXTERNAL_VALUE__ = <external_store>:<external_value>:<target_dataset>

Optionally the __EXTERNAL_VALUE__ marker can receive an additional parameter of :<override_name> making the full
syntax <external_store>:<external_value>:<target_dataset>:<override_name>

=head3 Updated Profile Code

  my $profile = qq(
     catalog
        shop
           number   = external_dataset:shop_information
           book
             id     = dataset:title_and_author dataset:title_and_genre
             author = dataset:title_and_author
             title  = dataset:title_and_author dataset:title_and_genre
             genre  = dataset:title_and_genre
             __EXTERNAL_VALUE__ = shop_information:number:title_and_author shop_information:number:title_and_genre
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              author   "Gambardella, Matthew",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              author   "Ralls, Kim",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              author   "Corets, Eva",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              author   "Corets, Eva",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              genre    "Computer",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              genre    "Fantasy",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              genre    "Fantasy",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              genre    "Fantasy",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ]
  }

=head2 Example 5 - Optional Dataset Parameters: name

=head3 Overview

Dataset declarations can receive additional parameters through comma seperated inclusions.  In this example
the XML element of 'genre' is renamed to 'style' during processing using the name declaration.

=head3 Updated Profile Code

  my $profile = qq(
     catalog
        shop
           number   = external_dataset:shop_information
           book
             id     = dataset:title_and_author dataset:title_and_genre
             author = dataset:title_and_author
             title  = dataset:title_and_author dataset:title_and_genre
             genre  = dataset:title_and_genre,name:style
             __EXTERNAL_VALUE__ = shop_information:number:title_and_author shop_information:number:title_and_genre
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              author   "Gambardella, Matthew",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              author   "Ralls, Kim",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              author   "Corets, Eva",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              author   "Corets, Eva",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              id       "bk101",
              number   1,
              style    "Computer",
              title    "XML Developer's Guide"
          },
          [1] {
              id       "bk102",
              number   1,
              style    "Fantasy",
              title    "Midnight Rain"
          },
          [2] {
              id       "bk103",
              number   2,
              style    "Fantasy",
              title    "Maeve Ascendant"
          },
          [3] {
              id       "bk104",
              number   2,
              style    "Fantasy",
              title    "Oberon's Legacy"
          }
      ]
  }

=head2 Example 6 - Optional Dataset Parameters: prefix

=head3 Overview

The prefix declaration assigns a prefix to the assignment name, for example genre with a prefix of shop_information_ will
become shop_information_genre

For consistency, in this example, the external information of name uses the additional optional parameter of :<override_name> as mentioned in Example 4 to override the external name 

=head3 Updated Profile Code

  my $profile = qq(
     catalog
        shop
           number   = external_dataset:shop_information
           book
             id     = dataset:title_and_author,prefix:shop_information_ dataset:title_and_genre,prefix:shop_information_
             author = dataset:title_and_author,prefix:shop_information_
             title  = dataset:title_and_author,prefix:shop_information_ dataset:title_and_genre,prefix:shop_information_
             genre  = dataset:title_and_genre,prefix:shop_information_
             __EXTERNAL_VALUE__ = shop_information:number:title_and_author:shop_information_number shop_information:number:title_and_genre:shop_information_number
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              shop_information_author   "Gambardella, Matthew",
              shop_information_id       "bk101",
              shop_information_number   1,
              shop_information_title    "XML Developer's Guide"
          },
          [1] {
              shop_information_author   "Ralls, Kim",
              shop_information_id       "bk102",
              shop_information_number   1,
              shop_information_title    "Midnight Rain"
          },
          [2] {
              shop_information_author   "Corets, Eva",
              shop_information_id       "bk103",
              shop_information_number   2,
              shop_information_title    "Maeve Ascendant"
          },
          [3] {
              shop_information_author   "Corets, Eva",
              shop_information_id       "bk104",
              shop_information_number   2,
              shop_information_title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              shop_information_genre    "Computer",
              shop_information_id       "bk101",
              shop_information_number   1,
              shop_information_title    "XML Developer's Guide"
          },
          [1] {
              shop_information_genre    "Fantasy",
              shop_information_id       "bk102",
              shop_information_number   1,
              shop_information_title    "Midnight Rain"
          },
          [2] {
              shop_information_genre    "Fantasy",
              shop_information_id       "bk103",
              shop_information_number   2,
              shop_information_title    "Maeve Ascendant"
          },
          [3] {
              shop_information_genre    "Fantasy",
              shop_information_id       "bk104",
              shop_information_number   2,
              shop_information_title    "Oberon's Legacy"
          }
      ]
  }

=head2 Example 7 - Optional Dataset Parameters: process

=head3 Overview

The process parameter can be used for inline manipulation of data.  In this example the
author is passed through a simple subroutine that returns an uppercase value.

The parser expects methods specified by the process declaration to be available to the
main namespace.

=head3 Updated Profile Code and Supporting Process Subroutine

  sub return_uc {
     return uc($_[0]);
  }

  my $profile = qq(
     catalog
        shop
           number   = external_dataset:shop_information
           book
             id     = dataset:title_and_author dataset:title_and_genre
             author = dataset:title_and_author,process:return_uc
             title  = dataset:title_and_author dataset:title_and_genre
             genre  = dataset:title_and_genre
             __EXTERNAL_VALUE__ = shop_information:number:title_and_author shop_information:number:title_and_genre
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              author   "GAMBARDELLA, MATTHEW",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              author   "RALLS, KIM",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              author   "CORETS, EVA",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              author   "CORETS, EVA",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              genre    "Computer",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              genre    "Fantasy",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              genre    "Fantasy",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              genre    "Fantasy",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ]
  }

=head2 Example 8 - Hinting for new datasets

=head3 Overview

During processing, the parser looks for indicators that it should create a new dataset.
As an example, when new data is encountered rather than overriding the existing data, a
new dataset is created.  Unfortunately this may lead to unexpected results when working
with poorly structured input where subsets of information may be missing from the XML
structure.

To mitigate this, the hint __NEW_DATASET__ = <dataset> is available to force the creation
of a new dataset upon entering a block.

If there are any concerns about the consistency of the XML document then it is recommended
that the __NEW_DATASET__ declaration is made within all respective blocks as part of the profile
definition.

=head3 Updated Profile Code and Supporting Process Subroutine

  sub return_uc {
     return uc($_[0]);
  }

  my $profile = qq(
     catalog
        shop
           number   = external_dataset:shop_information
           book
             __NEW_DATASET__ = title_and_author title_and_genre
             id     = dataset:title_and_author dataset:title_and_genre
             author = dataset:title_and_author,process:return_uc
             title  = dataset:title_and_author dataset:title_and_genre
             genre  = dataset:title_and_genre
             __EXTERNAL_VALUE__ = shop_information:number:title_and_author shop_information:number:title_and_genre
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              author   "GAMBARDELLA, MATTHEW",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              author   "RALLS, KIM",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              author   "CORETS, EVA",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              author   "CORETS, EVA",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              genre    "Computer",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              genre    "Fantasy",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              genre    "Fantasy",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              genre    "Fantasy",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ]
  }

=head2 Example 9 - Hinting for higher level data

=head3 Overview

There may be occasions where information at a parallel level is required and subsequently,
that information appears after the desired dataset information.  To accomodate this, 
the __NEW_EXTERNAL_VALUE_HOLDER__ marker is available.  

This can be used to create a stub store for the holder before it is actually processed by the parser.  
As the module uses aliases internally, the dataset is updated with a pointer which is subsequently
updated to reflect the appropriate value as and when it is reached by the parser.

The XML example has been updated to include an information section that details the
shop location.

__NEW_EXTERNAL_VALUE_HOLDER__ is declared at the corresponding indentation with a value of shop_information:address 
This tells the parser to store an externally referencable marker with a default value of '' -

  shop
     __NEW_EXTERNAL_VALUE_HOLDER__ = shop_information:address

The shop_information:address:title_and_author entry under __EXTERNAL_VALUE__ informs the parser to lookup
the externally stored value and store this value in the dataset, at which point storing the exising default
value -

  __EXTERNAL_VALUE__ = shop_information:number:title_and_author shop_information:number:title_and_genre

The indentation of information and address tells the parser to update the external_dataset entry for shop_information, 
subsequently updating the default value and reflecting the value where applicable across the desired datasets.

  information
    address = external_dataset:shop_information

=head3 Updated Profile Code and Supporting Process Subroutine

  sub return_uc {
     return uc($_[0]);
  }

  my $profile = qq(
     catalog
        shop
           __NEW_EXTERNAL_VALUE_HOLDER__ = shop_information:address
           number   = external_dataset:shop_information
           book
             __NEW_DATASET__ = title_and_author title_and_genre
             id     = dataset:title_and_author dataset:title_and_genre
             author = dataset:title_and_author,process:return_uc
             title  = dataset:title_and_author dataset:title_and_genre
             genre  = dataset:title_and_genre
             __EXTERNAL_VALUE__ = shop_information:number:title_and_author shop_information:number:title_and_genre shop_information:address:title_and_author shop_information:address:title_and_genre
           information
             address = external_dataset:shop_information
  );

=head3 Output

  \ {
      title_and_author   [
          [0] {
              address   "Regents Street",
              author    "GAMBARDELLA, MATTHEW",
              id        "bk101",
              number    1,
              title     "XML Developer's Guide"
          },
          [1] {
              address   "Regents Street",
              author    "RALLS, KIM",
              id        "bk102",
              number    1,
              title     "Midnight Rain"
          },
          [2] {
              address   "Oxford Street",
              author    "CORETS, EVA",
              id        "bk103",
              number    2,
              title     "Maeve Ascendant"
          },
          [3] {
              address   "Oxford Street",
              author    "CORETS, EVA",
              id        "bk104",
              number    2,
              title     "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              address   "Regents Street",
              genre     "Computer",
              id        "bk101",
              number    1,
              title     "XML Developer's Guide"
          },
          [1] {
              address   "Regents Street",
              genre     "Fantasy",
              id        "bk102",
              number    1,
              title     "Midnight Rain"
          },
          [2] {
              address   "Oxford Street",
              genre     "Fantasy",
              id        "bk103",
              number    2,
              title     "Maeve Ascendant"
          },
          [3] {
              address   "Oxford Street",
              genre     "Fantasy",
              id        "bk104",
              number    2,
              title     "Oberon's Legacy"
          }
      ]
  }

=head2 The use of Data::Printer vs Data::Dumper within the examples

I'm a long time advocate of Data::Dumper.  Data::Printer is also an excellent module.  In
the examples, for clarity purposes Data::Printer was chosen over Data::Dumper owing to the display differences that
result from the internal use of Data::Alias.

As an example, here is the output from Example 4 depicted through Data::Dumper and Data::Printer.

It's important to understand the internal structure of the datasets if you plan on making changes to the
returned information.

=head3 Using Data::Printer

  \ {
      title_and_author   [
          [0] {
              author   "Gambardella, Matthew",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              author   "Ralls, Kim",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              author   "Corets, Eva",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              author   "Corets, Eva",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ],
      title_and_genre    [
          [0] {
              genre    "Computer",
              id       "bk101",
              number   1,
              title    "XML Developer's Guide"
          },
          [1] {
              genre    "Fantasy",
              id       "bk102",
              number   1,
              title    "Midnight Rain"
          },
          [2] {
              genre    "Fantasy",
              id       "bk103",
              number   2,
              title    "Maeve Ascendant"
          },
          [3] {
              genre    "Fantasy",
              id       "bk104",
              number   2,
              title    "Oberon's Legacy"
          }
      ]
  }

=head3 Using Data::Dumper

  $VAR1 = \{
              'title_and_genre' => [
                                     {
                                       'number' => '1',
                                       'title' => 'XML Developer\'s Guide',
                                       'id' => 'bk101',
                                       'genre' => 'Computer'
                                     },
                                     {
                                       'number' => ${\${$VAR1}->{'title_and_genre'}->[0]->{'number'}},
                                       'title' => 'Midnight Rain',
                                       'id' => 'bk102',
                                       'genre' => 'Fantasy'
                                     },
                                     {
                                       'number' => '2',
                                       'title' => 'Maeve Ascendant',
                                       'id' => 'bk103',
                                       'genre' => 'Fantasy'
                                     },
                                     {
                                       'number' => ${\${$VAR1}->{'title_and_genre'}->[2]->{'number'}},
                                       'title' => 'Oberon\'s Legacy',
                                       'id' => 'bk104',
                                       'genre' => 'Fantasy'
                                     },
                                     {
                                       'number' => '1',
                                       'title' => 'XML Developer\'s Guide',
                                       'id' => 'bk101',
                                       'genre' => 'Computer'
                                     },
                                     {
                                       'number' => ${\${$VAR1}->{'title_and_genre'}->[4]->{'number'}},
                                       'title' => 'Midnight Rain',
                                       'id' => 'bk102',
                                       'genre' => 'Fantasy'
                                     },
                                     {
                                       'number' => '2',
                                       'title' => 'Maeve Ascendant',
                                       'id' => 'bk103',
                                       'genre' => 'Fantasy'
                                     },
                                     {
                                       'number' => ${\${$VAR1}->{'title_and_genre'}->[6]->{'number'}},
                                       'title' => 'Oberon\'s Legacy',
                                       'id' => 'bk104',
                                       'genre' => 'Fantasy'
                                     }
                                   ],
              'title_and_author' => [
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[0]->{'number'}},
                                        'title' => 'XML Developer\'s Guide',
                                        'author' => 'Gambardella, Matthew',
                                        'id' => 'bk101'
                                      },
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[0]->{'number'}},
                                        'title' => 'Midnight Rain',
                                        'author' => 'Ralls, Kim',
                                        'id' => 'bk102'
                                      },
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[2]->{'number'}},
                                        'title' => 'Maeve Ascendant',
                                        'author' => 'Corets, Eva',
                                        'id' => 'bk103'
                                      },
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[2]->{'number'}},
                                        'title' => 'Oberon\'s Legacy',
                                        'author' => 'Corets, Eva',
                                        'id' => 'bk104'
                                      },
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[4]->{'number'}},
                                        'title' => 'XML Developer\'s Guide',
                                        'author' => 'Gambardella, Matthew',
                                        'id' => 'bk101'
                                      },
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[4]->{'number'}},
                                        'title' => 'Midnight Rain',
                                        'author' => 'Ralls, Kim',
                                        'id' => 'bk102'
                                      },
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[6]->{'number'}},
                                        'title' => 'Maeve Ascendant',
                                        'author' => 'Corets, Eva',
                                        'id' => 'bk103'
                                      },
                                      {
                                        'number' => ${\${$VAR1}->{'title_and_genre'}->[6]->{'number'}},
                                        'title' => 'Oberon\'s Legacy',
                                        'author' => 'Corets, Eva',
                                        'id' => 'bk104'
                                      }
                                    ]
            };

=head1 SEE ALSO

Standing on the shoulders of giants, this module leverages the excellent XML::LibXML::Reader
which itself is built upon the powerful libxml2 library.  XML::LibXML::Reader uses an iterator
approach to parsing XML documents, resulting in an approach that is easier to program than
an event based parser (SAX) and much more lightweight than a tree based parser (DOM) which
loads the complete tree into memory.  

This was a particular consideration in the choice of scaffolding chosen for this module.

Data::Alias is utilised internally for lookback operations.  The module allows you to apply "aliasing semantics" 
to a section of code, causing aliases to be made wherever Perl would normally make copies instead. You can use 
this to improve efficiency and readability, when compared to using references.

=head1 THANKS

Thanks to the following for support, advice and feedback -

=over 4

=item Geoff Baldry

=item Hayley Hunt

=item Kordian Witek

=item Matej Sip - <sip.matej@gmail.com>

=item Sofia Blee

=item Vivek Chhikara - <chhikara.vivek@gmail.com>

=back

=for :list * LXML::LibXML::Reader
* LData::Alias

=head1 AUTHOR

James Spurin <james@spurin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by James Spurin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
