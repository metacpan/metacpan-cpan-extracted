BEGIN {
  if ($] < 5.006_001) {
    warn "\nSorry, at least Perl 5.6.1 is required for this module!\n\n";
    exit;
  }
}

use ExtUtils::MakeMaker;
use Config;

$|=0;

my %meta = (
    NAME => 'XML::CompactTree::XS',
    ABSTRACT  => 'Very fast parser of XML document into nested arrays',
    AUTHOR => 'Petr Pajas <pajas@matfyz.cz>',
    VERSION_FROM   => 'XS.pm',
    PREREQ_PM => {
        'Test::Simple' => 0,
        'XML::LibXML' => 1.68,
	# 'ExtUtils::CBuilder' => 0,
    },
    'OBJECT'    => '$(O_FILES)', # add the DOM extensions to libxml2
);

my (%config,%params);
@params{qw(DEFINE INC LIBS XMLPREFIX)}=();

@ARGV = grep {
  my ($key, $val) = split(/=/, $_, 2);
  if (exists $params{$key}) {
    $config{$key} = $val; 0
  } else { 1 }
} @ARGV;

my $xml_prefix = delete $config{XMLPREFIX};

if ($xml_prefix) {
  $config{INC}.=" -I${xml_prefix}/include";
  $config{LIBS}.=" -L${xml_prefix}/lib";
}

if ($^O ne 'MSWin32') {
  $config{INC} ||= scalar `xml2-config --cflags`;
  $config{LIBS} ||= scalar `xml2-config --libs`;
  chomp $config{$_} for qw(INC LIBS);
}

$config{LIBS} .= " -lxml2" unless ($config{LIBS} =~ /-l(?:lib)?xml2\b/);

if ($^O eq 'MSWin32') {
  my $suffix=$ENV{ACTIVEPERL_MINGW} ? '.lib' : '';
  $config{LIBS} =~ s/-lxml2\b/-llibxml2$suffix/g;
  $config{LIBS} .= " -liconv$suffix" unless ($config{LIBS} =~ /-liconv(?:$suffix)\b/);
  $config{LIBS} .= " -lzlib$suffix" unless ($config{LIBS} =~ /-lz(?:lib)?(?:$suffix)?\b/);
}
print "INC: $config{INC}\n";
print "LIBS: $config{LIBS}\n";
WriteMakefile( %meta, %config );

