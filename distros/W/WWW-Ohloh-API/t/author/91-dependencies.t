#!/usr/bin/perl 

use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

plan skip_all =>
  'add WWW::Ohloh::API to the environment variable TEST_AUTHOR to run this test'
  unless $ENV{TEST_AUTHOR} =~ /WWW::Ohloh::API/;

plan skip_all => 'test requires Perl 5.10 (or greater)' unless $] >= 5.010;

eval <<'END_TEST';    # because of 5.10 feature

    plan tests => 1;

    my @ignore = qw/ /;

    ok dependency_check_of('META');

    sub dependency_check_of {
        my @to_verify = @_;

        if ( 'META' ~~ @to_verify ) {
            @to_verify = grep { $_ ne 'META' } @to_verify;
            open my $meta_fh, '<', 'META.yml' or die;
            while (<$meta_fh>) {
                next unless /file: (?<filename>\S+)/;
                my $f = $+{filename};
                $f =~ s#^lib/##;
                $f =~ s#/#::#g if $f =~ s#\.pm$##;
                push @to_verify, $f;
            }
        }

        push @ignore, @to_verify;    # can't depend on yourself... (sic)

        # load the declared dependencies
        open my $build_fh, '<', 'Build.PL' or die;
        $/ = undef;
        <$build_fh> =~ /requires \s+ => \s+ { (?<modules>.*?) } /sx or die;

        my %depends = eval $+{modules};

        eval "use $_" for keys %depends;

        my $success = 1;

        unshift @INC, sub {
            my $f = $_[1];
            $f =~ s#/#::#g;
            $f =~ s#\.pm$##;

            return if $f ~~ @ignore;

            print "\tneed to include $f?\n";

            $success = 0;
        };

        for (@to_verify) {
            eval "use $_";
            warn "couldn't use '$_': $@\n" if $@;
        }

        return $success;
    }

};
END_TEST
