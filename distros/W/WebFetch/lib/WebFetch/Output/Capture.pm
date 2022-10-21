# WebFetch::Output::Capture
# ABSTRACT: capture WebFetch data without generating an output file
# This is mainly expected to be used for testing. But it can collect data retreived by any WebFetch front-end.
#
# Copyright (c) 2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package WebFetch::Output::Capture;
$WebFetch::Output::Capture::VERSION = '0.15.4';
use base "WebFetch";
use Data::Dumper;

# register capabilities with WebFetch
__PACKAGE__->module_register("output:capture");
my @data_records;
my $grep_func;

# set grep function to use when selecting news items
sub set_grep_func
{
    my $param_func = shift;
    if ( defined $grep_func and ref $grep_func eq "CODE" ) {
        $grep_func = $param_func;
    } else {
        __PACKAGE__::throw_param_error("set_grep_func received param which is not a CODE ref");
    }
    return;
}

# "capture" format handler
# capture function stashes all the received data records from SiteNews for inspection
sub fmt_handler_capture
{
    my ($self) = @_;

    WebFetch::debug "fetch: " . Dumper( $self->{data} );
    $self->no_savables_ok();    # rather than let WebFetch save the data, we'll take it here
    if ( exists $self->{data}{records} ) {
        if ( defined $grep_func and ref $grep_func eq "CODE" ) {
            push @data_records, grep { $grep_func->($_) } @{ $self->{data}{records} };
        } else {
            push @data_records, @{ $self->{data}{records} };
        }
    }
    return 1;
}

# return the file list
sub data_records
{
    my @ret_records = @data_records;    # save data for return
    @data_records = ();                 # clear saved records list because tests use this more than once
    return @ret_records;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebFetch::Output::Capture - capture WebFetch data without generating an output file

=head1 VERSION

version 0.15.4

=head1 SYNOPSIS

In perl scripts:

    use WebFetch::Input::RSS; # or another WebFetch input - this example shows RSS
    use WebFetch::Output::Capture;
    # ... fill in $params hashref
    my %Options = (
        dir => $params->{temp_dir},
        source_format => "rss",
        source => "file://".$input_dir."/".$params->{in},
        dest_format => "capture",
        dest => "", # unused
    );
    WebFetch::Input::RSS->run(\%Options);
    my @data_records = WebFetch::Output::Capture::data_records();

=head1 DESCRIPTION

This is a WebFetch output module which captures WebFetch output as a data structure
rather than formatting it and saving it in a file.
The data can be collected from any WebFetch input module.

This module is used for testing WebFetch.

=head1 FUNCTIONS

=over 4

=item $obj->set_grep_func( $func_ref )

This function receives a CODE reference and saves it for use in a grep of the WebFetch data records.
It is optional. If not set, the data_records() method will return all the data retreived by WebFetch.

=back

=over 4

=item $obj->fmt_handler_capture()

This function is called by WebFetch when the capture destination is selected.
It saves the output in a structure. There is no output to any file when using this format.

=back

=over 4

=item WebFetch::Output::Capture::data_records()

returns a list of the data records retrived by WebFetch.
The structure of each data record varies depending what input format was selected when WebFetch was run.
Usually another output module should be used to output this data to a file in a specific data format.
When using the capture method, you receive the raw data records.

=back

=head1 SEE ALSO

L<WebFetch>
L<https://github.com/ikluft/WebFetch>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/WebFetch/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/WebFetch/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2022 by Ian Kluft.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
