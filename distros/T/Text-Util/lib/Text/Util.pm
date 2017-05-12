package Text::Util;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";
use vars qw/@ISA @EXPORT @EXPORT_OK/;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw/clean_text merge_space/;

sub clean_text {
    my $str = shift;
    return unless $str;
    return chompf( merge_space($str) );
}

sub merge_space {
    my $str = shift;
    return '' unless $str;
   
    $str =~ s/\t+/ /g;
    $str =~ s/\r\n//g;
    $str =~ s/\s+/ /g;
    return $str;
}

sub chompf {
    my $str = shift;
    return '' unless $str;
    $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;
    return $str;
}


1;
__END__

=encoding utf-8

=head1 NAME

Text::Util - It's new tools for clean text

=head1 SYNOPSIS

    use Text::Util;

=head1 DESCRIPTION

Text::Util is a util for clean text data, forexample merge sapce etc 

Text::Util::merge_space merge more space to one
Text::Util::clean_text include merge_space step and remove all start and end space of string  

=head1 LICENSE

Copyright (C) mccheung.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mccheung <mc dot cheung at aol dot com>

=cut

