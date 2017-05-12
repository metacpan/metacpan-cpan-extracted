#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
delete $ENV{PAGER}
  if $ENV{PAGER};
$ENV{PERL_HTML_DISPLAY_CLASS}="HTML::Display::Dump";

use_ok('WWW::Mechanize::Shell');
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
isa_ok $s, 'WWW::Mechanize::Shell';

my $have_tableextract = eval {
    require HTML::TableExtract;
    die "Need at least HTML::TableExtract v2, found '$HTML::TableExtract::VERSION'" 
        unless $HTML::TableExtract::VERSION > 2;
    1
};

SKIP: {
    if ($@) {
        skip "Error loading HTML::TableExtract: '$@'", 1;
    } elsif (! $have_tableextract) {
        skip "Unknown error loading HTML::TableExtract, skipping tests", 1;
    } else {
        no warnings qw'redefine once';
        local *WWW::Mechanize::Shell::status = sub {};
        my @output;
        local *WWW::Mechanize::Shell::print_paged = sub {
            shift @_;
            push @output, grep { /\S/ } @_; 
        };
        $s->agent->{base} = 'http://example.com';
        $s->agent->update_html(<<HTML);
            <html>
                <head><base href="http://example.com" /></head>
                <body>
                    <table>
                    <thead><tr><th>ID</th><th>age</th><th>name</th></tr></thead>
                    <tbody>
                        <tr><td>1</td><td>John</td><td>41</td></tr>
                        <tr><td>2</td><td>Paul</td><td>47</td></tr>
                        <tr><td>3</td><td>George</td><td>45</td></tr>
                        <tr><td>4</td><td>Ringo</td><td>47</td></tr>
                    </tbody>
                    </table>
                </body>
            </html>
HTML
        $s->cmd('table name age');
        # TableExtract seems to be confused about the column order
        # hence we just check the number of rows:
        is(scalar @output, 5, "Five lines captured")
            or diag "@output";
    }
};
