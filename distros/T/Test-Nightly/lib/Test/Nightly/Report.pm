package Test::Nightly::Report;

use strict;

use Carp;
use Template;
use DateTime;

use Test::Nightly::Email;
use Test::Nightly::Report::Template;

use base qw(Test::Nightly::Base Class::Accessor::Fast);

my @methods = qw(
	email_report
	report_template
	report_output
	test
	tests
	test_report
	version_report
	version_result
);

__PACKAGE__->mk_accessors(@methods);

our $VERSION = '0.03';

=head1 NAME

Test::Nightly::Report - Generates a test report.

=head1 DESCRIPTION

Generates a report based on the tests that have been run, that can then be emailed to you, or output to a file. You probably should not be dealing with this directly.

=head1 SYNOPSIS

  use Test::Nightly::Report;
  
  my $nightly = Test::Nightly::Report->new({
    email_report => {
  	to => 'kirstinbettiol@gmail.com',
    }
  });

$report->run();

The following methods are available:

=cut

=head2 new()

  my $report = Test::Nightly::Report->new({
    email_report    => \%email_config,                # Emails the report. See Test::Nightly::Email for config.
    report_template => '/dir/somewhere/template.txt', # Defaults to internal template.
    report_output   => '/dir/somewhere/output.txt',   # File to output the report to.
    test_report     => 'all',                         # 'failed' || 'passed'. Defaults to all.
  });

Produces a report on the tests that have been run.  

Depending on what you pass in, defines what report is generated. 
If you would like the report emailed to you, pass in C<email_report>. 
If you would like the report to be logged somewhere, then pass in C<report_template>.

Default template can be seen in L<Test::Nightly::Report::Template>

=cut

sub new {

    my ($class, $conf) = @_;

	my $self = bless {}, $class;

	$self->_init($conf, \@methods);

	return $self;

}

=head2 run()

  $report->run({
    ... takes the same arguments as new ...
  });

Generates the report.

=cut

sub run {

    my ($self, $conf) = @_;

	$self->test_report('all') unless $self->test_report();
	$self->_debug('Running Report');

	# Return if there are no tests
	return if ( !$self->tests() );
	# Return if there are no passed tests and we are only reporting on passed tests
	return if ( !$self->_passed_tests() && $self->test_report() eq 'passed' );
	# Return if there are no failed tests and we are only reporting on failed tests
	return if ( !$self->_failed_tests() && $self->test_report() eq 'failed' );

	# Work out what test data we want.
	my %vals;

	if ($self->test_report() eq 'failed') {
		$vals{'tests'} = $self->_failed_tests();
	} elsif ($self->test_report() eq 'passed') {
		$vals{'tests'} = $self->_passed_tests();
	} else {
		$vals{'tests'} = $self->tests();
	}

	# Read in the passed in template, else use the default template
	my $template;
	if (defined $self->report_template()) {

		open DATA, $self->report_template() or $self->_add_error('Test::Nightly::Report::run() - Error with "report_template": ' . $self->report_output() . ': ' . $!);
		while(<DATA>) {
			$template .= $_ . "\r\n";
		}

	} else {
		$template = Test::Nightly::Report::Template::DEFAULT;
	}

	if ($template) {
	
		my $tt = Template->new({ABSOLUTE => 1});

		# Process the Report
		my $report = '';
		$tt->process(\$template, \%vals, \$report);
		carp $tt->error() if ($tt->error());

		# Send an email if an email address is passed in
		if (defined $self->email_report()) {

			my $email = Test::Nightly::Email->new($self->email_report());

			$email->email({
				subject	=> 'Results of your Tests',
				message => $report,
			});

		}	
		if (defined $self->report_output()) {

			open(FH,">" . $self->report_output()) || $self->_add_error('Test::Nightly::Report::run() - Error with "report_output": ' . $self->report_output() . ': ' . $!);
			print FH $report;
			close(FH);

		}  

	}

}

# Gets the tests from the the test output 

sub tests {

    my $self = shift;

	if (defined $self->test()) {
    	return $self->test()->tests();
	} else {
		return;
	}

}

# Gets the passed tests from the test output

sub _passed_tests {

	my $self = shift;

	return $self->test()->passed_tests();

}

# Gets the failed tests from the test output

sub _failed_tests {

	my $self = shift;

	return $self->test()->failed_tests();

}

=head1 List of methods:

=over 4

=item email_report

If set will email the report. Takes a hash ref of \%email_config, refer to Test::Nightly::Email for the options.

=item report_template

Pass this in if you wish to have your own customised report template. Otherwise, uses the default template is in Test::Nightly::Report::Template

=item report_output

Set this to a filepath/filename and the report will be outputted here.

=item test

Output of the test.

=item test_report

This is where you specify what you wish to report on after the outcome of the test. Specifying 'passed' will only report on tests that passed, specifying 'failed' will only report on tests that failed and specifying 'all' will report on both.

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 SEE ALSO

L<Test::Nightly>,
L<Test::Nightly::Test>,
L<Test::Nightly::Report>, 
L<Test::Nightly::Email>, 
L<Test::Nightly::Report::Template>, 
L<perl>.

=cut

1;
