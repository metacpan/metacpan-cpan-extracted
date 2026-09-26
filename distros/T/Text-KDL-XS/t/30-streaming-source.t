use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Text::KDL::XS qw(parse_kdl);

my $kdl = "a 1\nb 2\nc 3\n";

sub names { [ map { $_->name } @{ $_[0]->nodes } ] }

sub file_with {
    my ($bytes) = @_;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $bytes;
    close $fh;
    return $path;
}

# Coderef source - feed in tiny chunks to exercise the trampoline.
{
    my @chunks = split //, $kdl;
    my $reader = sub {
        my ($want) = @_;
        return '' unless @chunks;
        return shift @chunks;
    };
    my $doc = parse_kdl($reader);
    is scalar(@{ $doc->nodes }), 3, 'coderef source: 3 nodes';
    is $doc->nodes->[1]->name, 'b', 'coderef source: name';
    is $doc->nodes->[1]->args->[0]->as_perl, 2, 'coderef source: arg';
}

# Filehandle source.
{
    my $path = file_with($kdl);
    open my $in, '<', $path or die "open: $!";
    my $doc = parse_kdl($in);
    is scalar(@{ $doc->nodes }), 3, 'fh source: 3 nodes';
    is $doc->nodes->[2]->name, 'c', 'fh source: name';
}

# Handles are read with PerlIO's read, so layers, buffered data and handles
# without a file descriptor work.
{
    my $path = file_with("caf\xc3\xa9 1\n\xe2\x9c\x93 2\n");
    open my $decoded, '<:encoding(UTF-8)', $path or die "open: $!";
    is_deeply names(parse_kdl($decoded)), [ "caf\x{e9}", "\x{2713}" ], ':encoding(UTF-8) handle';

    open my $utf8, '<:utf8', $path or die "open: $!";
    is_deeply names(parse_kdl($utf8)), [ "caf\x{e9}", "\x{2713}" ], ':utf8 handle';

    open my $raw, '<:raw', $path or die "open: $!";
    is_deeply names(parse_kdl($raw)), [ "caf\x{e9}", "\x{2713}" ], ':raw handle';
}
{
    my $path = file_with($kdl);
    open my $in, '<', $path or die "open: $!";
    my $first_line = <$in>;
    is_deeply names(parse_kdl($in)), [qw(b c)], 'reading continues after <$fh>';
}
{
    open my $in, '<', \$kdl or die "open: $!";
    is_deeply names(parse_kdl($in)), [qw(a b c)], 'in-memory handle';
}
{
    my $path = file_with($kdl);
    open my $in, '<', $path or die "open: $!";
    is_deeply names(parse_kdl(*$in{IO})), [qw(a b c)], '*FH{IO} object';
    is_deeply names(parse_kdl(IO::File->new($path, 'r'))), [qw(a b c)], 'IO::File object';

    no warnings 'once';
    open KDL_BAREWORD, '<', $path or die "open: $!";
    is_deeply names(parse_kdl(*KDL_BAREWORD)), [qw(a b c)], 'bare glob';
    close KDL_BAREWORD;
}
{
    package Local::ReadOnly;
    sub new  { my ($class, $text) = @_; return bless { text => $text }, $class }
    sub read {
        my $self = shift;
        $_[0] = substr($self->{text}, 0, $_[1], '');
        return length $_[0];
    }
    package main;
    is_deeply names(parse_kdl(Local::ReadOnly->new($kdl))), [qw(a b c)], 'object with only a read method';
}
{
    my $path = file_with($kdl);
    open my $in, '<', $path or die "open: $!";
    close $in;
    my $lived = eval { parse_kdl($in); 1 };
    ok !$lived && $@ =~ /filehandle is not open/, 'a closed filehandle dies';
}

# Code reference chunks.
{
    my $big  = join '', map { "n$_ 1\n" } 1 .. 2000;
    my $sent = 0;
    my $doc  = parse_kdl(sub { $sent++ ? '' : $big });
    is scalar @{ $doc->nodes }, 2000, 'a chunk longer than requested is used in full';
}
{
    my $sent = 0;
    my $doc  = parse_kdl(sub { $sent++ ? undef : "n \"caf\x{e9} \x{2713}\"\n" });
    is $doc->nodes->[0]->args->[0]->value, "caf\x{e9} \x{2713}", 'a character string chunk is used as UTF-8';
}
{
    my $calls  = 0;
    my $parser = Text::KDL::XS::Parser->new(sub { $calls++; '' });
    is $calls, 1, 'the source is read once while the parser is created';
    is $parser->next_event, undef, 'empty input ends at once';
    is $parser->next_event, undef, 'and keeps returning undef';
    is $calls, 1, 'the source is not called again after it signalled the end';
}

done_testing;
