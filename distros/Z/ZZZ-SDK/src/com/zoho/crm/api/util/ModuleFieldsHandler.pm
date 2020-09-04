package ModuleFieldsHandler;
use warnings;
use src::com::zoho::crm::api::Initializer;
use src::com::zoho::crm::api::util::Converter;
use src::com::zoho::crm::api::util::Constants;
use JSON;
use File::Spec::Functions qw(catfile);
use Try::Catch;
use Log::Handler;
use File::Path;
use JSON::Parse "json_file_to_perl";

our $logger = Log::Handler->get_logger("SDKLogger");

sub get_directory
{
    return catfile(Initializer::get_resource_path(), $Constants::FIELD_DETAILS_DIRECTORY);
}

sub delete_fields_file
{
    try {
        my $record_field_details_path = catfile(ModuleFieldsHandler::get_directory(), Converter->new()->get_encoded_file_name());

        if(-e $record_field_details_path)
        {
            unlink($record_field_details_path);
        }
    }
    catch{
        my $e = shift;

        $ModuleFieldsHandler::logger->info($Constants::DELETE_FIELD_FILE_ERROR . "" . $e);
    }
}

sub delete_all_field_files
{
    try {
        my $record_field_details_directory = ModuleFieldsHandler::get_directory();

        if(-e $record_field_details_directory)
        {
            rmtree($record_field_details_directory);
        }
    }
    catch{
        my $e = shift;

        $ModuleFieldsHandler::logger->info($Constants::DELETE_FIELD_FILES_ERROR . "" . $e);
    }
}

sub delete_fields
{
    my($module) = @_;

    try {
        my $record_field_details_path = catfile(ModuleFieldsHandler::get_directory(), Converter->new()->get_encoded_file_name());

        if(-e $record_field_details_path)
        {
            my $record_field_details_json = json_file_to_perl($record_field_details_path);

            my %record_field_details_json = %{$record_field_details_json};

            if(exists($record_field_details_json{lc($module)}))
            {
                delete($record_field_details_json{lc($module)});
            }

            my $JSON = JSON->new->utf8;

            my $data;

            open($data, ">", $record_field_details_path);

            my $encoded_json = $JSON->encode(\%record_field_details_json);

            print $data $encoded_json;

            close($data);
        }
    }
    catch{
        my $e = shift;

        $ModuleFieldsHandler::logger->info($Constants::DELETE_MODULE_FROM_FIELDFILE_ERROR . "" . $e);
    }
}

1;