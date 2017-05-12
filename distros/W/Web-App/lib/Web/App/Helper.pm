package Web::App::Helper;

use Class::Easy;

use IO::Easy::File;
use IO::Easy::Dir;

use Project::Easy::Config;
use Project::Easy::Helper;

sub ::entangle {
	
	$Class::Easy::DEBUG = 'immediately';

	Project::Easy::Helper::_script_wrapper (
		IO::Easy::Dir->current->append ('bin', 'fake')
	);
	
	my $pack = $::project;
	
	my $apxs_libexec;
	my $apxs;
	
	foreach my $apxs_cmd ((
		'ap2xs',
		'apxs',
		'apxs2',
		'/usr/sbin/apxs', # Old Fedora verions
		'/usr/sbin/apxs2' # Opensuse "alias" [sic]
	)) {
		my $apxs_test = `$apxs_cmd -q LIBEXECDIR 2>/dev/null`;
		
		chomp $apxs_test;
		next unless $apxs_test;
		
		$apxs_libexec = $apxs_test;
		$apxs = $apxs_cmd;
		
	}
	
	die "no apxs libexec directory"
		unless $apxs_libexec;

	debug "found apxs libexecdir $apxs_libexec";
	
	my $httpd_dir  = `$apxs -q SBINDIR`;
	chomp $httpd_dir;
	my $httpd_name = `$apxs -q TARGET`;
	chomp $httpd_name;
	
	my $httpd_bin = IO::Easy->new ($httpd_dir)->append ($httpd_name);
	
	my $vars = {
		root	=> $pack->root,
		distro  => $pack->distro,
		project => $pack->id,
		user	=> scalar getpwuid ($<),
		group   => scalar getgrgid ($(),
		port	=> 50000,
		admin   => 'author@example.com',
		
		apxs_libexec => $apxs_libexec,
		
		httpd_bin => $httpd_bin,
	};

	my $files = &IO::Easy::File::__data__files;
	
	my $root = $pack->root;
	
	my $global_config_patch_json = delete $files->{global_config_patch_json};
	my $local_config_patch_json  = delete $files->{local_config_patch_json};
	
	debug "storing config files";
	
	foreach my $deploy_file_tmpl (keys %$files) {
		
		# for files with expansion
		my $deploy_file_name = Project::Easy::Config::string_from_template (
			$deploy_file_tmpl,
			$vars
		);

		my $deploy_file = $root->append ($deploy_file_name)->as_file;
		
		my $deploy_dir = $deploy_file->parent;
		$deploy_dir->create;
		
		my $deploy_tmpl = $files->{$deploy_file_tmpl};
		my $deploy_contents = Project::Easy::Config::string_from_template (
			$deploy_tmpl,
			$vars
		);
		
		my $result = $deploy_file->store_if_empty ($deploy_contents);
		
		# TODO: make correct routine for file names comparison (etc/ and etc, as example)
		# because some files may be incorrectly chmod'ed
		if ($deploy_dir->name eq $pack->bin) { # and $deploy_dir->updir eq $pack->root) {
			chmod (0755, $deploy_file);
		}
		
		# warn "something"
		#	unless defined $result;
	}
	
	debug "patching configuration for daemon";
	
	# within helper we have json structures
	my $serializer = Project::Easy::Config->serializer ('json');
	
	# global config
	my $patch = $serializer->parse_string ($global_config_patch_json);
	$pack->conf_path->patch ($patch);

	# local config, variables expansion
	$local_config_patch_json = Project::Easy::Config::string_from_template (
		$local_config_patch_json,
		$vars
	);
	$patch = $serializer->parse_string ($local_config_patch_json);
	$pack->fixup_path->patch ($patch);
	
	$pack->root->dir_io ('htdocs')->create;
	
	debug "done";
}

1;

__DATA__

########################################
IO::Easy etc/httpd.conf
########################################

PerlOptions +GlobalRequest

ErrorLog "var/log/error_log"
PidFile  "var/run/{$project}-backend.pid"


########################################
IO::Easy etc/{$distro}/httpd.conf
########################################

ServerName 127.0.0.1
ServerAdmin {$admin}
Listen {$port}
ServerRoot {$root}
LockFile {$root}/var/lock/accept
DocumentRoot {$root}/htdocs/
User  {$user}
Group {$group}

# Directive below is needed on old Fedora versions
#TypesConfig /path/to/mime.types

LoadModule perl_module {$apxs_libexec}/mod_perl.so
LoadModule mime_module {$apxs_libexec}/mod_mime.so

PerlConfigRequire {$root}/bin/mod_perl_startup

Include {$root}/etc/httpd.conf

<IfModule prefork.c>
	MaxClients	   15
	StartServers	 5
	MinSpareServers  1
	MaxSpareServers  3
	MaxRequestsPerChild  100
</IfModule>

########################################
IO::Easy etc/{$project}-web-app.xml
########################################

<?xml version="1.0" encoding="UTF-8"?>
<config xmlns:xi="http://www.w3.org/2001/XInclude">
	<request
		pack="Web::App::Request"
	/>
	
	<!--session
		pack="Web::App::Session"
		request_provider="Web::App::Session::Cookie"
		account_provider="Entity::Account"
		entity="{$project}"
	/-->
	
	<presenter
		pack="Web::App::Presenter::XSLT"
		type="xslt"
		template-set="{$project}"
		encoding="utf-8"
		extension="html"/>

	<presenter
		pack="Web::App::Presenter::XMLDump"
		type="xmldump"
		extension="xml"/>

	<presenter
		pack="Web::App::Presenter::JSON"
		type="json"
		extension="json"/>
	
	<xi:include href="{$project}-screens.xml"/>
</config>

########################################
IO::Easy etc/{$project}-screens.xml
########################################

<screens>
	
	<!-- request-queue description: how to understand
		screen in user request -->
	<request-queue separators='/!'>
		<user-name separator-symbol='•' name-position='before'/>
	</request-queue>
	
	<base-url>/</base-url>
	
	<screen id=""> <!-- default screen -->
		<presentation type="xslt"/>
	</screen>

	<screen id="config">
		<presentation type="json" var="request"/>
	</screen>
</screens>

########################################
IO::Easy bin/mod_perl_startup
########################################

#!/usr/bin/perl -w

use Class::Easy;
use Project::Easy qw(script);

use Web::App;
use Web::App::Request;

$Class::Easy::DEBUG = 'immediately';

warn "\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\nstarting Web::App mod_perl";

my $wa = Web::App->new (
	project => $::project
);

Web::App::Request->preload ($wa);

warn "init done";

1;

########################################
IO::Easy bin/backend
########################################

#!/usr/bin/perl

use Class::Easy;

use Project::Easy qw(script);
use Project::Easy::Helper;

# there initialization for core package
my $instance = $::project;

my $distro = $instance->distro;

print "project '".$instance->id."' using distribution: '$distro'\n";

Project::Easy::Helper::status ();

print "modules are ok\n";

my $backend = $instance->daemon ('backend');

print 'process id ' . ($backend->pid || '[undef]') . ' is' . (
	$backend->running
	? ''
	: ' not'
) . " running\n";

exit unless $ARGV[0];

if ($ARGV[0] eq 'stop') {
	if (! $backend->running) {
		print "no process is running\n";
		exit;
	}
	
	print "awaiting process to kill… ";
	$backend->shutdown;
	
	print "\n";

} elsif ($ARGV[0] eq 'start') {
	if ($backend->running) {
		print "no way, process is running\n";
		exit;
	}
	
	$backend->launch;
	
} elsif ($ARGV[0] eq 'restart') {
	if ($backend->running) {
		my $finished = $backend->shutdown;
		
		unless ($finished) {
			print "pid is running after kill, please kill manually\n";
			exit;
		}
	}
	
	$backend->launch;
}

########################################
IO::Easy share/presentation/{$project}/index.xsl
########################################
<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0">

	<xsl:output
		method="html"
		encoding="utf-8"/>

	<xsl:template match="/">
<html>
	<body>
		<h1>hello, world!</h1>
		<p>you have completed web-app installation and ready to start development.</p>
		<p>documentation: <a href="#">here</a></p>
		<p onclick="document.getElementById ('source').style.display = 'block';">click to view xml source</p>
		<textarea id="source" rows="20" style="width: 100%; display: none;"><xsl:copy-of select="/"/></textarea>
	</body>
</html>
	</xsl:template>

</xsl:stylesheet>

########################################
# IO::Easy::File global_config_patch_json
########################################

{
	"daemons" : {
		"backend" : {
			"conf_file" : "{$root}/etc/{$distro}/httpd.conf"
		}
	}
}

########################################
# IO::Easy::File local_config_patch_json
########################################

{
	"daemons" : {
		"backend" : {
			"bin" : "{$httpd_bin}"
		}
	}
}

########################################
IO::Easy share/presentation/symbols.ent
########################################

<!ENTITY	nbsp	"&#160;">
<!ENTITY	iexcl	"&#161;">
<!ENTITY	cent	"&#162;">
<!ENTITY	pound	"&#163;">
<!ENTITY	curren	"&#164;">
<!ENTITY	yen		"&#165;">
<!ENTITY	brvbar	"&#166;">
<!ENTITY	sect	"&#167;">
<!ENTITY	uml		"&#168;">
<!ENTITY	copy	"&#169;">
<!ENTITY	ordf	"&#170;">
<!ENTITY	laquo	"&#171;">
<!ENTITY	not		"&#172;">
<!ENTITY	shy		"&#173;">
<!ENTITY	reg		"&#174;">
<!ENTITY	macr	"&#175;">
<!ENTITY	deg		"&#176;">
<!ENTITY	plusmn	"&#177;">
<!ENTITY	sup2	"&#178;">
<!ENTITY	sup3	"&#179;">
<!ENTITY	acute	"&#180;">
<!ENTITY	micro	"&#181;">
<!ENTITY	para	"&#182;">
<!ENTITY	middot	"&#183;">
<!ENTITY	cedil	"&#184;">
<!ENTITY	sup1	"&#185;">
<!ENTITY	ordm	"&#186;">
<!ENTITY	raquo	"&#187;">
<!ENTITY	frac14	"&#188;">
<!ENTITY	frac12	"&#189;">
<!ENTITY	frac34	"&#190;">
<!ENTITY	iquest	"&#191;">
<!ENTITY	Agrave	"&#192;">
<!ENTITY	Aacute	"&#193;">
<!ENTITY	Acirc	"&#194;">
<!ENTITY	Atilde	"&#195;">
<!ENTITY	Auml	"&#196;">
<!ENTITY	Aring	"&#197;">
<!ENTITY	AElig	"&#198;">
<!ENTITY	Ccedil	"&#199;">
<!ENTITY	Egrave	"&#200;">
<!ENTITY	Eacute	"&#201;">
<!ENTITY	Ecirc	"&#202;">
<!ENTITY	Euml	"&#203;">
<!ENTITY	Igrave	"&#204;">
<!ENTITY	Iacute	"&#205;">
<!ENTITY	Icirc	"&#206;">
<!ENTITY	Iuml	"&#207;">
<!ENTITY	ETH		"&#208;">
<!ENTITY	Ntilde	"&#209;">
<!ENTITY	Ograve	"&#210;">
<!ENTITY	Oacute	"&#211;">
<!ENTITY	Ocirc	"&#212;">
<!ENTITY	Otilde	"&#213;">
<!ENTITY	Ouml	"&#214;">
<!ENTITY	times	"&#215;">
<!ENTITY	Oslash	"&#216;">
<!ENTITY	Ugrave	"&#217;">
<!ENTITY	Uacute	"&#218;">
<!ENTITY	Ucirc	"&#219;">
<!ENTITY	Uuml	"&#220;">
<!ENTITY	Yacute	"&#221;">
<!ENTITY	THORN	"&#222;">
<!ENTITY	szlig	"&#223;">
<!ENTITY	agrave	"&#224;">
<!ENTITY	aacute	"&#225;">
<!ENTITY	acirc	"&#226;">
<!ENTITY	atilde	"&#227;">
<!ENTITY	auml	"&#228;">
<!ENTITY	aring	"&#229;">
<!ENTITY	aelig	"&#230;">
<!ENTITY	ccedil	"&#231;">
<!ENTITY	egrave	"&#232;">
<!ENTITY	eacute	"&#233;">
<!ENTITY	ecirc	"&#234;">
<!ENTITY	euml	"&#235;">
<!ENTITY	igrave	"&#236;">
<!ENTITY	iacute	"&#237;">
<!ENTITY	icirc	"&#238;">
<!ENTITY	iuml	"&#239;">
<!ENTITY	eth		"&#240;">
<!ENTITY	ntilde	"&#241;">
<!ENTITY	ograve	"&#242;">
<!ENTITY	oacute	"&#243;">
<!ENTITY	ocirc	"&#244;">
<!ENTITY	otilde	"&#245;">
<!ENTITY	ouml	"&#246;">
<!ENTITY	divide	"&#247;">
<!ENTITY	oslash	"&#248;">
<!ENTITY	ugrave	"&#249;">
<!ENTITY	uacute	"&#250;">
<!ENTITY	ucirc	"&#251;">
<!ENTITY	uuml	"&#252;">
<!ENTITY	yacute	"&#253;">
<!ENTITY	thorn	"&#254;">
<!ENTITY	yuml	"&#255;">
<!ENTITY	fnof	"&#402;">
<!ENTITY	Alpha	"&#913;">
<!ENTITY	Beta	"&#914;">
<!ENTITY	Gamma	"&#915;">
<!ENTITY	Delta	"&#916;">
<!ENTITY	Epsilon	"&#917;">
<!ENTITY	Zeta	"&#918;">
<!ENTITY	Eta		"&#919;">
<!ENTITY	Theta	"&#920;">
<!ENTITY	Iota	"&#921;">
<!ENTITY	Kappa	"&#922;">
<!ENTITY	Lambda	"&#923;">
<!ENTITY	Mu		"&#924;">
<!ENTITY	Nu		"&#925;">
<!ENTITY	Xi		"&#926;">
<!ENTITY	Omicron	"&#927;">
<!ENTITY	Pi		"&#928;">
<!ENTITY	Rho		"&#929;">
<!ENTITY	Sigma	"&#931;">
<!ENTITY	Tau		"&#932;">
<!ENTITY	Upsilon	"&#933;">
<!ENTITY	Phi		"&#934;">
<!ENTITY	Chi		"&#935;">
<!ENTITY	Psi		"&#936;">
<!ENTITY	Omega	"&#937;">
<!ENTITY	alpha	"&#945;">
<!ENTITY	beta	"&#946;">
<!ENTITY	gamma	"&#947;">
<!ENTITY	delta	"&#948;">
<!ENTITY	epsilon	"&#949;">
<!ENTITY	zeta	"&#950;">
<!ENTITY	eta		"&#951;">
<!ENTITY	theta	"&#952;">
<!ENTITY	iota	"&#953;">
<!ENTITY	kappa	"&#954;">
<!ENTITY	lambda	"&#955;">
<!ENTITY	mu		"&#956;">
<!ENTITY	nu		"&#957;">
<!ENTITY	xi		"&#958;">
<!ENTITY	omicron	"&#959;">
<!ENTITY	pi		"&#960;">
<!ENTITY	rho		"&#961;">
<!ENTITY	sigmaf	"&#962;">
<!ENTITY	sigma	"&#963;">
<!ENTITY	tau		"&#964;">
<!ENTITY	upsilon	"&#965;">
<!ENTITY	phi		"&#966;">
<!ENTITY	chi		"&#967;">
<!ENTITY	psi		"&#968;">
<!ENTITY	omega	"&#969;">
<!ENTITY	thetasym	"&#977;">
<!ENTITY	upsih	"&#978;">
<!ENTITY	piv		"&#982;">
<!ENTITY	bull	"&#8226;">
<!ENTITY	hellip	"&#8230;">
<!ENTITY	prime	"&#8242;">
<!ENTITY	Prime	"&#8243;">
<!ENTITY	oline	"&#8254;">
<!ENTITY	frasl	"&#8260;">
<!ENTITY	weierp	"&#8472;">
<!ENTITY	image	"&#8465;">
<!ENTITY	real	"&#8476;">
<!ENTITY	trade	"&#8482;">
<!ENTITY	alefsym	"&#8501;">
<!ENTITY	larr	"&#8592;">
<!ENTITY	uarr	"&#8593;">
<!ENTITY	rarr	"&#8594;">
<!ENTITY	darr	"&#8595;">
<!ENTITY	harr	"&#8596;">
<!ENTITY	crarr	"&#8629;">
<!ENTITY	lArr	"&#8656;">
<!ENTITY	uArr	"&#8657;">
<!ENTITY	rArr	"&#8658;">
<!ENTITY	dArr	"&#8659;">
<!ENTITY	hArr	"&#8660;">
<!ENTITY	forall	"&#8704;">
<!ENTITY	part	"&#8706;">
<!ENTITY	exist	"&#8707;">
<!ENTITY	empty	"&#8709;">
<!ENTITY	nabla	"&#8711;">
<!ENTITY	isin	"&#8712;">
<!ENTITY	notin	"&#8713;">
<!ENTITY	ni		"&#8715;">
<!ENTITY	prod	"&#8719;">
<!ENTITY	sum		"&#8721;">
<!ENTITY	minus	"&#8722;">
<!ENTITY	lowast	"&#8727;">
<!ENTITY	radic	"&#8730;">
<!ENTITY	prop	"&#8733;">
<!ENTITY	infin	"&#8734;">
<!ENTITY	ang		"&#8736;">
<!ENTITY	and		"&#8743;">
<!ENTITY	or		"&#8744;">
<!ENTITY	cap		"&#8745;">
<!ENTITY	cup		"&#8746;">
<!ENTITY	int		"&#8747;">
<!ENTITY	there4	"&#8756;">
<!ENTITY	sim		"&#8764;">
<!ENTITY	cong	"&#8773;">
<!ENTITY	asymp	"&#8776;">
<!ENTITY	ne		"&#8800;">
<!ENTITY	equiv	"&#8801;">
<!ENTITY	le		"&#8804;">
<!ENTITY	ge		"&#8805;">
<!ENTITY	sub		"&#8834;">
<!ENTITY	sup		"&#8835;">
<!ENTITY	nsub	"&#8836;">
<!ENTITY	sube	"&#8838;">
<!ENTITY	supe	"&#8839;">
<!ENTITY	oplus	"&#8853;">
<!ENTITY	otimes	"&#8855;">
<!ENTITY	perp	"&#8869;">
<!ENTITY	sdot	"&#8901;">
<!ENTITY	lceil	"&#8968;">
<!ENTITY	rceil	"&#8969;">
<!ENTITY	lfloor	"&#8970;">
<!ENTITY	rfloor	"&#8971;">
<!ENTITY	lang	"&#9001;">
<!ENTITY	rang	"&#9002;">
<!ENTITY	spades	"&#9824;">
<!ENTITY	clubs	"&#9827;">
<!ENTITY	hearts	"&#9829;">
<!ENTITY	diams	"&#9830;">
<!ENTITY	loz		"&#9674;">
<!ENTITY	OElig	"&#338;">
<!ENTITY	oelig	"&#339;">
<!ENTITY	Scaron	"&#352;">
<!ENTITY	scaron	"&#353;">
<!ENTITY	Yuml	"&#376;">
<!ENTITY	circ	"&#710;">
<!ENTITY	tilde	"&#732;">
<!ENTITY	ensp	"&#8194;">
<!ENTITY	emsp	"&#8195;">
<!ENTITY	thinsp	"&#8201;">
<!ENTITY	zwnj	"&#8204;">
<!ENTITY	zwj		"&#8205;">
<!ENTITY	lrm		"&#8206;">
<!ENTITY	rlm		"&#8207;">
<!ENTITY	ndash	"&#8211;">
<!ENTITY	mdash	"&#8212;">
<!ENTITY	lsquo	"&#8216;">
<!ENTITY	rsquo	"&#8217;">
<!ENTITY	sbquo	"&#8218;">
<!ENTITY	ldquo	"&#8220;">
<!ENTITY	rdquo	"&#8221;">
<!ENTITY	bdquo	"&#8222;">
<!ENTITY	dagger	"&#8224;">
<!ENTITY	Dagger	"&#8225;">
<!ENTITY	permil	"&#8240;">
<!ENTITY	lsaquo	"&#8249;">
<!ENTITY	rsaquo	"&#8250;">
<!ENTITY	euro	"&#8364;">
