package XML::Atom::Lifeblog::Media;
use strict;

use Carp;
use File::Basename;
use File::Type;
use MIME::Types;

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->init(@_);
}

sub title    { $_[0]->{title}   }
sub type     { $_[0]->{type}    }
sub content  { $_[0]->{content} }

sub init {
    my($self, %param) = @_;
    if (my $name = $param{filename}) {
        $self->{content} = $self->_slurp($name);
        $self->{type}    = $param{type}  || $self->_guess_type($name);
        $self->{title}   = $param{title} || $self->_basename($name);
    }
    elsif (my $content = $param{content}) {
        $self->{content} = $content;
        $self->{type}    = $param{type}  || $self->_guess_type(\$content);
        $self->{title}   = $param{title} || $self->_random_title;
    }
    elsif (my $fh = $param{filehandle}) {
        local $/;
        $self->{content} = <$fh>;
        $self->{type}    = $param{type}  || $self->_guess_type(\$self->content);
        $self->{title}   = $param{title} || $self->_random_title;
    }
    else {
        Carp::croak("XML::Atom::Lifeblog::Media->new(): requires filename, content or filehandle parameter");
    }

    $self;
}

sub _slurp {
    my($self, $file) = @_;
    local $/;
    open my $fh, $file or Carp::croak("$file: $!");
    <$fh>;
}

sub _guess_type {
    my($self, $foo) = @_;
    ref($foo) ? $self->_guess_type_magic($$foo) : $self->_guess_type_mime($foo);
}

sub _guess_type_magic {
    my($self, $content) = @_;
    return File::Type->new->checktype_contents($content);
}

sub _guess_type_mime {
    my($self, $filename) = @_;
    my $mime = MIME::Types->new->mimeTypeOf($filename);
    return $mime ? $mime->type : undef;
}

sub _random_title {
    my $self = shift;
    my $ext = eval {
       [ MIME::Types->new->type($self->type)->extensions ]->[0];
    } || "dat";
    return "XML::Atom::Lifeblog-$$.$ext";
}

sub _basename {
    my($self, $file) = @_;
    File::Basename::basename($file);
}

1;

