package Zucchini::Config;
$Zucchini::Config::VERSION = '0.0.21';
{
  $Zucchini::Config::DIST = 'Zucchini';
}
# ABSTRACT: configuration provider
# vim: ts=8 sts=4 et sw=4 sr sta
use Moo;
use strict; # for kwalitee testing
use MooX::Types::MooseLike::Base qw(:all);

use Carp;
use Config::Any;
use Path::Class;
use Zucchini::Config::Create;

# object attributes
has data => (
    reader  => 'get_data',
    writer  => 'set_data',
    isa     => HashRef,
    is      => 'ro',
);
has options => (
    reader  => 'get_options',
    writer  => 'set_options',
    isa     => HashRef,
    is      => 'ro',
);
has site => (
    reader  => 'get_site',
    writer  => 'set_site',
    isa     => Str,
    is      => 'ro',
);
has config_file => (
    reader  => 'get_config_file',
    writer  => 'set_config_file',
    isa     => Str,
    default => sub {q{}.file($ENV{HOME}, q{.zucchini})},
    is      => 'ro',
);


sub BUILD {
    my ($self, $arg_ref) = @_;

    # if we've been asked to create a new config-file, do just that
    # and exit
    if ($arg_ref->{'create-config'}) {
        my $zucchini_cfg_create = Zucchini::Config::Create->new();

        $zucchini_cfg_create->write_default_config(
            $self->get_config_file
        );

        exit;
    }

    # store the config/arg_ref for future reference
    $self->set_options($arg_ref);

    # we'll allow (clever) people to pass a hashref for the config
    # (mostly useful for testing, but great for abuse too :) )
    if (ref($arg_ref->{config_data})) {
        $self->set_data( $arg_ref->{config_data} );
    }
    # load the config file - this is the preferred, default behaviour
    else {
        $self->_load_config();
    }

    # if we don't have a config file - abort
    if (not defined $self->get_data) {
        warn (
                $self->get_config_file
            . qq{: configuration file not found, use 'create-config' option to create one\n}
        );
        exit;
    }

    # see if we have any CLI options to inject from the config file
    if (defined $self->get_data()->{cli_defaults}) {
        my %merged_cli_options = (
            %{ $self->get_data->{cli_defaults} },
            %{ $self->get_options }
        );
        $self->set_options( \%merged_cli_options );
    }

    # deal with user options
    if (defined $self->get_options->{site}) {
        warn "using user-specified site label\n"
            if ($self->verbose(2));
        $self->set_site( delete $self->get_options->{site} );
    }

    # if we don't have a site specified, try to use a default
    if (not defined $self->get_site()) {
        warn "looking for default site\n"
            if ($self->verbose(2));
        # set the default site (if specified in config file)
        if (defined (my $default = $self->get_data()->{default_site})) {
            warn "using default site label\n"
                if ($self->verbose(2));
            $self->set_site($default);
        }
        else {
            warn "no default site specified\n";
        }
    }

    # make sure out config is sane
    if (not $self->_sane_config) {
        warn "configuration file is not valid\n";
        exit;
    }

    return;
}

sub get_siteconfig {
    my $self = shift;
    my ($site, $siteconfig);

    # get the site
    $site = $self->get_site;

    # make sure it's defined
    if (not defined $site) {
        warn 
                q{'}
            . $site
            . q{' is not defined}
            . qq{\n};
        return;
    }

    # fetch the config block for the specified site
    $siteconfig = $self->get_data()->{site}{$site};

    return $siteconfig;
}

sub ignored_directories {
    my $self = shift;

    my $ignored = $self->get_siteconfig()->{ignore_dirs};

    if (ref($ignored) eq q{ARRAY}) {
        # do nothing - it's already a list-ref
    }
    else {
        $ignored = [ $ignored ];
    }

    return $ignored;
}

sub ignored_files {
    my $self = shift;

    my $ignored = $self->get_siteconfig()->{ignore_files};

    if (ref($ignored) eq q{ARRAY}) {
        # do nothing - it's already a list-ref
    }
    else {
        $ignored = [ $ignored ];
    }

    return $ignored;
}

sub is_dry_run {
    my $self = shift;
    return $self->get_options()->{'dry-run'};
}

sub is_fsync {
    my $self = shift;
    return $self->get_options()->{'fsync'};
}

sub is_fsync_only {
    my $self = shift;
    return $self->get_options()->{'fsync-only'};
}

sub is_rsync {
    my $self = shift;
    return $self->get_options()->{'rsync'};
}

sub is_rsync_only {
    my $self = shift;
    return $self->get_options()->{'rsync-only'};
}

sub templated_files {
    my $self = shift;

    my $templated = $self->get_siteconfig()->{template_files};

    if (ref($templated) eq q{ARRAY}) {
        # do nothing - it's already a list-ref
    }
    else {
        $templated = [ $templated ];
    }

    return $templated;
}

sub always_process {
    my $self = shift;

    my $always_process = $self->get_siteconfig()->{always_process};

    return
        unless defined $always_process;

    if (ref($always_process) eq q{ARRAY}) {
        # do nothing - it's already a list-ref
    }
    else {
        $always_process = [ $always_process ];
    }

    return $always_process;
}

sub verbose {
    my $self    = shift;
    my $level   = shift || 1;
    return (($self->get_options()->{'verbose'}||0) >= $level);
}

sub _load_config {
    my $self    = shift;

    my $config_file = $self->get_config_file;

    # read/load/parse the config file
    my $cfg = Config::Any->load_files(
        {
            files   => [ $config_file ],
            use_ext => 0,
        }
    );

    for (@$cfg) {
        my ($filename, $config) = each %$_;
        # store the config data (to be fetched later with ->get_data()
        $self->set_data($config);
        warn "loaded config from file: $filename" if (0);
    }

    if (not defined $self->get_data()) {
        warn "$config_file: no configuration data loaded\n"
            if ($self->verbose);
        return;
    }

    return;
}

sub _sane_config {
    my $self    = shift;
    my $errors  = 0;

    my $site_config = $self->get_siteconfig();

    if (not defined $site_config) {
        warn "site-specific configuration block is missing\n";
        return;
    }

    # these entries should all exist (as top-level keys) in the site-config
    foreach my $required_key (qw[
        source_dir
        includes_dir
        output_dir
        template_files
        ignore_dirs
        ignore_files
        tags
    ]) {
        if (not exists $site_config->{$required_key}) {
            warn qq{** configuration option missing: $required_key\n};
            $errors++;
        }
    }

    # these directories should exist
    foreach my $required_dir (qw[source_dir includes_dir output_dir]) {
        # dir should exist
        if (
            exists $site_config->{$required_dir}
                and
            not -d $site_config->{$required_dir}
        ) {
            warn qq{** directory missing: $site_config->{$required_dir}\n};
            $errors++;
        }
    }

    return (not $errors);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Zucchini::Config - configuration provider

=head1 VERSION

version 0.0.21

=head1 SYNOPSIS

  # get a new config object
  my $zcfg = Zucchini::Config->new();

  # get a new config object (using an alternative file)
  my $zcfg = Zucchini::Config->new(
    { config_file => $some_other_file }
  );

  # get the parsed config data
  my $stuff = $zcfg->get_data();

=head1 DESCRIPTION

This module uses L<Config::Any> to attempt to load C<.zucchini>
in the user's home directory.

The preferred format is L<Config::General>, but any format supported
by L<Config::Any> can be used.

All examples will assume the user is using the Config::General format.

=head1 CONFIGURATION FILE

The C<.zucchini> configuration file is the governing force
for the behaviour of the various Zucchini components.

The default location for the configuration is set to

  $ENV{HOME}/.zucchini

This is usually overridden by using the C<--config=FILE> option when
using script/zucchini.

The file takes the following general form:

  # the site section to use if none specified
  default_site   'sitelabel1'

  # site section definitions
  <site>
    <sitelabel1>
    ...
    </sitelabel1>

    <sitelabel2>
    ...
    </sitelabel2>
  </site>

The C<< <sitelabelX> >> section contains information to configure
the behaviour for a single website. This section takes the following
general form:

  <sitelabel>
    source_dir          /path/to/tt_templates
    includes_dir        /path/to/tt_includes
    output_dir          /var/www/default_site/html

    template_files      \.html\z

    always_process      impressum.html
    always_process      \.imp\z

    ignore_dirs         CVS
    ignore_dirs         .svn

    ignore_files        \.swp\z
    ignore_files        \.tmp\z

    <tags>
        variable1       value1
        variable2       value2
    </tags>

    <rsync>
        hostname        remote.hosting.site
        path            /home/username/default_site/www
    </rsync>

    <ftp>
        hostname        remote.ftp.site
        username        joe.bloggs
        password        SecretWord
        passive         1
        path            /htdocs
    </ftp>

    <tt_options>
        PRE_PROCESS     my_header
        POST_PROCESS    my_footer
        # ... etc
  </sitelabel>

=head2 CONFIGURATION FILE ELEMENTS

These are the blocks and variables that make up
a C<.zucchini> configuration file:

=over

=item <site>

The E<lt>siteE<gt> tag is a top-level element to hold
the various configuration blocks for each site.

=item <"sitelabel">

Each site specific configuration block is contained in a
C<< <sitelabel>...</sitelabel> >> block. "sitelabel" should be
replaced with a meaningful label. For example, a configuration block
for the site "www.herlpacker.co.uk" might look like this:

  <site>
    <herlpacker>
      # site configuration here
    </herlpacker>
  </site>

To configure more than one site, simply add a new "sitelabel" block for
each site:

  <site>
    <herlpacker>
      # site configuration here
    </herlpacker>

    <chizography>
      # site configuration here
    </chizography>
  </site>

=item source_dir

Found in a "sitelabel" block, this is the path to the root directory
of the templated version of the site.

This is the directory that contains the files that will be processed
and copied to the I<output_dir>.

   # e.g.
   source_dir /home/zucchini/sites/MYSITE/tt_templates

=item includes_dir

Found in a "sitelabel" block, this is the path to the directory containing
blocks of Template Toolkit magic that are INCLUDEd or PROCESSed by the files
in I<source_dir>.

Examples of files you might expect to find as includes are header.tt and
footer.tt - the common parts before and after the varying body content.

   # e.g.
   source_dir /home/zucchini/sites/MYSITE/tt_includes

=item output_dir

Found in a "sitelabel" block, this is the path to the directory where
processed templates will be written to.

Also, files that are not ignored as a result of I<ignore_dirs> or
I<ignore_files> will be copied to the appropriate location under this
specified directory.

Quite often this will match the DocumentRoot location for a locally configured
VirtualHost in apache2.

    # e.g.
    output_dir /var/www/mysite

=item website

Found in a "sitelabel" block, this is the URL for the live site. It's
primarily used by the L<Zucchini::Fsync> functionality to retrieve the digest.md5
file it uses for local-remote file comparison.

    # e.g.
    website http://www.mysite.com/

=item template_files

Found in a "sitelabel" block, this option specifies which files should be
treated as templates.

Most of the time you will only need one entry, to specify files with the
".html" extension.

    # .html files should be treated as templates
    template_files      '\.html\z'

To indicate that other filetypes should also be treated as templates, add a
new row for each filetype you require.

    # .html files should be treated as templates
    template_files      '\.html\z'
    # .txt files also require template processing
    template_files      '\.txt\z'

The value used should be a perl regexp that can be applied to a filename.
If in doubt, copy an existing rule and modify the '.html'.

=item always_process

Found in a "sitelabel" block, this option specifies which files should always
be processed regardless of their modification time.

    # always process *.imp files
    always_process      '\.imp\z'

You can specify as many items as you require. B<Each value is interpolated into
a regular expression>.

This means that

    # this probably doesn't do what you think ...
    always_process      dex.html

will cause B<all> of your C<index.html> files to be processed. Instead use
something like:

    # you need to use start- and end- of string anchors
    always_process      \Adex.html\z

C<\A> and C<\z> are similar to C<^> amd C<$>. See L<perlre/Assertions> for
more details.

=item ignore_dirs

Found in a "sitelabel" block, this option is used to specify directories which
should not be processed during site templating.

This is mostly useful if your templates are managed with a version control
system (e.g. CVS, or subversion) and you don't want the repository management
directories to be copied as part of the live site source.

One I<ignore_dirs> statement is required for each directory to be ignored.

    # ignore CVS and subversion directories
    ignore_dirs 'CVS'
    ignore_dirs '.svn'

=item ignore_files

Found in a "sitelabel" block, this option is used to specify files which
should not be processed during site templating.

This is useful to prevent, for example, editor swap files from being copied
into the I<output_dir> as part of the processed site source.

One I<ignore_files> statement is required for each file to be ignored.

    # ignore vim swap files
    ignore_files '\.swp\z'

The value used should be a perl regexp that can be applied to a filename.
If in doubt, copy an existing rule and modify the '.html'.

=item lint_check

Found in a "sitelabel" block, this option enables HTML error checking.
While not as thorough as a full W3C validator, this option should alert you to
commons errors.

    # check for HTML errors
    lint_check 1

=item <tags>

This block, found in a "sitelabel" block, is used to set variables that
will be available in the template as a C<< [% ... %] >> style variable.

For example, defining:

    <tags>
        author     Joe Bloggs
        copyright  &copy; 2008 Joe Bloggs. All rights reserved.
    </tags>

will allow you to do the following in your templates (or footer.tt):

    <p>Site Designed by [%author%]</p>
    <p>[%copyright%]</p>

=item <rsync>

This block, found in a "sitelabel" block, defines the conection details used
when using the I<rsync> options to transfer the generated site to the remote
server.

    <rsync>
        # options go here
    </rsync>

=item <ftp>

This block, found in a "sitelabel" block, defines the conection details used
when using the I<fsync> options to transfer the generated site to the remote
server.

    <ftp>
        # options go here
    </ftp>

=item hostname

Found in an "rsync" or "ftp" block, this is the destination server for the
generated website.

    # e.g.
    <rsync>
        hostname    some.remote.server
        # ...
    </rsync>

In an "rsync" block you may prepend the value with the username:

    # e.g.
    <rsync>
        hostname    someuser@some.remote.server
        # ...
    </rsync>

=item path

Found in an "rsync" or "ftp" block, this is the path on the remote server
where the generated site will be copied to.

B<Note>: You don't usually require a trailing '-' for the "path" value inside
an "rsync" block.

    # e.g.
    <rsync>
        # ...
        path    /home/someuser/MYSITE/www
    </rsync>

=item username

Found in an "ftp" block, this is the username used during the FTP log-in phase
of the remote transfer.

    # e.g.
    <ftp>
        # ...
        username    joebloggs 
    </ftp>

=item password

Found in an "ftp" block, this is the password used during the FTP log-in phase
of the remote transfer.

    # e.g.
    <ftp>
        # ...
        password    SekritWurd 
    </ftp>

B<Note>: This password is stored unencrypted. Please be strict with the file
permissions of your I<.zucchini> file, preferably making the file only
readable to yourself:

    # stop people peeking at our FTP credentials
    chmod 0600 ~/.zucchini

=item <ttoptions>

This block allows you to set or override configuration options for the
L<Template> object that's created to process the templates.

No validation is performed by L<Zucchini>. You can explore the available
options by reading L<Template::Manual::Config>'s manual.

    # e.g.
    <tt_options>
        PRE_PROCESS     my_header
        POST_PROCESS    my_footer
        EVAL_PERL       1
    </tt_options>

=back

=head2 SETTING DEFAULT COMMAND-LINE VALUES

Sometimes it can be tedious adding the same command-line switches to calls to
zucchini.

You can preset commonly used options in the I<cli_defaults> section of your
I<.zucchini> file:

  <cli_defaults>
    verbose         1
    showdest        1
    showpath        1
  </cli_defaults>

Any options specified on the command-line will take precedence over the
defaults in the I<.zucchini> file.

  # we don't really want to see the destination
  zucchini --no-showdest

=head1 SEE ALSO

L<Config::Any>,
L<Config::General>,
L<perlre/Assertions>,
L<Template::Manual::Config>,
L<Zucchini>,
L<Zucchini::Fsync>,
L<Zucchini::Rsync>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
