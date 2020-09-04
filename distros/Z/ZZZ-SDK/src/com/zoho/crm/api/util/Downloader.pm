use strict;
use warnings;
use src::com::zoho::crm::api::util::Converter;
use src::com::zoho::crm::api::util::StreamWrapper;
use src::com::zoho::crm::api::Initializer;
use src::com::zoho::crm::api::util::Constants;

package Downloader;
use Moose;

extends 'Converter';

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

    return $self->get_response($response, $pack);
}

sub get_response
{
    my ($self, $response, $pack)= @_;

    my $json_details = Initializer::get_json_details();

    my %json_details = %{$json_details};

    my $package_path = $self->find_class_path($pack, $json_details);

    my $class_detail = $json_details{$package_path};

    my %class_detail = %{$class_detail};

    if(exists($class_detail{$Constants::INTERFACE}) && !$class_detail{$Constants::INTERFACE} eq '')
    {
        my $classes = $class_detail{$Constants::CLASSES};

        foreach(@$classes)
        {
            if(index("$_", $Constants::FILE_BODY_WRAPPER) != -1)
            {
                return $self->get_response($response, "$_");
            }
        }
    }
    else
    {
        my $instance;

        my $class_to_load = $self->construct_class_to_load($package_path, $json_details);

        require $class_to_load;

        my @names = split('\.', $pack);

        $instance =  (@names[@names-2] . '::' . @names[@names-1])->new();

        foreach my $member_name (keys %class_detail)
        {
            my $instance_value;

            my $member_detail = $class_detail{$member_name};

            my %member_detail = %{$member_detail};

            my $type = $member_detail{$Constants::TYPE};

            my $file_name = "";

            if("$type" eq $Constants::STREAM_WRAPPER_CLASS_PATH)
            {
                my $stream = $response->decoded_content();

                my $response_headers = $response->headers;

                my %response_headers = %{$response_headers};

                my $content_disposition = $response_headers{'content-disposition'};

                if(index($content_disposition, "'") != -1)
                {
                    my $start_index = rindex($content_disposition, "'");

                    $file_name = substr($content_disposition, $start_index + 1);
                }
                elsif(index($content_disposition, "\""))
                {
                    my $start_index = rindex($content_disposition, '=');

                    $file_name = substr($content_disposition, $start_index + 1);

                    $file_name =~ s/\"/""/g;
                }

                my $stream_wrapper = StreamWrapper->new($file_name, $stream, undef);

                $instance_value= $stream_wrapper;
            }
            $instance->{$member_name}  = $instance_value;
        }
        return $instance;
    }
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

sub construct_class_to_load
{

  my($self, $pack, $json_details) = @_;

  my $modified_class_path = $pack;

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

=head1 NAME

com::zoho::crm::api::util::Downloader - This class is to process the download file and stream response.

=cut

1;
