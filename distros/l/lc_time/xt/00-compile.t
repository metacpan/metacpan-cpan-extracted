#! perl -w
use v5.10;
use warnings;

use Test::More;
Test::Compile->import('compiles_ok');

compiles_ok('lib/lc_time.pm');

done_testing();


BEGIN {
    package Test::Compile;
    use warnings;
    use strict;

    use base 'Test::Builder::Module';
    use Exporter 'import';
    our @EXPORT = qw/compiles_ok/;

    my $tb = __PACKAGE__->builder;

    sub compiles_ok {
        my ($filename, $msg) = @_;
        $msg //= "compile '$filename'";

        my $libs = '-Ilib';
        if (grep m{^blib/} => @INC) {
            $libs .= ' -Mblib';
        }
        my @compile_errors = grep {
            $tb->note("[RAW] $_");
               $_ !~ m{^.+ syntax OK}
            && $_ !~ m{^.+ had compilation errors}
        } do {
            local $ENV{PATH} = $ENV{PATH} =~ /^(.+)$/ ? $1 : undef;
            local $ENV{PERL5LIB} = join(':', @INC, ($ENV{PERL5LIB} // ''));
            my $perl_bin = $^X =~ /^(.+)$/ ? $1 : 'perl';
            qx{$perl_bin $libs -wc $filename 2>&1};
        };

        if (@compile_errors) {
            my $ok = $tb->ok(0, $msg);
            for my $error (@compile_errors) {
                $tb->diag($error);
            }
            return $ok;
        }
        return $tb->ok(1, $msg);
    }

    1;
}
