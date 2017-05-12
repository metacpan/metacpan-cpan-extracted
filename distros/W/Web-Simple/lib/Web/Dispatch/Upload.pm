use strictures 1;

{
  package Web::Dispatch::Upload;
  require Plack::Request::Upload;
  our @ISA = qw(Plack::Request::Upload);
  use overload '""' => 'tempname', fallback => 1;

  sub is_upload { 1 }

  sub reason { '' }
}

{
  package Web::Dispatch::NotAnUpload;

  use overload '""' => '_explode', fallback => 1;

  sub new {
    my ($class, %args) = @_;
    bless {
      filename => $args{filename},
      reason => $args{reason}
    }, $class;
  }

  sub is_upload { 0 }

  sub reason { $_[0]->{reason} }

  sub _explode {
    die "Not actually an upload: ".$_[0]->{reason}
  }

  sub filename { $_[0]->_explode }
  sub headers { $_[0]->_explode }
  sub size { $_[0]->_explode }
  sub tempname { $_[0]->_explode }
  sub path { $_[0]->_explode }
  sub content_type { $_[0]->_explode }
  sub type { $_[0]->_explode }
  sub basename { $_[0]->_explode }
}

1;
