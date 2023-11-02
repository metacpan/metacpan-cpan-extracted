package Test::Smoke::App::Base;
use warnings;
use strict;
use Carp qw/ confess /;

our $VERSION = '0.002';

use base 'Test::Smoke::ObjectBase';

use Cwd 'abs_path';
use Getopt::Long qw/:config pass_through/;
use Test::Smoke::App::AppOption;
use Test::Smoke::App::AppOptionCollection;
use Test::Smoke::LogMixin;
use Test::Smoke::Util::Serialise qw/serialise/;

=head1 NAME

Test::Smoke::App::Base - Baseclass for Test::Smoke::App::* applications.

=head1 SYNOPSIS

    package Test::Smoke::App::Mailer;
    use base 'Test::Smoke::App::Base';
    sub run {...}

=head1 DESCRIPTION

    use Test::Smoke::App::Mailer;
    my $mailer = Test::Smoke::App::Mailer->new(
        main_options => [
            Test::Smoke::App::AppOption->new(
                name     => 'mailer',
                option   => '=s',
                allow    => [qw/MIME::lite sendmail/],
                helptext => "Mailsystem to use for sendig reports.",
            ),
        ],
        genral_options => [
            Test::Smoke::AppOption->new(
                name    => 'ddir',
                option  => '=s',
                helptxt => "Smoke Destination Directory.",
            ),

        ],
        special_options => {
            'MIME::Lite' => [
                mserver(),
                msport(),
                msuser(),
                mspass(),
            ],
            'sendmail' => [],
        },
    );

  $mailer->run();

=head2 Test::Smoke::App->new(%arguments)

=head3 Arguments

Named:

=over

=item main_options => $list_of_test_smoke_appoptions

=item general_options => $list_of_test_smoke_appoptions

These options are always valid.

=item special_options => $hashref

This is a hashref with the values of the C<allow>-array, that hold a list of
L<Test::Smoke::AppOptions>.

=back

=head3 Exceptions

None.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $struct = {
        _main_options    => [],
        _general_options => [],
        _special_options => {},
        _final_options   => {},
    };

    for my $known (keys %$struct) {
        (my $key = $known) =~ s/^_//;
        $struct->{$known} = delete $args{$key} if exists $args{$key};
    }

    my $self = bless $struct, $class;

    $self->process_options();
    return $self;
}

=head2 Test::Smoke::App::Base->configfile_option()

Returns a L<Test::Smoke::App::AppOption> for 'configfile'.

=cut

sub configfile_option {
    my $class = shift;
    return Test::Smoke::App::AppOption->new(
        name     => 'configfile',
        option   => 'config|c=s',
        default  => 'smokecurrent',
        helptext => "Set the name/prefix of the configfile\n",
    );
}

=head2 Test::Smoke::App::Base->verbose_option()

Returns a L<Test::Smoke::App::AppOption> for 'verbose'.

=cut

sub verbose_option {
    my $class = shift;
    return Test::Smoke::App::AppOption->new(
        name     => 'verbose',
        option   => 'v=i',
        allow    => [0, 1, 2],
        default  => 0,
        helptext => 'Set verbosity level.',
    );
}

=head2 $app->show_config_option

=cut

sub show_config_option {
    return Test::Smoke::App::AppOption->new(
        name => 'show_config',
        option => 'show-config',
        helptext => "Show all about config vars.",
    );
}

=head2 $app->process_options()

This process constists of three (3) steps:

=over

=item 1. pre_process_options

This step organizes the options in a AppOptionCollection.

=item 2. get_options

This step processes the arguments passed on the command line.

=item 3. post_process_options

This step integrates the arguments, their coded-defaults, config-file values
and command-line overrides.

=back

=head3 Arguments

None.

=head3 Returns

The object-instance.

=head3 Exceptions

None.

=cut

sub process_options {
    my $self = shift;

    $self->{_opt_collection} = Test::Smoke::App::AppOptionCollection->new();

    $self->_pre_process_options();
    $self->_get_options();
    $self->_post_process_options();

    return $self;
}

=head2 $app->option($option)

Return the value of an option.

=head3 Arguments

Positional.

=over

=item $option_name

=back

=head3 Returns

The value of that option if applicable.

=head3 Exceptions

=over

=item B<Invalid option 'blah' ($name => $type)>

=item B<Option 'blah' is invalid for $name => $type>

=back

=cut

sub option {
    my $self = shift;
    my ($option) = @_;

    my $opts = $self->final_options;
    if (exists $opts->{$option}) {
        my $is_main = grep $_->name eq $option, @{$self->main_options};
        return $opts->{$option} if $is_main;

        my $is_general = grep $_->name eq $option, @{$self->general_options};
        return $opts->{$option} if $is_general;

        for my $mainopt (@{$self->main_options}) {
            my $type = $opts->{$mainopt->name};
            my $specials = $self->special_options->{$type};
            my $is_special = grep $_->name eq $option, @$specials;
            return $opts->{$option} if $is_special;
        }

        confess("Option '$option' is not valid.");
    }
    confess("Invalid option '$option'");
}

sub _find_option {
    my $self = shift;
    my ($option) = @_;

    my ($oo) = grep $_->name eq $option, @{$self->main_options};
    return $oo if $oo;

    ($oo) = grep $_->name eq $option, @{$self->general_options};
    return $oo if $oo;

    for my $mo (@{$self->main_options}) {
        my $type = $self->final_options->{$mo->name};
        my $specials = $self->special_options->{$type};
        ($oo) = grep $_->name eq $option, @$specials;
        return $oo if $oo;
    }

    return;
}

=head2 $app->options()

=head3 Arguments

None.

=head3 Returns

A hash (list) of all options that apply to this instance of the app.

=head3 Exceptions

None.

=cut

sub options {
    my $self = shift;

    my %options;
    for my $opt (@{$self->main_options}) {
        my $type = $self->option($opt->name);
        $options{$opt->name} = $type;
        my $specials = $self->special_options->{$type};
        for my $opt (@$specials) {
            $options{$opt->name} = $self->option($opt->name);
        }
    }
    # collect all general options
    for my $opt (@{ $self->general_options }) {
        next if $opt->name =~ /^(?:help|show_config)$/;
        $options{$opt->name} = $self->option($opt->name);
    }

    return %options;
}

sub _pre_process_options {
    my $self = shift;

    unshift @{$self->general_options}, $self->configfile_option;
    push @{$self->general_options}, $self->show_config_option;
    push @{$self->general_options}, $self->verbose_option;
    for my $opt (@{$self->general_options}) {
        $self->opt_collection->add($opt);
    }

    for my $opt (sort {$a->name cmp $b->name} @{$self->main_options}) {
        $self->opt_collection->add_helptext("\n");
        $self->opt_collection->add($opt);
        for my $special (sort {lc($a) cmp lc($b)} @{$opt->allow}) {
            $self->opt_collection->add_helptext(
                sprintf("\nOptions for '%s':\n", $special)
            );
            my $specials = $self->special_options->{$special};
            for my $thisopt (@$specials) {
                $self->opt_collection->add($thisopt);
            }
        }
    }

    my $helptext = $self->opt_collection->helptext;
    my $help_option = Test::Smoke::App::AppOption->new(
        name    => 'help',
        option  => 'h',
        default => sub {
            print "Usage: $0 [options]\n\n$helptext";
            exit(0);
        },
        helptext => 'This message.',
    );
    push @{$self->general_options}, $help_option;
    $self->opt_collection->add($help_option);

    %{$self->{_dft_options}} = %{$self->opt_collection->options_with_default};
}

sub _get_options {
    my $self = shift;

    %{$self->{_cli_options}} = %{$self->opt_collection->options_for_cli};

    @{$self->{_ARGV}} = @{$self->{_ARGV_EXTRA}} = @ARGV;

    my $parser = Getopt::Long::Parser->new(config => [qw/no_ignore_case passthrough/]);
    $parser->getoptionsfromarray(
        $self->{_ARGV_EXTRA},
        $self->cli_options,
        @{ $self->opt_collection->options_list },
    );
}

sub _post_process_options {
    my $self = shift;

    $self->_obtain_config_file;
    %{$self->final_options} = %{$self->cli_options};

    # now combine with configfile
    $self->final_options(
        {
            %{$self->opt_collection->all_options},
            %{$self->dft_options},
            %{$self->from_configfile},
            %{$self->cli_options},
        }
    );
    my @errors;
    my %check_options = $self->options;
    for my $opt (keys %check_options) {
        my $oo = $self->_find_option($opt);
        my $value = $self->final_options->{$opt};
        $value = '<undef>' if !defined $value;
        push(
            @errors,
            sprintf(
                "Invalid value '%s' for option '%s'",
                $self->_show_option_value($opt), $opt
            )
        ) if !$oo->allowed($self->final_options->{$opt});
    }
    if (@errors) {
        print "$_\n" for @errors;
        exit(1);
    }

    if ($self->final_options->{show_config}) {
        print "Show configuration requested:\n";
        print
            sprintf(
                "  %-20s| %s\n",
                'Option',
                'Value'
            );
        print "----------------------+--------------------------------------------\n";
        my %options = $self->options;
        for my $opt (sort keys %options) {
            printf "  %-20s| %s\n",
                $opt,
                $self->_show_option_value($opt) || '?';
        }
        exit(0);
    }
}

sub _show_option_value {
    my $self =  shift;
    my ($option_name) = @_;

    return serialise( $self->option($option_name) );
}

sub _obtain_config_file {
    my $self = shift;
    $self->{_from_configfile} = {};
    $self->{_configfile_error} = undef;

    my $cf_name = $self->cli_options->{'configfile'};
    return if !$cf_name;

    if (!-f $cf_name) {
        for my $ext (qw/_config .config/) {
            if (-f "${cf_name}${ext}") { $cf_name .= $ext; last }
        }
    }

    if (-f $cf_name) {
        my $abs_cf = $self->cli_options->{'configfile'} = abs_path($cf_name);

        # Read the config-file in a localized environment
        our $conf;
        local $conf;
        delete $INC{$abs_cf};
        eval { local $^W; require $abs_cf };
        $self->{_configfile_error} = $@;
        %{$self->from_configfile} = %{ $conf || {} };
        delete $INC{$abs_cf};
        $self->from_configfile->{verbose} = delete($self->from_configfile->{v})
            if exists $self->from_configfile->{v};
    }
    else {
        $self->{_configfile_error} = "Could not find a configfile for '$cf_name'.";
    }
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

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
