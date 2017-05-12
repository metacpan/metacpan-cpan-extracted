package TestCommon::Credentials;
use File::Spec;

use base 'Exporter';

use vars qw( 
    $arg_verbose
    $arg_api_url
    $arg_authtoken
    $arg_devid
    $arg_appid
    $arg_certid
);

our @EXPORT = qw(
    $arg_verbose
    $arg_api_url
    $arg_authtoken
    $arg_devid
    $arg_appid
    $arg_certid    
);

sub load {
    my $class = shift;
    my $credentials_file_name = shift || 'test_api.credentials';

    # System independent path location of $credentials_file_name.
    my $credentials_file_path = File::Spec->catdir(
        File::Spec->rel2abs( File::Spec->curdir() ),
        't',
        $credentials_file_name
    );

    # See if there is a file with the eBay API credentials that was provided by
    # the user.  If there was then attempt to use it.  If there wasn't, then we
    # need to skip this test all-together.

    # Check for the existence of the test_api.credentials file.
    eval {
       require $credentials_file_path
    };
    
    if ( $@ ) {
        warn( "$@" . $credentials_file_path );
        return 0;
    }
    
    $arg_verbose = $::arg_verbose;
    $arg_api_url = $::arg_api_url;
    $arg_authtoken = $::arg_authtoken;
    $arg_devid = $::arg_devid;
    $arg_appid = $::arg_appid;
    $arg_certid = $::arg_certid;
        
    return 1;
}

1;

=head1 NAME

TestCommon::Credentials - loads eBay credentials from a flat file

=head1 SYNOPSIS

  use TestCommon::Credentials;
  
  unless ( TestCommon::Credentials->load() ) {
      # credentials did NOT load
  }
  
If loaded succesfully the available variables are:
  
  $::arg_appid     # application id
  $::arg_devid     # developer id
  $::arg_certid    # certification id
  $::arg_authtoken # eBay auth token
  $::arg_api_url   # eBay API URL  
  $::arg_verbose   # verbose logging flag
    
=head1 DESCRIPTION

This module reads a flat file and supplies the credentials needed by 
eBay::API

=head1 METHODS

=over 4

=item load

This method 

=back

=head1 AUTHOR

Tim Keefer <tim@timkeefer.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 eBay

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
