package WebService::TVDB::Util;
{
  $WebService::TVDB::Util::VERSION = '1.133200';
}

use strict;
use warnings;

# ABSTRACT: Utility functions

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(pipes_to_array get_api_key_from_file);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub pipes_to_array {
    my $string = shift;
    return unless $string;

    my @array;
    for ( split( /\|/, $string ) ) {
        next unless $_;
        push @array, $_;
    }

    return \@array;
}

sub get_api_key_from_file {
    my ($file) = @_;

    return do {
        local $/ = undef;
        open my $fh, "<", $file
          or die "could not open $file: $!";
        my $doc = <$fh>;

        # ensure there are no carriage returns
        $doc =~ s/(\r|\n)//g;

        return $doc;
    };
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TVDB::Util - Utility functions

=head1 VERSION

version 1.133200

=head1 SYNOPSIS

  use WebService::TVDB::Util qw(pipes_to_array);

=head1 METHODS

=head2 pipes_to_array($string)

Takes a string such as "|Comedy|Action|" and returns an array without the pipes.

=head2 get_api_key_from_file($file)

Slurps the api_key from file

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
