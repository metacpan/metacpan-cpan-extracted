package Text::Sass::XS;
use 5.008005;
use strict;
use warnings;
use base 'Exporter';
use Carp ();

our $VERSION = "0.11";

my @constants = qw(
    SASS_STYLE_NESTED
    SASS_STYLE_EXPANDED
    SASS_STYLE_COMPRESSED
    SASS_SOURCE_COMMENTS_NONE
    SASS_SOURCE_COMMENTS_DEFAULT
    SASS_SOURCE_COMMENTS_MAP
);
my @functions = qw(
    sass_compile
    sass_compile_file
);
our @EXPORT_OK = ( @constants, @functions );
our %EXPORT_TAGS = (
    'all'   => [ @constants, @functions ],
    'const' => \@constants,
    'func'  => \@functions
);

use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

sub sass_compile {
    my $source_string = shift;

    my $result;
    if (@_) {
        $result = _compile( $source_string, +{ _normalize_options(@_) } );
    }
    else {
        $result = _compile($source_string);
    }

    wantarray
        ? ( $result->{output_string}, $result->{error_message} )
        : $result->{output_string};
}

sub sass_compile_file {
    my $input_path = shift;

    my $result;
    if (@_) {
        $result = _compile_file( $input_path, +{ _normalize_options(@_) } );
    }
    else {
        $result = _compile_file($input_path);
    }

    wantarray
        ? ( $result->{output_string}, $result->{error_message} )
        : $result->{output_string};
}

sub _normalize_options {
    return unless @_;

    my %options = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    # include_paths must be a colon separated string.
    if ( $options{include_paths}
        && ref $options{include_paths} eq 'ARRAY' )
    {
        $options{include_paths} = join ':', @{ $options{include_paths} };
    }
    else {
        $options{include_paths} = "";
    }

    $options{image_path} = "" unless $options{image_path};

    return %options;
}

# OO Interface
sub new {
    my $class = shift;

    my $self = bless {
        options => {
            output_style    => SASS_STYLE_COMPRESSED(),
            source_comments => SASS_SOURCE_COMMENTS_NONE(),
            include_paths   => undef,
            image_path      => undef,
            @_,
        },
        _errstr => undef,
    }, $class;

    return $self;
}

sub options {
    my $self = shift;
    $self->{options};
}

sub errstr {
    my $self = shift;
    if (@_) {
        $self->{_errstr} = shift;
    }
    else {
        $self->{_errstr};
    }
}

sub compile {
    my $self          = shift;
    my $source_string = shift;

    my %options = _normalize_options( %{ $self->options } );
    my $result = _compile( $source_string, \%options );

    if ( $result->{error_status} ) {
        Carp::croak $result->{error_message};
    }
    else {
        return $result->{output_string};
    }
}

sub compile_file {
    my $self       = shift;
    my $input_path = shift;

    my %options = _normalize_options( %{ $self->options } );
    my $result = _compile_file( $input_path, \%options );

    if ( $result->{error_status} ) {
        Carp::croak $result->{error_message};
    }
    else {
        return $result->{output_string};
    }
}

# For Text::Sass Compatibility
sub scss2css { shift->compile(@_) }

sub sass2css {
    my $self = shift;
    $self->_require_pp;
    Text::Sass->new->sass2css(@_);
}

sub css2sass {
    my $self = shift;
    $self->_require_pp;
    Text::Sass->new->css2sass(@_);
}

sub _require_pp {
    return if $INC{"Text/Sass.pm"};
    local $@;
    eval 'require Text::Sass;';
    if ($@) {
        Carp::croak
            "Cannot load Text::Sass. If you want to use css2sass or sass2css method, you need to install Text::Sass first.";
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Sass::XS - Perl Binding for libsass

=head1 SYNOPSIS

  # OO Interface
  use Text::Sass::XS;
  use Try::Tiny;

  my $sass = Text::Sass::XS->new;

  try {
      my $css = $sass->compile(".something { color: red; }");
  }
  catch {
      die $_;
  };

  # OO Interface with options
  my $sass = Text::Sass::XS->new(
      include_paths   => ['path/to/include'],
      image_path      => '/images',
      output_style    => SASS_STYLE_COMPRESSED,
      source_comments => SASS_SOURCE_COMMENTS_NONE,
  );
  try {
      my $css = $sass->compile(".something { color: red; }");
  }
  catch {
      die $_;
  };


  # Compile from file.
  my $sass = Text::Sass::XS->new;
  my $css = $sass->compile_file("/path/to/foo.scss");

  # with options.
  my $sass = Text::Sass::XS->new(
      include_paths   => ['path/to/include'],
      image_path      => '/images',
      output_style    => SASS_STYLE_COMPRESSED,
      source_comments => SASS_SOURCE_COMMENTS_NONE,
  );
  my $css = $sass->compile_file("/path/to/foo.scss");


  # Functional Interface
  # export sass_compile, sass_compile_file and some constants
  use Text::Sass::XS ':all';

  my $sass = "your sass string here...";
  my $options = {
      output_style    => SASS_STYLE_COMPRESSED,
      source_comments => SASS_SOURCE_COMMENTS_NONE,
      include_paths   => 'site/css:vendor/css',
      image_path      => '/images'
  };
  my ($css, $errstr) = sass_compile($sass, $options);
  die $errstr if $errstr;

  my $sass_filename = "/path/to/foo.scss";
  my $options = {
      output_style    => SASS_STYLE_COMPRESSED,
      source_comments => SASS_SOURCE_COMMENTS_NONE,
      include_paths   => 'site/css:vendor/css',
      image_path      => '/images'
  };

  # In scalar context, sass_compile(_file)? returns css only.
  my $css = sass_compile_file($sass_filename, $options);
  print $css;


  # Text::Sass compatible Interface
  my $sass = Text::Sass::XS->new(%options);
  my $css = $sass->scss2css($source);

  # sass2css and css2sass are implemented by Text::Sass
  my $css  = $sass->sass2css($source);
  my $scss = $sass->css2sass($css);

=head1 DESCRIPTION

Text::Sass::XS is a Perl Binding for libsass.

L<libsass Project page|https://github.com/hcatlin/libsass>

=head1 OO INTERFACE

=over 4

=item C<new>

  $sass = Text::Sass::XS->new(options)

Creates a Sass object with the specified options. Example:

  $sass = Text::Sass::XS->new; # no options
  $sass = Text::Sass::XS->new(output_style => SASS_STYLE_NESTED);

=item C<compile(source_code)>

  $css = $sass->compile("source code");

This compiles the Sass string that is passed in the first parameter. If
there is an error it will C<croak()>.

=item C<compile_file(input_path)>

  $css = $sass->compile_file("/path/to/foo.scss");

This compiles the Sass file that is passed in the first parameter. If
there is an error it will C<croak()>.

=item C<options>

  $sass->options->{include_paths} = ['/path/to/assets'];

Allows you to inspect or change the options after a call to C<new>.

=item C<scss2css(source_code)>

  $css = $sass->scss2css("scss souce code");

Same as C<compile>.

=item C<sass2css(source_code)>

  $css = $sass->compile("sass source code");

Wrapper method of C<Text::Sass#sass2css>.

=item C<css2sass(source_code)>

  $css = $sass->css2sass("css source code");

Wrapper method of C<Text::Sass#css2sass>.

=back

=head1 FUNCTIONAL INTERFACE

=head1 EXPORT

Nothing to export.

=head1 EXPORT_OK

=head2 Funcitons

=over 4

=item C<sass_compile($source_string :Str, $options :HashRef)>

Returns css string if success. Otherwise throws exception.

Default value of C<$options> is below.

    my $options = {
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE, 
        include_paths   => undef,
        image_path      => undef,
    };

C<input_paths> is a coron-separated string for "@import". C<image_path> is a string using for "image-url".

=item C<sass_compile_file($input_path :Str, $options :HashRef)>

Returns css string if success. Otherwise throws exception. C<$options> is same as C<sass_compile>.

=back

=head2 Constants

For C<$options-E<gt>{output_style}>.

=over 4

=item C<SASS_STYLE_NESTED>

=item C<SASS_STYLE_EXPANDED>

=item C<SASS_STYLE_COMPRESSED>

=back

For C<$options-E<gt>{source_comments}>.

=over 4

=item C<SASS_SOURCE_COMMENTS_NONE>

=item C<SASS_SOURCE_COMMENTS_DEFAULT>

=item C<SASS_SOURCE_COMMENTS_MAP>

=back

=head1 EXPORT_TAGS

=over 4

=item :func

Exports C<sass_compile> and C<sass_compile_file>.

=item :const

Exports all constants.

=item :all

Exports :func and :const.

=back

=head1 SEE ALSO

L<Text::Sass> - Pure perl implementation.

L<CSS::Sass> - Yet another libsass binding.

=head1 LICENSE

Text::Sass::XS

Copyright (C) 2013 Yoshihiro Sasaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

libsass

Copyright (C) 2012 by Hampton Catlin.

See libsass/LICENSE for more details.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki@cpan.orgE<gt>

=cut

