use strict;
use warnings;
package WebService::Amazon::Glacier;
{
  $WebService::Amazon::Glacier::VERSION = '0.001';
}

use MooseX::App qw(Config);
use Net::Amazon::SignatureVersion4;
use YAML::XS;
use LWP::Protocol::https;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use URI::Encode;
use Digest::SHA qw(sha256_hex);
use POSIX qw(strftime);
use JSON;
use 5.010;


# ABSTRACT: Perl module to access Amazon's Glacier service.

# PODNAME: WebService::Amazon::Glacier


option 'Access_Key_Id' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    reader    => 'get_Access_Key_ID',
    predicate => 'has_Access_Key_ID',
    );

option 'Secret_Access_Key' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    reader    => 'get_Secret_Access_Key',
    predicate => 'has_Secret_Access_Key',
    );

option 'AccountID' => (
    is        => 'rw',
    isa       => 'Str',
    reader    => 'get_AccountID',
    predicate => 'has_AccountID',
    default   => '-',
    );

has 'Net_Amazon_SignatureVersion4' => (
    is     => 'rw',
    isa    => 'Object',
    writer => 'set_Net_Amazon_SignatureVersion4',
    reader => 'get_Net_Amazon_SignatureVersion4',
    );

option 'region' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_region',
    reader  => 'get_region',
    default => 'us-east-1',
    );

option 'limit' => (
    is      => 'rw',
    isa     => 'Int',
    writer  => 'set_limit',
    reader  => 'get_limit',
    default => 1000,
    );

has 'service' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_service',
    reader  => 'get_service',
    default => 'glacier',
    );

has 'ua' => (
    is     => 'rw',
    isa    => 'Object',
    writer => 'set_ua',
    reader => 'get_ua',
    );


sub BUILD{
    my $self=shift;
    my $awsSign=new Net::Amazon::SignatureVersion4();
    $self->set_Net_Amazon_SignatureVersion4($awsSign);
    $self->_update_signer();
    $self->set_ua(LWP::UserAgent->new( agent => 'perl-WebService::Amazon::Glacier'));
}

sub _update_signer{
    my $self=shift;
    $self->get_Net_Amazon_SignatureVersion4()->set_Access_Key_ID($self->get_Access_Key_ID());
    $self->get_Net_Amazon_SignatureVersion4()->set_Secret_Access_Key($self->get_Secret_Access_Key());
    $self->get_Net_Amazon_SignatureVersion4()->set_service($self->get_service());
    $self->get_Net_Amazon_SignatureVersion4()->set_region($self->get_region());
}


sub _submit_request{

    my ($self,$hr)=@_;
    
    $hr->protocol('HTTP/1.1');
    $self->_update_signer();
    $self->get_Net_Amazon_SignatureVersion4()->set_request($hr);
    my $response = $self->get_ua->request($self->get_Net_Amazon_SignatureVersion4()->get_authorized_request());
    if ( ! $response->is_success) {
	use Data::Dumper;
	my $error_detail=Data::Dumper->Dump([decode_json $response->decoded_content()]);
	$error_detail.="CREQ: \n".$self->get_Net_Amazon_SignatureVersion4()->get_canonical_request();
	$error_detail.="STS: \n".$self->get_Net_Amazon_SignatureVersion4()->get_string_to_sign();
	die  WebService::Amazon::Glacier::GlacierError->new( error_code => $response->code(),
							     error_message => $response->as_string()."\n".$error_detail,
	    );
    }
    return $response;
}
1;

__END__

=pod

=head1 NAME

WebService::Amazon::Glacier - Perl module to access Amazon's Glacier service.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    glacier list_vaults --Access_Key_Id AKIDEXAMPLE \
        --Secret_Access_Key wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY \
        --region us-west-2

    glacier list_vaults --config ~/.amazon.yaml

This module uses MooseX::App::Plugin::Config for configuration, so see
that module for usage instructions

    usage:
        glacier command [long options...]
        glacier help
        glacier command --help

    global options:
        --Access_Key_Id      [Required]
        --AccountID          [Default:"-"]
        --Secret_Access_Key  [Required]
        --config             Path to command config file
        --help --usage -?    Prints this usage information. [Flag]
        --limit              [Default:"1000"; Integer]
        --region             [Default:"us-east-1"]
        --service            [Default:"glacier"]

    available commands:
        create_vault                
        delete_vault                
        delete_vault_notifications  
        get_vault_notifications     
        glacier_error               
        help                        Prints this usage information
        list_vaults                 
        set_vault_notifications     

=head2 DESCRIPTION

This module interacts with the Amazon Glacier service.  It is an
extremely early version and is not yet complete.  It currently only
has the ability to interact with Vault objects.  Future releases will
allow interaction with Archives, Multipart uploads, and Jobs.

The focus of this module is to be used as a command line tool.
However, each of the modules may be imported and used by other modules
as well.  Please provide feedback if you have problems in either case.

Currently all the testing is performed manually.  In future releases,
there will be a test suite for some offline testing.  There will also
be a suite for testing against the live Glacier service.

=for Pod::Coverage BUILD
_update_signer

=head1 AUTHOR

Charles A. Wimmer <charles@wimmer.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
