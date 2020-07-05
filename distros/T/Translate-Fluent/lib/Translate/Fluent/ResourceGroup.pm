package Translate::Fluent::ResourceGroup;

use Moo;

has sets => (
  is => 'rw',
  default => sub { {} },
);

has fallback_order  => (
  is => 'ro',
  default => sub { ['language' ] },
);

has default_language => (
  is      => 'ro',
  default => sub { 'en' },
);

use Translate::Fluent::ResourceGroup::Context;
use Translate::Fluent::ResourceSet;

sub __build_self {
  my ($class, $context) = @_;
 
  my %params = ();
  if ($context->{default_language}) {
    $params{default_language} = delete $context->{default_language};
  }
  if ($context->{fallback_order}) {
    $params{fallback_order} = delete $context->{fallback_order};
  }

  return $class->new( %params );
}

sub slurp_file {
  my ($self, $fname, $context) = @_;

  $self = $self->__build_self( $context )
    unless ref $self;
  
  local $/ = undef;
  open my $fh, $fname or do {
    warn "Error opening file '$fname'";
    next;
  };

  my $fluent = <$fh>;
  next unless $fluent; # is the file empty?

  if (my ($ctx) = $fluent =~ m{ \A\#\s*context:\s*([^\n]+)\n }x) {
    my %fcontext;
      
    my @fcontext = map { split /\s*[:=]\s*/, $_, 2 } split /\s*[:=]\s/, $ctx;

    if ( !( scalar @fcontext % 2) ) {
      %fcontext = @fcontext;

      $context->{ $_ } //= $fcontext{ $_ }
        for keys %fcontext;
    } else {
      print STDERR "invalid context: '$ctx'\n";
      warn "Invalid context in fluent file '$fname' - ignoring";
    }
  }

  my $resset =  Translate::Fluent::Parser::parse_string( $fluent );
  if ($resset) {
    $self->add_resource_set( $resset, $context );
  }

  return $self if defined wantarray;

  return;
}

sub slurp_directory {
  my ($self, $directory, $context) = @_;

  $self = $self->__build_self( $context )
    unless ref $self;
  
  for my $k (qw(default_language fallback_order)) {
    die "'$k' is invalid when adding resources to a resource group"
      if $context->{$k};
  }

  my $recursive = delete $context->{recursive} // 0;

  $directory .='/' unless substr($directory, -1) eq '/';

  opendir my $dh, $directory or die "Can't open $directory: $!";
  my @all = readdir( $dh );
  my @files = grep { m{ \.flt\z }xi } @all;
  closedir( $dh );

  # first we slurp the subdirectories, so that the files
  # on the top directories override the files in the sub directories
  # I could go both ways, but I think it is more intuitive this way
  # TODO: add directory priority to the docs of slurp_directory
  if ($recursive) {
    my @dirs = grep { !m{\A\.} and -d "$directory$_" } @all;

    for my $dir ( @dirs ) {
      $self->slurp_directory( "$directory$dir", $context );
    }
  }

  for my $fname ( @files ) {
    my %context = %{$context};
  
    my $fname = "$directory$fname";
    $self->slurp_file( $fname, \%context );
  }

  return $self;
}

#TODO: add override priority to add_resource_set docs.
sub add_resource_set {
  my ($self, $resource_set, $context ) = @_;

  my @kv  = ();
  for my $fbo (@{ $self->fallback_order }) {
    my $fbok = $context->{ $fbo }
      || ($fbo eq 'language' ? 'dev' : 'default');
    
    push @kv, $fbok;
  }

  my $key = join '>', @kv;

  my $reset = $self->sets->{ $key };
  if ( $reset ) {
    for my $k (keys %{ $resource_set->resources }) {
      $reset->add_resource( $resource_set->resources->{ $k } );
    }

  } else {
    $self->sets->{ $key } = $resource_set;

  }

  return;
}

sub translate {
  my ($self, $res_id, $variables, $context) = @_;

  $context = $variables->{__context}
    if !$context and $variables->{__context};

  my $_ctx;
  if (ref $context eq 'Translate::Fluent::ResourceGroup::Context') {
    $_ctx = $context;
    $context = $_ctx->context;
  }

  my $res = $self->_find_resource( $res_id, $context );

  return unless $res and $res->isa("Translate::Fluent::Elements::Message");

  $_ctx ||= Translate::Fluent::ResourceGroup::Context->new(
                context   => $context,
                resgroup  => $self,
              );
  
  return $res->translate({ %{$variables//{}}, __resourceset => $_ctx });
}

sub get_term {
  my ($self, $term_id, $context) = @_;

  my $term = $self->_find_resource( $term_id, $context );

  return unless $term->isa("Translate::Fluent::Elements::Term");

  return $term;
}

sub get_message {
  my ($self, $message_id, $context) = @_;

  my $res = $self->_find_resource( $message_id, $context );

  return unless $res->isa("Translate::Fluent::Elements::Message");

  return $res;
}

sub _find_resource {
  my ($self, $res_id, $context) = @_;

  my $lang = $context->{language} || $self->default_language;
  my %ctx = ();
  my @fborder = @{ $self->fallback_order };
  for my $fb ( @fborder ) {
    $ctx{ $fb } = $context->{ $fb }
                || (($fb eq 'language') ? $lang : 'default');
  }
  my %fbnext  = map { $fborder[$_-1] => $fborder[$_] } 1..$#fborder;
  my $fbnext  = ($fborder[0]);

  my $res;

  RESSET:
  while (!$res) {
    my $key = join '>', map { $ctx{$_} } @fborder;
#    use Data::Dumper;
#    print STDERR "checking '$key' => ", Dumper( \%ctx );
    
    if ( my $rset = $self->sets->{ $key }) {
      last RESSET if $res = $rset->resources->{ $res_id };
    }

    my $fbnext_default = $fbnext eq 'language' ? 'dev' : 'default';
    if ($ctx{ $fbnext } eq $fbnext_default) {
      do {
        last RESSET
          unless $fbnext{ $fbnext }; #no where else to look for

        $ctx{ $fbnext } = $context->{ $fbnext }
                        || $fbnext eq 'language' ? $lang : 'default';

        $fbnext = $fbnext{ $fbnext };

      } until $ctx{ $fbnext } ne $fbnext_default;

      $ctx{ $fbnext } = $fbnext eq 'language'
        ? ( $self->__fallback_languages( $ctx{language} ) )[1]
        : 'default';
      $fbnext = $fborder[0];

    } else {
      $ctx{ $fbnext } = $fbnext eq 'language'
        ? ( $self->__fallback_languages( $ctx{language} ) )[1]
        : 'default';
    }
  };

  return $res;
}

sub __fallback_languages {
  my ($self, $lang, $default_lang) = @_;

  $default_lang ||= $self->default_language;

  my @langs = ($lang) if $lang;

  while ($lang and $lang=~m{\-}) {
    $lang =~ s{-\w+\z}{};
    push @langs, $lang;
  }
  unless ($lang eq $default_lang) {
    push @langs, $default_lang;
  }

  push @langs, 'dev' unless $default_lang eq 'dev';

  return @langs;
}

1;

__END__

=head1 NAME

Translate::Fluent::ResourceGroup - a group of contextualized L<ResourceSet>s.

=head1 SYNOPSIS

  my $group = Translate::Fluent::ResourceGroup->slurp_directory( "somedir" );
  my $variables = {};

  print $group->translate("some-resource", $variables, { language => "en" });

=head1 DESCRIPTION

Where L<Translate::Fluent::ResourceSet> allow you to get translations from a
single set of resources, C<Translate::Fluent::ResourceGroup> provides the
mechanisms to use multiple resource sets with basic rules to find the needed
resource across multiple resource set.

This main idea behind this is that often we don't have perfect translations
for our software, and that it is better to provide the text in the wrong
language than not being able to provide a translation at all.

=head2 FALLBACK_ORDER

while creating a resource group you can define a list of context parameters to
fall back through when looking for a resource (message or term). The order
in which they are listed is the order in which they are released.

When one context paramater is released, the next possible value for that
parameter is tested. For this purpose, language is special. The remaining
parameters, when released, the value 'default' is used.

For language, the fallback path is a bit longer. If the language used in the
translate context is a variant of a main language, then the main language is
used. After the main language, then the default_language of the ResourceGroup
is used (default is 'en'), and then 'dev' is used.

When a resource set is added to a group, all the context paramaters that are
not defined when adding the resource set default to 'default' or 'dev' (dev
for the language parameter).

Consider the following fallback order:

  [qw( site plugin language )]

And now consider the following translate context:

  { site      => "google.com",
    plugin    => "footer",
    language  => "pt-br",
  }

For this request, a given resource is going to be search is the ResourceSets
that have the following contexts:

  google.com > footer > pt-br
  default    > footer > pt-br
  google.com > default> pt-br
  default    > default> pt-br
  google.com > footer > pt
  default    > footer > pt
  google.com > default> pt
  default    > default> pt
  google.com > footer > en
  default    > footer > en
  google.com > default> en
  default    > default> en
  google.com > footer > dev
  default    > footer > dev
  google.com > default> dev
  default    > default> dev

=head1 METHODS

=head2 new([...])

Creates a new ResourceGroup. possible parameters are:

=over 4

=item * fallback_order => [qw<...>]

the fallback order defines the order with which context parameters of a
translation request are relaxed to find a translation resource.

context parameters that are not listed in the fallback_order are - at the
moment - ignored, as having an arbitrary list of context parameters may make
it very difficult to find any translation resources at all.

This behavior may change in the future, so try to avoid using context
parameters anywhere that are not listed in the fallback_order of the
ResourceGroup.

See L<#FALLBACK_ORDER> above for details on the fallback mechanism.

=item * default_language => '...'

The default language is the language used when a translation request is made
without a language context, or when the resource is not found in the given
language.

If a resource is still not found in the default_language, the default is to
look for it using 'dev' for the language. 

=back

=head2 slurp_directory( $directory, $context )

slurp_directory load all the files fluent in a directory (and, optionally,
sub-directories) and add all the resources found to the current ResourceGroup.

For convinience, if called as a static method, it created a new ResourceGroup
and returns it.

When called as a static method, slurp_directory supports a few extra
parameters in the $context, which are passed to C<new>:

=over 4

=item * fallback_order

=item * default_language

=back

Additionally, $context can also include a value for C<recursive>, which
will define if files existing in sub-directories are also loaded or not.

All the remaining values in $context are used as values for the contexts
of all the resources loaded.


=head3 context from files

Additionally, C<slurp_directory> checks the first line of each file
loaded to see if it matches:

  #context: \w+[:=]\w+([,;]\w+[:=]\w+)*

(meaning, "$key: $value" pais separated by , or ;)

If the first line of the files match that, those values are added to the
$context passed to slurp_directory.

To notice, values passed to slurp_directory have priority over those
defined in the translation files.

=head2 add_resource_set( $resource_set, $context )

add_resource_set adds a pre-existing ResourceSet to a ResourceGroup with
the context provided.

=head2 translate( $res_id, $variables, $context )

Search for a Message with the id $res_id using the $context provided and
translates it.

=head2 get_term( $term_id, $context )

Search for a Term with the id $term_id using the $context provided and returns
it. While this may be useful, it is intended for internal use.

=head2 get_message( $message_id, $context )

Search for a Message with the id $message_id using the $context provided and
returns it. While this may be useful, it is intended for internal use.

While you could use the returned $message to perform a translation, this would
fail when such translation needs a term or a message - which may not always
happen. Do not do that.

=head1 SEE MORE

This file is part of L<Translate::Fluent> - version, license and more general
information can be found in its documentation.

=cut

