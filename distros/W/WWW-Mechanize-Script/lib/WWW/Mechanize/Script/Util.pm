package WWW::Mechanize::Script::Util;

use strict;
use warnings;

use base qw/Exporter/;
use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;

# ABSTRACT: some basic utility functions for scripts

use Config::Any;
use Cwd qw(realpath);
use File::Basename qw(fileparse);
use File::ConfigDir qw(config_dirs);
use File::Find::Rule;
use Hash::Merge ();
use List::MoreUtils qw(uniq);
use Params::Util qw(_HASH _ARRAY _STRING);
use Pod::Usage;

$VERSION = '0.100';

@EXPORT      = ();
@EXPORT_OK   = qw(opt_required_all opt_required_one opt_exclusive load_config find_scripts);
%EXPORT_TAGS = ( ALL => \@EXPORT_OK );


sub opt_required_one
{
    my ( $opt_hash, @opt_names ) = @_;

    my @have = grep { defined( $opt_hash->{$_} ) } @opt_names;
    @have and return;

    pod2usage( -exitval => 1,
               -message => "Missing at least one of " . join( ", ", map { "--$_" } @opt_names ) );
}


sub opt_required_all
{
    my ( $opt_hash, @opt_names ) = @_;

    my @missing = grep { !defined( $opt_hash->{$_} ) } @opt_names;
    @missing or return;

    pod2usage(
               -exitval => 1,
               -message => "Missing "
                 . join( ", ", map { "--$_" } @missing )
                 . " argument"
                 . ( @missing > 1 ? "s" : "" )
             );
}


sub opt_exclusive
{
    my ( $opt_hash, @opt_names ) = @_;

    my @missing = grep { defined( $opt_hash->{$_} ) } @opt_names;
    @missing < 2 and return;

    @missing = map { "--" . $_ } @missing;
    my $final_m = pop @missing;
    pod2usage(
               -exitval => 1,
               -message => "Options "
                 . join( " and ", join( ", ", @missing ), $final_m )
                 . " are mutual exclusive"
             );
}


sub load_config
{
    my %opts;
    _HASH( $_[0] ) and %opts = %{ $_[0] };
    my %cfg = (
        defaults => {
                      terse       => 'failed_only',
                      save_output => 'yes',           # report ...
                      show_html   => 'yes',           # report ...
                    },
        request => {
            agent => {
                agent => (
                          ( defined( $opts{file} ) and $opts{file} =~ m/(?:_w$|^wap\/)/ )
                          ? "Nokia6210/1.0 (03.01) UP.Link/5.0.0.4 VZDE-check_wap $VERSION"
                          : "Mozilla/5.0 (Windows; U; WinNT4.0; en-US; rv: VZDE-check_web $VERSION)"
                         ),
                accept_cookies => 'yes',    # check LWP::UA param
                show_cookie    => 'yes',    # check LWP::UA param
                show_headers   => 'yes',    # check LWP::UA param
                send_cookie    => 'yes',    # check LWP::UA param
                     },
                   },
              );

    # find config file
    my @cfg_dirs = uniq map { realpath($_) } config_dirs();
    my $progname = fileparse( $0, qr/\.[^.]*$/ );
    my @cfg_pattern = map { ( "check_web." . $_, $progname . "." . $_ ) } Config::Any->extensions();
    my @cfg_files = File::Find::Rule->file()->name(@cfg_pattern)->maxdepth(1)->in(@cfg_dirs);
    if (@cfg_files)
    {
        my $merger = Hash::Merge->new('LEFT_PRECEDENT');
        # read config file(s)
        my $all_cfg = Config::Any->load_files(
                                               {
                                                 files           => [@cfg_files],
                                                 use_ext         => 1,
                                                 flatten_to_hash => 1,
                                               }
                                             );

        foreach my $filename (@cfg_files)
        {
            defined( $all_cfg->{$filename} )
              or next;    # file not found or not parsable ...
                          # merge into default and previous loaded config ...
            %cfg = %{ $merger->merge( \%cfg, $all_cfg->{$filename} ) };
        }
    }

    return %cfg;
}


sub find_scripts
{
    my ( $cfg, @patterns ) = @_;
    my @script_filenames;

    my @cfg_dirs =
      defined( $cfg->{script_dirs} )
      ? (
          _ARRAY( $cfg->{script_dirs} )
          ? @{ $cfg->{script_dirs} }
          : (
              _STRING( $cfg->{script_dirs} )
              ? ( $cfg->{script_dirs} )
              : ( config_dirs("check_web") )
            )
        )
      : ( config_dirs("check_web") );
    @cfg_dirs =
      grep { -d $_ } map { File::Spec->file_name_is_absolute($_) ? $_ : config_dirs($_) } @cfg_dirs;
    # grep { -d $_ }
    # map { File::Spec->catdir( $_, $directories ) }
    # config_dirs( $cfg{script_dir} // "check_web" );    # XXX basename $0
    foreach my $pattern (@patterns)
    {
        if ( -f $pattern and -r $pattern )
        {
            push( @script_filenames, $pattern );
        }
        else
        {
            my ( $volume, $directories, $fn ) = File::Spec->splitpath($pattern);
            my @script_pattern =
              $fn =~ m/\.[^.]*$/ ? ($fn) : map { $fn . "." . $_ } Config::Any->extensions();
            my @script_dirs = grep { -d $_ }
              map { File::Spec->catdir( $_, $directories ) } @cfg_dirs;
            push( @script_filenames,
                  File::Find::Rule->file()->name(@script_pattern)->maxdepth(1)->in(@script_dirs) );
        }
    }
    return @script_filenames;
}

1;

__END__

=pod

=head1 NAME

WWW::Mechanize::Script::Util - some basic utility functions for scripts

=head1 VERSION

version 0.101

=head1 EXPORTS

This module doesn't export anything by default, but any of the following on request:

=over 4

=item *

opt_required_all

=item *

opt_required_one

=item *

opt_exclusive

=item *

load_config

=item *

find_scripts

=back

=head1 FUNCTIONS

=head2 opt_required_one(\%opt_hash, @opt_names)

Fails by invoking pod2usage when none of the options in @opt_names are
given in %opt_hash.

=head2 opt_required_all(\%opt_hash, @opt_names)

Fails by invoking pod2usage when any of the options in @opt_names are
missing in %opt_hash.

=head2 opt_exclusive(\%opt_hash, @opt_names)

Fails by invoking pod2usage when more than one of the options in @opt_names
are given in %opt_hash.

=head2 load_config(;\%opt_hash)

Tries to load the primary configuration. It looks in any directory returned
by L<File::ConfigDir/config_dirs> for files named either I<check_web> or
like the basename of the invoking script (C<$0>) with any extension
supported by L<Config::Any>. The found configuration files are merged into
a single configuration hash using L<Hash::Merge> with the I<LEFT_PRECEDENT>
ruleset.

When an option hash is given, the default agent is computed based on
the value of I<$opt_hash{file}>.

=head2 find_scripts(\%cfg,@patterns)

Finds scripts based on configuration and given patterns.

=over 4

=item *

When C<%cfg> contains an array with full qualified path names below the
I<script_dirs>, those directories are scanned. When the directories are
relative, the are concatenated using L<File::ConfigDir/config_dirs> (each
entry in the I<script_dirs> is evaluated separately).

When C<%cfg> contains a string below the key I<script_dirs>, the
I<config_dirs($cfg{script_dirs})> is used to find the scripts.

In any other case, I<config_dirs("check_web")> is used.

=item *

The C<@patterns> list must contain one or more file names or expandable
shell patterns with or without directory parts and/or extensions.

Valid entries are for example:

=over 8

=item -

qw(check_host_app_one)

=item -

qw(check_host/app_one)

=item -

qw(check_host_app_one.json)

=item -

qw(check_host/app_one.yml)

=item -

qw(check_splunk_[1-5])

=item -

qw(splunk/test*)

=back

=back

Returns the list of found script file names.

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
