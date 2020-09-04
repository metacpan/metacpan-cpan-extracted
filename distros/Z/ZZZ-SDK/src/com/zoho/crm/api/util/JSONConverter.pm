#use strict;
package JSONConverter;

use warnings;
use JSON;
use Scalar::Util::Numeric qw(isint isfloat);
use src::com::zoho::crm::api::util::Converter;
use src::com::zoho::crm::api::Initializer;
use src::com::zoho::crm::api::util::DataTypeConverter;
use src::com::zoho::crm::api::util::Constants;
use src::com::zoho::crm::api::util::Choice;
use Data::Dumper ;
use Cwd qw(realpath);
use List::MoreUtils qw(first_index);
use File::Spec::Functions qw(catfile);

use Moose;
use Try::Catch;
use Log::Handler;

extends 'Converter';
has 'unique_hash' => (is => "rw");

# sub file_to_package_name {
#     my $filepath = shift;
#     print "Received file path ";
#     print "$filepath" . "\n";
#     my @spl = split "/", $filepath;
#     #only if the string contains /, do this, else just return whatever received.
#     if(index($filepath, "/") != -1)
#     {
#         my $is_com_read = 0;
#         my $package_str = "";
#         foreach(@spl)
#         {
#             if (!$is_com_read && "$_" eq "com")
#             {
#                 $is_com_read = 1;
#                 $package_str = $package_str . "com";
#             }
#             elsif($is_com_read)
#             {
#                 $package_str = $package_str . "." . $_;
#             }
#         }
#         print substr($package_str,0,-3);
#         $filepath = substr($package_str,0,-3);
#     }

#     return $filepath;
# }

sub is_not_record_request
{
    my ($self, $request_instance, $class_detail, $instance_number) = @_;

    my $request_json = {};

    my %class_detail = %{$class_detail};

    foreach my $member_name (keys %class_detail)
    {
        my $member_detail = $class_detail{$member_name};

        my %member_detail = %{$member_detail};

        if(exists($member_detail{$Constants::READ_ONLY}) || !exists($member_detail{$Constants::NAME}))
        {
            next;
        }

        my $key_name = $member_detail{$Constants::NAME};

        my $modification = $request_instance->$Constants::IS_MODIFIED_METHOD($key_name);

        my $field_value = undef;

        if(defined($modification) && $modification != 0)
        {
            $field_value = $request_instance->{$member_name};
        }

        unless(defined($field_value))
        {
            $self->mandatory_check($member_name, \%member_detail, $modification);
        }

        if(defined($modification) && $modification != 0 && $self->value_checker(blessed($request_instance), $member_name, $member_detail, $field_value, $self->{unique_hash}, $instance_number))
        {
            $key_name = $member_detail{$Constants::NAME};

            if($request_instance->isa('record::FileDetails'))
            {
                if(lc($key_name) eq lc($Constants::ATTACHMENT_ID))
                {
                    $request_json->{lc($key_name)} = $field_value;
                }
                elsif(lc($key_name) eq lc($Constants::FILE_ID))
                {
                    $request_json->{lc($key_name)} = $field_value;
                }
                else
                {
                    $request_json->{$key_name} = $field_value;
                }
            }
            else
            {
                $request_json->{$key_name} = $self->set_data($member_detail, $field_value);
            }
        }
    }

    return $request_json;
}

sub is_record_request
{
    my ($self, $record_instance, $class_detail, $instance_number) = @_;

    my $request_json = {};

    my $module_detail = ();

    my $module_api_name = $self->{common_api_handler}->{module_api_name};

    unless($module_api_name eq '')
    {
        $self->{common_api_handler}->{module_api_name} = undef;

        my $full_detail = Utility::search_json_details($module_api_name);

        if(defined($full_detail))
        {
            my %full_detail = %{$full_detail};

            $module_detail = $full_detail{$Constants::MODULEDETAILS};
        }
        else
        {
            $module_detail = $self->get_module_detail_from_user_spec_json($module_api_name);
        }
    }
    else
    {
        $module_detail = $class_detail;

        my $init = Initializer::get_json_details();

        my %json_details = %{$init};

        $class_detail  = $json_details{$Constants::RECORD_NAMESPACE};
    }

    my %module_detail = %{$module_detail};

    my %class_detail = %{$class_detail};

    my $key_values = $record_instance->{key_values};

    my %key_values = %{$key_values};

    my $key_modified = $record_instance->{key_modified};

    my %key_modified = %{$key_modified};

    my @primary_keys = ();

    my @required_keys = ();

    if(defined($module_api_name))
    {
        foreach my $key_name (keys %module_detail)
        {
            my $key_detail = $module_detail{$key_name};

            my %key_detail = %{$key_detail};

            if(exists($key_detail{$Constants::REQUIRED}) && $key_detail{$Constants::REQUIRED})
            {
                push(@required_keys, $key_detail{$Constants::NAME});
            }

            if(exists($key_detail{$Constants::PRIMARY}) && $key_detail{$Constants::PRIMARY})
            {
                push(@primary_keys, $key_detail{$Constants::NAME});
            }
        }

        foreach my $key_name (keys %class_detail)
        {
            my $key_detail = $class_detail{$key_name};

            my %key_detail = %{$key_detail};

            if(exists($key_detail{$Constants::REQUIRED}) && $key_detail{$Constants::REQUIRED})
            {
                push(@required_keys, $key_detail{$Constants::NAME});
            }

            if(exists($key_detail{$Constants::PRIMARY}) && $key_detail{$Constants::PRIMARY})
            {
                push(@primary_keys, $key_detail{$Constants::NAME});
            }
        }
    }

    my $primary_keys_size = @primary_keys;

    foreach my $key_name (keys %key_modified)
    {
        if($key_modified{$key_name} != 1)
        {
            next;
        }

        my $key_detail = ();

        my $key_value = exists($key_values{$key_name}) ? $key_values{$key_name} : undef;

        my $json_value = undef;

        my $member_name = $self->build_name($key_name);

        if(keys(%module_detail) > 0 && (exists($module_detail{$key_name}) || exists($module_detail{$member_name})))
        {
            if(exists($module_detail{$key_name}))
            {
                $key_detail = $module_detail{$key_name};
            }
            else
            {
                $key_detail = $module_detail{$member_name};
            }
        }
        elsif(exists($class_detail{$member_name}))
        {
            $key_detail = $class_detail{$member_name};
        }

        my %key_detail = %{$key_detail};

        if(keys(%key_detail) > 0)
        {
            if(exists($key_detail{$Constants::READ_ONLY}) || !exists($key_detail{$Constants::NAME}))
            {
                next;
            }

            unless(defined($key_value))
            {
                $self->mandatory_check()
            }

            if($self->value_checker(blessed($record_instance), $key_name, $key_detail, $key_value, $self->{unique_hash}, $instance_number))
            {
                $json_value = $self->set_data($key_detail, $key_value);
            }
        }
        else
        {
            $key_value = $self->redirector_for_object_to_json($key_value);
        }

        my $primary_index = first_index {$_ eq $key_name} @primary_keys;

        my $required_index = first_index {$_ eq $key_name} @required_keys;

        unless($primary_index == -1)
        {
            splice(@primary_keys, $primary_index, 1);
        }

        unless($required_index == -1)
        {
            splice(@required_keys, $required_index, 1);
        }

        $request_json->{$key_name} = $json_value;
    }

    my $primary_size = @primary_keys;

    my $required_size = @required_keys;

    if($required_size > 0 && defined($module_api_name) && (defined($self->{common_api_handler}->{mandatory_checker}) && $self->{common_api_handler}->{mandatory_checker}) && uc($self->{common_api_handler}->{category_method}) eq $Constants::REQUEST_CATEGORY_CREATE)
    {
        die SDKException->new($Constants::MANDATORY_VALUE_MISSING_ERROR, $Constants::MANDATORY_KEY_MISSING_ERROR . join(',', @required_keys));
    }

    if($primary_keys_size == $primary_size && defined($module_api_name) && (defined($self->{common_api_handler}->{mandatory_checker}) && $self->{common_api_handler}->{mandatory_checker}) && uc($self->{common_api_handler}->{category_method}) eq $Constants::REQUEST_CATEGORY_UPDATE)
    {
        die SDKException->new($Constants::MANDATORY_VALUE_MISSING_ERROR, $Constants::MANDATORY_KEY_MISSING_ERROR . join(',', @primary_keys));
    }

    return $request_json;
}

sub mandatory_check
{
    my($self, $member_name, $member_detail, $modification) = @_;

    my %member_detail = %{$member_detail};

    my $is_required = exists($member_detail{$Constants::REQUIRED}) ? $member_detail{$Constants::REQUIRED} : 0;

    my $is_primary = exists($member_detail{$Constants::PRIMARY}) ? $member_detail{$Constants::PRIMARY} : 0;

    if($is_required && uc($self->{common_api_handler}->{category_method}) eq $Constants::REQUEST_CATEGORY_CREATE)
    {
        die SDKException->new($modification eq '' ? $Constants::MANDATORY_VALUE_MISSING_ERROR : $Constants::MANDATORY_KEY_NULL_ERROR, $modification eq '' ? ($Constants::MANDATORY_KEY_MISSING_ERROR . $member_name) : ($Constants::MANDATORY_KEY_NULL_ERROR . $member_name));
    }

    if($is_required && $modification == 1 && uc($self->{common_api_handler}->{category_method}) eq $Constants::REQUEST_CATEGORY_UPDATE)
    {
        die SDKException->new($Constants::MANDATORY_KEY_NULL_ERROR, $Constants::MANDATORY_VALUE_NULL_ERROR . $member_name);
    }

    if($is_primary && uc($self->{common_api_handler}->{category_method}) eq $Constants::REQUEST_CATEGORY_UPDATE && !($self->{common_api_handler}->{mandatory_checker} != '' && $self->{common_api_handler}->{mandatory_checker}))
    {
        die SDKException->new($modification eq '' ? $Constants::MANDATORY_VALUE_MISSING_ERROR : $Constants::MANDATORY_KEY_NULL_ERROR, $modification eq '' ? ($Constants::MANDATORY_KEY_MISSING_ERROR . $member_name) : ($Constants::MANDATORY_KEY_NULL_ERROR . $member_name));
    }
}

sub form_request
{
    my ($self, $request_instance, $pack, $instance_number) = @_;

    my $package_path = "";

    my $init = Initializer::get_json_details();

    my %json_details = %{$init};

    $pack =~ s/::/./;

     $package_path = $self->find_class_path($pack, \%json_details);

    my $class_json_details = $json_details{$package_path};

    my %class_json_details = %{$class_json_details};

    my $request_hash = {};

    if(exists($class_json_details{$Constants::INTERFACE}) && !$class_json_details{$Constants::INTERFACE} eq '')
    {
        my $request_class_path = $package_path;

        my @classes = $class_json_details{$Constants::CLASSES};

        foreach(@classes)
        {
            my $request_class_lower = lc($request_class_path);

            my $class_lower = lc("$_");

            if($request_class_lower eq $class_lower)
            {
                %class_json_details = $json_details{"$_"};

                last;
            }
        }
    }

    if(blessed($request_instance) && $request_instance->isa('record::Record'))
    {
        my $module_api_name = $self->{common_api_handler}->{module_api_name};

        my $return_json = $self->is_record_request($request_instance, $class_json_details, $instance_number);

        $self->{common_api_handler}->{module_api_name} = $module_api_name;

        return $return_json;
    }
    else
    {
        return $self->is_not_record_request($request_instance, $class_json_details, $instance_number);
    }
    # foreach my $key (keys %class_json_details)
    # {
    #
    #     my $member_json_details = $class_json_details{$key};
    #
    #     my %member_json_details=%{$member_json_details};
    #
    #     if(exists($class_json_details{$Constants::READ_ONLY}) || !exists($member_json_details{$Constants::NAME}))
    #     {
    #         next;
    #     }
    #
    #     my $is_modified_method = "is_key_modified";
    #
    #     my $set_key_modified_method = "set_key_modified";
    #
    #     my $modified = $request_object->$is_modified_method($key);
    #
    #     #required check and throw exception
    #     if ($modified eq '' && exists($member_json_details{$Constants::REQUIRED}))
    #     {
    #         my %error=();
    #
    #         $error{$Constants::INDEX}=$instance_number;
    #
    #         $error{$Constants::CLASS}=$pack;
    #
    #         $error{$Constants::FIELD}=$key;
    #
    #         die SDKException->new({code =>$Constants::REQUIRED_FIELD_ERROR},{message =>''},{details => \%error},{cause =>''});
    #     }
    #
    #     my $member_data = $request_object->{$key};
    #
    #     if(!$modified eq '' && $self->value_checker($pack,$key,$member_json_details,$member_data,$self->{unique_hash},$instance_number))#add value_checker
    #     {
    #
    #         $request_object->$set_key_modified_method(0, $key);
    #
    #         my $key_name = $member_json_details{$Constants::NAME};
    #
    #         my $type = $member_json_details{$Constants::TYPE};
    #
    #         if("$type" eq "List")
    #         {
    #             my @array=$self->set_json_array($member_data, $member_json_details);
    #
    #             $request_hash->{$key_name} =[@array];
    #         }
    #         elsif("$type" eq "Map" || "$type" eq "HashMap")
    #         {
    #             $request_hash->{$key_name} = $self->set_json_object($member_data, \%member_json_details);
    #         }
    #         elsif(exists($member_json_details{$Constants::STRUCTURE_NAME}))
    #         {
    #             $request_hash->{$key_name} = $self->form_request($member_data, $member_json_details{$Constants::STRUCTURE_NAME}, 1);
    #         }
    #         else
    #         {
    #             $request_hash->{$key_name} = DataTypeConverter::post_convert($member_data, $type);
    #         }
    #     }
    # }
    #
    # if($package_path eq 'com.zoho.crm.api.record.Record')
    # {
    #
    #     use JSON::Parse 'json_file_to_perl';
    #
    #     my $record_field_details_path =  $self->get_record_json_file_path();
    #
    #     my $record_json= json_file_to_perl($record_field_details_path);
    #
    #     my %record_json = %{$record_json};
    #
    #     if(!($self->{common_api_handler}->{module_api_name} eq ''))
    #     {
    #         return $request_hash;
    #     }
    #     my $record_json_details= $record_json{$self->{common_api_handler}->{module_api_name}};
    #
    #     my %record_json_details = %{$record_json_details};
    #
    #     if(!%record_json_details)
    #     {
    #         return $request_hash;
    #     }
    #
    #     my $key_values = $request_object->{'key_values'};
    #
    #     my %key_values = %{$key_values};
    #
    #     foreach my $key_name (keys %record_json_details)
    #     {
    #         my $key_json_details=$record_json_details{$key_name};
    #
    #         my %key_json_details= %{$key_json_details};
    #
    #         if(exists($key_values{$key_name}))
    #         {
    #             my $key_value;
    #
    #             if(exists($key_json_details{$Constants::STRUCTURE_NAME}))
    #             {
    #                 $key_value = $self->form_request($key_values{$key_name},$key_json_details{$Constants::STRUCTURE_NAME},1);
    #             }
    #             else
    #             {
    #                 $key_value = $key_values{$key_name};
    #             }
    #
    #             $request_hash->{$key_name}=$key_value;
    #         }
    #     }
    # }

  }

  sub append_to_request
  {
      my $JSON = JSON->new->utf8;

      my ($class, $request_base, $request_object) = @_;

      my $request_body = $request_object->{request_body};

      my $body = $JSON->encode($request_body);

      # $request_object->{request_body} = $body;

      return $body;
  }

sub get_data
{
    my ($self, $key_data, $member_detail) = @_;

    my $member_value = undef;

    my %member_detail = %{$member_detail};

    unless($key_data eq undef)
    {
        my $type = $member_detail{$Constants::TYPE};

        if("$type" eq $Constants::LIST_NAMESPACE)
        {
            my @instance_value = $self->get_collections_data($key_data, $member_detail);
            $member_value = [@instance_value];
        }
        elsif("$type" eq $Constants::MAP_NAMESPACE)
        {
            $member_value = $self->get_map_data($key_data, $member_detail);
        }
        elsif("$type" eq $Constants::CHOICE_NAMESPACE || (exists($member_detail{$Constants::STRUCTURE_NAME}) && $member_detail{$Constants::STRUCTURE_NAME} eq $Constants::CHOICE_NAMESPACE))
        {
            $member_value = Choice->new($key_data);
        }
        elsif(exists($member_detail{$Constants::STRUCTURE_NAME}) && exists($member_detail{$Constants::MODULE}))
        {
            $member_value = $self->is_record_response($key_data, $self->get_module_detail_from_user_spec_json($member_detail{$Constants::MODULE}),$member_detail{$Constants::STRUCTURE_NAME});
        }
        elsif(exists($member_detail{$Constants::STRUCTURE_NAME}))
        {
            $member_value = $self->get_response($key_data, $member_detail{$Constants::STRUCTURE_NAME});
        }
        else
        {
            $member_value = DataTypeConverter::pre_convert($key_data, $type);
        }
    }

    return $member_value;
}

sub set_data
{
    my($self, $member_detail, $field_value) = @_;

    my %member_detail = %{$member_detail};

    unless($field_value eq undef)
    {
        my $type = $member_detail{$Constants::TYPE};

        if("$type" eq $Constants::LIST_NAMESPACE)
        {
            return $self->set_json_array($field_value, $member_detail);
        }
        elsif("$type" eq $Constants::MAP_NAMESPACE)
        {
            return $self->set_json_object($field_value, $member_detail)
        }
        elsif("$type" eq $Constants::CHOICE_NAMESPACE || (exists($member_detail{$Constants::STRUCTURE_NAME}) && $member_detail{$Constants::STRUCTURE_NAME} eq $Constants::CHOICE_NAMESPACE))
        {
            return $field_value->get_value();
        }
        elsif(exists($member_detail{$Constants::STRUCTURE_NAME}) && exists($member_detail{$Constants::MODULE}))
        {
            return $self->is_record_request($field_value, $self->get_module_detail_from_user_spec_json($member_detail{$Constants::MODULE}), 0);
        }
        elsif(exists($member_detail{$Constants::STRUCTURE_NAME}))
        {
            return $self->form_request($field_value, $member_detail{$Constants::STRUCTURE_NAME}, 1);
        }
        else
        {
            return DataTypeConverter::post_convert($field_value, $type);
        }
    }

    return undef;
}

  sub set_json_object
  {
      my ($self, $field_value, $member_detail) = @_;

      my %member_detail = %{$member_detail};

      my %request_object = %{$field_value};

      my %json_object = ();

      my $size = keys(%request_object);

      if($size > 0)
      {
          if(!%member_detail || (%member_detail && !exists($member_detail{$Constants::KEYS})))
          {
              foreach my $key (keys %request_object)
              {
                  my $value = $request_object{$key};

                  $json_object{$key} = $self->redirector_for_object_to_json($value);
              }
          }
          else
          {
              if(exists($member_detail{$Constants::KEYS}))
              {
                  my @keys_detail = $member_detail{$Constants::KEYS};

                  foreach(@keys_detail)
                  {
                      my $key_detail = $_;

                      my %key_detail = %{$key_detail};

                      my $key_name = $key_detail{$Constants::NAME};

                      if(exists($member_detail{$key_name}) && !$member_detail{$key_name} eq '')
                      {
                          my $key_value = $self->set_data($key_detail, $request_object{$key_name});

                          $json_object{$key_name} = $key_value;
                      }
                  }
              }
          }
      }

      return %json_object;
  }

  sub set_json_array
  {
      my ($self, $field_value, $member_detail) = @_;

      my %member_detail = %{$member_detail};

      my @json_array = ();

      my @request_objects = @$field_value;

      my $size = keys(@request_objects);

      if($size > 0)
      {
          if(!%member_detail || (%member_detail && !exists($member_detail{$Constants::STRUCTURE_NAME})))
          {
              foreach(@$field_value)
              {
                  push(@json_array, $self->redirector_for_object_to_json("$_"));
              }
          }
          else
          {
              my $pack = $member_detail{$Constants::STRUCTURE_NAME};

              if($pack eq $Constants::CHOICE_NAMESPACE)
              {
                  for my $k (@request_objects)
                  {
                      push(@json_array, $k->get_value());
                  }
              }
              elsif(exists($member_detail{$Constants::MODULE}) && !($member_detail{$Constants::MODULE} eq ''))
              {
                  my $instance_no = 0;

                  for my $k (@request_objects)
                  {
                      push(@json_array, $self->is_record_request($k, $self->get_module_detail_from_user_spec_json($member_detail{$Constants::MODULE}), $instance_no));

                      $instance_no += 1;
                  }
              }
              else
              {
                  my $instance_no = 0;

                  for my $k (@request_objects)
                  {
                      push(@json_array, $self->form_request($k, $pack, $instance_no));

                      $instance_no += 1;
                  }
              }
          }
      }

      return \@json_array;
  }

  sub redirector_for_object_to_json
  {
      my ($self, $member_data) = @_;

      if(ref($member_data) eq "HASH")
      {
          return $self->set_json_object($member_data, undef);
      }
      elsif(ref($member_data) eq "ARRAY")
      {
          return $self->set_json_array($member_data, undef);
      }
      else
      {
          return $member_data;
      }
  }
  sub get_wrapped_response
  {
      my ($self, $response, $pack) = @_;

      my $response_string = $response->decoded_content();

      if($response_string )
      {
          my $response = JSON->new->utf8->decode($response_string);

          return $self->get_response($response, $pack)
      }

      return undef;
  }

sub not_record_response
{
    my ($self, $instance, $response_json, $class_detail) = @_;

    my %response_json = %{$response_json};

    my %class_detail = %{$class_detail};

    foreach my $key (keys %class_detail)
    {
        my $key_detail = $class_detail{$key};

        my %key_detail = %{$key_detail};

        my $key_name = exists($key_detail{$Constants::NAME}) ? $key_detail{$Constants::NAME} : '';

        if(!$key_name eq '' && exists($response_json{$key_name}) && !($response_json{$key_name} eq ''))
        {
            my $key_data = $response_json{$key_name};

            my $member_value = $self->get_data($key_data, $key_detail);

            $instance->{$key} = $member_value;
        }
    }

    return $instance;
}

sub is_record_response
{
    my ($self, $response_json, $class_detail, $pack) = @_;

    my %response_json = %{$response_json};

    my %class_detail = %{$class_detail};

    my @names = split('\.', $pack);

    my $record_instance =  (@names[@names-2] . "::" . @names[@names-1])->new();

    my $module_api_name = $self->{common_api_handler}->{module_api_name};

    my $module_detail = ();

    my %key_values = ();

    if(!($module_api_name eq '' || $module_api_name eq undef))
    {
        $self->{common_api_handler}->{module_api_name} = '';

        my $full_detail = Utility::search_json_details($module_api_name);

        if(!$full_detail eq '')
        {
            my %full_detail = %{$full_detail};

            $module_detail = $full_detail{$Constants::MODULEDETAILS};

            my $module_package = $full_detail{$Constants::MODULEPACKAGENAME};

            my @split_names = split('\.', $module_package);

            $record_instance =  @split_names[@split_names-1]->new();
        }
        else
        {
            $module_detail = $self->get_module_detail_from_user_spec_json($module_api_name);
        }
    }
    else
    {
        $module_detail = $class_detail;

        my $json_details = Initializer::get_json_details();

        my %json_details=%{$json_details};

        $class_detail = $json_details{$pack};
    }

    my %module_detail = %{$module_detail};

    # if(blessed($record_instance) && $record_instance->isa('Record'))
    # {
    #     @names = split('\.', $Constants::RECORD_NAMESPACE);
    #
    #     $record_instance =  @names[@names-1]->new();
    # }

    foreach my $key_name (keys %{$response_json})
    {
        my $member_name = $self->build_name($key_name);

        my $key_detail = ();

        if(keys(%module_detail) > 0 && (exists($module_detail{$key_name}) || exists($module_detail{$member_name})))
        {
            if(exists($module_detail{$key_name}))
            {
                $key_detail = $module_detail{$key_name};
            }
            else
            {
                $key_detail = $module_detail{$member_name};
            }
        }
        elsif(exists($class_detail{$member_name}))
        {
            $key_detail = $class_detail{$member_name};
        }

        my $key_value;

        my $key_data = $response_json{$key_name};

        if(keys(%{$key_detail}) > 0)
        {
            $key_value = $self->get_data($key_data, $key_detail);
        }
        else
        {
            $key_value = $self->redirector_for_json_to_object($key_data);
        }

        $key_values{$key_name} = $key_value;
    }

    $record_instance->{$Constants::KEY_VALUES} = \%key_values;

    return $record_instance;
}

sub build_name
{
    my ($self, $member_name) = @_;

    my $sdk_name = '';

    my @name_split = split('_', $member_name);

    $sdk_name = lc(@name_split[0]);

    if(keys(@name_split) > 1)
    {
        for(my $i=1; $i<@name_split; ++$i)
        {
            $sdk_name = $sdk_name . "_" . lc(@name_split[$i]);
        }
    }

    return $sdk_name;
}

  sub get_response
  {
      my ($self,$response,$pack) = @_;

      if($response eq undef)
      {
          return undef;
      }

      my %response_json = %{$response};

      my $json_details = Initializer::get_json_details();

      my %json_details=%{$json_details};

      my $package_path = $self->find_class_path($pack, $json_details);

      my $class_detail = $json_details{$package_path};

      my %class_detail = %{$class_detail};

      my $instance;

      if(exists($class_detail{$Constants::INTERFACE}) && !$class_detail{$Constants::INTERFACE} eq '')
      {
          my @classes = $class_detail{$Constants::CLASSES};

          $instance = $self->find_match(@classes, \%response_json);
      }
      else
      {
          #load class and create instance.
          my $class_to_load = $self->construct_class_to_load($package_path,$json_details);

          require $class_to_load;

          my @names = split('\.', $pack);

          $instance =  (@names[@names-2] . '::' . @names[@names-1])->new();

          if(blessed($instance) && $instance->isa('record::Record'))
          {
              my $module_api_name = $self->{common_api_handler}->{module_api_name};

              $instance = $self->is_record_response(\%response_json, \%class_detail, $pack);

              $self->{common_api_handler}->{module_api_name} = $module_api_name;
          }
          else
          {
              $instance = $self->not_record_response($instance, \%response_json, \%class_detail);
          }
         #  foreach my $key (keys %class_json_details)
         #  {
         #      my $member_json_details = $class_json_details{$key}; #
         #
         #      my %member_json_details = %{$member_json_details};
         #
         #      my $key_name = exists($member_json_details{"name"}) ? $member_json_details{"name"} : '';
         #
         #      if(!$key_name eq '' && exists($response{$key_name}) && !$response{$key_name} eq '')
         #      {
         #
         #          my $key_data = $response{$key_name};
         #
         #          my $type = $member_json_details{"type"};
         #
         #          if("$type" eq "List")
         #          {
         #
         #              my @instance_value = $self->get_collections_data($key_data, $member_json_details);
         #
         #              $instance->{$key} = [@instance_value];
         #          }
         #          elsif("$type" eq "Map")
         #          {
         #              my $instance_value = $self->get_map_data($key_data, $member_json_details);
         #
         #              $instance->{$key} = $instance_value;
         #          }
         #          elsif(exists($member_json_details{$Constants::STRUCTURE_NAME}))
         #          {
         #              my $instance_value = $self->get_response($key_data, $member_json_details{$Constants::STRUCTURE_NAME});
         #
         #              $instance->{$key} = $instance_value;
         #          }
         #          else
         #          {
         #              my $instance_value = DataTypeConverter::pre_convert($key_data, $type);
         #
         #              $instance->{$key} = $instance_value;
         #          }
         #      }
         #  }
         #
         # if($package_path eq 'com.zoho.crm.api.record.Record' )
         # {
         #
         #   use JSON::Parse 'json_file_to_perl';
         #
         #     my $json_details = Initializer::get_json_details();
         #
         #     my %json_details=%{$json_details};
         #
         #     my $package_path = $self->find_class_path($pack, $json_details);
         #
         #     my $class_json_details = $json_details{$package_path};
         #
         #     my %record_json_details = %{$class_json_details};
         #
         #     my %module_json_details = ();
         #
         #     if(($self->{common_api_handler}->{module_api_name}) && !($self->{common_api_handler}->{module_api_name} eq ''))
         #     {
         #         my $record_field_details_path =  $self->get_record_json_file_path();
         #
         #         my $record_json= json_file_to_perl($record_field_details_path);
         #
         #         my %record_json = %{$record_json};
         #
         #         my $module_json_details= $record_json{$self->{common_api_handler}->{module_api_name}};
         #
         #         %module_json_details = %{$module_json_details};
         #     }
         #
         #   my $instance_value;
         #
         #     if(%module_json_details)
         #     {
         #         foreach my $key_name (keys %module_json_details)
         #         {
         #             my $key_json_details = $module_json_details{$key_name};
         #
         #             my %key_json_details = %{$key_json_details};
         #
         #             my $field_name = lc $key_name;
         #
         #             if(!exists($record_json_details{$field_name}))
         #             {
         #                 if(exists($response{$key_name}))
         #                 {
         #                     my $key_value;
         #
         #                     if(exists($key_json_details{$Constants::STRUCTURE_NAME}))
         #                     {
         #                         $key_value = $self->get_response($response{$key_name},$key_json_details{$Constants::STRUCTURE_NAME});
         #
         #                     }
         #                     else
         #                     {
         #                         $key_value = $response{$key_name};
         #                     }
         #
         #                     $instance_value->{$key_name}=$key_value;
         #                 }
         #             }
         #         }
         #     }
         #     else
         #     {
         #         foreach my $json_key_name (keys $response)
         #         {
         #             my $key_name = lc $json_key_name;
         #
         #             if(!exists($record_json_details{$key_name}))
         #             {
         #                 $instance_value->{$json_key_name} = $response{$json_key_name};
         #             }
         #         }
         #     }
         #
         #   $instance->{"key_values"} = $instance_value;
         # }
      }

      return $instance;

  }

  sub get_map_data
  {
      my ($self,$response, $member_detail) = @_;

      my %member_detail = '';

      if(!$member_detail eq '')
      {
          %member_detail = %{$member_detail};
      }

      my %response = %{$response};

      my %map_instance = ();

      my $size = keys(%response);

      if($size > 0)
      {
          if(!%member_detail || (%member_detail && !exists($member_detail{$Constants::KEYS})))
          {
              foreach my $key (keys %response)
              {
                  my $value = $self->redirector_for_json_to_object($response{$key});

                  $map_instance{$key} = $value;
              }
          }
          else
          {
              if(exists($member_detail{$Constants::KEYS}))
              {
                  my $keys_detail = $member_detail{$Constants::KEYS};

                  foreach(@$keys_detail)
                  {
                      my $key_detail = $_;

                      my %key_detail = %{$key_detail};

                      my $key_name = $key_detail{$Constants::NAME};

                      if(exists($response{$key_name}) && !($response{$key_name} eq ''))
                      {
                          my $key_value = $self->get_data($response{$key_name}, $key_detail);

                          $map_instance{$key_name} = $key_value;
                      }
                  }
              }
          }
      }

      return \%map_instance;
  }

  sub get_collections_data
  {
      my ($self, $responses, $member_detail) = @_;

      my @values = ();

      my %member_detail = '';

      if(!$member_detail eq '')
      {
          %member_detail = %{$member_detail};
      }

      my @responses = @$responses;

      my $size = keys(@responses);

      if($size > 0)
      {
          if(!%member_detail || (%member_detail && !exists($member_detail{$Constants::STRUCTURE_NAME})))
          {
              foreach(@$responses)
              {
                  push(@values, $self->redirector_for_json_to_object("$_"));
              }
          }
          else
          {
              my $pack = $member_detail{$Constants::STRUCTURE_NAME};

              if("$pack" eq $Constants::CHOICE_NAMESPACE)
              {
                  require 'src/com/zoho/crm/api/util/Choice.pm';

                  foreach(@responses)
                  {
                      push(@values, Choice->new($_));
                  }
              }
              elsif(exists($member_detail{$Constants::MODULE}) && "$member_detail{$Constants::MODULE}" ne '')
              {
                  foreach(@$responses)
                  {
                      push(@values, $self->is_record_response($_, $self->get_module_detail_from_user_spec_json($member_detail{$Constants::MODULE}), $pack));
                  }
              }
              else
              {
                  foreach(@$responses)
                  {
                      push(@values, $self->get_response($_, $pack));
                  }
              }
          }
      }

      return @values;
  }

  sub redirector_for_json_to_object
  {
      my ($self, $key_data) = @_;

      if(ref($key_data) eq "HASH")
      {
          return $self->get_map_data($key_data, undef);
      }
      elsif(ref($key_data) eq "ARRAY")
      {
          return $self->get_collections_data($key_data, undef);
      }
      {
          return $key_data;
      }
  }

sub get_module_detail_from_user_spec_json
{
    my ($self, $module) = @_;

    use JSON::Parse 'json_file_to_perl';

    my $file_handler;

    my $module_detail = ();

    my $record_field_details_path = catfile(Initializer::get_resource_path(), $Constants::FIELD_DETAILS_DIRECTORY, Converter->new->get_encoded_file_name());

    my $record_field_details_json = json_file_to_perl($record_field_details_path);

    $module_detail = Utility::get_json_object($record_field_details_json, $module);

    my %module_detail = %{$module_detail};

    return \%module_detail;
}

  sub find_match
  {
      my ($self, $classes, $response_json) = @_;

      my %response_json = %{$response_json};

      my $package_name = "";

      my $ratio = 0;

      foreach(@$classes)
      {
          my $match_ratio = $self->find_ratio("$_", \%response_json);

          if($match_ratio == 1.0)
          {
              $package_name = "$_";

              $ratio = 1;

              last;
          }
          elsif($match_ratio > $ratio)
          {
              $ratio = $match_ratio;

              $package_name = "$_";
          }
      }

      return $self->get_response(\%response_json, $package_name);
  }

  sub find_ratio
  {
      my ($self,$class_name, $response_json) = @_;

      my %response_json = %{$response_json};

      my $init = Initializer::get_json_details();

      my %json_details=%{$init};

      my $class_detail = $json_details{$class_name};

      my %class_detail = %{$class_detail};

      my $matches = 0;

      my $total_points = keys %class_detail;

      if("$total_points" == 0)
      {
          return;
      }
      else
      {
          foreach my $key (keys %class_detail)
          {
              my $member_detail = $class_detail{$key};

              my %member_detail = %{$member_detail};

              my $key_name = exists($member_detail{"name"}) ? $member_detail{"name"} : undef;

              if(!$key_name eq '' && exists($response_json{$key_name}) && !$response_json{$key_name} eq '')
              {
                  my $key_data = $response_json{$key_name};

                  my $type = ref($key_data);

                  my $structure_name = '';

                  if(exists($member_detail{$Constants::STRUCTURE_NAME}))
                  {
                      $structure_name = $member_detail{$Constants::STRUCTURE_NAME};
                  }

                  if($type eq "HASH")
                  {
                      $type = "Map";
                  }

                  if ($type eq "ARRAY")
                  {
                      $type = "List";
                  }

                  if("$type" eq $member_detail{$Constants::TYPE})
                  {
                      $matches += 1;
                  }
                  elsif(lc($member_detail{$Constants::TYPE}) eq lc($Constants::CHOICE_NAMESPACE))
                  {
                      my $vals = $member_detail{$Constants::VALUES};

                      foreach(@$vals)
                      {
                          if($_ eq $key_data)
                          {
                              $matches += 1;

                              last;
                          }
                      }
                  }

                  if($structure_name ne '' && $structure_name eq $member_detail{$Constants::TYPE})
                  {
                      if(exists($member_detail{$Constants::VALUES}))
                      {
                          my $vals = $member_detail{$Constants::VALUES};

                          foreach(@$vals)
                          {
                              if($_ eq $key_data)
                              {
                                  $matches += 1;

                                  last;
                              }
                          }

                      }
                      else
                      {
                          $matches += 1;
                      }
                  }
              }
          }
      }

      return $matches/$total_points;
  }

  sub construct_class_to_load
  {
    my($self, $class_path, $json_details) = @_;

    my $modified_class_path = $class_path;

    if(index($modified_class_path, "com") == -1)
    {

        foreach my $key (keys %{$json_details})
        {

            if(index($key, $modified_class_path) != -1)
            {
                $modified_class_path = $key;

                last;
            }
        }
    }

    $modified_class_path =~ s/\./\//g;

    return 'src/'.$modified_class_path.'.pm';
  }

  sub find_class_path
  {
      my ($self, $class_path, $json_details) = @_;

      if(index($class_path, "com") == -1)
      {
          foreach my $key (keys %{$json_details})
          {
              if(index($key, $class_path) != -1)
              {

                  $class_path =  $key;
              }
          }
      }

      return $class_path;
  }

1;
