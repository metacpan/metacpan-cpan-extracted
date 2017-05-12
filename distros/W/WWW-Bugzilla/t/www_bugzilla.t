#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);

my $server = 'landfill.bugzilla.org/bugzilla-3.4-branch';

verify_host($server);
plan(tests => 35);

use_ok('WWW::Bugzilla');

my $bug_number = 8515;

my $email    = 'bmc@shmoo.com';
my $password = 'pileofcrap';
my $product  = 'FoodReplicator';

my $summary     = 'this is my summary';
my $description = "this is my description.\nthere are many like it, but this one is mine.";
my @products = ('FoodReplicator', 'LJL Test Product', "Spider S\x{e9}\x{e7}ret\x{ed}\x{f8}ns", 'Sam\'s Widget', 'MyOwnBadSelf', 'WorldControl');
my @added_comments;
my @added_files;

check_products();
check_states();
check_comments();
check_create_by_product();
check_file_attach();
check_attached_files();
exit;

sub check_products {
    my $bz = WWW::Bugzilla->new(
            use_ssl => 1,
            server   => $server,
            email    => $email,
            password => $password,
            );
    ok($bz, 'new');

    eval { $bz->available('component'); };
    like($@, qr/available\(\) needs a valid product to be specified/, 'product first');

    my @available = $bz->available('product');
    is_deeply(\@available, \@products, 'expected: product');

    eval { $bz->product('this_is_not_a_real_product'); };
    like ($@, qr/error \: Sorry\, either the product/, 'invalid product');

    $bz->summary($summary);
    $bz->description($description);
    push (@added_comments, $description);
    ok($bz->product($available[0]), 'set: product');
    my $bugid = $bz->commit();
    like ($bugid, qr/^\d+$/, "bugid : $bugid");
    $bug_number = $bugid;
}
   
sub check_states {
    my $bz = WWW::Bugzilla->new(
            use_ssl => 1,
            server     => $server,
            email      => $email,
            password   => $password,
            bug_number => $bug_number
            );


    my $comment = 'comments here - 1';
    is($bz->summary, $summary, 'summary');
    ok($bz->additional_comments($comment), 'add comment');
    ok($bz->commit, 'commit');
    push (@added_comments, $comment);

    ok($bz->change_status('fixed'), 'mark fixed');
    ok($bz->commit, 'commit');

    ok($bz->change_status('reopened'), 'reopened');
    ok($bz->commit, 'commit');

    ok($bz->mark_as_duplicate(2998), 'mark as duplicate');
    ok($bz->commit, 'commit');
    push (@added_comments, '*** This bug has been marked as a duplicate of <span class="bz_closed"><a href="show_bug.cgi?id=2998" title="RESOLVED FIXED - Hardlinks not created and the world is thence seriously out of control">bug 2998</a></span> ***');
}

sub check_comments {
    my $bz = WWW::Bugzilla->new(
            use_ssl => 1,
            server     => $server,
            email      => $email,
            password   => $password,
            bug_number => $bug_number
            );


    my @comments = $bz->get_comments();
    is_deeply(\@comments, \@added_comments, 'comments');
}

sub check_create_by_product {
    my $bz = WWW::Bugzilla->new(
            use_ssl => 1,
            server   => $server,
            email    => $email,
            password => $password,
            product  => $product
            );
    ok($bz, 'new');

    is($bz->product, $product, 'new bug, with setting product');

    my %expected = (
            'component' => [ 'renamed component', 'Salt', 'Salt II', 'SaltSprinkler', 'SpiceDispenser', 'VoiceInterface' ],
            'version'  => [ '1.0' ],
            'platform' => [ 'All', 'DEC', 'HP', 'Macintosh', 'PC', 'SGI', 'Sun', 'Other' ],
            'os' => [ 'All', 'Windows 3.1', 'Windows 95', 'Windows 98', 'Windows ME', 'Windows 2000', 'Windows NT', 'Windows XP', 'Windows Server 2003', 'Mac System 7', 'Mac System 7.5', 'Mac System 7.6.1', 'Mac System 8.0', 'Mac System 8.5', 'Mac System 8.6', 'Mac System 9.x', 'Mac OS X 10.0', 'Mac OS X 10.1', 'Mac OS X 10.2', 'Linux', 'BSD/OS', 'FreeBSD', 'NetBSD', 'OpenBSD', 'AIX', 'BeOS', 'HP-UX', 'IRIX', 'Neutrino', 'OpenVMS', 'OS/2', 'OSF/1', 'Solaris', 'SunOS', "M\x{e1}\x{e7}\x{d8}\x{df}", 'Other' ]
            );

    foreach my $field (keys %expected) {
        my @available = $bz->available($field);
        is_deeply(\@available, $expected{$field}, "expected: $field");
        eval { $bz->$field($available[1]); };
        ok(!$@, "set: $field");
    }

    $bz->assigned_to($email);
    $bz->summary($summary);
    $bz->description($description);
    $bug_number = $bz->commit;
    like($bug_number, qr/^\d+$/, "bugid: $bug_number");
}

sub check_file_attach {
    my $bz = WWW::Bugzilla->new(
            use_ssl => 1,
            server     => $server,
            email      => $email,
            password   => $password,
            bug_number => $bug_number
            );

    my $filepath = './GPL';
    my $name = 'Attaching the GPL, since everyone needs a copy of the GPL!';
    my $id = $bz->add_attachment( filepath => $filepath, description => $name);
    like($id, qr/^\d+$/, 'add attachment');
    push (@added_files, { id => $id, name => $name, obsolete => 0 });

    $name .= ' but as a big file';   
 
    $id = $bz->add_attachment( filepath => $filepath, description => $name );
    like($id, qr/^\d+$/, 'add big attachment');
    push (@added_files, { id => $id, name => $name, obsolete => 0 });
}

sub check_attached_files {
    my $bz = WWW::Bugzilla->new(
            use_ssl => 1,
            server     => $server,
            email      => $email,
            password   => $password,
            bug_number => $bug_number
            );

    my @attachments = $bz->list_attachments();

    is_deeply(\@added_files, \@attachments, 'attached files');

    my $file = slurp('./GPL');
    is($file, $bz->get_attachment(id => $attachments[0]->{'id'}), 'get attachment by id');
    is($file, $bz->get_attachment(name => $attachments[0]->{'name'}), 'get attachment by name');
    eval { $bz->get_attachment(); };
    like ($@, qr/You must provide either the 'id' or 'name' of the attachment you wish to retreive/, 'get attachment without arguments');

    $bz->obsolete_attachment(id => $attachments[0]->{'id'});
    @attachments = $bz->list_attachments();
    is ($attachments[0]{'obsolete'}, 1, 'obsolete_attachment');
}

sub slurp {
    my ($file) = @_;
    local $/;
    open (F, '<', $file) || die 'can not open file';
    return <F>;
}

sub verify_host {
    my ($server) = @_;
    use WWW::Mechanize;
    my $mech = WWW::Mechanize->new( autocheck => 0);
    $mech->get("https://$server");
    return if ($mech->res()->is_success && $mech->content() !~ /The site you are currently accessing is temporarily down for its hourly update from CVS/);
    plan skip_all => "Cannot access remote host.  not testing";
    exit;
}

