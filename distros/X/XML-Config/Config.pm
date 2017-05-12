#(c)2000 XML Global Technologies, Inc. 
# $Id: Config.pm,v 1.2 2000/05/21 23:41:03 matt Exp $

package XML::Config;
use XML::Parser;
use vars qw($VERSION);

my $err_str = undef;
$VERSION = 0.2;


sub new {
	my $class = shift;
	my $self = {};
	bless($self,$class);
	return($self);
}



sub load_conf {
	my ($self, $file, $h, $dno) = @_;


	$self->{fill_callers_hash} = 1;
	$self->{enforce_overwrite} = 1;

	if (!defined($h)) {
		$self->{fill_callers_hash} = 0;
	}

	if (!defined($dno)) {
		$self->{enforce_overwrite} = 0;
	}

		
	eval {
		my $xp = new XML::Parser(parent => $self, Handlers => {Char => \&XML::Config::__charparse});
		$xp->parsefile($file);
		undef($xp);
	};
		
	if ($@) {
		
		if ($@ !~ m!file.*found!i) {
			my $fbak = $file . '.bak';
			undef($@);
				
			eval {
				my $xp = new XML::Parser(parent => $self, Handlers => {Char => \&XML::Config::__charparse});
				$xp->parsefile($file);
				$err_str = "WARN: Loaded backup configuration\n";
				undef($xp);
			};
				
			if ($@) {		
				$err_str = "PARSE ERROR, BACKUP READ ATTEMPTED: $@\n";
				return(undef);
			}
		}
			
		else {
			$err_str = "PARSE ERROR: $@\n";
			return(undef);
		}
			
	}	
		
	
	my $conf = $self->{conf};


	if ($self->{fill_callers_hash} > 0) {

		if ($self->{enforce_overwrite}) {
			for (keys(%{$conf})) {
				my $k = $_;
				foreach my $no_o (@{$dno}) {
					if ($no_o eq $k) {
						next();
					}
					else { 
						$h->{$k} = $conf->{$k};
					}
				}
		
			}
		}

		else {
			for (keys(%{$conf})) {
				$h->{$_} = $conf->{$_};
			}
		}
		return(1);
	}

	else {
		return %{$conf};
	}
}


sub err_str { return $err_str }

sub __charparse {
	my ($xp,$str) = @_;
	my $self = $xp->{parent};
	return if $str =~ /^\s*$/m;
	$self->{conf}{$xp->current_element} = $str;
}

__END__

=pod
=head1 NAME
XML::Config
=head1 VERSION INFORMATION

Version: 0.1

$Id: Config.pm,v 1.2 2000/05/21 23:41:03 matt Exp $

=head1 SYNOPSIS

use XML::Config;

my $cfg = new XML::Config;
my %CONF = $cfg->load_conf("path/to/file.xml");

	-OR-

my %CONF = $cfg->load_conf("path/to/file.xml",\%your_local_config_hash);

	-OR-

my %CONF = $cfg->load_conf("path/to/file.xml",\%your_local_config_hash, \@do_not_overide_these);


=head1 DESCRIPTION

XML::Config is a simple shallow XML to hash converter.  Given a configuration file in the form:

<goxml_config process="spider">
	<foo>Bar</foo>
	<bar>Foo</bar>
</goxml_config>

... XML::Config->load_conf returns:

{
	foo => 'bar',
	bar => 'foo'
}


XML::Config will also try to load "path/to/file.xml.bak" in the case of a non-file not found parse error.
if it does this, it will set the err_str to "WARN: Loaded backup configuration\n";

The second way of calling load_conf() with the hash reference allows you to set defaults to your config hash,
and have the XML overide some of them.

The third way makes it possible to disallow overwrites of certain variables.  This is a good security measure.
=head1 METHODS

load_conf($conf_file_path)
err_str()

=head1 AUTHOR

XML Global Technologies, Inc (Matthew MacKenzie)

=head1 COPYRIGHT

(c)2000 XML Global Technologies, Inc.



				
