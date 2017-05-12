# No hashbang, use default Perl interpreter derived by ExtUtils::MakeMaker

################################################################################
# File: ............... Makefile.PL
# Location: ........... package root
# Original Author: .... h2xs
# Last Modified By: ... Jeff Nokes
# Last Modified: ...... 03/15/2007 @ 15:49
#
# Description:
# MakeMaker script used to generate makefile for eBay::API Perl SDK package
# install.
#
# How to execute:
#
#   perl  Makefile.PL  --help
#
################################################################################





# Required Includes
# ------------------------------------------------------------------------------
  use strict;                # Help control variable hell.
  use 5.008001;              # Requires Perl v.5.8.1 or higher, due to UTF-8
                             # encoded data used in eBay API.
  use ExtUtils::MakeMaker;   # Needed to make the makefile.
  use File::Find;            # Needed to traverse auto-gen tree.
  use File::Spec;            # Needed to create system agnostic paths.
  use Getopt::Long;          # Needed for command line option parsing.






# Variable Declarations
# ------------------------------------------------------------------------------
# Constants
  # none

# Globals
  # none

# Lexicals
  # Used to store the list of all directories to be installed during the
  # `make install` phase.
    my %lib_dirs_normalized;     # Stores a normalized list of all dirs under
                                 # ./lib.
    my @lib_dirs;                # Used to store the list returned from
                                 # keys(%lib_dirs_normalized), for further
                                 # processing.

  # Stores output from the call to the real auto-generation script below.
    my $script_output;      # Stores the output from the autogen script
                            # execution below.

  # Path to the real autogeneration script.
    my $script_path = File::Spec->catfile(
                                           'lib',
                                           'eBay',
                                           'API',
                                           'XML',
                                           'tools',
                                           'codegen',
                                           'xsd'
                                         );
    ## Debug
    #  print('DEBUG:  $script_path = ' . $script_path . "\n");

  # Name of the script to execute.
    my $script_name = 'genEBayApiDataTypes.pl';

    ## Debug
    #  print('DEBUG:  $script_name = ' . $script_name . "\n");

  # Command line arguments, have them default assinged to undefined.
    my $arg_noautogen;
    my $arg_appid;
    my $arg_devid;
    my $arg_certid;
    my $arg_authtoken;
    my $arg_usage;
    my $arg_help;
    my $arg_verbose;
    my $arg_api_url = 'https://api.sandbox.ebay.com/ws/api.dll';
    my $arg_xsd = 'http://developer.ebay.com/webservices/latest/eBaySvc.xsd';
    my $arg_xsd_file = '';
    
  # Random scalar used for storing return values temporarily, can be used for
  # anything.
    my $rv;





# Subroutine Prototypes
# ------------------------------------------------------------------------------
  sub usage(;);





# Main Script
# ------------------------------------------------------------------------------

# Begin block to force the flushing of output buffers so users can see output
# in realtime, more-or-less ...
   BEGIN {

      my $current_fh;           # Stores the current filehandle for preservation.

      # Set the flag for STDOUT
        $current_fh = select(STDOUT);   # Get what the fh was before selecting STDOUT.
        $| = 1;                         # Set the autoflush flag to TRUE.
        select($current_fh);            # Reselect the original fh.

      # Set the flag for STDERR
        $current_fh = select(STDERR);   # Get what the fh was before selecting STDERR.
        $| = 1;                         # Set the autoflush flag to TRUE.
        select($current_fh);            # Reselect the original fh.

   }# end BEGIN block



# Get any command line arguments provided by the user.
  Getopt::Long::GetOptions (
     'noautogen'   => \$arg_noautogen,
     'verbose'     => \$arg_verbose,
     'appid=s'     => \$arg_appid,
     'devid=s'     => \$arg_devid,
     'certid=s'    => \$arg_certid,
     'api_url=s'   => \$arg_api_url,
     'authtoken=s' => \$arg_authtoken,
     'usage'       => \$arg_usage,
     'xsd=s'       => \$arg_xsd,
     'xsd_file=s'  => \$arg_xsd_file,
     'help'        => \$arg_help,
  );



# Check for user request of usage/help.  If requested, show useage and exit the
# script with success.
  if ($arg_usage || $arg_help)
     {&usage();
      exit(0);
     }# end if



# Print a beginning statement to the user, who needs to know that executing
# this script will attempt to autogenerate the latest call and datatype classes
# for them, which means they'll need an internet connection during the execution
# of this script.
  print(
          "\n" .
          "\n" .
          "\n" .
          'BEGIN: eBay API Perl SDK package installation' . "\n" .
          "\n" .
          "\n"
       );



# If all necessary eBay API credentials were supplied by the user, then attmept
# to generate the credentials file to use in the installation tests, for making
# a test API call to eBay's Sandbox API test environment.
  if (
        $arg_appid      &&
        $arg_devid      &&
        $arg_certid     &&
        $arg_authtoken 
     )
     {# Create a system independent file path for the credentials file.
        my $credentials_file_path = File::Spec->catfile(
              't',
              'test_api.credentials',
           );

      # Attempt to create a file containing all of these parms, for use in
      # test scripts.
        (
            (
                   open(CRED_FILE, ">$credentials_file_path")
               and
                   # Attempt to write to the credentials file, all of the
                   # provided credentials from the user at the command line.
                     print CRED_FILE (
                        '$::arg_appid = \'' . $arg_appid . "';\n" .
                        '$::arg_devid = \'' . $arg_devid . "';\n" .
                        '$::arg_certid = \'' . $arg_certid . "';\n" .
                        '$::arg_authtoken = \'' . $arg_authtoken . "';\n" .
                        '$::arg_api_url = \'' . $arg_api_url . "';\n" .
                        '$::arg_verbose = \'' . $arg_verbose . "';\n" .
                        '1;'
                        
                     )
            )
           and
               close(CRED_FILE)
           and
               print STDOUT (
                  "\n" .
                  'Successfully created testing credentials file ...' . "\n" .
                  "\n" .
                  "\n"
               )
        )
        or
        warn(
               "\n" .
               'WARNING !!! - Attempted to create temporary credentials file, operation' . "\n" .
               'failed!  No API call tests will be performed during the `make test` phase.' . "\n" .
               "\n" .
               "\n"
            );

     }# end if

  else {
     print STDOUT (
        "\n" .
        'ATTENTION !!! - I either did not detect all required command line arguments to' . "\n" .
        'perform any explicit API call tests during `make test`, or the \'noautogen\'' . "\n" .
        'command line argument was given; skipping configuration of these specific tests.' . "\n" .
        "\n" .
        "\n"
     );
  }# end else




################################################################################
# Auto-generate all eBay call and datatype classes, using the provided package
# tools.

# Determine if the user decided to not perform the autogeneration of eBay call
# and datatype classes.  If they don't want it, don't do it.
  if (!$arg_noautogen) {

    # Print out some info to the user, so they know what is going on.
      print(
              "\n" .
              '*'x80 . "\n" .
              "\n" .
              'BEGIN: auto-generation of eBay call and datatype classes ...' . "\n" .
              "\n" .
              "\n" .
              'Note:  If you are auto-generating the ebay call and datatype classes, then' . "\n" .
              '       you must have an active internet connection before attempting to' . "\n" .
              '       execute this installation!' . "\n" .
              "\n" .
              "\n"
           );

    # Give the user time to digest this message.
      sleep(5);

    # Execute the autogeneration script, using the argument passed in via
    # Makefile.PL, as the fully qualified URL to the XSD documentation.  We need
    # to use a system() call here, since we want to stay in this script post
    # fork() and execution, unlike exec().  `` will not give unbuffered output.
      my @gen_cmd = (
        "cd $script_path",
        "&&",
        "$^X $script_name",
      );
      
      if ( $arg_xsd_file ) {
        die "Unable to locate local xsd file: $arg_xsd_file" 
            if ! -e $arg_xsd_file;

        push( @gen_cmd, "--file=$arg_xsd_file" );  
      }
      else {    
        push( @gen_cmd, "--url=$arg_xsd" );
      }
   
      print( 
        "\nGenerating base classes -\n" 
        . join( ' ', @gen_cmd ) 
      );
 
      system( join( ' ', @gen_cmd ) );

    # Print out some info to the user, that the auto-generation phase has completed.
      print(
              "\n" .
              "\n" .
              'END:  auto-generation of eBay call and datatype classes ...' . "\n" .
              "\n" .
              '*'x80 . "\n" .
              "\n" .
              "\n"
           );

  }# end if

  else {
     # Mention to the user that they have chosen to skip the autogeneration
     # step, and they will have to do it on their own.
       print(
               "\n" .
               'ATTENTION !!! - You have opted not to auto-generate the eBay call and' . "\n" .
               'datatype classes during the Makefile generation phase.  Before this SDK' . "\n" .
               'will function properly, you __MUST__ perform the auto-generation process' . "\n" .
               'manually.  Please reference the perldoc in API.pm for directions on how' . "\n" .
               'to auto-generate the classes manually.' . "\n" .
               "\n" .
               "\n"
            );

     # Sleep for a bit to let the user digest this.
       sleep(5);

  }# end else

#
################################################################################



################################################################################
# Makefile Generation

  # Print something to the user so they know what step this script is on.
    print(
            "\n" .
            '*'x80 . "\n" .
            "\n" .
            'BEGIN: Makefile generation ...' . "\n" .
            "\n" .
            "\n"
         );


  # Get a list of all directories under ./lib, to make sure everything that
  # was auto-generated, gets installed at `make install` time.
    File::Find::find(\&wanted, 'lib');

    ## Debug
    #  foreach my $path (sort(keys(%lib_dirs_normalized))) {
    #     print STDERR ('DEBUG:  Path = ' . $path . "\n");
    #  }# end foreach loop

    # Get all of the hash keys (paths), and put them into a sorted array.
      @lib_dirs = sort(keys(%lib_dirs_normalized));

      # Add more dirs on a one-off basis
        push(
               @lib_dirs,
               'eg',          # The 'eg' (examples) directory
               'eg/XML',      # The example script dir for XML API scripts
            );


  # Attempt to write the makefile.
    WriteMakefile(

       # The name of the package.
         NAME => 'eBay::API',
       
       # Tests
         test => { TESTS => 't/*.t t/calls/*.t' },
       
       NO_META => 1,
         
       # The version of the package.
         VERSION_FROM  => 'lib/eBay/API.pm',  #(uses $VERSION)

       # Required modules & their respective versions (e.g. Module::Name => 1.1).
       # Can be these versions or higher.  Many of these should be default
       # installed with a standard Perl installation.
         PREREQ_PM  => {
            'Compress::Zlib'      => 1.41,
            'Crypt::SSLeay'       => 0.51,
            'Cwd'                 => 3.18,
            'Data::Dumper'        => 2.121,
            'Devel::StackTrace'   => 1.03,
            'Encode'              => 1.9801,
            'Error'               => 0.15,
            'Exception::Class'    => 1.14,
            'Exporter'            => 5.567,
            'File::Find'          => 1.05,
            'File::Path'          => 1.06,
            'File::Spec'          => 3.18,
            'Getopt::Long'        => 2.34,
            'HTTP::Headers'       => 1.47,
            'HTTP::Request'       => 1.34,
            'HTTP::Status'        => 1.28,
            'IO::File'            => 1.10,
            'LWP::Parallel'       => 2.57,
            'LWP::UserAgent'      => 2.023,
            'Params::Validate'    => 0.74,
            'Scalar::Util'        => 1.11,
            'Time::HiRes'         => 1.51,
            'Time::localtime'     => 1.02,
            'XML::Simple'         => 2.09,
            'XML::Tidy'           => '1.2.54HJnFa',
            'XML::Writer'         => 0.600,
         },

       # Add these new keywords supported since 5.005
         ($] >= 5.005 ?
           (ABSTRACT_FROM  => 'lib/eBay/API.pm', # retrieve abstract from module
            AUTHOR         => 'eBay Inc. <perl@ebay.com>',
           )
           : ()
         ),

       # Directories to scan, to make sure all auto-generated code gets
       # installed in the appropriate directories.  This should account for
       # everything, even the non-auto-generated stuff under the XML dir tree.
         PMLIBDIRS => \@lib_dirs,

# Nokes:  Save for reference.  The PM section will override the PMLIBDIRS,
#         and we want everything.
#
#       # Individual files to install, so extra stuff from the package doesn't
#       # get installed.  Basically, everything under eBay and eBay/API.
#         PM => {
#            'lib/eBay/API.pm'       => '$(INST_LIBDIR)/eBay/API.pm',
#            'lib/eBay/Exception.pm' => '$(INST_LIBDIR)/eBay/Exception.pm',
#            'lib/eBay/API/BaseApi.pm'   => '$(INST_LIBDIR)/eBay/API/BaseApi.pm',
#         },

    );# end ExtUtils::MakeMaker::WriteMakefile()


  # Print out some info to the user, that the makfile creation phase has
  # completed.
    print(
            "\n" .
            "\n" .
            'END: Makefile generation ...' . "\n" .
            "\n" .
            '*'x80 . "\n" .
            "\n" .
            "\n" .
            "\n" .
            "\n"
         );

#
################################################################################





# Subroutine Definitions
# ------------------------------------------------------------------------------

# wanted()
#
# Description:   Subroutine used as the default callback for
#                File::Find::finddepth().  It basically gets invoked for each
#                directory path found under a certain starting point in the
#                tree.  This sub will attempt to append each path found, to the
#                script lexical hash %lib_dirs_normalized, for later use when
#                configuring the lib dirs that need to get installed during the
#                `make install` step.
#
# Note:          This sub assumes implicit access to all script lexcial
#                variables.
#
# Arguments:     01 [R]  File::Find passes in all available arguments, see
#                        File::Find documentation for further details.
#
# Upon Success:  returns TRUE
# Upon Failure:  (can't really get this)

sub wanted {

   # Push the path into the hash, so we will have only single occurances of
   # paths to provide to MakeMaker.
     \%lib_dirs_normalized->{$File::Find::dir}++;

   # Return success to the caller.
     return(1);

}# end sub wanted()




# usage()
#
# Description:  Simple subroutine used to display the usage of this script to
#               the user who is trying to execute it.  It will just print to
#               STDOUT.
#
# Arguments:    None
#
# Returns:      Nothing

sub usage (;) {

   # Local Variables
     my $msg = <<"USAGE";


--------------------------------------------------------------------------------
usage:

perl  Makefile.PL  [any standard Perl options] \\
                   [--noautogen] \\
                   [--xsd='<url to alternate xsd file>] \\
                   [--xsd_file='<path to local xsd file>] \\
                   [--appid='<provided_from_eBay_devzone_registration>']  \\
                   [--devid='<provided_from_eBay_devzone_registration>']  \\
                   [--certid='<provided_from_eBay_devzone_registration>'] \\
                   [--api_url='<alternate eBay api url>'] \\
                   [--authtoken='<your eBay Sandbox authtoken>' |
                                `cat authtokenfilename`]                  \\
                   [--usage|--help]

Options:
   Standard ExtUtils::MakeMaker Options: (i.e. PREFIX=/usr/local/lib/perl)
   --noautogen:  Boolean used to tell script not to perform the
                 auto-generation of eBay call and datatype classes.
   --verbose:    Boolean used to enable verbose logging   
   --xsd:        URL of the eBay xsd schema file. Default xsd,
                 http://developer.ebay.com/webservices/latest/eBaySvc.xsd
   --xsd_file:   path to local xsd schema file.
   --appid:      String containing the AppID provided to you by the eBay
                 Developer's Program, upon registration.
   --devid:      String containing the DevID provided to you by the eBay
                 Developer's Program, upon registration.
   --certid:     String containing the CertID provided to you by the eBay
                 Deverloper's Program, upon registration.
   --api_url:    URL to alternate eBay API location, defaults to the sandbox
   --authtoken:  String containing the authentication token provided to you by
                 the eBay Deverloper's Program, upon registration.
   --usage:      Displays usage of this script.
   --help:       Same as --usage.

Notes:
   (1)  If you provide the --noautogen switch, you will have to auto-generate
        all eBay call and datatype classes yourself.  Please read the pod
        documentation in API.pm  and
        <module_root>/eBay/API/XML/tools/codegen/xsd/README
        for further information on how to manually generate this code.
   (2)  If any of the --appid, --devid, --certid, --authtoken switches
        are missing, the `make test` process will not attempt to make an API
        call to the eBay Sandbox API test environment.  If the 'noautogen'
        argument is detected, this will negate any attempts to make API call
        tests as well.
   (3)  It is _ALWAYS_ recommended that you wrap any of your command line
        argument values in single quotes.  Many properties such as certid's and
        authtokens usually have characters in them that will mean something to
        whatever shell you are trying to install this module in (i.e. '\$').

--------------------------------------------------------------------------------


USAGE

   # Print the usage to the user
     print($msg);

}# end sub usage()








#'# Putting this here to alleviate my editor's coloring of quoted text

# Extra stuff to keep around for future reference
# ------------------------------------------------------------------------------
=pod
Ignore anything you may see from here ...

                   [--username=<your eBay Sandbox username>] \\
                   [--password=<your eBay Sandbox password>] \\

... to here
=cut

