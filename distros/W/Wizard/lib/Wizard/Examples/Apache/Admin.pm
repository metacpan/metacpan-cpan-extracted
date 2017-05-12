# -*- perl -*-

use strict;

use Wizard::SaveAble ();
use Wizard::Examples::Apache::Config ();
use Symbol ();
use Socket ();


package Wizard::Examples::Apache::Admin;


sub Parse {
    my($self, $template, $server, $host, $prefs) = @_;
    $template =~ s/\~\~([\w\-]+)\~\~/
        my $sf;
        foreach my $s (@_) {
            if (exists($s->{$1})) {
                $sf = $s;
                last;
            }
        }
        die "Unknown pattern: $1" unless $sf;
        $sf->{$1}/eg;
    $template
}


sub new {
    my($proto, $host, $server) = @_;

    my $cfg = $Wizard::Examples::Apache::Config::config;
    my $file = $cfg->{'apache-prefs-file'};
    my $prefs = Wizard::SaveAble->new($file);
    my $basedir = $prefs->{'apache-prefs-basedir'} or die "Missing basedir";
    my $h = Wizard::SaveAble->new(File::Spec->catfile($basedir, "$host.cfg"));
    my $hostdir = File::Spec->catdir($basedir, $host);
    my $s = Wizard::SaveAble->new(File::Spec->catfile($hostdir,
						      "$server.cfg"));
    my $serverdir = File::Spec->catdir($basedir, $server);
    bless({'prefs' => $prefs,
	   'basedir' => $basedir,
	   'host' => $h,
	   'hostdir' => $hostdir,
	   'server' => $s,
	   'serverdir' => $serverdir}, (ref($proto) || $proto));
}


sub MakeHttpdConf {
    my $self = shift;

    # Start by loading the original httpd.conf and replace patterns
    my $serverdir = ;
    my $conffile = File::Spec->catfile($self->{'serverdir'}, 'httpd.conf');
    unless (-f $conffile) {
	$conffile = File::Spec->catfile($self->{'hostdir'}, 'httpd.conf');
    }
    my $fh = Symbol::gensym();
    my $conf;
    local $/ = undef;
    (open($fh, "<$conffile")  &&  defined($conf = <$fh>)  &&  close($fh))
	or die "Failed to load HTTPD config file $conffile: $!";
    my $host = $self->{'host'};
    my $server = $self->{'server'};
    my %ports;
    $ports{$server->{'apache-server-http-port'}} = 1
	if $server->{'apache-server-http-port'};
    $ports{$server->{'apache-server-https-port'}} = 1
	if $server->{'apache-server-https-port'};

    # Next thing: Load the virtual servers
    my $serverdir = $self->{'serverdir'};
    return $conf unless -d $serverdir;
    my $dh = Symbol::gensym();
    opendir($dh, $serverdir) or die "Failed to open directory $serverdir: $!";
    my %interfaces;
    while (my $f = <$dh>) {
	next unless $f =~ /(.*).cfg$/;
	my $vserver_name;
	my $file = File::Spec->catfile($serverdir, $f);
	my $fh = Symbol::gensym();
	my $vserver = Wizard::SaveAble->new($file);
	my $name = $vserver->{'apache-virtualserver-name'};
	my $ip = Socket::inet_aton($name);
	unless (defined($ip)) {
	    $self->Warn("Failed to resolve host name $name; ignoring host $f");
	    next;
	}
	$ip = Socket::inet_ntoa($ip);

	$ports{$vserver->{'apache-virtualserver-http-port'}} = 1
	    if $vserver->{'apache-virtualserver-http-port'};
	$ports{$vserver->{'apache-virtualserver-https-port'}} = 1
	    if $vserver->{'apache-virtualserver-https-port'};

	if (my $i = $vserver->{'interface'}) {
	    if ($interfaces{$i}) {
		my $name = $vserver->{'apache-virtualserver-name'};
		$self->Warn("Duplicate interface $i in $name; ignoring");
	    } else {
		$interfaces{$i} = $ip;
	    }
	}

	if ($vserver->{'configuration'}) {
	    $conf .= $vserver->{'configuration'};
	} else {
	    my $mode = $vserver{'apache-virtualserver-http-mode'};
	    if ($mode eq 'http'  ||  $mode eq 'both') {
		$conf .= Wizard::Examples::Apache::Admin::Config::HTTP->Cnf
		    ($prefs, $host, $server, $vserver);
	    }
	    if ($mode eq 'https'  || $mode eq 'both') {
		$conf .= Wizard::Examples::Apache::Admin::Config::HTTPS->Cnf
		    ($prefs, $host, $server, $vserver);
	    }
	    if ($mode eq 'redirect') {
		$conf .= Wizard::Examples::Apache::Admin::Config::Redirect->Cnf
		    ($prefs, $host, $server, $vserver);
	    }
	}
    }

    # Make sure, the defaults are valid
    $conf .= <<"EOF";

<VirtualHost _default_:*>
</VirtualHost>

EOF

    # Finally parse the config file.
    (Parse($conf, $server, $host, $prefs), \%interfaces);
}


sub IfUp {
    my($self, $i, $ip) = @_;
    my $arch = $self->{'apache-host-arch'};
    my $interface = $self->{'apache-host-interface'};
    if ($arch =~ /linux/) {
	my $ifconfig = "$self->{'apache-host-ifconfig'} $interface";
	return $self->Warn("Failed to parse netmask of interface $interface:\n"
			   "$ifconfig\nIgnoring interface $interface:$i.\n")
	    unless ($ifconfig =~ /mask:\s*(\d+\.\d+\.\d+\.\d+)/i);
	my $netmask = $1;
	return $self->Warn("Failed to parse interface $interface:\n$ifconfig"
			   . "\nIgnoring interface $interface:$i.\n")
	    unless ($ifconfig =~ /inet\s+addr:\s*(\d+\.\d+\.\d+\.\d+)/i);
	my $ifip = $1;
	my $net1 = Net::Netmask->new($ip, $netmask);
	my $net2 = Net::Netmask->new($ip, $netmask);
	return $self->Warn("The detected configuration of interface"
			   . " $interface doesn't match the IP address"
			   . " $ip.\nIgnoring interface $interface:$i.\n")
	    unless ($net1->base() == $net2->base());
	my $command = "$self->{'apache-host-ifconfig'} $interface:$i"
	    . " $ip up\n";
	print "Switching interface $i up: $command\n" if $::verbose;
	system $command unless $::debug;
    }
}


package Wizard::Examples::Apache::Admin::Config::HTTP;

sub new {
    my($prefs, $host, $server, $vserver) = @_;
    my $self = { %$vserver };
    $self->{'apache-virtualserver-pagedir'} =
	File::Spec->catdir($server->{'apache-server-root'},
			   $vserver->{'apache-virtualserver-name'},
			   'pages');
    $self->{'apache-virtualserver-cgidir'} =
	File::Spec->catdir($server->{'apache-server-root'},
			   $vserver->{'apache-virtualserver-name'},
			   'cgi-bin');
    $self->{'apache-virtualserver-logdir'} =
	File::Spec->catdir($server->{'apache-server-root'},
			   $vserver->{'apache-virtualserver-name'},
			   'logs');
    if (my $port = $self->{'apache-virtualserver-http-port'}) {
	if ($port ne $self->{'apache-server-http-port'}) {
	    $self->{'apache-server-port'} = ":$port";
	}
    }
    $self->{'apache-server-port'} ||= '';
    my @index = $server->{'apache-server-index'} ?
	split(/ /, $server->{'apache-server-index'}) :
	    ('welcome.html', 'index.html',
	     'welcome.htm', 'index.htm',
	     '/cgi-bin/noDirLists');
    my %options;
    if ($server->{'apache-server-options'}) {
	foreach my $key (split(/ /, $server->{'apache-server-options'})) {
	    $options{'apache-server-options'} = 1;
	}
    } else {
	$options{'Indexes'} = 1;
    }
    my @aliases = '  ScriptAlias ~~apache-virtualserver-cgidir~~';

    if ($vserver->{'apache-virtualserver-enable-ssi'}) {
	unshift(@index, 'welcome.shtml', 'index.shtml');
	unshift(@aliases,
		'  ScriptAlias AddType text/html .shtml',
		'  AddHandler server-parsed .shtml');
	$options{'ExecCGI'} = 1;
    }
    if ($vserver->{'apache-virtualserver-enable-pcgi'}) {
	unshift(@index, 'welcome.phtml', 'index.phtml');
	unshift(@aliases,
		'  AddHandler x-pcgi-script .phtml');
	$options{'ExecCGI'} = 1;
    }
    if ($vserver->{'apache-virtualserver-enable-ep'}) {
	unshift(@index, 'welcome.ep', 'index.ep');
	unshift(@aliases,
		'  AddType x-ep-script .ep',
		'  ScriptAlias /cgi-bin/ep.cgi');
	$options{'ExecCGI'} = 1;
    }

    $conf->{'apache-virtualserver-options'} = "Options "
	. $conf->{'apache-virtualserver-options'} || join(" ", keys %options);
    $conf->{'apache-virtualserver-index'} = "DirectoryIndex "
	. $conf->{'apache-virtualserver-index'} || join(" ", @index);
    $conf->{'apache-virtualserver-aliases'} = join("\n", @aliases);
    bless($conf, (ref($proto) || $proto));
}

sub Template {
    <<'EOF';
<VirtualHost ~~apache-virtualserver-name~~~~apache-server-port~~>
  ServerName ~~apache-virtualserver-name~~
  ServerAdmin ~~apache-virtualserver-admin~~
  DocumentRoot ~~apache-virtualserver-pagedir~~
  CustomLog ~~apache-virtualserver-logdir~~ combined
  ~~apache-virtualserver-index~~
~~apache-virtualserver-aliases~~
  <Directory ~~apache-virtualserver-pagedir~~>
    ~~apache-virtualserver-options~~
  </Directory>
</VirtualHost>
EOF
}

sub Cnf {
    my($proto, $prefs, $host, $server, $vserver) = @_;
    my $conf = $proto->new($prefs, $host, $server, $vserver);
    my $template = $conf->Template();
    Wizard::Examples::Apache::Admin::Parse($template, $conf, $template,
					   $server, $host, $prefs);
}


package Wizard::Examples::Apache::Admin::Config::HTTPS;

@Wizard::Examples::Apache::Admin::Config::HTTPS::ISA =
    qw(Wizard::Examples::Apache::Admin::Config::HTTP);

sub Template {
    my $self = shift;
    my $template = $self->SUPER::Template();
    my $ssl = <<'EOF';
  SSLEngine on
  SSLCertificateFile ~~apache-virtualserver-crtfile~~
  SSLCertificeteKeyFile ~~apache-virtualserver-keyfile~~
EOF
}


sub new {
    my $proto = shift;
    my $conf = $proto->SUPER::new(@_);
    my $port = $conf->{'apache-virtualserver-https-port'}  ||
	$server->{'apache-server-https-port'};
    $conf->{'apache-server-port'} = ":$port";
}


package Wizard::Examples::Apache::Admin::Config::Redirect;

@Wizard::Examples::Apache::Admin::Config::Redirect::ISA =
    qw(Wizard::Examples::Apache::Admin::Config::HTTP);

sub Template {
    <<'EOF';
<VirtualHost ~~apache-virtualserver-name~~~~apache-server-port~~>
  ServerName ~~apache-virtualserver-name~~
  ServerAdmin ~~apache-virtualserver-admin~~
  <Location />
    Redirect 301 ~~apache-virtualserver-redirect~~
  </Location>
</VirtualHost>
EOF
}


1;
