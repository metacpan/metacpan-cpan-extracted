package WSST::SchemaParserManager;

use strict;
use File::Basename qw(fileparse);
use WSST::SchemaParser;
use WSST::SchemaParser::YAML;

our $VERSION = '0.1.1';

my $SINGLETON_INSTANCE = undef;

sub new {
    my $class = shift;
    
    my $self = {
        parsers => [],
        parser_type_map => {},
    };
    
    return bless($self, $class);
}

sub get_schema_parser {
    my $self = shift;
    my $path = shift;
    my ($fname, $dir, $ext) = fileparse($path, qr/\.[^.]*/);
    return $self->{parser_type_map}->{$ext}
        if $self->{parser_type_map}->{$ext};
    $ext =~ s/^\.//;
    $ext = uc($ext);
    my $cls = "WSST::SchemaParser::$ext";
    eval "require $cls;";
    if ($@) {
        die "parser not found: $path";
    }
    return $cls->new();
}

sub instance {
    my $class = shift;
    
    unless ($SINGLETON_INSTANCE) {
        $class->init();
    }
    
    return $SINGLETON_INSTANCE;
}

sub init {
    my $class = shift;
    
    my $self = $SINGLETON_INSTANCE = $class->new();

    foreach my $key (sort keys %WSST::SchemaParser::) {
        next if $key !~ /^(.+)::$/;
        my $cls = "WSST::SchemaParser::$1";
        my $obj = $cls->new();
        foreach my $type (@{$obj->types}) {
            $self->{parser_type_map}->{$type} = $obj;
        }
    }
}

=head1 NAME

WSST::SchemaParserManager - SchemaParserManager class of WSST

=head1 DESCRIPTION

SchemaParserManager is a "Singleton" class.
This class manages schema parsers.

=head1 METHODS

=head2 new

Constructor.

=head2 get_schema_parser

Returns schema parser object for the specified filepath.

=head2 instance

Returns "Singleton" instance.

=head2 init

Initialize this class.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
