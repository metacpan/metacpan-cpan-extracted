# NAME

WebService::Amazon::Glacier - Perl module to access Amazon's Glacier service.

# VERSION

version 0.001

# SYNOPSIS

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

## DESCRIPTION

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

# AUTHOR

Charles A. Wimmer <charles@wimmer.net>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

    The (three-clause) BSD License
