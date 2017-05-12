package Test::Settings;
{
  $Test::Settings::VERSION = '0.003';
}

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
	want_smoke
	want_non_interactive
	want_extended
	want_author
	want_release
	want_all

	enable_smoke
	enable_non_interactive
	enable_extended
	enable_author
	enable_release
	enable_all

	disable_smoke
	disable_non_interactive
	disable_release
	disable_extended
	disable_author
	disable_release
	disable_all

	current_settings
	current_settings_env
	current_settings_env_all
);

our %EXPORT_TAGS = (
	'all' => \@EXPORT_OK,
);

# Things we currently know about
my %flags = (
	want_smoke           => 'AUTOMATED_TESTING',
	want_non_interactive => 'NONINTERACTIVE_TESTING',
	want_extended        => 'EXTENDED_TESTING',
	want_author          => 'AUTHOR_TESTING',
	want_release         => 'RELEASE_TESTING',
);

sub _get_env_name {
	my ($flag) = @_;

	if ($flags{$flag}) {
		return $flags{$flag};
	} else {
		require Carp;
		Carp::croak("No such flag $flag\n");
	}
}

sub _get_flag {
	my ($flag) = @_;

	my $env_name = _get_env_name($flag);

	return $ENV{$env_name};
}

sub _set_flag {
	my ($flag) = @_;

	my $env_name = _get_env_name($flag);

	$ENV{$env_name} = 1;
}

sub _clear_flag {
	my ($flag) = @_;

	my $env_name = _get_env_name($flag);

	delete $ENV{$env_name};
}

sub want_smoke           { _get_flag('want_smoke')           }
sub want_non_interactive { _get_flag('want_non_interactive') }
sub want_extended        { _get_flag('want_extended')        }
sub want_author          { _get_flag('want_author')          }
sub want_release         { _get_flag('want_release')         }
sub want_all {
	return 1 if
	  want_smoke &&
	  want_non_interactive &&
	  want_extended &&
	  want_author &&
	  want_release
	;
}

sub enable_smoke           { _set_flag('want_smoke')           }
sub enable_non_interactive { _set_flag('want_non_interactive') }
sub enable_extended        { _set_flag('want_extended')        }
sub enable_author          { _set_flag('want_author')          }
sub enable_release         { _set_flag('want_release')         }
sub enable_all {
	enable_smoke;
	enable_non_interactive;
	enable_extended;
	enable_author;
	enable_release;
}

sub disable_smoke           { _clear_flag('want_smoke')           }
sub disable_non_interactive { _clear_flag('want_non_interactive') }
sub disable_extended        { _clear_flag('want_extended')        }
sub disable_author          { _clear_flag('want_author')          }
sub disable_release         { _clear_flag('want_release')         }
sub disable_all {
	disable_smoke;
	disable_non_interactive;
	disable_extended;
	disable_author;
	disable_release;
}

sub current_settings {
	my @values = (
		want_smoke() || '',
		want_non_interactive() || '',
		want_extended() || '',
		want_author() || '',
		want_release() || '',
	);

	return sprintf(<<EOF, @values);
want_smoke:           %s
want_non_interactive: %s
want_extended:        %s
want_author:          %s
want_release:         %s
EOF

}

sub current_settings_env {
	my $output = '';

	for my $flag (sort keys %flags) {
		my $env_name = _get_env_name($flag);

		if (my $f = _get_flag($flag)) {
			$output .= sprintf("%s=1\n", $env_name);
		}
	}

	return $output;
}

sub current_settings_env_all {
	my $output = '';

	for my $flag (sort keys %flags) {
		my $env_name = _get_env_name($flag);

		if (my $f = _get_flag($flag)) {
			$output .= sprintf("%s=1\n", $env_name);
		} else {
			$output .= sprintf("%s=0\n", $env_name);
		}
	}

	return $output;
}

1;
__END__

=head1 NAME

Test::Settings - Ask or tell when certain types of tests should be run

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Check the current settings

  use Test::Settings qw(:all);

  if (want_smoke) {
    printf("I must be a smoke tester\n");
  }  

  if (want_non_interactive) { ... }
  if (want_extended) { ... }
  if (want_author) { ... }
  if (want_release) { ... }

  if (want_all) { ... }

Change settings

  enable_smoke;
  enable_non_interactive;
  enable_extended;
  enable_author;
  enable_release;
  enable_all;

  disable_smoke;
  disable_non_interactive;
  disable_extended;
  disable_author;
  disable_release;
  disable_all;

Helper - see the settings as a string

  print current_settings;

Print enabled settings as ENV vars

  print current_settings_env;

Print all settings as ENV vars

  print current_settings_env_all;

=head1 DESCRIPTION

There are a number of Environment variables used to control how tests should 
behave, and sometimes these can change names or meaning.

This library tries to provide a consistent interface so that testers/toolchain 
users can determine the state of testing without having to care about the 
intricacies behind the scenes.

=head2 Inspecting the state of things

Currently, the following methods are provided to see what the current state of 
testing options are. Unless explicitly requested by a user or tool, these will 
usually all return false.

=head3 want_smoke

  if (want_smoke) { ... }

Returns true if we are currently being run by a smoker or a 'robot'.

=head3 want_non_interactive

  if (want_non_interactive) { ... }

Returns true if we are in non-interactive mode. This means tests should not 
prompt the user for information.

=head3 want_extended

  if (want_extended) { ... }

Returns true if extended testing has been requested. Often modules will ship 
with extra (non author/release) tests that users may opt in to run.

=head3 want_author

  if (want_author) { ... }

Returns true if author testing has been requested. Author tests are used during 
development time only.

=head3 want_release

  if (want_release) { ... }

Returns true if release testing has been requested. Release tests are used when 
a new release of a distribution is going to be built to check sanity before 
pushing to CPAN.

=head3 want_all

  if (want_all) { ... }

Returns true if all of the above wants are true.

=head2 Changing the state of things

The methods below allow modification of the state of testing. This can be used 
by smokers and build tools to inform testing tools how to run.

=head3 enable_smoke

=head3 disable_smoke

  enable_smoke();
  disable_smoke();

This enables or disables (default) smoke testing.

=head3 enable_non_interactive

=head3 disable_non_interactive

  enable_non_interactive();
  disable_non_interactive();

This enables or disables (default) non-interactive testing.

=head3 enable_extended

=head3 disable_extended

  enable_extended();
  disable_extended();

This enables or disables (default) extended testing.

=head3 enable_author

=head3 disable_author

  enable_author();
  disable_author();

This enables or disables (default) author testing.

=head3 enable_release

=head3 disable_release

  enable_release();
  disable_release();

This enables or disables (default) release testing.

=head3 enable_all

=head3 disable_all

Enable or disable all of the test switches at once.

=head2 Extra information

If you'd like a quick representation of the current state of things, the methods 
below will help you inspect them.

=head3 current_settings

  my $str = current_settings();
  print $str;

Displays a table of the current settings of all wants.

=head3 current_settings_env

  my $str = current_settings_env();
  print $str;

Prints enabled settings only as ENV vars.

=head3 current_settings_env_all

  my $str = current_settings_env_all();
  print $str

Prints ALL settings asa ENV vars.

=head1 SEE ALSO

L<Test::S> - Change test settings on the command line

L<Test::DescribeMe> - Tell test runners what kind of test you are

L<Test::Is> - Skip test in a declarative way, following the Lancaster Consensus

L<https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md> -
The Annotated Lancaster Consensus

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
