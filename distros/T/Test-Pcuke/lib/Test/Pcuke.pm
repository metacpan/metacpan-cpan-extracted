package Test::Pcuke;

use warnings;
use strict;

use Carp;

use Encode qw{encode};

use Test::Pcuke::Gherkin;
use Test::Pcuke::Gherkin::I18n;
use Test::Pcuke::Report;
use Test::Pcuke::Executor;
use File::Find;

=head1 NAME

Test::Pcuke - Cucumber for Perl 5

=head1 VERSION

Version 0.0.4

=cut

our $VERSION = '0.000006';


=head1 SYNOPSIS

Provides functionality for the pcuke command which is an implementation
of cucumber in Perl 5, and the command itself

If you are interested in pcuke command, please read L<Test::Pcuke::Manual>

B<There are some bugs lurking around. Please report if you find any!>

	use Test::Pcuke;
	
	my $conf = { ... };
	my $runner = Test::Pcuke->new( $config );
	
	$runner->run();

As to v. 0.0.2 only utf-8 encoding is supported!

To see the list of languages that pcuke supports use a command:

	$ pcuke --i18n help

To see the information on a language, 'ru' for example, use:

	$ pcuke --i18n ru
	
	

=head1 METHODS

=head2 new $conf

	Creates an instance of Test::Pcuke, a I<runner>.

=cut

sub new {
	my ($class, $args) = @_;
	
	my $conf = $class->_translate_cmdline_args( $args );
	
	bless $conf, $class;
	
	return $conf;	
}

sub _translate_cmdline_args {
	my ($class, $args) = @_;
	my $conf = {
		encoding	=> 'utf8'
	};
	
	my @keys = map { ( /^--([-\w]+)$/ ) ? ($1) : () } keys %$args;
	foreach ( @keys ) {
		$conf->{$_} = $args->{"--$_"};
	}
	
	if ( $args->{'<filename>'} ) {
		$conf->{features} = $args->{'<filename>'};
	}
	
	return $conf; 
}

=head2 run

	Starts the process
	
=cut

sub run {
	my ($self) = @_;
	my $features;
	
	return $self->i18n() if $self->{i18n};
	
	$self->{_executor} = Test::Pcuke::Executor->new( $self->{encoding} );
	
	$self->load_step_definitions();
	$self->process_features();
	
	my $report = Test::Pcuke::Report->new(
		features	=>  $self->{_executed_features},
	);
	
	my $output = $report->build(); 
	
	$output = encode($self->{encoding}, $output)
		if $self->{encoding};
	
	print $output;
}

sub i18n {
	my ($self) = @_;
	
	if ( my $lang = $self->{i18n} =~ /^help$/i ) {
		print join "\n", map {
			Encode::encode($self->{encoding},$_)
		} @{ Test::Pcuke::Gherkin::I18n->languages }, "\n";
	} 
	else {
		my $info = Test::Pcuke::Gherkin::I18n->language_info( $self->{i18n} );
        foreach (@$info) {
        	print join( " -> ",
        		Encode::encode($self->{encoding}, $_->[0]),
        		Encode::encode($self->{encoding}, $_->[1])
        	),"\n";
        }	
	}
}

sub executor { $_[0]->{_executor} }

sub process_features {
	my ($self) = @_;
	my $files;
	
	if ( ref $self->{features} eq 'ARRAY') {
		$files = $self->{features};
	}
	else {
		$files = $self->scan_dir('features');
	}
	
	foreach ( @$files ) {
		my $content = $self->get_file_content($_);
		my $feature = Test::Pcuke::Gherkin->compile($content, $self->executor);
		$feature->execute;
		$self->collect_feature($feature);
	}
}


sub get_file_content {
	my ($self, $fn) = @_;
	
	my $encoding = $self->{encoding} || 'utf-8';
	
	local $/;
	
	my ($fh, $content);
	
	open( $fh, "<:encoding($encoding)", $fn )
		or confess "Can't open $fn for reading";
	$content = <$fh>;
	close $fh;
	
	return $content;
}

sub scan_dir {
	my ($self, $dir) = @_;
	$dir ||= 'features';

	my $files;
	
	find( sub {
		return unless /\.feature$/i;
		push @$files, $File::Find::name;
	}, $dir );
	
	return $files;
}

sub collect_feature {
	my ($self, $feature) = @_;
	push @{ $self->{_executed_features} }, $feature;
}

sub load_step_definitions {
	my ($self) = @_;
	my $dir ||= 'features';
	
	my @step_definitions = ();
	
	find( sub {
		push @step_definitions, $File::Find::name
			if /\.pm$/i;
	}, $dir );
	
	foreach (@step_definitions) {
		require "$_";
	}
	
}

1; # End of Test::Pcuke
__END__
=head1 AUTHOR

"Andrei V. Toutoukine", C<< <"tut at isuct.ru"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pcuke at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pcuke>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pcuke>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pcuke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pcuke>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pcuke/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 "Andrei V. Toutoukine".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

