package Helm::Task;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Data::UUID;
use File::Spec::Functions qw(catfile);

has helm => (is => 'ro', writer => '_helm', isa => 'Helm');

# must be implemented in child classes
sub execute {
    my ($self, %args) = @_;
    die "You must implement the execute method in your child class " . ref($self) . "!";
}

sub validate {
    my $self = shift;
    die "You must implement the validate method in your child class " . ref($self) . "!";
}

sub help {
    my ($self, $task) = @_;
    return qq(No help documentation for "$task". Bug your implementers);
}

# can be implemented in child classes
sub setup    { }
sub teardown { }

sub unique_tmp_file {
    my ($self, %args) = @_;
    my $file = catfile('', 'tmp', Data::UUID->new->create_str);
    $file = $args{prefix} . $file if $args{prefix};
    $file .= $args{suffix} if $args{suffix};
    return $file;
}

sub param {
    my $self = shift;
    my $name = shift;
    die "param() requires a name" unless $name;
    $self->{__params} ||= {};
    my $params = $self->{__params};

    # set it if we have a value
    $params->{$name} = $_[0] if @_;
    return $params->{$name};
}

sub params {
    my $self = shift;
    if( $self->{__params} ) {
        return %{$self->{__params}};
    } else {
        return ();
    }
}

__PACKAGE__->meta->make_immutable;

1;
