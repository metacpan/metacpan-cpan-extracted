#! perl

use strict;
use warnings;

# PODNAME: check_web2
# ABSTRACT: allows checking of website according to configured specifications

use v5.10.1;

use Getopt::Long;

use Params::Util qw(_ARRAY);

use WWW::Mechanize::Script::Util qw(:ALL);
use WWW::Mechanize::Script;

our $VERSION = '0.100';
my %opts;
my @options = ( "file=s", "help|h", "usage|?" );

GetOptions( \%opts, @options ) or pod2usage(2);

defined( $opts{help} )
  and $opts{help}
  and pod2usage(
                 {
                   -verbose => 2,
                   -exitval => 0
                 }
               );
defined( $opts{usage} ) and $opts{usage} and pod2usage(1);
opt_required_all( \%opts, qw(file) );

my %cfg = load_config( \%opts );
do
{
    my %cfgvar = ( OPTS_FILE => $opts{file} );
    my $cfgkeys = join( "|", keys %cfgvar );
    $cfg{summary}->{target} =~ s/@($cfgkeys)[@]/$cfgvar{$1}/ge;
    $cfg{report}->{target}  =~ s/@($cfgkeys)[@]/$cfgvar{$1}/ge;
} while (0);

my $wms = WWW::Mechanize::Script->new( \%cfg );

_ARRAY( $cfg{wtscript_extensions} )
  and Config::Any::WTScript->extensions( @{ $cfg{wtscript_extensions} } );
my @script_files = find_scripts( \%cfg, $opts{file} );

my ( $code, @msgs ) = (0);
eval {
    my @script;
    my $scripts = Config::Any->load_files(
                                           {
                                             files           => [@script_files],
                                             use_ext         => 1,
                                             flatten_to_hash => 1,
                                           }
                                         );
    foreach my $filename (@script_files)
    {
        defined( $scripts->{$filename} )
          or next;    # file not found or not parsable ...
                      # merge into default and previous loaded config ...
        push( @script, @{ $scripts->{$filename} } );
    }
    ( $code, @msgs ) = $wms->run_script(@script);
};
$@ and say("UNKNOWN - $@");
exit( $@ ? 255 : $code );

__END__

=pod

=head1 NAME

check_web2 - allows checking of website according to configured specifications

=head1 VERSION

version 0.101

=head1 SYNOPSIS

  $ check_web2 --file domain1/site1.json
  $ check_web2 --file domain2/site1.yml
  # for compatibility
  $ check_web2 --file domain1/site2.wts

=head1 DESCRIPTION

check_web2 is intended to be used to check web-sites according a configuration.
The configuration covers the request configuration (including agent part) and
check configuration to specify check parameters.

See C<WWW::Mechanize::Script> for details about the configuration options.

=head2 HISTORY

This script is created as successor of an check_web script of a nagios setup
based on HTTP::WebCheck. This module isn't longer maintained, so decision
was made to create a new environment simulating the old one basing on
WWW::Mechanize.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-mechanize-script at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Script>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW:Mechanize::Script

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Mechanize-Script>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Mechanize-Script>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Mechanize-Script/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script or by email
to bug-www-mechanize-script@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jens Rehsack <rehsack@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
