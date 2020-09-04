use strict;
use warnings;
use src::com::zoho::crm::api::util::Converter;
use src::com::zoho::crm::api::util::Constants;
package FormDataConverter;
use Moose;

extends 'Converter';

sub form_request
{
    my ($self, $request_instance, $pack, $instance_number) = @_;

    my $package_path = "";

    my $init = Initializer::get_json_details();

    my %json_details = %{$init};

    $pack =~ s/::/./;

    $package_path = $self->find_class_path($pack, \%json_details);

    my $class_detail = $json_details{$package_path};

    my %class_detail = %{$class_detail};

    my $request_hash={};

    foreach my $member_name (keys %class_detail)
    {
        my $member_detail = $class_detail{$member_name};

        my %member_detail = %{$member_detail};

        if(exists($class_detail{$Constants::READ_ONLY}) || !exists($member_detail{$Constants::NAME}))
        {
            next;
        }

        my $modification = $request_instance->$Constants::IS_MODIFIED_METHOD($member_detail{$Constants::NAME});

        #required check and throw exception
        # if ($modified eq '' && exists($member_detail{$Constants::REQUIRED}))
        # {
        #     my %error=();
        #     $error{$Constants::INDEX}=$instance_number;
        #     $error{$Constants::CLASS}=$pack;
        #     $error{$Constants::FILED}=$member_name;
        #     die SDKException->new({code =>$Constants::REQUIRED_FIELD_ERROR },{message =>''},{details => \%error},{cause =>''});
        # }

        my $field_value = $request_instance->{$member_name};

        if(defined($modification) && $modification != 0 && $self->value_checker(blessed($request_instance), $member_name, $member_detail, $field_value, $self->{unique_hash}, $instance_number))
        {
            my $key_name = $member_detail{$Constants::NAME};

            my $type = $member_detail{$Constants::TYPE};

            if (defined $field_value)
            {
                if("$type" eq "List")
                {
                    my @array = $self->set_json_array($field_value, $member_detail);

                    $request_hash->{$key_name} = [@array];
                }
                elsif("$type" eq "Map" || "$type" eq "HashMap")
                {
                    $request_hash->{$key_name} = $self->set_json_object($field_value, \%member_detail);
                }
                elsif(exists($member_detail{$Constants::STRUCTURE_NAME}))
                {
                    $request_hash->{$key_name} = $self->form_request($field_value, $member_detail{$Constants::STRUCTURE_NAME}, 0);
                }
                else
                {
                    $request_hash->{$key_name} = $field_value;
                }
            }
        }
    }

    return $request_hash;
}

sub append_to_request
{
    my ($self, $request_base, $request_object) = @_;

    my $request_body = $request_object->{request_body};

    my %modified_request_body = ();

    foreach my $key (keys %$request_body)
    {
        my $value = $$request_body{$key};

        if(blessed($value) && $value->isa('StreamWrapper'))
        {
            $modified_request_body{$key} = [$value->get_name()];
        }
        else
        {
            $modified_request_body{$key} = $value;
        }
    }

    $request_object->{file} = 1;

    return \%modified_request_body;
}

sub set_json_object
{
    my ($self, $field_value, $member_json_details) = @_;

    my %member_json_details = %{$member_json_details};

    my %field_value = %{$field_value};

    my %json_object = ();

    if(!%member_json_details)
    {
        foreach my $key (keys %field_value)
        {
            my $value = $field_value{$key};
            $json_object{$key} = $self->redirector_for_object_to_json($value);
        }
    }
    else
    {
        my @keys_detail = $member_json_details{$Constants::KEYS};
        foreach(@keys_detail)
        {
            my %key_detail = $_;
            my $key_name = $key_detail{$Constants::NAME};
            if(exists($member_json_details{$key_name}) && !$member_json_details{$key_name} eq '')
            {
                if(exists($key_detail{$Constants::STRUCTURE_NAME}))
                {
                    $json_object{$key_name} = $self->form_request($field_value{$key_name}, $key_detail{$Constants::STRUCTURE_NAME}, 1);
                }
                else
                {
                    $json_object{$key_name} = $self->redirector_for_object_to_json($field_value{$key_name});
                }
            }
        }
    }

    return %json_object;
}

sub set_json_array
{
    my ($self, $field_value, $member_json_details) = @_;

    my %member_json_details = %{$member_json_details};

    my @json_array = ();
    if(!%member_json_details)
    {
        foreach(@$field_value)
        {
            push(@json_array, $self->redirector_for_object_to_json("$_"));
        }
    }
    else
    {
        if(exists($member_json_details{$Constants::STRUCTURE_NAME}))
        {
            my $instance_number = 1;
            my $package = $member_json_details{$Constants::STRUCTURE_NAME};
            for my $k (@$field_value)
            {
                push(@json_array, $self->form_request($k, $package, $instance_number));
                $instance_number += 1;
            }
        }
        else
        {
            foreach(@$field_value)
            {
                push(@json_array, $self->redirector_for_object_to_json("$_"));
            }
        }
    }

    return @json_array;
}

sub find_class_path
{
    my ($self, $pack, $json_details) = @_;
    if(index($pack, "com") == -1)
    {
        foreach my $key (keys %{$json_details})
        {
            if(index($key, $pack) != -1)
            {

                $pack =  $key;
            }
        }
    }
    return $pack;
}

sub get_response
{
    my ($self,$response,$pack)= @_;
}

sub  get_wrapped_response
{
    my ($self,$response,$pack)= @_;
}





=head1 NAME

com::zoho::crm::api::util::FormDataConverter - This class is to process the upload file and stream.

=cut
1;
