	# Load the Module::Install bundled in ./inc/
	use inc::Module::Install;

	# Define metadata
      name     'WSRF-Lite';
      all_from 'lib/WSRF/Lite.pm';
      author   'Mark Mc Keown <Mark.McKeown@manchester.ac.uk>';
      abstract 'Implementation of WSRF';
      license  'perl';
      version  '0.8.3.1';
	
	# add some requires for modules that dont properly specify dependencies
	requires 'Params::Validate' 		=> '0.91';
	requires 'DateTime::Locale'			=> '0.41';
	requires 'DateTime::TimeZone'		=> '0.78';
	requires 'IO::Socket::SSL'			=> '1.08';
	requires 'List::MoreUtils'			=> '0.22';
	
	# wsrf requires	
	requires 'SOAP::Lite'   			=> '0.67';
	requires 'XML::DOM'     			=> '1.44';
	requires 'DateTime::Format::Epoch'  => '0.11';
	requires 'DateTime::Format::W3CDTF' => '0.04';
	requires 'HTTP::Daemon' 			=> '1.39';
	requires 'HTTP::Daemon::SSL' 		=> '1.04';
	requires 'MIME::Base64' 			=> '3.07';
	requires 'Digest::SHA1' 			=> '2.11';
	requires 'Crypt::OpenSSL::RSA' 		=> '0.22';
	requires 'Sys::Hostname::Long' 		=> '1.4';
	# requires libxml2 on your system
	requires 'XML::LibXML'		        => '1.64';
	# not windows compatible ...
	if ( not( $^O =~ /MSWin32|Windows_NT/i ) ) {
		requires 'Crypt::OpenSSL::X509' 	=> '0.7';
	} else {
		print STDOUT "\n\nSorry, but MS Windows is not a suitable platform for asynchronous services.\n" 
		           . "While, you can still create services, you will not be able to use HTTPS\n"
		           . "because Crypt::OpenSSL::X509 is not compatible with windows (yet).\n\n";
	}
	
	build_requires 'Test::More'   => '0.42';
	build_requires 'Test::Simple' => '0.44';

    no_index       'Container.pl';
    no_index       'preForkContainer.pl';
    no_index       'SContainer.pl';
    no_index       'installer.pl';
    #no_index       'client-scripts';
    no_index       'test';
	auto_install;
	WriteAll;

