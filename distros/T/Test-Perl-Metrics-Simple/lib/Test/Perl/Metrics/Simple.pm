package Test::Perl::Metrics::Simple;

use strict;
use warnings;
use Carp qw(croak);
use Test::Builder qw();
use Perl::Metrics::Simple;

#-----------------------------------------------------------------------------

our $VERSION = 0.1;

#-----------------------------------------------------------------------------

my $TEST = Test::Builder->new();
my %METRICS_ARGS;

#-----------------------------------------------------------------------------

sub import {
    my($self, %args) = @_;
    my $caller = caller();

    ## no critic
    no strict 'refs';
    *{$caller . '::metrics_ok'}     = \&metrics_ok;
    *{$caller . '::all_metrics_ok'} = \&all_metrics_ok;

    $TEST->exported_to($caller);

    if($args{'-complexity'}){
        $args{'-complexity'} = 30 unless($args{'-complexity'} =~ /\d+/);
    }else{
        $args{'-complexity'} = 30;
    }

    %METRICS_ARGS = %args;

    return 1;
}

#-----------------------------------------------------------------------------

sub metrics_ok {
    my($file, $test_name) = @_;
    croak('no file specified') if(not defined $file);
    croak(sprintf('%s does not exist', $file)) if(not -f $file);
    $test_name ||= sprintf('Test::Perl::Metrics::Simple for %s', $file);

    my $metrics  = undef;
    my $analysis = undef;
    my $ok = 0;

    eval {
        $metrics  = Perl::Metrics::Simple->new();
        $analysis = $metrics->analyze_files($file);
        $ok = 1 if(grep($METRICS_ARGS{'-complexity'} > $_, map($_->{'mccabe_complexity'}, @{$analysis->subs()})));
    };

    $TEST->ok($ok, $test_name);

    if($@){
        $TEST->diag("\n");
        $TEST->diag(sprintf('Perl::Metrics::Simple had errors in %s', $file));
        $TEST->diag(sprintf("\t%s", $@));
    }elsif(not $ok){
        $TEST->diag("\n");
        $TEST->diag(sprintf("There is a method of complexity's exceeding %d", $METRICS_ARGS{'-complexity'}));

        foreach my $sub (sort {$b->{'mccabe_complexity'} <=> $a->{'mccabe_complexity'}} @{$analysis->subs()}){
            next if($sub->{'mccabe_complexity'} < $METRICS_ARGS{'-complexity'});
            $TEST->diag(sprintf('Complexity : %3d   method : %s'), $sub->{'mccabe_complexity'}, $sub->{'name'});
        }
    }

    return $ok;
}

#-----------------------------------------------------------------------------

sub all_metrics_ok {
    my @dirs = @_ ? @_ : _starting_points();
    my @files = _all_code_files(@dirs);
    $TEST->plan(tests => scalar @files);

    my $okays = 0;
    $okays += grep(metrics_ok($_), @files);
    return $okays == @files;
}

#-----------------------------------------------------------------------------

sub _all_code_files {
    my @dirs = @_ ? @_ : _starting_points();
    return Perl::Metrics::Simple->new()->list_perl_files(@dirs);
}

#-----------------------------------------------------------------------------

sub _starting_points {
    return -e 'blib' ? 'blib' : 'lib';
}

#-----------------------------------------------------------------------------

1;


__END__

=head1 NAME

Test::Perl::Metrics::Simple - Use Perl::Metrics::Simple in test programs

=head1 SYNOPSIS

Test one file:

  use Test::Perl::Metrics::Simple;
  use Test::More tests => 1;
  metrics_ok($file);

Or test all files in one or more directories:

  use Test::Perl::Metrics::Simple;
  all_metrics_ok($dir_1, $dir_2, $dir_N);

Or test all files in a distribution:

  use Test::Perl::Metrics::Simple;
  all_metrics_ok();

Recommended usage for CPAN distributions:

  use strict;
  use warnings;
  use File::Spec;
  use Test::More;

  if(not $ENV{'TEST_AUTHOR'}){
      my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
      plan(skip_all => $msg);
  }

  eval{require Test::Perl::Metrics::Simple;};

  if($@){
      my $msg = 'Test::Perl::Metrics::Simple required to criticise code';
      plan(skip_all => $msg);
  }

  Test::Perl::Metrics::Simple->import(-complexity => 30);
  all_metrics_ok();

=head1 VERSION

This is VERSION 0.1

=head1 DESCRIPTION

Test::Perl::Metrics::Simple is a module that tests Cyclomatic complexity of the code.

=head1 FUNCTIONS

=head2 import(%opt)

The value is set to Test::Perl::Metrics::Simple.

=head2 metrics_ok($file)

Cyclomatic complexity of the specified file is tested.

=head2 all_metrics_ok(@dirs)

Cyclomatic complexity of all the codes that exist in the specified directory is checked.

=head1 AUTHOR

Seiki Koga E<lt>koga@shanon.co.jpE<gt>

=head1 SEE ALSO

L<Perl::Metrics::Simple>, L<Perl::Metrics>, L<Test::More>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
