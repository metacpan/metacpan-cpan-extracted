#!/usr/bin/perl

use Text::MarkPerl;

sub slurp {
    my ($filename) = @_;
    open my $file, '<', $filename or die "Couldn't open $filename: $!";
    local $/ = undef;
    return <$file>;
}    


die "Y U NO INPUT FILE" if !$ARGV[0];
my $file_name  = $ARGV[0];
my $file_contents = slurp($file_name);

Text::MarkPerl::parse($file_contents);










