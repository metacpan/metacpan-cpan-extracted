use inc::Module::Install;

name 'UUID-Generator-PurePerl';
all_from 'lib/UUID/Generator/PurePerl.pm';

requires 'Exporter'     => 5.562;
requires 'Carp'         => 0;
requires 'Time::HiRes'  => 1.20;
requires 'Digest'       => 1.00;

recommends 'Digest::MD5' => 2.20;
recommends 'Digest::SHA' => 5.32;

requires 'UUID::Object' => 0.04;

use FindBin;
if (-e "${FindBin::Bin}/ext/UUID/Object.pm") {
    my $sub_test
        = sub {
            my $self = shift;
            my $r = $self->MY::test(@_);

            # from Module::Install::Makefile::fix_up_makefile()

            $r =~ s{\b ( test_harness \Q($(TEST_VERBOSE)\E, \s* )
                   }{$1'ext', }gxmso;

            #$r =~ s{ ( \s* \Q"-I$(INST_LIB)"\E \s* ) }{ "-Iext"$1}gxmso;
            $r =~ s{ ( \Q$(FULLPERLRUN)\E \s* ) }{$1"-Iext" }gxmso;

            return $r;
        };

    no strict 'refs';
    *{'MY::test'} = $sub_test;
}

test_requires 'Test::More';

auto_include;

WriteAll;
