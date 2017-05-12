package Ukigumo::Client::YamlConfig;
use strict;
use warnings;
use YAML::Tiny;
use Ukigumo::Constants;
use String::CamelCase qw/camelize/;

use Mouse;

# Arguments
has c => (
    is       => 'ro',
    isa      => 'Ukigumo::Client',
    required => 1,
);

has ukigumo_yml_file => (
    is       => 'ro',
    isa      => 'Str',
    default  => '.ukigumo.yml',
);

has travis_yml_file => (
    is       => 'ro',
    isa      => 'Str',
    default  => '.travis.yml',
);

# Generates automatically
has config => (
    is      => 'ro',
    isa     => 'HashRef',
    builder => '_build_config',
);

has notifiers => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_notifiers',
);

# Configurable by yml
has env => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->config->{env} },
);

has project_name => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub { shift->config->{project_name} },
);

has notifications => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { shift->config->{notifications} || {} },
);

## Executable commands
has before_install => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Str]]',
    lazy    => 1,
    default => sub { shift->_array_of_str_from_config('before_install') },
);

has install => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Str]]',
    lazy    => 1,
    default => sub { shift->_array_of_str_from_config('install') },
);

has before_script => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Str]]',
    lazy    => 1,
    default => sub { shift->_array_of_str_from_config('before_script') },
);

has script => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Str]]',
    lazy    => 1,
    default => sub { shift->_array_of_str_from_config('script') },
);

has after_script => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef[Str]]',
    lazy    => 1,
    default => sub { shift->_array_of_str_from_config('after_script') },
);

no Mouse;

sub apply_environment_variables {
    my ($self) = @_;
    my $c = $self->c;

    my $env = $self->env;
    if ($env && (my $ref = ref $env) ne 'ARRAY') {
        $ref ||= 'SCALAR';
        $c->logger->warnf("`env` must be array reference: in spite of it was given `$ref`");
        $c->reflect_result(STATUS_FAIL);
        die "`env` must be array reference: in spite of it was given `$ref`\n";
    }
    for my $e (@$env) {
        my ($k, $v) = %$e;
        $ENV{$k} = $v;
    }
}

sub effective_yml_file {
    my ($self) = @_;

    my @files = ($self->ukigumo_yml_file, $self->travis_yml_file);
    for my $file (@files) {
        return $file if -f $file;
    }

    return;
}

sub _build_config {
    my ($self) = @_;
    my $c = $self->c;

    my $ukigumo_yml = $self->effective_yml_file;
    if ($ukigumo_yml) {
        my $y = eval { YAML::Tiny->read($ukigumo_yml) };
        if (my $e = $@) {
            $c->logger->warnf("YAML syntax error in $ukigumo_yml: $e");
            $c->reflect_result(STATUS_FAIL);
            die "$ukigumo_yml: $e\n";
        }
        unless (defined $y->[0]) {
            $c->logger->warnf("$ukigumo_yml: does not contain anything");
            $c->reflect_result(STATUS_FAIL);
            die "$ukigumo_yml: does not contain anything\n";
        }
        return $y->[0];
    }

    $c->logger->infof("There is no yaml file");
    return +{};
}

sub _array_of_str_from_config {
    my ($self, $key) = @_;

    my $str = $self->config->{$key};
    (defined $str && not ref $str) ? [$str] : $str;
}

sub _build_notifiers {
    my ($self) = @_;

    my @notifiers;
    for my $type (keys %{$self->notifications}) {
        if ($type eq 'ikachan') {
            push @notifiers, @{$self->_load_notifier_class($type, NOTIFIER_IKACHAN)};
        }
        elsif ($type eq 'github_statuses') {
            push @notifiers, @{$self->_load_notifier_class($type, NOTIFIER_GITHUBSTATUSES)};
        } else {
            push @notifiers, @{$self->_load_notifier_class($type)};
        }
    }
    return \@notifiers;
}

sub _load_notifier_class {
    my ($self, $type, $module_name) = @_;

    unless ($module_name) {
        $module_name = 'Ukigumo::Client::Notify::' . camelize($type);
    }

    (my $module_path = $module_name) =~ s!::!/!g;
    $module_path .= '.pm';
    require $module_path;

    my $notifier_config = $self->notifications->{$type};
    $notifier_config = [$notifier_config] unless ref $notifier_config eq 'ARRAY';

    my @notifiers;
    for my $args (@$notifier_config) {
        push @notifiers, $module_name->new($args);
    }

    return \@notifiers;
}

1;
