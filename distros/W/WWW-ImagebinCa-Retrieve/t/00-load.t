#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 24;

my $Test_ID = 'meAMq7';
my $Image_extension = '.jpg';
my $Image_description = 'Bored Cat';

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('File::Spec');
    use_ok('HTML::TokeParser::Simple');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::ImagebinCa::Retrieve' );
}

diag( "Testing WWW::ImagebinCa::Retrieve $WWW::ImagebinCa::Retrieve::VERSION, Perl $], $^X" );

use WWW::ImagebinCa::Retrieve;
my $bin = WWW::ImagebinCa::Retrieve->new(timeout => 10);
isa_ok($bin,'WWW::ImagebinCa::Retrieve');
can_ok($bin, qw(new retrieve error page_id image_uri page_uri description
                where what full_info));

my $full_info = $bin->retrieve(
    what => $Test_ID,
    where => 't/',
    save_as => 'test',
);

SKIP: {
    unless ( defined $full_info ) {
        ok(
            defined $bin->error,
            'error() method must return an error message0',
        );
        diag "\n\n\nGot error (" . $bin->error . ") from retrieve(). "
                . "If the message says that page ID doesn't exist then"
                . " PLEASE send an email to zoffix\@cpan.org "
                . " saying that WWW::Imagebin::Retrieve needs "
                . " its test suite updated. Thank you!\n\n"
                . "---(sleeping for 10 seconds)\n\n\n\n";
        sleep 10;
        skip "Got error on retrieve()", 14;
    }
    is(
        $full_info->{what},
        $Test_ID,
        '{what} key',
    );
    is(
        $full_info->{what},
        $bin->what,
        '{what} and what() must match',
    );
    
    is(
        "$full_info->{page_id}",
        $Test_ID,
        '{page_id} contains ID of the page',
    );
    is(
        $full_info->{page_id},
        $bin->page_id,
        '{page_id} and ->page_id() must match',
    );

    isa_ok($full_info->{page_uri}, 'URI');
    is(
        "$full_info->{page_uri}",
        "http://imagebin.ca/view/$Test_ID.html",
        '{page_uri} must contain URI to the page',
    );
    is(
        $full_info->{page_uri},
        $bin->page_uri,
        '{page_uri} and ->page_uri must match',
    );

    isa_ok($full_info->{image_uri}, 'URI');
    can_ok($full_info->{image_uri}, qw(path_segments));
    is(
        "$full_info->{image_uri}",
        "http://imagebin.ca/img/$Test_ID$Image_extension",
        '{image_uri} must have direct URI to the image',
    );
    is(
        $full_info->{image_uri},
        $bin->image_uri,
        '{image_uri} and ->image_uri must match',
    );

    is(
        $full_info->{description},
        $Image_description,
        '{description} must contain the description of the image',
    );
    is(
        $full_info->{description},
        $bin->description,
        '{description} and ->description() must match',
    );
    
    like(
        $full_info->{where},
        qr{t[\\/]test$Image_extension},
        '{where} must contain the local location of the image',
    );
    is(
        $full_info->{where},
        $bin->where,
        '{where} and ->where() must match',
    );
}


