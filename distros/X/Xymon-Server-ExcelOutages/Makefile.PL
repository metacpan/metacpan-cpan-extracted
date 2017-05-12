

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $message = "Where is you cgi-bin directory ";
my $default = "/usr/local/apache2/cgi-bin/";
my $value = prompt($message, $default);


WriteMakefile(
    NAME         => 'Xymon::Server::ExcelOutages',
    VERSION_FROM => 'lib/Xymon/Server/ExcelOutages.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Produce an excel spreadsheet of outages',
    EXE_FILES    => ['scripts/ExcelOutages.pl'],	
    INSTALLDIRS  => 'perl',
    INSTALLSCRIPT   => "$value",
    PREREQ_PM    => {
			'Test::Simple' => 0.44,
			'Spreadsheet::WriteExcel' => '2.37',
			'Xymon::DB::Schema'       => '0.02',
			'Xymon::Server::History'  => '0.17',
                    },
);
