# Load the Module::Install bundled in ./inc/
    use inc::Module::Install;
    
    # Define metadata
    name            'lsid-perl';
	version 		'1.1.7';
	license 		'cpl';
  	abstract 		'Perl module for building clients and servers which resolve and perform metadata queries on LSIDs.';
    all_from        'lib/LS.pm';
    author 			'IBM <http://lsid.sourceforge.net/>';
	
    # Specific dependencies
    requires        'Carp'              => '0';
    requires        'SOAP::Lite'    	=> '0.69';
	requires        'Compress::Zlib'    => '1.22';
	requires        'URI'    	 		=> '1.21';
	requires        'LWP'    	 		=> '5.53';
	requires        'Net::FTP'    	 	=> '2.65';
	requires        'Net::DNS'    	 	=> '0.28';
	requires        'XML::XPath'    	=> '1.12';
	requires        'MIME::Base64'    	=> '2.12';
	requires        'File::Temp'    	=> '0.12';
	requires        'File::Copy'    	=> '2.01';
	requires        'RDF::Core'    	 	=> '0.30';
	requires        'Time::HiRes'    	=> '1.20';
	requires        'MIME::Tools'    	=> '6.106';
	requires        'Error'    			=> '0.15';
	
	no_index directory => 'examples';
    	
	auto_install;
    WriteAll;