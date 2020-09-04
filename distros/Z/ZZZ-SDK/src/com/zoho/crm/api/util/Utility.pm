use warnings;
use JSON;
package Utility;

use src::com::zoho::crm::api::fields::FieldsOperations;
use src::com::zoho::crm::api::relatedlists::RelatedListsOperations;
use src::com::zoho::crm::api::modules::ModulesOperations;
use src::com::zoho::crm::api::util::Constants;
use src::com::zoho::crm::api::Initializer;
use src::com::zoho::crm::api::HeaderMap;
use Cwd qw(realpath);
use Cwd qw(getcwd);
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use File::Spec::Functions qw(catfile);
use JSON::Parse "json_file_to_perl";
use Moose;

our %apitype_vs_datatype = ();

our %apitype_vs_structurename = ();

our $new_file = 0;

our $get_modified_modules = 0;

our $mutex :shared;

sub get_fields
{
    lock($Utility::mutex);

    my ($module_api_name) = @_;

    my $resources_path = catfile(Initializer::get_resource_path(), $Constants::FIELD_DETAILS_DIRECTORY);

    unless(-e $resources_path)
    {
        unless(Utility::search_json_details($module_api_name) eq "")
        {
            return;
        }

        mkdir $resources_path;
    }

    my $record_field_details_path = Utility::get_file_name();

    my $record_field_details_json=();

    my %record_field_details_json=();

    if(-e $record_field_details_path && !(-z $record_field_details_path))
    {
        $record_field_details_json = json_file_to_perl($record_field_details_path);

        %record_field_details_json = %{$record_field_details_json};

        if(Initializer::get_auto_refresh_fields() && !$Utility::new_file && !$Utility::get_modified_modules)
        {
            $Utility::get_modified_modules = 1;

            Utility::modify_fields($record_field_details_path, (exists($record_field_details_json{$Constants::FIELDS_LAST_MODIFIED_TIME})) ? $record_field_details_json{$Constants::FIELDS_LAST_MODIFIED_TIME} : undef);

            $Utility::get_modified_modules = 0;
        }

        $record_field_details_json = json_file_to_perl($record_field_details_path);

        if(exists($record_field_details_json{lc($module_api_name)}))
        {
            return;
        }
        else
        {
            Utility::fill_data_type();

            $record_field_details_json{lc($module_api_name)} = {};

            Utility::write_to_file($record_field_details_path, \%record_field_details_json);

            my $field_details = Utility::get_fields_details($module_api_name);

            $record_field_details_json = json_file_to_perl($record_field_details_path);

            %record_field_details_json = %{$record_field_details_json};

            $record_field_details_json{lc($module_api_name)} = $field_details;

            Utility::write_to_file($record_field_details_path, \%record_field_details_json);

            # my $encoded_json = $JSON->encode(\%record_field_details_json);
            #
            # open($data, ">", $record_field_details_path);
            #
            # print $data $encoded_json;
            #
            # close($data);

        }
    }
    elsif(Initializer::get_auto_refresh_fields())
    {
        $Utility::new_file = 1;

        Utility::fill_data_type();

        my $module_api_names = Utility::get_modules(undef);

        $record_field_details_json{$Constants::FIELDS_LAST_MODIFIED_TIME} = "".gettimeofday();

        foreach(@$module_api_names)
        {
            my $module = $_;

            unless(exists($record_field_details_json{lc($module)}))
            {
                $record_field_details_json{lc($module)} = {};

                Utility::write_to_file($record_field_details_path, \%record_field_details_json);

                # open($data, ">", $record_field_details_path);
                #
                # my $encoded_json = $JSON->encode(\%record_field_details_json);
                #
                # print $data $encoded_json;
                #
                # close($data);

                my $field_details = Utility::get_fields_details($module);

                $record_field_details_json = json_file_to_perl($record_field_details_path);

                %record_field_details_json = %{$record_field_details_json};

                $record_field_details_json{lc($module)} = $field_details;

                Utility::write_to_file($record_field_details_path, \%record_field_details_json);

                # $encoded_json = $JSON->encode(\%record_field_details_json);
                #
                # print $data $encoded_json;
                #
                # close($data);
            }
        }

        $Utility::new_file = 0;
    }
    else
    {
        Utility::fill_data_type();

        $record_field_details_json{lc($module_api_name)} = {};

        Utility::write_to_file($record_field_details_path, \%record_field_details_json);

        my $field_details = Utility::get_fields_details($module_api_name);

        $record_field_details_json = json_file_to_perl($record_field_details_path);

        %record_field_details_json = %{$record_field_details_json};

        $record_field_details_json{lc($module_api_name)} = $field_details;

        Utility::write_to_file($record_field_details_path, \%record_field_details_json);
    }
}

sub get_file_name
{
    return catfile(Initializer::get_resource_path(), $Constants::FIELD_DETAILS_DIRECTORY, Converter->new->get_encoded_file_name())
}

sub modify_fields
{
    my($record_field_details_path, $modified_time) = @_;

    my $modified_modules = Utility::get_modules($modified_time);

    my $record_field_details_json = json_file_to_perl($record_field_details_path);

    my %record_field_details_json = %{$record_field_details_json};

    $record_field_details_json{$Constants::FIELDS_LAST_MODIFIED_TIME} = "".gettimeofday();

    Utility::write_to_file($record_field_details_path, \%record_field_details_json);

    my $modified_modules_count = @$modified_modules;

    if($modified_modules_count > 0)
    {
        foreach(@$modified_modules)
        {
            my $module = $_;

            if(exists($record_field_details_json{lc($module)}))
            {
                delete($record_field_details_json{lc($module)});
            }
        }

        Utility::write_to_file($record_field_details_path, \%record_field_details_json);

        foreach(@$modified_modules)
        {
            my $module = $_;

            Utility::get_fields($module);
        }
    }
}

sub get_modules
{
    my($header) = @_;

    my $header_map = HeaderMap->new();

    my @api_names = ();

    if(defined($header))
    {
        $header_map->add(modules::GetModulesHeader::If_modified_since, DateTime->from_epoch(epoch => $header));
    }

    my $response = modules::ModulesOperations->new()->get_modules($header_map);

    unless($response eq "" || $response eq undef)
    {
        if($response->get_status_code() == $Constants::NO_CONTENT_STATUS_CODE || $response->get_status_code() == $Constants::NOT_MODIFIED_STATUS_CODE)
        {
            return \@api_names;
        }

        my $response_object = $response->get_object();

        if(blessed($response_object) && $response_object->isa('modules::ResponseWrapper'))
        {
            my $modules = $response_object->get_modules();

            foreach(@$modules)
            {
                my $module = $_;

                if($module->get_api_supported())
                {
                    push(@api_names, $module->get_api_name());
                }
            }
        }
    }

    return \@api_names;
}

sub search_json_details
{
    my ($key) = @_;

    $key = $Constants::PACKAGE_NAMESPACE . ".record." . $key;

    my $json_details = Initializer::get_json_details();

    my %json_details=%{$json_details};

    foreach my $key_in_json (keys %json_details)
    {
        if(lc($key) eq lc($key_in_json))
        {
            my $return_json = {};

            $return_json->{$Constants::MODULEPACKAGENAME} = $key_in_json;

            $return_json->{$Constants::MODULEDETAILS} = $json_details{$key_in_json};

            return $return_json;
        }
    }

    return undef;
}

sub get_json_object
{
    my ($json, $key) = @_;

    my %json = %{$json};

    foreach my $key_in_json (keys %json)
    {
        if(lc($key) eq lc($key_in_json))
        {
            return $json{$key_in_json};
        }
    }

    return "";
}

sub get_related_lists
{
    my($related_module_name, $module_api_name, $common_api_handler) = @_;

    lock($Utility::mutex);

    my $is_new_data = 0;

    my $key = lc($module_api_name . $Constants::UNDERSCORE . $Constants::RELATED_LISTS);

    my $resources_path = catfile(Initializer::get_resource_path(), $Constants::FIELD_DETAILS_DIRECTORY);

    unless(-e $resources_path)
    {
        mkdir $resources_path;
    }

    my $record_field_details_path = Utility::get_file_name();

    my $record_field_details_json = ();

    my %record_field_details_json = ();

    if( -e $record_field_details_path)
    {
        $record_field_details_json = json_file_to_perl($record_field_details_path);

        %record_field_details_json = %{$record_field_details_json};
    }

    if(! -e $record_field_details_path or (-e $record_field_details_path && !(exists($record_field_details_json{$key}))))
    {
        $is_new_data = 1;

        my $related_list_values = Utility::get_related_list_details($module_api_name);

        $record_field_details_json = (-e $record_field_details_path)? json_file_to_perl($record_field_details_path) : {};

        %record_field_details_json = %{$record_field_details_json};

        $record_field_details_json{$key} = $related_list_values;

        Utility::write_to_file($record_field_details_path, \%record_field_details_json);
    }

    $record_field_details_json = json_file_to_perl($record_field_details_path);

    my $module_related_list = $record_field_details_json{$key};

    if(!(Utility::check_related_list_exists($related_module_name, $module_related_list, $common_api_handler)) && !$is_new_data)
    {
        delete($record_field_details_json{$key});

        Utility::write_to_file($record_field_details_path, \%record_field_details_json);

        Utility::get_related_lists($related_module_name, $module_api_name, $common_api_handler);
    }
}

sub check_related_list_exists
{
    my($related_module_name, $module_related_list_array, $common_api_handler) = @_;

    foreach(@$module_related_list_array)
    {
        my $related_list_jo = $_;

        my %related_list_jo = %{$related_list_jo};

        if($related_list_jo{$Constants::API_NAME} ne "" && lc($related_list_jo{$Constants::API_NAME}) eq lc($related_module_name))
        {
            $common_api_handler->set_module_api_name($related_list_jo{$Constants::MODULE});

            Utility::get_fields($related_list_jo{$Constants::MODULE});

            return 1;
        }
    }

    return 0;
}

sub get_related_list_details
{
    my($module_api_name) = @_;

    my @related_list_array = ();

    my $response = relatedlists::RelatedListsOperations->new($module_api_name)->get_related_lists();

    if(defined($response))
    {
        if($response->get_status_code() == $Constants::NO_CONTENT_STATUS_CODE)
        {
            return \@related_list_array;
        }

        my $data_object = $response->get_object();

        if(defined($data_object))
        {
            if(blessed($data_object) && $data_object->isa('relatedlists::ResponseWrapper'))
            {
                my $related_lists = $data_object->get_related_lists();

                foreach(@$related_lists)
                {
                    my $related_list = $_;

                    my %related_list_detail = ();

                    $related_list_detail{$Constants::API_NAME} = $related_list->get_api_name();

                    $related_list_detail{$Constants::MODULE} = $related_list->get_module();

                    $related_list_detail{$Constants::NAME} = $related_list->get_name();

                    $related_list_detail{$Constants::HREF} = $related_list->get_href();

                    push(@related_list_array, \%related_list_detail);
                }
            }
            elsif(blessed($data_object) && $data_object->isa('relatedlists::APIException'))
            {
                my %error_response = ();

                $error_response{$Constants::CODE} = $data_object->get_code()->get_value();

                $error_response{$Constants::STATUS} = $data_object->get_status()->get_value();

                $error_response{$Constants::MESSAGE} = $data_object->get_message()->get_value();

                die SDKException->new({code =>$Constants::API_EXCEPTION},{message =>''},{details => \%error_response},{cause =>''});
            }
            else
            {
                my %error_response = ();

                $error_response{$Constants::CODE} = $data_object->get_code()->get_value();

                die SDKException->new({code =>$Constants::API_EXCEPTION},{message =>''},{details => \%error_response},{cause =>''});
            }
        }
        else
        {
            my %error_response = ();

            $error_response{$Constants::CODE} = $data_object->get_code()->get_value();

            die SDKException->new({code =>$Constants::API_EXCEPTION},{message =>''},{details => \%error_response},{cause =>''});
        }
    }

    return \@related_list_array;
}

sub get_fields_details
{
    my($module_api_name) = @_;

    # use src::com::zoho::crm::api::fields::ResponseWrapper;
    # use src::com::zoho::crm::api::fields::APIException;

    my $fields;

    my %fields_details = ();

    my $response = fields::FieldsOperations->new($module_api_name)->get_fields(undef);

    if(defined($response))
    {
        if($response->get_status_code() == $Constants::NO_CONTENT_STATUS_CODE)
        {
            return \%fields_details;
        }

        my $data_object = $response->get_object();

        if(blessed($data_object))
        {
            if($data_object->isa('fields::ResponseWrapper'))
            {
                $fields = $data_object->get_fields();

                my %keys_to_skip = map { $_ => 1 } @Constants::KEYSTOSKIP;

                my %inventory_modules = map { $_ => 1 } @Constants::INVENTORY_MODULES;

                foreach(@$fields)
                {
                    my $field = $_;

                    my $key_name = $field->get_api_name();

                    print($key_name);

                    if(exists($keys_to_skip{$key_name}))
                    {
                        next;
                    }

                    my %field_detail = ();

                    my $field_detail=Utility::set_data_type(\%field_detail, $field, $module_api_name);

                    %field_detail=%{$field_detail};

                    $fields_details{$field->get_api_name()} = \%field_detail;
                }

                if(exists($inventory_modules{lc($module_api_name)}))
                {
                    my %field_detail = ();

                    $field_detail{$Constants::NAME} = $Constants::LINE_TAX;

                    $field_detail{$Constants::TYPE} = $Constants::LIST_NAMESPACE;

                    $field_detail{$Constants::STRUCTURE_NAME} = $Constants::LINETAX;

                    $fields_details{$Constants::LINE_TAX} = \%field_detail;
                }

            }
        }
        else
        {
            my %error_response = ();

            $error_response{$Constants::CODE} = $data_object->get_code()->get_value();

            $error_response{$Constants::STATUS} = $data_object->get_status()->get_value();

            $error_response{$Constants::MESSAGE} = $data_object->get_message()->get_value();

            die SDKException->new({code =>$Constants::API_EXCEPTION},{message =>''},{details => \%error_response},{cause =>''});
        }
    }

    return \%fields_details;
}

sub set_data_type
{
    my($field_detail, $field, $module_api_name) = @_;

    my %field_detail = %{$field_detail};

    my $data_type = $field->get_data_type();

    my $module = "";

    my $key_name = $field->get_api_name();

    my %inventory_modules = map { $_ => 1 } @Constants::INVENTORY_MODULES;

    if(defined($field->get_system_mandatory()) && $field->get_system_mandatory() && !(lc($module_api_name) eq $Constants::CALLS && lc($key_name) eq $Constants::CALL_DURATION))
    {
        $field_detail{$Constants::REQUIRED} = 1;
    }

    if(lc($key_name) eq lc($Constants::PRODUCT_DETAILS) && exists($inventory_modules{lc($module_api_name)}))
    {
        $field_detail{$Constants::NAME} = $key_name;

        $field_detail{$Constants::TYPE} = $Constants::LIST_NAMESPACE;

        $field_detail{$Constants::STRUCTURE_NAME} = $Constants::INVENTORY_LINE_ITEMS;

        return \%field_detail;
    }
    elsif(lc($key_name) eq lc($Constants::PRICING_DETAILS) && lc($module_api_name) eq $Constants::PRICE_BOOKS)
    {
        $field_detail{$Constants::NAME} = $key_name;

        $field_detail{$Constants::TYPE} = $Constants::LIST_NAMESPACE;

        $field_detail{$Constants::STRUCTURE_NAME} = $Constants::PRICINGDETAILS;

        return \%field_detail;
    }
    elsif(lc($key_name) eq lc($Constants::PARTICIPANT_API_NAME) && (lc($module_api_name) eq $Constants::EVENTS || lc($module_api_name) eq $Constants::ACTIVITIES))
    {
        $field_detail{$Constants::NAME} = $key_name;

        $field_detail{$Constants::TYPE} = $Constants::LIST_NAMESPACE;

        $field_detail{$Constants::STRUCTURE_NAME} = $Constants::PARTICIPANTS;

        return \%field_detail;
    }
    elsif(lc($key_name) eq lc($Constants::COMMENTS) && (lc($module_api_name) eq $Constants::CASES || lc($module_api_name) eq $Constants::SOLUTIONS))
    {
        $field_detail{$Constants::NAME} = $key_name;

        $field_detail{$Constants::TYPE} = $Constants::LIST_NAMESPACE;

        $field_detail{$Constants::STRUCTURE_NAME} = $Constants::COMMENT_NAMESPACE;

        return \%field_detail;
    }
    elsif(lc($key_name) eq lc($Constants::LAYOUT))
    {
        $field_detail{$Constants::NAME} = $key_name;

        $field_detail{$Constants::TYPE} = $Constants::LAYOUT_NAMESPACE;

        $field_detail{$Constants::STRUCTURE_NAME} = $Constants::LAYOUT_NAMESPACE;

        return \%field_detail;
    }
    elsif(exists($Utility::apitype_vs_datatype{$data_type}))
    {
        $field_detail{$Constants::TYPE} = $Utility::apitype_vs_datatype{$data_type};
    }
    else
    {
        return \%field_detail;
    }

    if(exists($Utility::apitype_vs_structurename{$data_type}))
    {
        $field_detail{$Constants::STRUCTURE_NAME} = $Utility::apitype_vs_structurename{$data_type};
    }

    if(!$field->get_pick_list_values() eq '' && defined($field->get_pick_list_values()))
    {
        my $possible_values = $field->get_pick_list_values();

        my @values = ();

        foreach(@$possible_values)
        {
            push(@values, $_->get_actual_value());
        }

        my $length = @values;

        if($length > 0)
        {
            $field_detail{$Constants::VALUES} = \@values;
        }
    }

    if(lc($data_type) eq lc($Constants::SUBFORM))
    {
        $module = $field->get_subform()->get_module();

        $field_detail{$Constants::MODULE} = $module;
    }

    if(lc($data_type) eq lc($Constants::LOOKUP))
    {
        $module = $field->get_lookup()->get_module();

        if(!$module eq '' && !(lc($module) eq lc($Constants::SE_MODULE)))
        {
            $field_detail{$Constants::MODULE} = $module;
        }
        else
        {
            $module = '';
        }
    }

    if(length($module) > 0)
    {
        Utility::get_fields($module);
    }

    $field_detail{$Constants::NAME} = $key_name;

    return \%field_detail;
}

sub fill_data_type
{
    my @field_api_names_string = ("textarea", "text", "website", "email", "phone", "mediumtext", "multiselectlookup",
        "profileimage");

    my @field_api_names_integer = ("integer");

    my @field_api_names_boolean = ("boolean");

    my @field_api_names_double = ("double", "percent", "lookup", "currency");

    my @field_api_names_long = ("long", "bigint", "autonumber");

    my @field_api_names_file = ("imageupload");

    my @field_api_names_field_file = ("fileupload");

    my @field_api_names_datetime = ("datetime", "event_reminder");

    my @field_api_names_date = ("date");

    my @field_api_names_lookup = ("lookup");

    my @field_api_names_owner_lookup = ("userlookup", "ownerlookup");

    my @field_api_names_multiuser_lookup = ("multiuserlookup");

    my @field_api_names_multimodule_lookup = ("multimodulelookup");

    my @field_api_names_picklist = ("picklist");

    my @field_api_names_multiselect_picklist = ("multiselectpicklist");

    my @field_api_names_subform = ("subform");

    my @field_api_name_task_remind_at = ("ALARM");

    my @field_api_name_recurring_activity = ("RRULE");

    my @field_api_name_reminder = ("multireminder");

    foreach(@field_api_names_string)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::STRING_NAMESPACE;
    }

    foreach(@field_api_names_integer)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::INTEGER_NAMESPACE;
    }

    foreach(@field_api_names_boolean)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::BOOLEAN;
    }

    foreach(@field_api_names_double)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::DOUBLE_NAMESPACE;
    }

    foreach(@field_api_names_long)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::LONG_NAMESPACE;
    }

    foreach(@field_api_names_file)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::FILE_NAMESPACE;
    }

    foreach(@field_api_names_datetime)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::DATETIME_NAMESPACE;
    }

    foreach(@field_api_names_date)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::DATE_NAMESPACE;
    }

    foreach(@field_api_names_lookup)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::RECORD_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::RECORD_NAMESPACE;
    }

    foreach(@field_api_names_owner_lookup)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::USER_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::USER_NAMESPACE;
    }

    foreach(@field_api_names_multiuser_lookup)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::LIST_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::USER_NAMESPACE;
    }

    foreach(@field_api_names_multimodule_lookup)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::LIST_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::MODULE_NAMESPACE;
    }

    foreach(@field_api_names_picklist)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::CHOICE_NAMESPACE;
    }

    foreach(@field_api_names_multiselect_picklist)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::LIST_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::CHOICE_NAMESPACE;
    }

    foreach(@field_api_names_subform)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::LIST_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::RECORD_NAMESPACE;
    }

    foreach(@field_api_names_field_file)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::LIST_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::FIELD_FILE_NAMESPACE;
    }

    foreach(@field_api_name_task_remind_at)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::REMINDAT_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::REMINDAT_NAMESPACE;
    }

    foreach(@field_api_name_recurring_activity)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::RECURRING_ACTIVITY_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::RECURRING_ACTIVITY_NAMESPACE;
    }

    foreach(@field_api_name_reminder)
    {
        $Utility::apitype_vs_datatype{$_} = $Constants::LIST_NAMESPACE;

        $Utility::apitype_vs_structurename{$_} = $Constants::REMINDER_NAMESPACE;
    }
}

sub write_to_file
{
    my($file_path, $file_contents) = @_;

    my $data;

    my $JSON = JSON->new->utf8;

    open($data, ">", $file_path);

    my $encoded_json = $JSON->encode(\%$file_contents);

    print $data $encoded_json;

    close($data);

}
=head1 NAME

com::zoho::crm::api::util::Utility - This class handles module field details.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<get_fields>

This method to fetch field details of the current module for the current user and store the result in a JSON file.

Param module_api_name : A String containing the CRM module API name.

=item C<get_fields_details>

This method to get module field data from Zoho CRM.

Param module_api_name : A String containing the CRM module API name.

Returns A Object representing the Zoho CRM module field details.

=back

=cut

1;
