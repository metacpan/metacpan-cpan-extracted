package Test2::Harness::Worker;
use strict;
use warnings;

use Storable qw/retrieve store_fd/;

sub import {
    my $class = shift;
    return unless @_;
    my ($conf_file, $run_file) = @_;

    require Test2::Harness::Config;
    my $config = retrieve($conf_file) or die "Could not load config file";
    unlink($conf_file) or warn "Could not unlink config file: $!";

    open(my $fh, '>', $run_file) or die "Could not open run file for writing: $!";

    my $run = Test2::Harness::Run->new(
        config => $config,
    );

    my ($test_file, $set_env) = $run->run();

    if ($test_file) {
        $test_file = "./$test_file" unless $test_file =~ m{^\.*/};

        my $caller = caller;
        no strict 'refs';
        *{"$caller\::test_file"} = sub() { $test_file };
        *{"$caller\::set_env"} = $set_env || sub() { };

        return;
    }

    store_fd($run, $fh) or die "Could not store run file";
    close($fh);

    exit 0;
}

sub runtime_code { <<"EOT" }
#line ${\(__LINE__ + 1)} "${\__FILE__}"
use strict;
use warnings;
my \$test_file = test_file();
set_env();
\$@ = '';
do \$test_file;
die \$@ if \$@;
exit 0;
EOT

1;
