package Test::Dist;

use 5.006;
use strict;
use warnings;
use Test::Builder ();
use Test::More ();
use Test::Dist::Manifest;
use Module::CPANTS::Analyse;

=head1 NAME

Test::Dist - Distribution kwalitee tests in one command

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Test::More;
    use Test::Dist as => 0.01;
    # using as => $version in use you may avoid breakage
    # due to future tests additions to this module
    use lib::abs '../lib';
    chdir lib::abs::path('..');

    Test::Dist::dist_ok(
        '+'   => 1, # Add one more test to plan due to NoWarnings
        run   => 1, # Start condition. By default uses $ENV{TEST_AUTHOR}
        skip  => [qw(prereq)], # Skip prereq from testing
        fixme => { # For options, see Test::Fixme
            match => qr/FIXIT|!!!/, # Your own fixme patterns
        },
        kwalitee => {
            req => [qw( has_separate_license_file has_example )], # Optional metrics, that you require to pass
        },
    );
    
    # Also, see examples and tests in this distribution

=head1 FUNCTIONS

=head2 dist_ok(%options)

=head1 TESTS

=over 4

=item kwalitee

Use L<Module::CPANTS::Analyse> for testing kwalitee

=item metayml

Check C<META.yml> using L<Test::YAML::Meta>

=item changes

Check the correctness of C<Changelog> file

=item fixme

Test all modules and scripts using L<Test::Fixme>

=item useok

Loading all modules by L<Test::More>C<::use:ok>

=item syntax

Checking all scripts by perl -c $file

=item podcover

Checking all modules for POD coverage using L<Test::Pod::Coverage>

=item prereq

Checking prereq list using L<Test::Prereq>

=back

=head1 OPTIONS

=over 4

=item '+' => 1|0

How many tests add to plan

=item run [ = $ENV{TEST_AUTHOR} ]

Run condition for test

=item skip => [ TESTS ]

Skip some of tests

=item kwalitee : { req => [ LIST ] }

Force checking for some of optional metrics

=item metayml : [ LIST ]

For options see L<Test::YAML::Meta>

=item fixme

For options see L<Test::Fixme>

=item useok : { ... }

    useok => {
        file_match => qr{^lib/.*\.pm$},
        mod_skip   => [ 'Module::Developed', qr{^Module::Developed::} ],
    }

=item syntax

    syntax => {
        file_match => qr{^(lib|bin|script)/.*\.p(?:m|l|od)$},
        file_skip  => [ 'script/dummy.pl', qr{^bin/t/} ],
        match      => qr{!!!},
    }

=item podcover

    podcover => {
        mod_match  => qr{^Only::Some::Scope},
        mod_skip   => [ 'Only::Some::Scope::Developed', qr{^Only::Some::Scope::Developed::} ],
    }

=item prereq

For options see L<Test::Prereq>

=back

=cut

my $Test = Test::Builder->new;
our %TESTS = (
	'0.01' => [qw( kwalitee metayml changes fixme useok syntax podcover prereq )],
);
our %TEST_OK = map { $_ => 1 } @{ $TESTS{$VERSION} };
%TEST_OK or die "Test set no defined. This is an author error.";

our @TESTS = (
	[ kwalitee => [], sub {
		my ($self,%args) = @_;
		my %required = map { $_ => 1 } @{$args{req} || [] };
		for my $gen ($self->_kwalitee_generators) {
		#for my $gen (@{ Module::CPANTS::Kwalitee->new->generators() } ) {
			#next if $gen =~ /Unpack/;
			#next if $gen =~ /(^?:CpantsErrors|Distname|Prereq)$/;
			#if ($gen eq 'Module::CPANTS::Kwalitee::Manifest') { $gen = 'Test::Dist::Manifest' }
			for my $indicator (@{ $gen->kwalitee_indicators() }) {
				next if $indicator->{needs_db};
				my $test = $indicator->{name};
				next if $test =~ /(?:debian|fedora)/;
				next if $test =~ /(?:no_generated_files|extracts_nicely|extractable)/; # Not worked within source
				$self->_queue(sub {
					#return $Test->skip("OS-oriented metric") if $test =~ /(?:debian|fedora)/;
					#return $Test->skip("Only for distribution") if $test =~ /(?:no_generated_files|extracts_nicely|extractable)/; # Not worked within source
					my $ok =  $indicator->{code}->( $self->{d} );
					{
						no strict 'refs';
						local ${ 'TO'.'DO' } = ($indicator->{is_experimental} ? 'Experimental' : 'Optional').' metric'
							if !$required{$test} and ( $indicator->{is_experimental} or $test =~ /^(?:
								has_separate_license_file | has_example |
								uses_test_nowarnings | is_prereq
							)$/x );
						$Test->ok( $ok, $test . (!$ok ? " (from: $gen)" : '') )
							or map { $_ and ref $_ ? map { $Test->diag($_) } @$_ : $Test->diag($_) }
								#$generator,
								@{ $indicator }{qw( error remedy )},
								$self->{d}{error}{ $test };
					}
				});
			}
		}
		
	}],
	[ metayml => 'Test::YAML::Meta' => sub {
		my $self = shift;
		my ($file,$vers,$msg) = @_;
		$file ||= 'META.yml';
		$msg  ||= "$file meets specification";
		my $yaml;
		$self->_queue(sub {
			$yaml = Test::YAML::Meta::yaml_file_ok($file);
		});
		$self->_queue(sub {
			if ($yaml) {
				my %hash;
				$hash{spec} = $vers if($vers);
				$hash{yaml} = $yaml;
				my $spec = Test::YAML::Meta::Version->new(%hash);
				if(my $result = $spec->parse()) {
					$self->_ok(0,$msg);
					$Test->diag("  ERR: $_") for( $spec->errors );
				} else {
					$Test->ok(1,$msg);
				}
			} else {
				$Test->_ok(0, $msg);
			}
		});
	}],
	[ changes => [] => sub {
		my $self = shift;
		my $msg = "Check Changes";
		if (exists $self->{d}{file_changelog} and -e $self->{d}{file_changelog}) {
			if (my $version = $self->{d}{meta_yml}{version}) {
				$msg .= " $version";
				$self->_queue(sub {
					my $file    = $self->{d}{file_changelog};
					open(my $f, '<', $file) or return $self->_ok(0, $msg, "Could not open file ($file)");
					my $found = 0;
					my @not_found;
					while (<$f>) {
						chomp;
						if (/^\d/) { # Common
							my ($cvers, $date) = split(/\s+/, $_, 2);
							if ($version eq $cvers) {
								$found = $_;
								last;
							} else {
								push(@not_found, "$cvers");
							}
						}
						elsif (/^\s+version: ([\d.]+)$/) { # YAML
							if ($version eq $1) {
								$found = $_;
								last;
							} else {
								push(@not_found, "$1");
							}
						}
						elsif (/^\* ([\d.]+)$/) { # Apocal
							if ($version eq $1) {
								$found = $_;
								last;
							} else {
								push(@not_found, "$1");
							}
						} elsif (/^Version ([\d.]+)($|[:,[:space:]])/) { # Plain "Version N"
							if ($version eq $1) {
								$found = $_;
								last;
							} else {
								push(@not_found, "$1");
							}
						}
					}
					close($f);
					if ($found) {
						$Test->ok(1,$msg);
					} else {
						$Test->ok(1,$msg. " not found.");
						if (@not_found) {
							$Test->diag(qq(expecting version $version, found versions: ). join(', ', @not_found));
						} else {
							$Test->diag(qq(expecting version $version, But no versions where found in the Changes file.));
						}
					}
				});
			} else {
				$self->_queue(sub { $self->_ok(0, $msg, "No dist version" ); });
			}
		} else {
			$self->_queue(sub { $self->_ok(0, $msg, "No Changelog found"); });
		}
	}],
	
	[ fixme => 'Test::Fixme' => sub {
		my $self = shift;
		my %args = @_;
		$args{match} = 'FIX'.'ME|TO'.'DO' unless defined $args{match} && length $args{match};
		$args{file_match} = $args{filename_match} if defined $args{filename_match} and !defined $args{file_match};
		$args{file_match} = qr{^(lib|bin|script)/.*\.p(?:m|l|od)$} unless defined $args{file_match};
		my @files = $self->_filelist(%args);
		for my $file (@files) {
			$self->_queue(sub {
				my $results = Test::Fixme::scan_file( file => $file, match => $args{match} );
				if ( !$results or @$results == 0 ) {
					$self->_ok( 1, "Fixme '$file'" );
				}
				else {
					$self->_ok( 0, "Fixme '$file'", Test::Fixme::format_file_results($results) );
				}
			});
		}
	} ],
	[ useok => [], sub {
		my $self = shift;
		my %args = @_;
		my @files = $self->_modlist(%args);
		for my $file (@files) {
			$self->_queue(sub {
				Test::More::use_ok($file);
			});
		}
		if (!@files) {
			$self->_queue(sub { $Test->skip("Found no modules for use_ok check"); });
		}
	}],
	[ syntax => [], sub {
		my $self = shift;
		my %args = @_;
		$args{file_match} = qr{^(?:bin|script)/.+} unless defined $args{file_match};
		my @files = $self->_filelist(%args);
		for my $file (@files) {
			$self->_queue(sub {
				my $res = `$^X -c '$file' 2>&1`;
				my $rc = $? >> 8;
				$self->_ok($rc == 0, "syntax $file", $rc ? ("Exitcode = $rc",$res) : ());
			});
		}
		if (!@files) {
			$self->_queue(sub { $Test->skip("Found no files for syntax check"); });
		}
	}],
	[ podcover => ['Test::Pod::Coverage 1.08','Pod::Coverage 0.18'], sub {
		my $self = shift;
		my %args = @_;
		my @files = $self->_modlist(%args);
		for my $file (@files) {
			$self->_queue(sub {
				Test::Pod::Coverage::pod_coverage_ok($file, "POD coverage on $file");
			});
		}
		if (!@files) {
			$self->_queue(sub { $Test->skip("Found no modules for pod-coverage check"); });
		}
	}],
	[ prereq => 'Test::Prereq', sub {
		my $self = shift;
		my @args = @_;
		$self->_queue(sub {
			$Test->diag("Runnkig Test::Prereq. Please, wait a while...");
			local $0 = 'Makefile.PL'; # Hack
			local *STDOUT;
			local *STDERR;
			local $ENV{PERL5LIB} = 'lib';
			my $old_gff = \&Test::Prereq::_get_from_file;
			my %uses;
			no warnings 'redefine';
			local *Test::Prereq::_get_from_file = sub {
				my( $class, $file ) = @_;
				my $module  = Module::Info->new_from_file( $file );
				$module->die_on_compilation_error(1);
				my @used    = eval{ $module->modules_used };
				#push @{ $uses{$_} ||= [] }, $file;
				$Test->diag("$@") if $@;
				goto &$old_gff;
			};
			local *Test::Prereq::_get_dist_modules = sub {
				[ map { $_->{in_lib} ? ($_->{module}) : () } @{ $self->{d}{modules} } ]
			};
			local *Test::Prereq::_get_loaded_modules = sub {
				my $class = shift;
				my @found;
				for my $file (
					grep {
						m{^(?:lib/.+\.pm|t/.+\.t|script/.+)$}
					} @{$self->{d}{files_array}}
				) {
					my $used = $class->_get_from_file( $file );
					#warn "Found @{$used} from $file";
					push @found, @$used;
				}
				return { map { $_ => 1 } @found };
			};
			{
				local $SIG{__WARN__} = sub {};
				Test::Prereq::prereq_ok(@args);
			}
		});
	} ],
);

sub _matchsub {
	my $self = shift;
	my $match = shift;
	$match or return sub { 0 };
	my @match_qr;
	my %match_eq;
	for ( @{ $match } ) {
		if (UNIVERSAL::isa($_,"Regexp")) {
			push @match_qr, $_;
		} else {
			$match_eq{$_} = 1;
		}
	}
	return sub {
		return 1 if $match_eq{$_[0]};
		for (@match_qr) {
			return 1 if $_[0] =~ $_;
		}
		return 0;
	};
}

sub _filelist {
	my $self = shift;
	my %args = @_;
	my $skip = $self->_matchsub(delete $args{file_skip});
	my @files = ( map { ( $_ =~ $args{file_match} && !$skip->($_) ) ? ($_) : () }  @{ $self->{d}{files_array} } );
}

sub _modlist {
	my $self = shift;
	my %args = @_;
	$args{file_match} = qr{^lib/.*\.pm$} unless defined $args{file_match};
	my @files = $self->_filelist(%args);
	$args{mod_match} = qr{.+} unless defined $args{mod_match};
	my $skip = $self->_matchsub(delete $args{mod_skip});
	@files = map {
		my $x = $_;
		$x =~ s{^lib/}{};
		$x =~ s/\.pm$//;
		$x =~ s|/|::|g;
		$skip->($x) ? () : ($x);
	} @files;
	return @files;
}

sub import {
	my $me = shift;
	my $cl = caller;
	no strict 'refs';
	*{$cl.'::dist_ok'} = \&dist_ok;
	if (@_ and $_[0] eq 'as') {
		shift;
		my $version = shift;
		%TEST_OK = map { $_ => 1 } @{ $TESTS{$version} };
		%TEST_OK or die "$me not defined test set for version $version";
		$Test->diag("Using $me $VERSION as of $version") if $VERSION ne $version;
	}
}

sub dist_ok {
	my $self = bless {};
	my %args = (
		run => $ENV{TEST_AUTHOR},
		@_,
	);
	my %skip = map { $_ => 1 } @{ delete($args{skip}) || [] };
	$self->{skip} = \%skip;
	$self->{args} = \%args;
	$self->{dist} = '.';
	$self->_init;
	for (@{ $self->{testqueue} || [] }) {
		$_->();
	}
}

sub _kwalitee_generators {
	my $self = shift;
	my @gen;
	for my $gen (@{ Module::CPANTS::Kwalitee->new->generators() } ) {
		next if $gen =~ /Unpack/;
		next if $gen =~ /(^?:CpantsErrors|Distname|Prereq)$/;
		if ($gen eq 'Module::CPANTS::Kwalitee::Manifest') { $gen = 'Test::Dist::Manifest' }
		push @gen, $gen;
	}
	@gen;
}

sub _init {
	my $self = shift;
	if (!$Test->has_plan and !$self->{args}{run}) {
		$Test::NoWarnings::do_end_test = 0 if $INC{'Test/NoWarnings.pm'};
		$Test->plan( skip_all => "Run condition not met" );
		return;
	};
	$self->{testqueue} = [];
	$self->{a} = Module::CPANTS::Analyse->new({
		distdir => $self->{dist},
		dist    => $self->{dist},
	});
	for my $gen ($self->_kwalitee_generators) {
		local $^W;
		$gen->analyse($self->{a});
	}
	$self->{d} = $self->{a}->d();
	my $tests = 0;
	for (@TESTS) {
		my ($key,$use,$code) = @$_;
		next unless $TEST_OK{$key};
		next if $self->{skip}{$key};
		my @use = ref $use ? @$use : $use;
		my $req = join '; ', map { "use $_ ()" } @use;
		#warn "loading: $req";
		if (eval "$req; 1") {
			$code->($self,
				$self->{args}{$key} ? (
					ref $self->{args}{$key} eq 'ARRAY' ? @{ $self->{args}{$key} } :
					ref $self->{args}{$key} eq 'HASH'  ? %{ $self->{args}{$key} } :
					$self->{args}{$key}
				) : ()
			);
		} else {
			$self->_queue(sub {
				$self->_skip(join(", ",@use)." required for testing $key");
			});
		}
		
	}
	$Test->plan( tests =>
		$tests
		+ @{ $self->{testqueue} }
		+ ( $self->{args}{'+'} || 0 )
	) unless $Test->has_plan;
	return;
}

sub _queue {
	my $self = shift;
	my $code = shift;
	push @{ $self->{testqueue} }, $code;
	return;
}

sub _skip {
	my( $self, $why, $n ) = @_;
	$n ||= 1;
	$Test->skip($why) for 1..$n;
}

sub _ok {
	my( $self, $ok, $name, @message ) = @_;
	$Test->ok( $ok, $name );
	$Test->diag( $_ ) for @message;
}

END {
	for (<Debian_CPANTS.txt*>) {
		unlink $_ or $! and print STDERR "#! unlink $_: $!\n";
	}
}

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-dist at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Dist>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to

=over 4

=item * B<Alexandr Ciornii> for L<Module::CPANTS::Analyse>

=item * B<brian d. foy> for L<Test::Prereq>

=item * B<Barbie> for L<Test::YAML::Meta>

=item * B<Edmund von der Burg> for L<Test::Fixme>

=item * B<Andy Lester> for L<Test::Pod::Coverage>

=item * B<G. Allen Morris III> for L<Test::CheckChanges>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Test::Dist
