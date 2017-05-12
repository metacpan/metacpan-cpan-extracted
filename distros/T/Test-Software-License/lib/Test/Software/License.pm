package Test::Software::License;

use 5.008004;
use warnings;
use strict;

use version;
our $VERSION = '0.004000';
use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use parent 0.228 qw(Exporter);
use Software::LicenseUtils 0.103007;
use File::Slurp::Tiny qw(read_file read_lines);
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use List::AllUtils qw(any);
use Try::Tiny;
use Parse::CPAN::Meta 1.4409;

use constant {FFR => 'File::Find::Rule', TRUE => 1, FALSE => 0, EMPTY => -1};

use Test::Builder 1.001002;

@Test::Software::License::EXPORT = qw(
	all_software_license_ok
);

my $passed_a_test = FALSE;
my $meta_author = FALSE;
my @meta_yml_url;

#######
# import
#######
sub import {
	my ($self, @args) = @_;
	my $pack = caller;
	my $test = Test::Builder->new;

	$test->exported_to($pack);
	$test->plan(@args);

	$self->export_to_level(1, $self, @Test::Software::License::EXPORT);
	return 1;
}

#######
# all_software_license_ok
#######
sub all_software_license_ok {
	my $options = shift if ref $_[0] eq 'HASH';
	$options ||= {strict => FALSE, diag => FALSE};
	my $test = Test::Builder->new;
	_from_perlscript_ok($options);
	_from_perlmodule_ok($options);
	_from_metayml_ok($options);
	_from_metajson_ok($options);
	_check_for_license_file($options);

	if (not $options->{strict}) {
		$test->ok($passed_a_test,
			'This distribution appears to have a valid License');
	}
	return;
}

#######
# _from_perlmodule_ok
#######
sub _from_perlmodule_ok {
	my $options = shift;
	my $test    = Test::Builder->new;
	my @files   = FFR->perl_module->in('lib');

	if ($#files == EMPTY) {
		$test->skip('no perl_module found in lib');
	}
	else {
		if ($options->{diag}) {
			my $found_perl_modules = $#files + 1;
			$test->ok($files[0],
				'found (' . $found_perl_modules . ') perl modules to test');
		}
		_guess_license($options, \@files);
	}
	return;
}

#######
# _from_perlscript_ok
#######
sub _from_perlscript_ok {
	my $options = shift;
	my $test    = Test::Builder->new;

	my @dirs = qw( script bin );
	foreach my $dir (@dirs) {
		my @files = FFR->perl_script->in($dir);
		if ($#files == EMPTY) {
			$test->skip('no perl_scripts found in ' . $dir);
		}
		else {
			if (not $options->{diag}) {
				my $found_perl_scripts = $#files + 1;
				$test->ok($files[0],
					"found ($found_perl_scripts) perl script to test in $dir");
			}
			_guess_license($options, \@files);
		}
	}
	return;
}

#######
# composed method test for license
#######
sub _guess_license {
	my $options   = shift;
	my $files_ref = shift;
	my $test      = Test::Builder->new;

	try {
		foreach my $file (@{$files_ref}) {
			my $ps_text = read_file($file);
			my @guesses = Software::LicenseUtils->guess_license_from_pod($ps_text);
			if ($options->{strict}) {
				$test->ok($guesses[0], "$file -> @guesses");
			}
			else {
				if ($#guesses >= 0) {
					$test->ok(1, "$file -> @guesses");
					$passed_a_test = TRUE;
				}
				else {
					$test->skip('no licence found in ' . $file);
				}
			}
		}
	};
	return;
}

#######
# _from_metayml_ok
#######
sub _from_metayml_ok {
	my $options = shift;
	my $test    = Test::Builder->new;

	if (-e 'META.yml') {
		try {
			my $meta_yml = Parse::CPAN::Meta->load_file('META.yml');
			$meta_author = $meta_yml->{author}[0];

			# force v1.x metanames
			my @guess_yml = Software::LicenseUtils->guess_license_from_meta_key($meta_yml->{license},1);
			my @guess_yml_meta_name;
			my @guess_yml_url;
#			my @guess_yml_url;

#			my $software_license_url = 'unknown';

			for (0 .. $#guess_yml) {
				push @guess_yml_meta_name, $guess_yml[$_]->meta_name;
			}
			if (@guess_yml) {
				$test->ok(
					sub {
						any {m/$meta_yml->{license}/} @guess_yml_meta_name;
					},
					"META.yml -> license: $meta_yml->{license} -> @guess_yml"
				);
				$passed_a_test = TRUE;
			}
			else {
				$test->ok(0, "META.yml -> license: $meta_yml->{license} -> unknown");
				$passed_a_test = FALSE;
			}

			if ($meta_yml->{resources}->{license}) {
				for (0 .. $#guess_yml) {
					push @guess_yml_url, $guess_yml[$_]->url;

				}

				# check for a valid license, sl-url
				if (
					_hack_check_license_url($meta_yml->{resources}->{license}) ne FALSE)
				{
					if ( any {/$meta_yml->{resources}->{license}/} @guess_yml_url )
					{
						$test->ok(1,
							"META.yml -> resources.license: $meta_yml->{resources}->{license} -> "
								. _hack_check_license_url($meta_yml->{resources}->{license}));
						$passed_a_test = TRUE;
					}
					else {
						$test->ok(0,
							"META.yml -> resources.license: $meta_yml->{resources}->{license} -> license miss match"
						);
						$passed_a_test = FALSE;

					}
				}
				else {
					$test->ok(0,
						"META.yml -> resources.license: $meta_yml->{resources}->{license} -> unknown"
					);
					$passed_a_test = FALSE;
				}
			}
			else {
				$test->skip("META.yml -> resources.license:  [optional]");
			}
		};
	}
	else {
		$test->skip('no META.yml found');
	}
	return;
}

#######
# _from_metajson_ok
#######
sub _from_metajson_ok {
	my $options = shift;
	my $test    = Test::Builder->new;

	if (-e 'META.json') {
		try {
			my $meta_json = Parse::CPAN::Meta->load_file('META.json');
			$meta_author = $meta_json->{author}[0];
			my @guess_json
				= _hack_guess_license_from_meta(@{$meta_json->{license}});
			my @guess_json_meta_name;
			my @guess_json_url;

			for (0 .. $#guess_json) {
				push @guess_json_meta_name, $guess_json[$_]->meta_name;
			}

			foreach my $json_license (@{$meta_json->{license}}) {

				# force v2 metanames
				my @guess_json
					= Software::LicenseUtils->guess_license_from_meta_key($json_license,
					2);

				if (@guess_json) {
					$test->is_eq($guess_json[0]->meta2_name,
						$json_license,
						"META.json -> license: $json_license -> @guess_json");
					$passed_a_test = TRUE;
				}
				else {
					$test->ok(0, "META.json -> license: $json_license -> unknown");
					$passed_a_test = FALSE;
				}
			}

			if ($meta_json->{resources}->{license}) {

				# find url from $meta_json->{license}
				for (0 .. $#guess_json) {
					push @guess_json_url, $guess_json[$_]->url;
				}

				# check for a valid license, sl-url
				if (_hack_check_license_url($meta_json->{resources}->{license}) ne
					FALSE)
				{
					if (any {/$meta_json->{resources}->{license}/} @guess_json_url) {

						$test->ok(1,
							"META.json -> resources.license: $meta_json->{resources}->{license} -> "
								. _hack_check_license_url($meta_json->{resources}->{license})
						);
						$passed_a_test = TRUE;
					}
					else {
						$test->ok(0,
							"META.json -> resources.license: $meta_json->{resources}->{license} -> license miss match"
						);
						$passed_a_test = FALSE;
					}
				}
				else {
					$test->ok(0,
						"META.json -> resources.license: $meta_json->{resources}->{license} -> unknown"
					);
					$passed_a_test = FALSE;
				}
			}
			else {
				{
					$test->skip("META.json -> resources.license:  [optional]");
				}
			}
		};
	}
	else {
		$test->skip('no META.json found');
	}
	return;
}

#######
# _check_for_license_file
#######
sub _check_for_license_file {
	my $options = shift;
	my $test    = Test::Builder->new;

	if ($options->{strict}) {

		if (-e 'LICENSE') {
			$test->ok(1, 'LICENSE file found');
			my $license_file;
			my @license_file;
			try {
				@license_file = read_lines('LICENSE', chomp => 1);
			};

			my $meta_author_name = $meta_author;
			$meta_author_name =~ s/\b\W*[\w0-9._%+-]+@[\w0-9.-]+\.[\w]{2,4}\W*$//;

			my @copyright_holder
				= grep(/^This software is Copyright/i, @license_file);

			if (any {m/$meta_author_name/} @copyright_holder) {
				$test->ok(1,
					"LICENSE file Copyright Holder contains META Author name: $meta_author_name"
				);
			}
			else {
				$test->ok(0,
					"LICENSE file Copyright Holder dose not contain META Author name: $meta_author_name"
				);
			}
		}
		else {
			$test->ok(0, 'no LICENSE file found');
		}
	}
	else {
		if (-e 'LICENSE') {
			$test->ok(1, 'LICENSE file found');
		}
		else {
			$test->skip('no LICENSE file found');
		}
	}
	return;
}

#######
## hack to support meta license strings
#######
sub _hack_guess_license_from_meta {
	my $license_str = shift;
	my @guess;
	try {
		my $hack = 'license : ' . $license_str;
		@guess = Software::LicenseUtils->guess_license_from_meta($hack);
	};
	return @guess;
}

#######
## hack to support meta license urls
#######
sub _hack_check_license_url {
	my $license_url = shift;

	my @cpan_meta_spec_licence_name = qw(
		agpl_3
		apache_1_1
		apache_2_0
		artistic_1
		artistic_2
		bsd
		freebsd
		gfdl_1_2
		gfdl_1_3
		gpl_1
		gpl_2
		gpl_3
		lgpl_2_1
		lgpl_3_0
		mit
		mozilla_1_0
		mozilla_1_1
		openssl
		perl_5
		qpl_1_0
		ssleay
		sun
		zlib
	);

	foreach my $license_name (@cpan_meta_spec_licence_name) {

		my @guess = _hack_guess_license_from_meta($license_name);
		if (@guess) {
			for (0 .. $#guess) {
				push my @sl_urls, $guess[$_]->url;
				if (any {m/$license_url/} @sl_urls) {
					return $guess[$_];
				}
			}
		}
	}

	return FALSE;

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Software::License - just another xt, for Software::License

=head1 VERSION

This document describes Test::Software::License version 0.004000

=head1 SYNOPSIS

	use Test::More;
	use Test::Requires { 'Test::Software::License' => 0.004000 };

	all_software_license_ok();

	# the following is brutal, if it exists it must have a valid license
	# all_software_license_ok({ strict => 1 });

	done_testing();

For an example of a complete test file look in eg/xt/software-license.t

=head1 DESCRIPTION

Test::Software::License it is intended to be used as part of your xt tests.

It now checks the META license and resources.license against
Software::License, checking that the two correlate.


=head1 METHODS

=over 4

=item * all_software_license_ok

This is the main method you should use, it uses all of the internal methods to
check your distribution for License information. It checks the contents of
scripts/bin along with lib, it expects to find META.[yml|json],
just for good measure it checks for the presence of a LICENSE file.

	all_software_license_ok();

If you want to check every perl file in your distribution has a valid license
use the following, its brutal, good for finding CPANTS issues if that is your thing.

	all_software_license_ok({ strict => 1 });

If you are trying to track down a issue you will get the best results with prove -lv

=item * import



=back

=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head2 CONTRIBUTORS

none at present

=head1 COPYRIGHT

Copyright E<copy> 2013-2014 the Test::Software::License
L</AUTHOR> and L</CONTRIBUTORS> as listed above.


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Software::License>

L<XT::Manager>

=cut


