use strict;
use warnings;
use utf8;
no utf8;
use MIME::Base64;

package Converter;

use Moose;

use Scalar::Util::Numeric qw(isint isfloat);

use src::com::zoho::api::exception::SDKException;
use src::com::zoho::crm::api::util::Constants;


use Try::Catch;

use Log::Handler;

use src::com::zoho::crm::api::Initializer;

our %unique_values_hash = ();


sub new
{
  my $class=shift;

  my $self =
  {
      'common_api_handler'=>shift
  };

  bless $self,$class;

  return $self;
}
sub get_response
{
   my ($self,$response,$pack)= @_;
}

sub form_request
{
  my ($self,$request_object,$pack,$instance_number)= @_;
}

sub append_to_request
{
    my ($self,$request_base,$request_object) = @_;
}

sub get_wrapped_response
{
    my ($self,$response,$pack)= @_;
}

sub value_checker
{
    my ($self, $class_name, $member_name, $key_details, $value, $unique_values_map, $instance_number)=@_;

    my %key_details = %{$key_details};

    my %error=();

    my $name = $key_details{$Constants::NAME};

    my $type = $key_details{$Constants::TYPE};

    my $check = 1;

    my $given_type;

    if(exists($Constants::REF_TYPES{$type}))
    {
        if(ref($value) eq 'ARRAY')
        {
            my $structure_name = $key_details{$Constants::STRUCTURE_NAME};

            my $index = 0;

            # $structure_name =~ s/\./\//g;
            #
            # $structure_name = 'src/' . $structure_name . '.pm';
            #
            # require $structure_name;

            my @names = split('\.', $structure_name);

            my $class_name =  ((lc(@names[@names-2]) ne 'util' ? (@names[@names-2] . '::') : "") . @names[@names-1]);

            foreach(@$value)
            {
                my $each_instance = $_;

                unless($each_instance->isa($class_name))
                {
                    $check = 0;

                    $instance_number = $index;

                    $type = $Constants::ARRAY_KEY . "(" . $structure_name . ")";

                    $given_type = blessed($each_instance);

                    last;
                }

                $index = $index + 1;
            }
        }
        else
        {
            $check = (ref($value) eq $Constants::REF_TYPES{$type})? 1 : 0;

            $type = $Constants::REF_TYPES{$type};

            $given_type = ref($value);
        }
    }
    elsif(exists($Constants::SPECIAL_TYPES{$type}))
    {
        unless($value->isa($Constants::SPECIAL_TYPES{$type}))
        {
            $check = 0;

            $type = $Constants::SPECIAL_TYPES{$type};

            $given_type = blessed($value);
        }
    }
    elsif(!(exists($Constants::DEFAULT_TYPES{$type})))
    {
        my $index = 0;

        my @names = split('\.', $type);

        my $class_name =  ((lc(@names[@names-2]) ne 'util' ? (@names[@names-2] . '::') : "") . @names[@names-1]);

        unless($value->isa($class_name))
        {
            $check = 0;

            $given_type = blessed($value);
        }
    }

    unless($check)
    {
        $error{$Constants::FIELD} = $name;

        $error{$Constants::CLASS} = $class_name;

        $error{$Constants::ACCEPTED_TYPE} = $type;

        $error{$Constants::GIVEN_TYPE} = $given_type;

        $error{$Constants::INDEX}=$instance_number;

        die SDKException->new($Constants::TYPE_ERROR , undef, \%error, undef);
    }

    if (exists($key_details{$Constants::VALUES}))
    {
        my $values = $key_details{$Constants::VALUES};

        my $is_accepted = 0;

        if(blessed($value) && $value->isa('Choice'))
        {
            $value = $value->get_value();
        }

        foreach(@$values)
        {
            my $each_value = $_;

            if($each_value eq $value)
            {
                $is_accepted = 1;

                last;
            }
        }

        if($is_accepted == 0)
        {
            $error{$Constants::INDEX}=$instance_number;

            $error{$Constants::CLASS}=$class_name;

            $error{$Constants::FIELD}=$member_name;

            $error{$Constants::ACCEPTED_TYPE}=$key_details{$Constants::VALUES};

            die SDKException->new($Constants::UNACCEPTED_VALUES_ERROR , undef, \%error, undef);
        }
    }

    if (exists($key_details{$Constants::MIN_LENGTH}) || exists($key_details{$Constants::MAX_LENGTH}))
    {
        my $count = length($value);

        if(ref($value) eq 'ARRAY')
        {
            $count = scalar(@$value);
        }

        if(exists($key_details{$Constants::MIN_LENGTH}) && ($count < $key_details{$Constants::MIN_LENGTH}))
        {
            $error{$Constants::INDEX}=$instance_number;

            $error{$Constants::CLASS}=$class_name;

            $error{$Constants::FIELD}=$member_name;

            $error{$Constants::MIN_LENGTH}=$key_details->{$Constants::MIN_LENGTH};

            die SDKException->new($Constants::MINIMUM_LENGTH_ERROR , undef, \%error, undef);
        }

        if(exists($key_details{$Constants::MAX_LENGTH}) && ($count > $key_details{$Constants::MAX_LENGTH}))
        {
            $error{$Constants::INDEX}=$instance_number;

            $error{$Constants::CLASS}=$class_name;

            $error{$Constants::FIELD}=$member_name;

            $error{$Constants::ACCEPTED_TYPE}=$key_details->{$Constants::MAX_LENGTH};

            die SDKException->new($Constants::MAXIMUM_LENGTH_ERROR , undef, \%error, undef);
        }
    }

    if(exists($key_details->{$Constants::REGEX}))
    {
        unless($value =~ $key_details->{$Constants::REGEX})
        {
            $error{$Constants::INDEX}=$instance_number;

            $error{$Constants::CLASS}=$class_name;

            $error{$Constants::FIELD}=$member_name;

            die SDKException->new({code =>$Constants::REGEX_MISMATCH_ERROR}, {message =>''}, {details => \%error}, {cause =>''});
        }
    }

    if(exists($key_details{$Constants::UNIQUE}))
    {
        if(!exists($Converter::unique_values_hash{$key_details{$Constants::NAME}}))
        {
            $Converter::unique_values_hash{$key_details{$Constants::NAME}}=[];
        }

        # my %unique_values_map = %{$Converter::unique_values_hash};

        my %key_map = $Converter::unique_values_hash{$key_details{$Constants::NAME}};

        if(exists($key_map{$value}))
        {
            #$error{'first-index'}=grep { $unique_values_map->{$key_details->{"name"}}[$_] eq $value };
            $error{$Constants::INDEX}=$instance_number;

            $error{$Constants::CLASS}=$class_name;

            $error{$Constants::FIELD}=$member_name;

            $error{$Constants::ACCEPTED_TYPE}=$key_details{$Constants::VALUES};

            die SDKException->new({code =>$Constants::UNACCEPTED_VALUES_ERROR}, {message =>''}, {details => \%error}, {cause =>''});
        }

        my @array = $Converter::unique_values_hash->{$key_details{$Constants::NAME}};

        unless(defined(@array))
        {
            @array = ();
        }

        # my @array = @$ref;

        push(@array,$value);

        $Converter::unique_values_hash{$key_details->{$Constants::NAME}} = \@array;
    }

    return 1;
}

sub get_encoded_file_name
{
    use File::Spec::Functions qw(catfile);

    my $file_name = Initializer::get_user()->get_email();

    my @field = split /@/, $file_name;

    $file_name = @field[0];

    $file_name = $file_name . Initializer::get_environment()->get_url();

    utf8::encode($file_name);

    my @ascii = unpack("C*", $file_name);

    my $str = MIME::Base64::encode_base64(join '', map chr, @ascii);

    $str =~ s/\n//;
    # $str = ~ s/\r//g;

    return $str. ".json";

    # my $test = __FILE__;
    #
    # my ($volume,$directory,$file) = File::Spec->splitpath( $test );
    #
    # my $test_path = catfile($directory, "../../../../../", $str. ".json");
    #
    # return $test_path;

    # return "/Users/raja-7453/Documents/AutomateSDK/PerlSDK/zohocrm-perl-sdk/src/". $str. ".json";
}

=head1 NAME

com::zoho::crm::api::util::Converter - This abstract class is to construct API request and response.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates a Converter class instance with the CommonAPIHandler class instance.

Param common_api_handler : A CommonAPIHandler class instance.

=item C<get_response>

This method is to process the API response.

Param response :  A Object containing the API response contents or response.

Param pack : A String containing the expected method return type.

Returns A Object representing the POJO class instance.

=item C<form_request>

This method is to construct the API request.

Param request_object : A Object containing the POJO class instance.

Param pack : A String containing the expected method return type.

Param instance_number : An Integer containing the POJO class instance list number.

Returns A Object representing the API request body object.

=item C<append_to_request>

This  method is to construct the API request body.

Param request_base : A dummy variable.

Param request_object : A object of APIHTTPConnector class.

=item C<get_wrapped_response>

This method is to process the API response.

Param response :  A Object containing the HttpResponse class instance.

Param pack : A Stirng contaning class Path.

Returns A Object representing the POJO class instance.

=item C<value_checker>

This method is to validate if the input values satisfy the constraints for the respective fields.

Param class_name : A String containing the class name.

Param member_name : A String containing the member name.

Param key_details : A JSONObject containing the key JSON details.

Param value : A Object containing the key value.

Param unique_values_map : A HashMap containing the construct objects.

Param instance_number : An Integer containing the POJO class instance list number.

Returns A Boolean representing the key value is expected pattern, unique, length, and values.

=back

=cut

1;
