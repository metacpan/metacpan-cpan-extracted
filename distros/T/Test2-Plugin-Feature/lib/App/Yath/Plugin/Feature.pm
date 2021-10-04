package App::Yath::Plugin::Feature;

use strict;
use warnings;

our $VERSION = '0.001112';

use parent 'App::Yath::Plugin';
use App::Yath::Options;

option_group {prefix => 'Feature', category => "Plugin feature"} => sub {

    option match => (
        #short        => 'm',
        description  => ['Only match steps in from features with available ones'],
    );

    option matching => (
        type         => 's',
        default      => 'first',
        long_examples => [ 'mode' ],
        description  => [ "Step function multiple matches behaviour:
                           `first` (default) selects first match,
                           `relaxed` warns and runs first match or
                           `strict` stops execution"],
        action        => sub {
            my ($prefix, $field, $raw, $norm, $slot, $settings, $handler) = @_;

            die "$raw is not an allowed extention"
                unless $raw =~ /(first|relaxed|strict)/;

            $handler->($slot,$raw);
        }
    );

    option output => (
        #short        => 'o',
        type         => 's',
        default      => 'TAP',
        long_examples => [ 'mode' ],
        description  => [ "Output harness. Defaults to 'TermColor'. See 'Outputs'"],
    );

    option theme => (
        #short        => 'c',
        type         => 's',
        default      => 'dark',
        long_examples => [ 'mode' ],
        description  => [ "Theme for 'TermColor'. `light` or `dark` (default)"],
        action        => sub {
            my ($prefix, $field, $raw, $norm, $slot, $settings, $handler) = @_;

            die "$raw is not an allowed theme"
                unless $raw =~ /(light|dark)/;

            $handler->($slot,$raw);
        }
    );

    option steps => (
        type         => 'm',
        long_examples => [ 'path' ],
        description  => [ "Include an extra step file, or directory of step files (as identified by *_steps.pl)"],
    );

    option config => (
        #short        => 'g',
        type         => 's',
        long_examples => [ 'path' ],
        description  => [ "A YAML file containing configuration profiles"],
    );

    option i18n => (
        type         => 's',
        long_examples => [ 'LANG' ],
        description  => [ 'List keywords for a particular language.',
                       '\'--i18n help\' lists all languages available.'],

    );

    option profile => (
        #short        => 'p',
        type         => 's',
        default      => 'default',
        long_examples => [ 'name' ],
        description  => [ "Name of the profile to load from the above config file. Defaults to `default`"],
    );

    option extension => (
        #short        => 'e',
        type         => 's',
        long_examples => [ 'Extension::Module', ' Extension::Module[string]' ],
        description  => [ 'Load an extension. You can place a string in brackets ',
                          'at the end of the module name which will be eval\'d ',
                          'and passed to new() for the extension.'],
    );

    option tags => (
        #short        => 't',
        type         => 'm',
        long_examples => [ '@tag', ' @tag1,@tag2', ' ~@tag' ],
        description  => [ "Run scenarios tagged with '\@tag', ",
                          "'\@tag1' or '\@tag2', or without '\@tag'"],
    );

    option debug_profile => (
        name         => 'feature-debug-profile',
        type         => 'b',
        description  => [ "Shows information about which profile was loaded and how and then terminates"],
    );

    option option => (
        type         => 'm',
        long_examples => [ 'KEY=VALUE' ],
        description   => ['Support prove options syntax for drop-in compatibility',
                          'where KEY=VALUE is one of:',
                          ' config=path', ' profile=name', ' debug-profile',
                          ' output=string', ' steps=step_files', ' tags=@tag',
                          ' i18n=LANG', ' extension=extension:module',
                          ' matching=mode', ' match',
                          'See the description of each in --feature-KEY'
                         ],

        action        => sub {
          my ($prefix, $field, $raw, $norm, $slot, $settings, $handler) = @_;

          return if $raw !~ /^(config|debug-profile|extension|i18n|match|matching|profile|output|steps|tags)=.+/;

            my ($option,$value) = split /=/, $raw, 2;

            if ( $option =~ /steps/ ) {
                push @{$settings->Feature->$option}, $value
            } else {
                $settings->Feature->$option = $value;
            }
        }
    );
};

use Test2::Harness::TestFile;

# Munge the file list found
# Trying to run: 'psql $args $tf->file'

sub munge_files {
    my ($plugin, $testfiles, $settings) = @_;

    for my $tf (@$testfiles) {
       if ($tf->file =~ m/[.]feature$/) {
            my @args = ();
            foreach (qw(config debug_profile extension i18n
                        matching output profile theme)) {
              push @args, "--$_", $settings->Feature->$_
                if defined $settings->Feature->$_;
            }
            push @args, '--match'
                if defined $settings->Feature->match
                && $settings->Feature->match;
            foreach (@{$settings->Feature->steps}) {
              push @args, '--steps', $_;
            }
            foreach (@{$settings->Feature->tags}) {
              push @args, '--tags', $_;
            }
            $tf = Test2::Harness::TestFile->new(
                file => $tf->file,
                job_class => 'Test2::Harness::Runner::Job::Feature',
                relative => $tf->relative,
                queue_args => [
                    command => 'pherkin',
                    non_perl => 1,
                    +test_args => [@args, ( '--file', $tf->relative )]
                ]
           );
       }
    }
}

use File::Basename;

# Claim our files
sub claim_file {
    my ($plugin, $item, $settings) = @_;
    my ($filename, $dirs, $suffix0) = fileparse($item);
    return if -d $item;
    return $suffix0 eq 'feature'
           ? Test2::Harness::TestFile->new(file => $item)
           : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Plugin::Feature - Plugin to allow testing Pherkin files.

=head1 VERSION

version 0.001112

=head1 SYNOPSIS

    # Run all feature tests in the examples directory
    $ yath test --plugin feature examples

=head1 DESCRIPTION

This module set invocation option to interfaces yath with Test::BDD::Cucumber, a feature-complete Cucumber-style testing in Perl

=head1 SOURCE

The source of the plugin can be found at
L<http://github.com/ylavoie/test2-Plugin-Feature/>

=head1 SEE ALSO

L<Test::BDD::Cucumber> - Feature-complete Cucumber-style testing in Perl

=head1 MAINTAINERS

=over 4

=item Yves Lavoie E<lt>ylavoie@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Yves Lavoie E<lt>ylavoie@cpan.orgE<gt>

=back

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
