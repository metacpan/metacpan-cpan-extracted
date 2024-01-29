use v5.36;

use FindBin;
use JSON::PP qw/encode_json decode_json/;
use Data::Section::Simple qw/get_data_section/;

# read files
opendir my $dh, "$FindBin::Bin/spec/specs" or die "opendir failed: $!";
# my @files = grep /\.json/ && !/^~/, readdir $dh;
my @files = grep /\.json/, readdir $dh;
closedir $dh;

my $i = 1;
for my $file (sort @files) {
    my $spec = decode_json(do {
        open my $fh, '<', "$FindBin::Bin/spec/specs/$file"
            or die "open failed $file: $!";
        local $/;
        <$fh>;
    });

    my $code_base = get_data_section($file eq '~lambdas.json' ? 'lambda.t' : 'default.t');

    my $t = "$FindBin::Bin/../t/specs/$file" =~ s!(?<=/)~(?=[^/]+\.json)!!r =~ s/\.json$/.t/r;
    open my $fh, '>', $t
        or die "open failed $t: $!";
    print $fh $code_base;
    say $fh '__DATA__';
    for my $test (@{ $spec->{tests} }) {
        my %test = %$test;
        if (
            (ref $test{data} eq 'HASH' && exists $test{data}{lambda}) &&
            (ref $test{data}{lambda} eq 'HASH' && exists $test{data}{lambda}{perl})
        ) {
            if ($test{data}{lambda}{perl} eq 'sub { no strict; $calls += 1 }') {
                $test{data}{lambda}{perl} = 'do { my $calls = 0; sub { ++$calls } }'
            }
        }
        my ($name, $desc) = delete @test{qw/name desc/};
        print $fh <<__EOD__;
=== $name: $desc
--- case
@{[ JSON::PP->new->canonical->pretty->encode(\%test) ]}
__EOD__
    }
    close $fh or die "close failed $t: $!";

    $i++;
}
__DATA__
@@ default.t
use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;
use JSON::PP qw/decode_json/;

use Text::MustacheTemplate;
use Text::MustacheTemplate::HTML;

# emulate CGI.escapeHTML https://docs.ruby-lang.org/ja/latest/method/CGI/s/escapeHTML.html
local $Text::MustacheTemplate::HTML::ESCAPE = do {
    my %m = (
        q!'! => '&#39;',
        q!&! => '&amp;',
        q!"! => '&quot;',
        q!<! => '&lt;',
        q!>! => '&gt;',
    );
    sub {
        my $text = shift;
        $text =~ s/(['&"<>])/$m{$1}/mego;
        return $text;
    };
};

subtest parse => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $template = Text::MustacheTemplate->parse($case->{template});
        my $result = $template->($case->{data});
        is $result, $case->{expected}, $block->name;
    }
};

subtest render => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $result = Text::MustacheTemplate->render($case->{template}, $case->{data});
        is $result, $case->{expected}, $block->name;
    }
};

done_testing;

@@ lambda.t
use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;
use JSON::PP qw/decode_json/;

use Text::MustacheTemplate;
use Text::MustacheTemplate::HTML;

local $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING = 1;

# emulate CGI.escapeHTML https://docs.ruby-lang.org/ja/latest/method/CGI/s/escapeHTML.html
local $Text::MustacheTemplate::HTML::ESCAPE = do {
    my %m = (
        q!'! => '&#39;',
        q!&! => '&amp;',
        q!"! => '&quot;',
        q!<! => '&lt;',
        q!>! => '&gt;',
    );
    sub {
        my $text = shift;
        $text =~ s/(['&"<>])/$m{$1}/mego;
        return $text;
    };
};

subtest parse => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $template = Text::MustacheTemplate->parse($case->{template});
        my $result = $template->(expand_lambda($case->{data}));
        is $result, $case->{expected}, $block->name;
    }
};

subtest render => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $result = Text::MustacheTemplate->render($case->{template}, expand_lambda($case->{data}));
        is $result, $case->{expected}, $block->name;
    }
};

sub expand_lambda {
    my $data = shift;
    if (ref $data eq 'HASH') {
        if (exists $data->{__tag__} && $data->{__tag__} eq 'code') {
            return eval $data->{perl};
        } else {
            my %h;
            for my $key (keys %$data) {
                $h{$key} = expand_lambda($data->{$key});
            }
            return \%h;
        }
    } elsif (ref $data eq 'ARRAY') {
        return [map { expand_lambda($_) } @$data];
    } else {
        return $data;
    }
}

done_testing;
