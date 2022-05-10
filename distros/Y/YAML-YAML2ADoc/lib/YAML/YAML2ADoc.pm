package YAML::YAML2ADoc;

use strict;
use warnings;
use v5.32;
use experimental qw(switch);
our $VERSION = '0.1.0';

use enum qw(TEXT YAML);
use constant {
    SOURCE_MARKER   => "----\n",
    SOURCE_STYLE    => "[source,yaml]\n",
};

sub strip_comment { return $_[0] =~ s/^\h*#\h*//r }

sub run {
    my ($output, $inputs_ref) = @_;
    @ARGV = @$inputs_ref;

    if ($output ne '-') {
        # Change the default handler for print to the file
        open my $out, '>', $output
          or die "Failed to open output $output $!";
        select $out;
    }

    my $state = TEXT;
    while (my $line = <<>>) {
        given ($state) {
            when (TEXT) {
                given ($line) {
                    # empty lines are ignored
                    when (/^$/) { next }
                    # still in TEXT
                    when (/^\h*#/) { print strip_comment($line) }
                    # leaving text
                    default {
                        print "\n", SOURCE_STYLE, SOURCE_MARKER, $line;
                        $state = YAML;
                    }
                }
            }
            when (YAML) {
                given ($line) {
                    # empty lines are ignored
                    when (/^$/) { next }
                    # leaving YAML
                    when (/^\h*#/) {
                        print SOURCE_MARKER, "\n", strip_comment($line);
                        $state = TEXT;
                    }
                    # still in YAML
                    default { print $line }
                }
            }
        }
    }

    # Put the final closing marker in case we finished in YAML
    print SOURCE_MARKER if ($state == YAML);
}

1;


__END__

=encoding utf-8

=head1 NAME

YAML::YAML2ADoc - Something like yaml2rst but for AsciiDoc and in Perl

=head1 SYNOPSIS

  use YAML::YAML2ADoc;

  my $output_file = 'defaults.adoc';
  my @input_files = ('defaults.yaml');
  YAML::YAML2ADoc::run($output_file, \@input_files);

=head1 DESCRIPTION

YAML::YAML2ADoc the module for C<yaml2adoc>. Please refer to the script
file for further information.

=head1 AUTHOR

Bertalan Zoltán Péter E<lt>bertalan.peter@bp99.euE<gt>

=head1 COPYRIGHT

Copyright 2022- Bertalan Zoltán Péter

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
