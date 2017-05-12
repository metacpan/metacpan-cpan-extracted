package DTS_UT::Test::Harness::Straps::NoExec;

=pod

=head1 NAME

DTS_UT::Test::Harness::Straps::NoExec - subclass of Test::Harness::Straps to eval test file code instead of forking 
a process to execute it.

=head1 DESCRIPTION

C<DTS_UT::Test::Harness::Straps::NoExec> will execute a test file code (Perl code, of course) by using an C<eval> instead
of forking a process to execute the script and read the results from it.

This is usefull to execute test in a web application running in a Apache/mod_perl or IIS/PerlEz environment, were 
forking a new process from the server process itself is never a good idea for performance reasons. There are some issues
forking with IIS 5 with Perl, so this modules solves this problem as well.

C<DTS_UT::Test::Harness::Straps::NoExec> is a hack from C<Test::Harness::Straps> module. Those modules are not maintained
anyore, so if you're taking serious about using it, my recomendation is that you check out L<TAP::Parser> module 
documentation.

=head1 EXPORT

Everything that C<Test::Harness::Straps> does.

=cut

use warnings;
use strict;

use base qw(Test::Harness::Straps);

#required for _wait2exit subroutine
eval { require POSIX; &POSIX::WEXITSTATUS(0) };
if ($@) {
    *_wait2exit = sub { $_[0] >> 8 };
}
else {
    *_wait2exit = sub { POSIX::WEXITSTATUS( $_[0] ) }
}

=head1 METHODS

=head2 new

It expects as a parameter a C<DTS_UT::Model::UnitTest> object. 

Returns a C<DTS_UT::Test::Harness::Straps::NoExec> object.

=cut

sub new {

    my $class = shift;
    my $test  = shift;

    my $self = $class->SUPER::new(@_);

    $self->{test} = $test;

    return $self;

}

=head2 get_test

Returns the C<DTS_UT::Model::UnitTest> object passed as an argument for C<new> method.

=cut

sub get_test {

    my $self = shift;

    return $self->{test};

}

=head2 analyze_file

Overrides C<analyze_file> method from C<Test::Harness::Straps> class.

Expects as parameter the package name that will be tested. The test script than needs to change it's default output 
to a text file instead of C<STDOUT>.

See the methods C<failure_output> and C<output> of L<Test::More::Builder> class.

=cut

sub analyze_file {

    my $self    = shift;
    my $package = shift;

    local $ENV{PERL5LIB} = $self->_INC2PERL5LIB;

    if ($Test::Harness::Debug) {

        local $^W = 0;    # ignore undef warnings
        print "# PERL5LIB=$ENV{PERL5LIB}\n";

    }

    my $result_file = $self->get_test()->run_test($package);

  # :TODO:11/11/2008:arfreitas: printing here just damages output from the CGI.
  # Should use any other module with try-catch structure to check for error
  # messages in the calling program. Double check for problems with such modules
  # when running in environments like mod_perl and Perlex
  #    print $@, "\n" if ( defined($@) );

    unless ( open( FILE, '<', $result_file ) ) {

        print 'Could not read result file ', $result_file, ": $!\n";
        return;

    }

    my $results = $self->analyze_fh( $result_file, \*FILE );
    my $exit = close FILE;

    $results->set_wait($?);

    if ( $? && $self->{_is_vms} ) {

        eval q{use vmsish "status"; $results->set_exit($?); };

    }
    else {

        $results->set_exit( _wait2exit($?) );

    }

    $results->set_passing(0) unless $? == 0;

    $self->_restore_PERL5LIB();

    return $results;

}

=head1 SEE ALSO

=over

=item *
L<Test::Harness::Straps>

=item *
L<Test::More::Builder>

=item *
DTS_UT::Model::UnitTest

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
