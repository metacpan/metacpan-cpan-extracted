package Test::Smoke::App::ConfigSmoke;
use warnings;
use strict;

our $VERSION = '0.103';

use base 'Test::Smoke::App::Base';

use Cwd;
use File::Basename;
use File::Spec;
use File::Path;
use System::Info;
use Test::Smoke::App::Options;

use Test::Smoke::App::ConfigSmoke::Files;
use Test::Smoke::App::ConfigSmoke::MakeOptions;
use Test::Smoke::App::ConfigSmoke::Reporter;
use Test::Smoke::App::ConfigSmoke::Scheduler;
use Test::Smoke::App::ConfigSmoke::SmokeDB;
use Test::Smoke::App::ConfigSmoke::Mail;
use Test::Smoke::App::ConfigSmoke::SmokeEnv;
use Test::Smoke::App::ConfigSmoke::Smokedir;
use Test::Smoke::App::ConfigSmoke::Sync;

use Test::Smoke::App::ConfigSmoke::WriteSmokeScript;

=head1 NAME

Test::Smoke::App::ConfigSmoke - App for configuring L<Test::Smoke>.

=head1 DESCRIPTION

This app will replace the old C<configsmoke.pl>.

=cut

use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = \&_sort_configkeys;
local $Data::Dumper::Trailingcomma = 1; # perl-5.24.0 or DD-1.60

=head2 Test::Smoke::App::ConfigSmoke->new()

Adding attributes: C<usedft>, C<current_values>, C<sysinfo>, C<prefix>, C<configfile>.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_usedft} = $self->option('des');
    $self->{_current_values} = { };
    $self->{_sysinfo} = System::Info->new();

    my $prefix = $self->option('configfile') // 'smokecurrent';
    $self->_set_prefix($prefix);

    # undo the 'v' => 'verbose' mangling
    $self->from_configfile->{v} = delete($self->from_configfile->{verbose})
        if exists($self->from_configfile->{verbose});

    return $self;
}

sub _set_prefix {
    my $self = shift;
    my ($maybe_prefix) = @_;

    (my $prefix = basename($maybe_prefix)) =~ s{[_.]config$}{};

    my $configfile = $prefix eq $maybe_prefix
        ? "${prefix}_config"
        : $maybe_prefix;

    $self->configfile_error(undef);
    $self->{_prefix} = $prefix;
    $self->{_configfile} = $configfile;

    # try to get an absolute version of $0
    $self->{_dollar_0} = Cwd::abs_path($0);

    return $self;
}

=head2 run

Configure the Test::Smoke suite and write the configfile.

=cut

sub run {
    my $self = shift;

    $self->say_hi();

    $self->config_smokedir();
    if ($^O eq 'MSWin32') {
        require Test::Smoke::App::ConfigSmoke::MSWin32;
        Test::Smoke::App::ConfigSmoke::MSWin32->import('config_mswin32');
        $self->config_mswin32();
    }
    $self->config_sync();
    $self->config_make_options();
    $self->config_smoke_db();
    $self->config_mail();
    $self->config_files();
    $self->config_reporter_options();
    $self->config_scheduler();
    $self->config_smoke_env();

    $self->current_values->{perl_version} = $self->default_for_option(
        Test::Smoke::App::Options->perl_version
    ) // 'blead';
    $self->current_values->{is56x} = 0;

    $self->write_config();

    my ($cronbin, $crontime) = (
        $self->current_values->{cronbin},
        $self->current_values->{crontime}
    );
    $self->write_smoke_script($cronbin, $crontime);

    $self->say_bye();
}

=head2 say_hi

Show introductory text.

=cut

sub say_hi {
    my $self = shift;

    printf <<"EOHI", __PACKAGE__, $VERSION, $self->prefix;


-->%s v%s with prefix '%s'<--

Welcome to the Perl core smoke suite.

This is a new version of the configure script, SOME THINGS ARE DIFFERENT!

You will be asked some questions in order to configure this smoke suite.
Please make sure to read the documentation "perldoc configsmoke"
in case you do not understand a question.

* Values in angled-brackets (<>) are alternatives (none other allowed)
* Values in square-brackets ([]) are default values (<Enter> confirms)
* Use single space to clear a value
* Answer '&-d' to continue with all default answers


EOHI
}

=head2 say_bye

Configuration has finshed, show some of the results and say goodbye.

=cut

sub say_bye {
    my $self = shift;

    my $report = join("\n", map { "\t$_" } split(m/\n/, $self->report_build_configs));

    printf <<"EOBYE", $self->current_values->{cfg}, $report, Cwd::abs_path($self->smoke_script);
Finished configuration of Test::Smoke!

* Please check '%s' for
  the build-configurations you want to test:
%s

* Run your Perl core smoker with:
\t%s

* Have the appropriate amount of fun!

                                    The TestSmokeTeam.
EOBYE
}

=head2 write_config

This method writes all the relevant values to the config-file.

=cut

sub write_config {
    my $self = shift;

    # Filter some values we don't want:
    my @donot_save = qw( cronbin docron add2cron );
    my %current_config = %{ $self->current_values };
    delete($current_config{$_}) for @donot_save;

    # Write the actual config-file
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = \&_sort_configkeys;
    (my $current_config = Dumper(\%current_config)) =~ s{\n*$}{};
    if ( open(my $fh, '>', $self->configfile) ) {
        print {$fh} "\$conf = $current_config;\n";
        close($fh);
        printf "  >> Created '%s'\n", $self->configfile;
    }
    else {
        printf "!!!!!\nProblem: Could not create(%s): $!\n!!!!!\n",
               $self->configfile;
        print "Please, fix this yourself.\n";
        print "\$conf = $current_config;\n";
    }
}

=head2 handle_option

Shows the help-text for an option and handles input for it.

=cut

sub handle_option {
    my $self = shift;
    my $option = shift;

    my $prompt_type = $option->configtype || 'prompt';

    printf "** %s - %s\n", $option->name, $option->helptext;
    my $value = $self->$prompt_type($option);
    $self->current_values->{$option->name} = $value;
}

=head2 default_for_option

Default values can come from differnt sources:

I<app-option>, I<config-file>, I<config-default> or I<option-default>.

=cut

sub default_for_option {
    my $self = shift;
    my $option = shift;
    my ($debug) = @_;

    my $caller = (caller 1)[3];

    if ( exists({$self->options}->{$option->name})) {
        my $value = {$self->options}->{$option->name};
        $debug and printf "  ^^$caller^^ '%s' from app-options: '$value'\n", $option->name;
        return $value;
    }
    if ( exists($self->from_configfile->{$option->name}) ) {
        my $value = $self->from_configfile->{$option->name};
        $debug and printf "  ^^$caller^^ '%s' from config-file: '$value'\n", $option->name;
        return $value;
    }
    if ( defined(my $value = $option->configdft->($self)) ) {
        $debug and printf "  ^^$caller^^ '%s' from config-default: '$value'\n", $option->name;
        return $value;
    }
    if ( defined(my $value = $option->default) ) {
        $debug and printf "  ^^$caller^^ '%s' from option-default: '$value'\n", $option->name;
        return $value;
    }
    $debug and printf "  ^^$caller^^ '%s' no default found\n", $option->name;
    return;
}

=head2 prompt

Ask for a text answer.

=cut

sub prompt {
    my $self = shift;
    my $option = shift;

    my $message = $option->configtext;

    my $df_val = $self->default_for_option($option);

    if ($option->configtype eq 'prompt_yn') {
        $df_val =~ tr{01}{ny};
    }

    unless ( defined $message ) {
        my $retval = defined $df_val ? $df_val : "undef";
        (caller 1)[3] or print "Got [$retval]\n";
        return $df_val;
    }

    $message =~ s/\s+$//;

    my %ok_val;
    my $alt = $option->configalt
        ? $option->configalt->($self)
        : [ $option->default ];

    %ok_val = map { (lc $_ => 1) } @$alt if @$alt;

    my $default = defined $df_val ? $df_val : 'undef';
    if ( @$alt && defined $df_val ) {
        $default = $df_val = $alt->[0] unless exists $ok_val{ lc $df_val };
    }
    my $alts    = @$alt ? "<" . join( "|", @$alt ) . "> " : "";
    print "\n$message\n";

    my( $input, $clear );
    INPUT: {
        if ( $self->usedft ) {
            $input = defined $df_val ? $df_val : " ";
        } else {
            print "$alts\[$default] \$ ";
            chomp( $input = <STDIN> );
        }

        if ( $input eq " " ) {
            $input = "";
            $clear = 1;
        } elsif ( $input eq '&-d' ) {
            $self->usedft(1);
            print "(OK, We'll run with --des from now on.)\n";
            redo INPUT;
        } else {
            $input =~ s/^\s+//;
            $input =~ s/\s+$//;
            $input = $df_val unless length $input;
        }

        my $_allow = do {
            local ($Data::Dumper::Indent, $Data::Dumper::Terse) = (0, 1);
            defined($option->allow)
                ? Data::Dumper::Dumper($option->allow)
                : '*';
        };
        printf "Input is not OK (%s)\n", $_allow and redo INPUT
            if !$option->allowed($input, @_);

        last INPUT unless %ok_val;
        printf "Expected one of: '%s'\n", join "', '", @$alt and redo INPUT
            unless exists $ok_val{ lc $input };

    }

    my $retval = length $input ? $input : $clear ? "" : $df_val;
    print "Got [@{[ defined($retval) ? $retval : 'undef' ]}]\n";
    return $retval;
}

=head2 prompt_yn

Ask for a Yes/No answer.

=cut

sub prompt_yn {
    my $self = shift;
    my $option = shift;

    my $default = $self->default_for_option($option);
    $default =~ tr{01}{ny};
    $option->configdft( sub { $default } );

    my $yesno = lc($self->prompt($option, qr{^[ny]$}i)) || 0;
    ( my $retval = $yesno ) =~ tr/ny/01/;
    return 0 + $retval;
}

=head2 prompt_noecho

Ask for a password type of string

=cut

sub prompt_noecho {
    my $self = shift;
    my $option = shift;

    eval "use Term::ReadKey";
    if ($@) {
        print "\n\t!!! Please install Term::ReadKey !!!\n";
        return;
    }

    (my $message = $option->configtext || '') =~ s{\s+$}{};
    print "\n$message\n";

    my $cur_value = $self->default_for_option($option);
    my $show_default = defined($cur_value) ? '******' : 'undef';
    my $new_value;
    GETPWD: {
        my $input;
        if ( $self->usedft ) {
            $input = defined $cur_value ? $cur_value : " ";
        } else {
            print "[$show_default] \$ ";
            ReadMode('noecho');
            chomp( $input = ReadLine(0) );
            ReadMode('restore');
        }

        if ($input eq "") {
            $new_value = $cur_value;
        }
        elsif ($input eq " ") {
            $new_value = '';
        }
        elsif ($input eq '&-d') { # WHY ???
            $self->usedft(1);
            $new_value = $cur_value;
        }
        else {
            $new_value = $input;
        }

        if (! $option->allowed($new_value) ) {
            my $_allow = do {
                local ($Data::Dumper::Indent, $Data::Dumper::Terse) = (0, 1);
                defined($option->allow)
                    ? Data::Dumper::Dumper($option->allow)
                    : '*';
            };
            printf "Input is not OK (%s)\n", $_allow;
            redo GETPWD;
        }
    }
    return $new_value;
}

=head2 prompt_file

Ask for an existing filename.

=cut

sub prompt_file {
    my $self = shift;
    my $option = shift;

    GETFILE: {
        my $file = $self->prompt( $option );

        # thaks to perlfaq5
        $file =~ s{^ ~ ([^/]*)}
                  {$1 ? ( getpwnam $1 )[7] :
                   ( $ENV{HOME} || $ENV{LOGDIR} ||
                   "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" )}ex;
        $file = File::Spec->rel2abs( $file ) unless !$file && $option->configfnex;

        print "'$file' does not exist: $!\n" and redo GETFILE
            unless -f $file || $option->configfnex;

        printf "Got [%s]\n", defined $file ? $file : 'undef';
        return $file;
    }
}

=head2 prompt_dir

Ask for a directory name.

=cut

sub prompt_dir {
    my $self = shift;
    my $option = shift;

    my $dft = exists($self->from_configfile->{ $option->name })
        ? $self->from_configfile->{ $option->name }
        : "";

    if ($dft and !File::Spec->file_name_is_absolute($dft)) {
        $dft = File::Spec->rel2abs( $dft )
    }

    GETDIR: {
        my $dir = $self->prompt($option);

        if ( $dir eq "" and !@{ $option->configalt } and ! $option->allowed($dir) ) {
            print "Got []\n";
            return "";
        }

        # thanks to perlfaq5
        $dir =~ s{^ ~ ([^/]*)}
                 {$1 ? ( getpwnam $1 )[7] :
                       ( $ENV{HOME} || $ENV{LOGDIR} ||
                         "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" )}ex;

        defined( $dir = _chk_dir( $dir ) ) or redo GETDIR;

        print "Got [$dir]\n";
        return $dir;
    }
}

sub _chk_dir {
    my( $dir ) = @_;
    defined $dir or return;
    my $cwd = cwd();
    File::Path::mkpath( $dir, 1, 0755 ) unless -d $dir;

    if ( ! chdir $dir  ) {
        warn "Cannot chdir($dir): $!\n";
        $dir = undef;
    } else {
        $dir = File::Spec->canonpath( cwd() );
    }
    chdir $cwd or die "Cannot chdir($cwd) back: $!";

    return $dir;
}

sub _sort_configkeys {
    my @order = (
        # Test::Smoke (startup) related
        qw( cfg v smartsmoke renice killtime umask ),

        # Perl dist related
        qw( perl_version is56x ddir ),

        # Sync related
        qw( sync_type fsync rsync opts source tar server sdir sfile
            unzip patchbin cleanup cdir hdir pfile
            gitbin gitdir gitorigin gitdfbranch gitbare gitbranchfile ),

        # OS specific make related
        qw( w32cc w32make w32args ),

        # Test environment related
        qw( force_c_locale locale defaultenv perlio_only skip_tests ),

        # SmokeDB
        qw( smokedb_url poster send_log send_out ua_timeout curlbin ),

        # Report related
        qw( mail mail_type mailbin mailxbin sendmailbin sendemailbin
            mserver msport msuser mspass from to ccp5p_onfail
            swcc cc swbcc bcc ),

        # Archive reports and logfile
        qw( adir lfile ),

        # make fine-tuning
        qw( makeopt testmake harnessonly hasharness3 harness3opts ),

        # user_notes
        qw( hostname user_note un_file un_position ),

        # internal files
        qw( outfile rptfile jsnfile ),

        # ENV stuff
        qw( perl5lib perl5opt delay_report ),
    );

    my $i = 0;
    my %keyorder = map { $_ => $i++ } @order;

    my @keyord = sort {
        $a <=> $b
    } @keyorder{ grep exists $keyorder{ $_}, keys %{ $_[0] } };

    return [ @order[ @keyord ],
             sort grep !exists $keyorder{ $_ }, keys %{ $_[0] } ];
}

1;

=head1 COPYRIGHT

(c) 2020, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
