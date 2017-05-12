
use Test::More tests => 4;

use strict;
use XML::Parser::GlobEvents qw(parse);

(my $file = __FILE__) =~ s/[\w.~]+$/basic.xml/;

my $expected = { -name => 'foo', -path => '/foo', -attr => {}, -text => 'test' };

{
	my %data;
    parse(\'<foo>test</foo>',
        '/*' =>  sub {
            my($node) = @_;
            %data = map { $_ => $node->{$_} } qw(-name -path -attr -text);
        }
    );
    is_deeply(\%data, $expected, 'parse from string');
}

{
    my %data;
    parse($file,
        '/*' =>  sub {
            my($node) = @_;
            %data = map { $_ => $node->{$_} } qw(-name -path -attr -text);
        }
    );
    is_deeply(\%data, $expected, 'parse from file');
}

{
	open my $fh, '<', $file or die "Can't open file '$file': $!";
	my %data;
    parse($fh,
        '/*' =>  sub {
            my($node) = @_;
            %data = map { $_ => $node->{$_} } qw(-name -path -attr -text);
        }
    );
    is_deeply(\%data, $expected, 'parse from filehandle');
}

{
    my %data;
    parse(\*DATA,
        '/*' =>  sub {
            my($node) = @_;
            %data = map { $_ => $node->{$_} } qw(-name -path -attr -text);
        }
    );
    is_deeply(\%data, $expected, 'parse from DATA');
}

__DATA__
<foo>test</foo>
