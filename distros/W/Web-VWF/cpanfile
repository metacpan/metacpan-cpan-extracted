# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.20.0';

requires 'CGI::ACL', '0.06';   # For deny_cloud
requires 'CGI::Carp';
requires 'CGI::IDS';   # Intrusion detection, used by Allow.pm and Display.pm
requires 'CGI::Info', '1.14';   # 1.14 for is_ai()
requires 'CGI::Lingua', '0.61';
requires 'CHI';
requires 'Carp';
requires 'Carp::Always';
requires 'Class::Simple';
requires 'Config::Abstraction';
requires 'Config::Auto';   # Display/table.pm
requires 'Crypt::URandom';   # CSPRNG for CSRF tokens
requires 'DBD::CSV';
requires 'DBI';
requires 'Data::Dumper';
requires 'Data::Throttler';
requires 'Data::Validate::URI';   # Allow.pm and Display.pm, to check Referer URLs
requires 'Database::Abstraction';
requires 'DateTime';   # Allow.pm, for the DShield feed date
requires 'Digest::MD5';
requires 'Digest::SHA';
requires 'Error';
requires 'FCGI';
requires 'FCGI::Buffer';
requires 'File::HomeDir';
requires 'File::Slurp';   # Display/table.pm
requires 'File::Spec';
requires 'File::pfopen';
requires 'Filesys::Df';
requires 'HTML::D3';   # Display/meta_data.pm
requires 'HTML::SocialMedia';
requires 'HTTP::Date';   # For the Last-Modified header
requires 'HTTP::Status';
requires 'JSON::MaybeXS';
requires 'LWP::Simple::WithCache';   # Allow.pm, the DShield feed
requires 'LWP::UserAgent';
requires 'Log::Abstraction';
requires 'Log::WarnDie', '0.09';
requires 'Module::Runtime';   # Safe dynamic loading; avoids string eval
requires 'Object::Configure';
requires 'Params::Get', '0.13';
requires 'Params::Validate::Strict';
requires 'Readonly';
requires 'Scalar::Util';
requires 'String::Random';
requires 'Sys::MemInfo';
requires 'Sys::Uptime';
requires 'System::Info';
requires 'Template';   # The rendering engine behind the .tmpl files
requires 'Template::Filters';
requires 'Template::Plugin::EnvHash';
requires 'Template::Plugin::JSON';
requires 'Template::Plugin::Math';
requires 'Text::xSV::Slurp';
requires 'Time::Duration::Parse';   # VWF.pm, rate-limit durations such as '5 minutes'
requires 'Time::HiRes';
requires 'Time::Piece';
requires 'Time::Seconds';
requires 'Timer::Simple';
requires 'Try::Tiny';
requires 'XML::LibXML';   # Allow.pm, parses the DShield feed
requires 'YAML';   # Throttle.pm, Allow.pm and Display.pm
requires 'version', '0.77';
recommends 'Filesys::Df';
recommends 'Mail::DKIM';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # Minimum version for TEST_REQUIRES
};

on 'test' => sub {
	requires 'File::Copy::Recursive';   # t/example-site.t, to run the example from a copy
	requires 'HTTP::Response';
	requires 'Test::DescribeMe';
	requires 'Test::Memory::Cycle';
	requires 'Test::Mockingbird';
	requires 'Test::Most';
	requires 'Test::Returns';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
