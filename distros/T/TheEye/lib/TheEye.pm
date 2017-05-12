package TheEye;

use 5.010;
use Mouse;
use POSIX qw/strftime/;
use File::Util;
use File::ShareDir 'dist_dir';
use TAP::Parser qw/all/;
use TAP::Parser::Aggregator qw/all/;
use Time::HiRes qw(gettimeofday tv_interval);
use Sys::Hostname;

# ABSTRACT: TheEye is a TAP based monitoring system
#
our $VERSION = '0.5'; # VERSION

has 'test_dir' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    #default  => dist_dir('TheEye') . '/t',
    default  => './t',
);

has 'debug' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 0,
    predicate => 'is_debug',
);

has 'hostname' => (
    is => 'rw', 
    isa => 'Str', 
    default => hostname()
);



sub run {
    my ($self) = @_;
    my $f = File::Util->new();
    print STDERR "processing files in " . $self->test_dir . "\n"
      if $self->debug;
    my @files = $f->list_dir( $self->test_dir, qw/ --files-only --recurse --pattern=\.t$/ );
    my @results;
    foreach my $file (@files) {
        print STDERR "processing " . $file . "\n" if $self->debug;
        my $t0 = [gettimeofday];
        my $parser = TAP::Parser->new( { source => $file, merge => 1 } );
        my $message;
        my @steps;
        my $t1 = [gettimeofday];
        while ( my $result = $parser->next ) {
            if ( $result->type eq 'comment' ) {
                if(exists $steps[-1]){
                    $steps[-1]->{comment} .= $result->as_string . "\n";
                } else {
                    # debug output of the tests
                    print STDERR $result->as_string."\n";
                }
            }
            else {
                my $hash = {
                    message => $result->as_string,
                    delta   => tv_interval($t1),
                    type    => $result->type,
                    status  => ( $result->is_ok ? 'ok' : 'not_ok' ),
                };
                print STDERR Dumper($hash);
                push( @steps, $hash );
            }
            $t1 = [gettimeofday];
        }
        my $aggregate = TAP::Parser::Aggregator->new;
        $aggregate->add( 'testcases', $parser );
        my $hash = {
            delta  => tv_interval($t0),
            passed => scalar $aggregate->passed,
            failed => scalar $aggregate->failed,
            file   => $file,
            'time' => time,
            steps  => \@steps,
        };
        push( @results, $hash );
    }
    return @results;
}


sub save {
    my ( $self, $tests ) = @_;

    #print STDERR "saving ".($#lines +1)." results\n" if $self->debug;
    return;
}


sub graph {
    my ( $self, $tests ) = @_;

    #print STDERR "saving ".($#lines +1)." results\n" if $self->debug;
    return;
}


sub notify {
    my ( $self, $tests ) = @_;
    foreach my $test ( @{$tests} ) {
        foreach my $step ( @{ $test->{steps} } ) {
            if ( $step->{status} eq 'not_ok' ) {
                my $message = 'we have a problem: ' . $test->{file} . "\n";
                $message .= $step->{message} . "\n";
                $message .= $step->{comment} if $step->{comment};
                print STDERR $message;
            }
        }
    }

    #print STDERR "saving ".($#lines +1)." results\n" if $self->debug;
    return;
}


sub load_plugin {
    my ($self, $plugin) = @_;

    my $plug = 'TheEye::Plugin::'.$plugin;
    print STDERR "Loading $plugin Plugin\n" if $self->is_debug;
    with($plug);
    return;
}


1;    # End of TheEye

__END__

=pod

=encoding UTF-8

=head1 NAME

TheEye - TheEye is a TAP based monitoring system

=head1 VERSION

version 0.5

=head1 SYNOPSIS

This is a short test snippet. look at the /bin directory for soem more
ideas. howeveer, you can also simply use the scripts in bin and not play
with the liraries at all.

    use TheEye;
    use Data::Dumper;

    my $mon = TheEye->new(debug=> 1, test_dir => 't');
    $mon->load_plugin('Store::RRD');
    $mon->rrd_dir('rrds/');
    my $results;
    @{$results} = $mon->run();
    $mon->save($results);
    print Dumper($results);

=head1 FUNCTIONS

=head2 run

The run function runs the tests in the test directory (and all
directories under it recusively) and returns an array of test results
(each TAP line is one test result array field). These resuts contain
some meta data as eg. the time it took to run the test.

comments in TAP output are written into the reponse hash of the
according test - not as a separate hash.

=head2 save

This is only a knob to override with plugins. the default does not save
anything. use eg. the RRD plugin or write your own.

=head2 graph

This is only a knob to override with plugins. the default does not draw
anything. use eg. the RRD plugin or write your own.

=head2 notify

This is the most basic version - we notify to STDERR and hope that
someone picks it up. this is really only a more advanced override knob.

=head2 load_plugin

This loads a plugin from the TheEye::Plugin namespace

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-theeye at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TheEye>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TheEye

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TheEye>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TheEye>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TheEye>

=item * Search CPAN

L<http://search.cpan.org/dist/TheEye/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
