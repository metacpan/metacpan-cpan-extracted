package HeaderParamValidator;

use Moose;
use src::com::zoho::crm::api::util::DataTypeConverter;
use src::com::zoho::crm::api::util::Constants;
use src::com::zoho::api::exception::SDKException;
use src::com::zoho::crm::api::Initializer;
use JSON::Parse 'json_file_to_perl';
use Cwd qw(realpath);

sub validate
{
    my($self, $header_param, $value) = @_;

    my $name = $header_param->get_name();

    my $class_name = $header_param->get_class_name();

    my $json_details = $self->get_json_details();

    my %json_details=%{$json_details};

    my $json_class_name = $self->get_file_name($class_name);

    my $type_detail = undef;

    if(exists($json_details{$json_class_name}))
    {
        $type_detail = $self->get_key_json_details($name, $json_details{$json_class_name});
    }

    if(defined($type_detail))
    {
        my %type_detail = %{$type_detail};

        if(!($self->check_data_type($type_detail, $value)))
        {
            my $param_or_header = index($json_class_name, "Param") != -1 ? "PARAMETER" : "HEADER";

            my %error=();

            $error{$param_or_header} = $name;

            $error{$Constants::CLASS} = $json_class_name;

            $error{$Constants::ACCEPTED_TYPE} = $type_detail{$Constants::TYPE};

            die SDKException->new($Constants::TYPE_ERROR, '', \%error, '');
        }
        else
        {
            $value = DataTypeConverter::post_convert($value, $type_detail{$Constants::TYPE});
        }
    }

    return $value;
}

sub check_data_type
{
    my($self, $key_detail, $value) = @_;

    my %key_detail = %{$key_detail};

    my $data_type = $key_detail{$Constants::TYPE};

    if(exists($Constants::SPECIAL_TYPES{$data_type}))
    {
        unless($value->isa($Constants::SPECIAL_TYPES{$data_type}))
        {
            return 0;
        }
    }

    return 1;
}

sub get_key_json_details
{
    my($self, $name, $json_details) = @_;

    my %json_details = %{$json_details};

    foreach my $key (keys %json_details)
    {
        my $detail = $json_details{$key};

        my %detail = %{$detail};

        if(exists($detail{$Constants::NAME}))
        {
            if(lc($detail{$Constants::NAME}) eq lc($name))
            {
                return \%detail;
            }
        }
    }
}

sub get_file_name
{
    my($self, $name) = @_;

    my $sdk_name = "";

    my @names = split('\.', $name);

    my $split_size = @names;

    $sdk_name = lc(@names[0]);

    for(my $i=1; $i<$split_size-1; ++$i)
    {
        $sdk_name = $sdk_name . "." . lc(@names[$i]);
    }

    return $sdk_name . "." . @names[$split_size-1];
}

sub get_json_details
{
    unless(defined(Initializer::get_json_details()))
    {
        my $json_file_path = realpath($Constants::JSON_DETAILS_FILE_PATH);

        my $json_details = json_file_to_perl($json_file_path);

        Initializer::json_details($json_details);
    }

    return Initializer::get_json_details();
}
1;