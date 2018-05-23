use Dumbbench;

use XS::Logger     ();
use Cpanel::Logger ();

my $bench = Dumbbench->new(
    target_rel_precision => 0.005,    # seek ~0.5%
    initial_runs         => 20,       # the higher the more reliable
);

my $xs = XS::Logger->new;
my $cp = Cpanel::Logger->new;

$bench->add_instances(

    # Dumbbench::Instance::Cmd->new(command => [qw(perl -e 'something')]),
    # Dumbbench::Instance::PerlEval->new(code => 'for(1..1e7){something}'),

    Dumbbench::Instance::PerlSub->new( name => 'XS new',     code => sub { XS::Logger->new     for 1 .. 100 } ),
    Dumbbench::Instance::PerlSub->new( name => 'cPanel new', code => sub { Cpanel::Logger->new for 1 .. 100 } ),

    Dumbbench::Instance::PerlSub->new( name => 'XS info',     code => sub { $xs->info("My message") for 1 .. 100 } ),
    Dumbbench::Instance::PerlSub->new( name => 'cPanel info', code => sub { $cp->info("My message") for 1 .. 100 } ),

    Dumbbench::Instance::PerlSub->new( name => 'XS info with %d %s', code => sub { $xs->info( "My message %d %s", $_, "a string" ) for 1 .. 100 } ),
    Dumbbench::Instance::PerlSub->new( name => 'cPanel info %d %s', code => sub { $cp->info( sprintf( "My message %d %s", $_, "a string" ) ) for 1 .. 100 } ),

);

# (Note: Comparing the run of externals commands with
#  evals/subs probably isn't reliable)
$bench->run;
$bench->report;

__END__

XS new: Ran 23 iterations (1 outliers).
XS new: Rounded run time per iteration: 6.765e-05 +/- 2.3e-07 (0.3%)
cPanel new: Ran 27 iterations (5 outliers).
cPanel new: Rounded run time per iteration: 2.163e-04 +/- 1.1e-06 (0.5%)
XS info: Ran 36 iterations (0 outliers).
XS info: Rounded run time per iteration: 4.464e-04 +/- 2.2e-06 (0.5%)
cPanel info: Ran 26 iterations (2 outliers).
cPanel info: Rounded run time per iteration: 2.0461e-03 +/- 9.8e-06 (0.5%)
XS info with %d %s: Ran 54 iterations (5 outliers).
XS info with %d %s: Rounded run time per iteration: 4.468e-04 +/- 2.2e-06 (0.5%)
cPanel info %d %s: Ran 40 iterations (4 outliers).
cPanel info %d %s: Rounded run time per iteration: 2.274e-03 +/- 1.0e-05 (0.5%)
    ~/workspace  ✔ 
