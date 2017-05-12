# vim:ts=4:sw=4:tw=78
# $Id: Build.PL 149 2006-02-08 14:52:12Z nicolaw $

use strict;
use Module::Build;
use vars qw($build);

$build = Module::Build->new(
		module_name        => 'WWW::Dilbert',
		license            => 'open_source',
		create_makefile_pl => 'passthrough',
		create_readme      => 1,
		create_packlist    => 1,
		sign               => 0,

		requires => {
			'LWP::UserAgent' => 0,
			'HTTP::Request'  => 0,
			'Carp'           => 0,
		},

		build_requires => {
			'Test'                => 0,
			'Test::More'          => 0,
			'Test::Pod'           => 0,
			'Test::Pod::Coverage' => 0,
		},
	);

$build->create_build_script;


# Send perl and module version information home if we've been given
# permission to do so by a human being - default to not send for automated
# testing environments, of if the user does not respond within 20 seconds.

my $url = $ENV{AUTOMATED_TESTING} ? undef : may_send_version_information();
if ($url) {
	my @resp = ();
	eval {
		local $SIG{ALRM} = sub { die; };
		alarm 10;
		my $ua = LWP::UserAgent->new(
				agent => 'Build.PL $Revision: 202 $',
				timeout => 9,
				max_size => 500,
			);
		$ua->env_proxy;
		my $response = $ua->get($url);
		if ($response->is_success()) {
			for (split(/\s*\n+\s*/, $response->content())) {
				push @resp, $_ if $_;
			}
		}
		alarm 0;
	};
	print substr($resp[0],0,79) || "Thank you for sending this information.";
	print "\n\n";
}

sub may_send_version_information {
	eval {
		require Config;
		require LWP::UserAgent;
	};
	return undef if $@;

	my $str = sprintf('%s?%s=%s&%s=%s&%s=%s&%s=%s&%s=%s&%s=%s',
			'http://perlgirl.org.uk/lib/usage.cgi',
			'name',     $build->dist_name(),
			'version',  $build->dist_version(),
			'osname',   $Config::Config{osname},
			'archname', $Config::Config{archname},
			'osver',    $^O,
			'perlver',  $]
		);

	print "\nThank you for downloading ".$build->dist_name()."\n\n";
	print "I would like to find out how many people are using this software,\n";
	print "and on what operating systems and Perl versions. If you have an\n";
	print "internet connection, may I transmit the following information:\n\n";
	print "$str\n\n";

	my $send = 0;
	eval {
		local $SIG{ALRM} = sub { die; };
		alarm 20;
		$send = $build->y_n('Send this anonymous information?','n');
		alarm 0;
	};

	return $send ? $str : undef;
}

1;

