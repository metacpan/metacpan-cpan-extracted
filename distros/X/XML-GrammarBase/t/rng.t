#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

package MyGrammar::RNG;

use MooX 'late';

use File::Spec;

with ('XML::GrammarBase::Role::RelaxNG');

has '+module_base' => (default => 'XML-GrammarBase');
has '+data_dir' => (default => File::Spec->catdir(File::Spec->curdir(), "t", "data"));
has '+rng_schema_basename' => (default => 'fiction-xml.rng');

package main;

sub _utf8_slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    binmode $in, ':encoding(utf8)';

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

# TEST:$c=0;
sub test_file
{
    my ($filename, $assert_cb) = @_;

    {
        my $rng = MyGrammar::RNG->new();

        my $xml_parser = XML::LibXML->new();
        $xml_parser->validation(0);

        my $dom = $xml_parser->parse_file($filename);
        eval {
            $rng->rng_validate_dom($dom);
        };

        # TEST:$c++;
        $assert_cb->($@, "rng_validate_dom()");
    }

    {
        my $rng = MyGrammar::RNG->new();

        eval {
            $rng->rng_validate_file($filename);
        };

        # TEST:$c++;
        $assert_cb->($@, "rng_validate_file()");
    }


    {
        my $rng = MyGrammar::RNG->new();

        eval {
            $rng->rng_validate_string(_utf8_slurp($filename));
        };

        # TEST:$c++;
        $assert_cb->($@, "rng_validate_string()");
    }
}

# TEST:$test_file=$c;

test_file(
    File::Spec->catfile(
        File::Spec->curdir(), "t", "data", "fiction-xml-test.xml"
    ),
    sub {
        my $Err = shift;
        my $blurb = shift;

        # TEST*$test_file
        is ($Err, '', "$blurb - No exception was thrown", );
    }
);

test_file(
    File::Spec->catfile(
        File::Spec->curdir(), "t", "data", "fiction-xml-invalid-test.xml"
    ),
    sub {
        my $Err = shift;
        my $blurb = shift;

        # TEST*$test_file
        ok ($Err, "$blurb - An exception was thrown",);
    }
);

