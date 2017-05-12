use strict;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 
use warnings;
use Module::Build;
my $builder = Module::Build->subclass(
    class => 'BuildYahooMarketing',
    code  => q#
                 use strict; use warnings;

                 our $run_post;  

                 my %config_defaults = ( endpoint       => 'https://sandbox.marketing.ews.yahooapis.com/services',
                                         vault_endpoint => 'https://sandbox.vmarketing.ews.yahooapis.com/services',
                                         uri            => 'http://marketing.ews.yahooapis.com/V6',
                                         version        => 'V6',
                                       );

                 sub ACTION_posttest {
                     my ( $self, $cover ) = @_;

                     $run_post = 1;

                     eval { require YAML;
                            require DateTime;
                            require DateTime::Format::W3CDTF;
                          };
                     die "Build posttest requires the following CPAN modules:
    YAML
    DateTime
    DateTime::Format::W3CDTF

Please make sure they're properly installed on your system.  
" if $@;

    

                     my $build = Module::Build->current;

                     $build->notes(run_post_tests => 'yes');

                     my $section = $ENV{ YAHOO_MARKETING_CONFIG_SECTION } 
                                 ? $ENV{ YAHOO_MARKETING_CONFIG_SECTION } 
                                 : ( $build and $build->args('config_section') )
                                   ? $build->args('config_section') 
                                   : 'sandbox'
                     ;

                     $build->notes(config_section => $section);

                     my $debug_level = defined $ENV{ YAHOO_MARKETING_DEBUG }
                                     ? $ENV{ YAHOO_MARKETING_DEBUG }
                                     : ( $build and $build->args('SOAPdebug') )
                                        ? $build->args('SOAPdebug') 
                                        : 0
                     ;

                     $build->notes(SOAP_debug_level => $debug_level);

                     my $config;
                     unless( -e 'yahoo-marketing.yml' ){
                         print STDERR "Failed to find a YAML configuration file in the default location.\n"
                                     ."Please enter your Yahoo! EWS Sandbox information when prompted.\n"
                                     ."A configuration file will be created for you\n\n"
                                     ."DO NOT enter your live account information!\n\n"
                         ;
                         
   
                         my @config_values = qw/ username password license master_account default_account endpoint uri vault_endpoint version /;

                         foreach my $name ( @config_values ){
                             my $prompt = $name; $prompt =~ s/_/ /g;
                             $prompt .= " [$config_defaults{ $name }]" if defined $config_defaults{ $name };
                             my $value = $build->prompt( "$prompt:" );

                             if( not $value and $config_defaults{ $name } ){
                                $value = $config_defaults{ $name };
                             }
    
                             $config->{ 'default' }->{ $name } = $value unless $name eq 'default_account';            
                             $config->{ 'sandbox' }->{ $name } = $value;            
                         }
                         YAML::DumpFile( 'yahoo-marketing.yml', $config );
                     }else{
                        $config = YAML::LoadFile( 'yahoo-marketing.yml' );
                     }

                     $cover 
                         ? $self->ACTION_testcover
                         : $self->SUPER::ACTION_test
                     ;
                }
                sub ACTION_posttestcover {
                     my $self = shift;
                     $run_post = 1;
                     $self->ACTION_posttest( 1 );
                }
                sub ACTION_test {
                     my $self = shift;

                     my $build = Module::Build->current;
                     unless( $run_post ){
                         $build->notes(run_post_tests => '');
                         $build->notes(SOAP_debug_level => '');
                         $build->notes(config_section => '');
                     }
                     print STDERR "\nNOTE: we can run tests that will connect to Yahoo! Marketing's "
                                 ."\nEWS, verifying your login credentials and more completely testing "
                                 ."\nthat this package is performing correctly.  If you would like to "
                                 ."\nrun these tests, please use perl Build posttest."
                                 ."\n\n"
                         unless $run_post;
                     $self->SUPER::ACTION_test;
                }
             #,
);



my $build = $builder->new(
    module_name         => 'Yahoo::Marketing',
    license             => 'artistic',
    dist_author         => 'Jeff Lavallee <jeff@zeroclue.com>',
    dist_version_from   => 'lib/Yahoo/Marketing.pm',
    build_requires => {
        'Test::More'     => 0,
        'YAML'           => '0.01',
        'Module::Build'  => '0.26',  
    },
    requires => {
        'Test::More'                 => 0,
        'perl'                       => '5.6.1',   
        'SOAP::Lite'                 => '0.66',
        'YAML'                       => '0.01',
        'Class::Accessor::Chained'   => '0.01',
        'Module::Build'              => '0.26',  
        'Scalar::Util'               => '1.01',
        'Test::Class'                => '0.10',
        'Test::Simple'               => '0.60', # for displaying error message in tests correctly
        'Error'                      => '0.15',
        'Cache::Cache'               => '1.01',
        'XML::XPath'                 => '1.10',
        'Crypt::SSLeay'              => '0.40',
	    'DateTime::Format::ISO8601'  => 0,
	    'DateTime::Format::W3CDTF'   => 0,
    },
    add_to_cleanup      => [ 'Yahoo-Marketing-*' ],
    create_makefile_pl  => 'traditional',
    get_options => { SOAPdebug       => { type  => '+'  },
                     config_section  => { type  => '=s' },
                   },
);


$build->create_build_script();





