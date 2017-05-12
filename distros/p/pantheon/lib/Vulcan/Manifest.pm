package Vulcan::Manifest;

use strict;
use warnings;

use Carp;

our @EXT = qw( in ex );

sub new
{
    local $/ = "\n";

    my ( $class, $file ) = splice @_;
    confess "no manifest" unless defined $file && -e $file;

    $file = readlink $file if -l $file;
    confess "invalid manifest: $file" unless -f $file;

    my %list = map { $_ => {} } @EXT;
    my %file = map { $_ => "$file.$_" } @EXT;
    my %path;

    confess "open: $file" unless open my $fh => $file;

    for my $path ( <$fh> )
    {
        $path =~ s/#.*//; $path =~ s/^\s*//; $path =~ s/\s*$//;
        next if $path =~ /^$/;

        my $list = $path =~ s/^-\s*// ? $list{ex} : $list{in};
        map { $list->{$_} = 1 } @{ $path{$path} ||= [ glob $path ] };
    }

    close $fh;
    map { delete $list{in}{$_} if $list{in}{$_} } keys %{ $list{ex} };
    map { $list{$_} = [ sort keys %{ $list{$_} } ] } keys %list;
    bless { list => \%list, file => \%file }, ref $class || $class;
}

sub dump
{
    local $| = 1;
    my $self = shift;
    my ( $list, $file ) = @$self{ 'list', 'file' };

    for my $ext ( keys %$list )
    {
        confess "cannot write $file: $!" unless open my $fh, '>', $file->{$ext};
        map { print $fh "$_\n" } @{ $list->{$ext} };
        close $fh;
    }
    return $self;
}

sub AUTOLOAD
{
    my $self = shift;
    my $list = our $AUTOLOAD =~ /::(\w+)$/ ? $self->{$1} : {};
    return @$list{@_};
}

sub DESTROY
{
    my $self = shift;
    unlink values %{ $self->{file} };
}

1;
