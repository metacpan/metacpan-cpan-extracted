
use ExtUtils::MakeMaker;

## on *nix-like system, you can make life easier by having these packages installed:
# libipc-run-perl libalien-wxwidgets-perl libssl-dev libcrypt-openssl-rsa-perl \
# libssl-dev libcrypt-openssl-rsa-perl libcrypt-ssleay-perl libxml-simple-perl libattr1-dev

rename('README.md','README') if -f 'README.md';

WriteMakefile(
	NAME		=> 'Wrangler',
	AUTHOR		=> 'Clipland (clipland@cpan.org)',
	ABSTRACT_FROM	=> 'lib/Wrangler.pm',
	VERSION_FROM	=> 'lib/Wrangler.pm',
	LICENSE		=> 'restricted',
	PREREQ_PM	=> {
		'Alien::wxWidgets'	=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
							#  -> wxWidgets: wxWidgets is currently licenced under the "wxWindows Library Licence" pending approval of the "wxWidgets Library Licence" which will be identical apart from the name. "but basically you can distribute proprietary binaries without distributing any source code, and neither will wxWidgets conflict with GPL code you may be using or developing with it."
# unused in 2.x	'Browser::Open'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
# unused in 2.x	'Crypt::SSLeay'		=> 0,		# The Artistic License 2.0 (GPL Compatible)
							#  -> openssl: "The OpenSSL toolkit is licensed under an Apache-style licence which basically means that you are free to get and use it for commercial and non-commercial purposes."
		'Cwd'			=> 0,		# PathTools "This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself."
		'Data::Dumper'		=> 0,		# "This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself."
# unused in 2.x	'Data::Uniqid'		=> 0,		# in README: This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
		'Digest::MD5'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
# unused in 2.x	'Digest::MD5::File'	=> 0,		# This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
		'Encode'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'File::Spec'		=> 0,		# PathTools
		'File::ExtAttr'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'File::HomeDir'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
# replaced by	'File::Slurp'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'Path::Tiny'		=> 0.054,	# The Apache License, Version 2.0, January 2004
		'Image::ExifTool'	=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'Image::MetaData::JPEG'	=> 0,		# GPL v2
		'IO::Scalar'		=> 0,		# IO-stringy: in COPYING: This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
# unused in 2.x	'IPC::Run'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'JSON::XS'		=> 0,		# in COPYING: This module is licensed under the same terms as perl itself.
		'MIME::Types'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
# unused in 2.x	'Smil'			=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'Sys::Filesystem'	=> 0,		# The Apache License, Version 2.0, January 2004

# unused in 2.x	'WWW::Mechanize'		 => 0,	# The Perl 5 License (Artistic 1 & GPL 1)
# unused in 2.x	'WWW::Mechanize::DecodedContent' => 0,	# The Perl 5 License (Artistic 1 & GPL 1)
		'Wx'			=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'Wx::Perl::Packager'	=> 0,		# in README: This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
		'Wx::TreeListCtrl'	=> 0,		# in README: This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself
# unused in 2.x	'XML::ASX'		=> 0,		# only copyright, no licensing
# unused in 2.x	'XML::Simple'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)

		# Wrangler uses some icons of the Tango Icon Library which is public domain as of
		# release 0.8.90 http://tango.freedesktop.org

		# Wrangler sometimes builds on layouts or priciples put to use in other modules. That's
		# inherent to how programming works, after all. Still, given that Wrangler itself
		# is released under a restrictive license, the authors have taken great care to give
		# credit where credit is due. Influences have been noted in the source-code whenever
		# possible. Also the authors wish to highlight these influential modules:
		# Padre: The Perl 5 License (Artistic 1 & GPL 1)
		# Kephra: The GNU General Public License, Version 2, June 1991
		# Perl5 itself is free software; you can redistribute it and/or modify it under the terms of either: a) the GNU General Public License as published by the Free Software Foundation; either external linkversion 1, or (at your option) any later version, or b) the "Artistic License". 

	},
	BUILD_REQUIRES	=> {
		'Test::Deep'		=> 0,		# in POD: same as Perl / Artistic
	},
	TEST_REQUIRES	=> {
		'Test::Simple'		=> 0.44,	# The Perl 5 License (Artistic 1 & GPL 1)
		'File::Temp'		=> 0,		# The Perl 5 License (Artistic 1 & GPL 1)
		'Test::Deep'		=> 0,		# in POD: same as Perl / Artistic
	},
	EXE_FILES	=> [
		'bin/wrangler'
	],
	META_MERGE	=> {	# CPAN::Meta::Spec
		'meta-spec'	=> { version => 2 },
		resources	=> {
			repository => {
				type=> 'git',
				url => 'https://github.com/clipland/wrangler.git',
				web => 'https://github.com/clipland/wrangler',
			},
		},
		prereqs	=> {
			test => {
				recommends => {
					'File::HomeDir' => 0,
				},
			},
		},
	},
	dist => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	realclean => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	MIN_PERL_VERSION => 5.010,	# we sometimes use the defined-or operator
);


## credits for the following go to ~NICOLAW and her RRD::Simple, it has just been
## adapted to MakeMaker (license was: Apache License Version 2.0)

# Send perl and module version information home if we've been given
# permission to do so by a human being - default to not send for automated
# testing environments, or if the user does not respond within 20 seconds.

my $url = $ENV{AUTOMATED_TESTING} ? undef : may_send_version_information();
if ($url) {
	my @resp = ();
	eval {
		local $SIG{ALRM} = sub { die; };
		alarm 10;
		my $ua = LWP::UserAgent->new(
				agent => 'LWP+Makefile.PL',
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
	print '  > '.substr($resp[0],0,79) || "  Thank you.";
	print "\n\n";
}else{
	print "  Skipped.\n";
}

sub may_send_version_information {
	eval {
		require Config;
		require LWP::UserAgent;
	};
	return undef if $@;

	my %values = (
			'dist'    => 'Wrangler',
			'version' => '2.15',
			'osname'  => $Config::Config{osname},
			'archname'=> $Config::Config{archname},
			'osver'   => $^O,
			'perlver' =>  $]
	);
	my $str = sprintf('%s?%s=%s&%s=%s&%s=%s&%s=%s&%s=%s&%s=%s', 'http://www.clipland.com/wrangler/makeping', (%values) );

	print "\n  Thank you for downloading Wrangler\n\n";
	print "  The Wrangler authors would like to find out how many people\n";
	print "  are using their software, and on what operating systems and Perl\n";
	print "  versions. If you have an Internet connection, may this script\n";
	print "  transmit the following information:\n\n";
	while(($key, $value) = each %values){
		print "    $key : $values{$key}\n";
	}
	print "\n  via GET $str\n";

	my $send = 0;
	eval {
		local $SIG{ALRM} = sub { die; };
		alarm 20;
		my $prompt = prompt("\n\n  Send this anonymous information?",'n');
		$send = $prompt =~ /y/i ? 1 : undef;

		alarm 0;
	};

	return defined $send && !ref($send) && "$send" == 1 ? $str : undef;
}
