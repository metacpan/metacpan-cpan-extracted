use 5.010;
package WebService::Libris::FileCache;
use Mojo::Base -base;
use Mojo::DOM;

has 'directory';

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->_init;
    $self
}

sub _init {
    my $self = shift;
    my $d = $self->directory;
    unless (-d $d) {
        require File::Path;
        File::Path::make_path($d)
    }
}

sub _filename {
    my ($self, $key) = @_;
    $key =~ s{/}{_}g;
    $self->directory . $key . '.xml'
}

sub get {
    my ($self, $key) = @_;
    my $filename = $self->_filename($key);
    return undef unless open my $h, '<:encoding(UTF-8)', $filename;
    my $contents = do { local $/; <$h> };
    return undef unless length $contents;
    Mojo::DOM->new->xml(1)->parse($contents);
}

sub set {
    my ($self, $key, $value) = @_;
    my $filename = $self->_filename($key);
    open my $h, '>', $filename or die "Can't open file '$filename' for writing: $!";
    print { $h } $value->to_xml;
    close $h;
    $value;
}


1;
