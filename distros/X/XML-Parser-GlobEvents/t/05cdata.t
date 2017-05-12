#!/usr/bin/perl -w

use Test::More tests => 1;

use XML::Parser::GlobEvents qw(parse);

(my $file = __FILE__) =~ s/[\w.~]+$/cdata.xml/;

my $data;

parse($file,
    '/*' => {
    	End => sub {
            my($node) = @_;
            $data = $node;
        },
        Whitespace => 'trim',
    }
  );

is($data->{-text}, "This\nis\na\ntest", 'CDATA is treated as text');