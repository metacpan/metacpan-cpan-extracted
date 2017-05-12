package XML::Loy::ActivityStreams;
use strict;
use warnings;
use XML::Loy with => (
  prefix    => 'activity',
  namespace => 'http://activitystrea.ms/schema/1.0/'
);

# Todo: support to_json
# Todo: verbs and object-types may need namespaces
# Todo: Support ActivityStreams 2 as a anamespace

use Carp qw/carp/;

# No constructor
sub new {
  carp 'Only use ' . __PACKAGE__ . ' as an extension to Atom';
  return;
};

# Add or get ActivityStreams actor
sub actor {
  my $self  = shift;

  # Set actor
  if ($_[0]) {
    my $actor = $self->author( @_ );

    $actor->set('object-type', _check_prefix('person'));
    return $actor;
  }

  # Get actor
  else {
    my $actor = $self->author->[0];
    if ($actor) {

      my $object_type = $actor->children('object-type');

      return unless $object_type = $object_type->[0];

      # Prepend namespace if not defined
      if (index($object_type->text, '/') == -1) {
	$object_type->content(
	  __PACKAGE__->_namespace . lc $object_type->text
	);
      };

      return $actor;
    };
  };

  return;
};


# Add or get ActivityStreams verb
sub verb {
  my $self = shift;

  # Set verb
  if ($_[0]) {
    return $self->set(verb => _check_prefix($_[0]));
  }

  # Get verb
  else {
    my $verb = $self->children('verb');

    return unless $verb = $verb->[0];

    # Prepend namespace if not defined
    if (index($verb->text, '/') == -1) {
      my $nverb = __PACKAGE__->_namespace . lc $verb->text;
      $verb->content($nverb);
      return $nverb;
    };

    return $verb->text;
  }
};


# Add or get ActivityStreams object
sub object {
  shift->_target_object(object => @_ );
};


# Add or get ActivityStreams target
sub target {
  shift->_target_object(target => @_ );
};


sub _target_object {
  my $self = shift;
  my $type = shift;

  # Add target or object
  if ($_[0]) {
    my %params = @_;

    my $obj = $self->set($type);

    $obj->id( delete $params{id} ) if exists $params{id};

    if (exists $params{'object-type'}) {

      my $type = delete $params{'object-type'};

      $obj->set('object-type', _check_prefix($type));
    };

    foreach (keys %params) {
      $obj->add('-' . $_ => $params{$_});
    };

    return $obj;
  }

  # Get target or object
  else {
    my $obj = $self->at($type);

    return unless $obj->[0];

    my $object_type = $obj->children('object-type')->[0];

    # Prepend namespace if not defined
    if (index($object_type->text, '/') == -1) {
      $object_type->content(
	__PACKAGE__->_namespace . lc($object_type->text)
      );
    };

    return $obj;
  };
};


# Prefix relative object types and verbs with
# ActivityStreams namespace
sub _check_prefix {
  if (index($_[0], '/') == -1) {
    return __PACKAGE__->_namespace . lc $_[0];
  };
  return $_[0];
};


1;


__END__

=pod

=head1 NAME

XML::Loy::ActivityStreams - ActivityStreams Extension for Atom


=head1 SYNOPSIS

  # Create new Atom object
  my $atom = XML::Loy::Atom->new('feed');

  # Extend with ActivityStreams
  $atom->extension(-ActivityStreams);

  # New atom entry
  my $entry = $atom->entry(id => 'first_post');

  for ($entry) {

    # Define activity actor
    $_->actor(name => 'Fry');

    # Define activity verb
    $_->verb('loves');

    # Define activity object
    $_->object(
      'object-type' => 'person',
      'name'        => 'Leela'
    )->title('Captain');

    # Set related Atom information
    $_->title(xhtml => 'Fry loves Leela');
    $_->summary("Now it's official!");
    $_->published(time);
  };

  # Retrive verb
  print $entry->verb;

  # Print ActivityStream as XML
  print $atom->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <feed xmlns="http://www.w3.org/2005/Atom"
  #       xmlns:activity="http://activitystrea.ms/schema/1.0/">
  #   <entry xml:id="first_post">
  #     <id>first_post</id>
  #     <author>
  #       <name>Fry</name>
  #       <activity:object-type>http://activitystrea.ms/schema/1.0/person</activity:object-type>
  #     </author>
  #     <activity:verb>http://activitystrea.ms/schema/1.0/loves</activity:verb>
  #     <activity:object>
  #       <activity:object-type>http://activitystrea.ms/schema/1.0/person</activity:object-type>
  #       <name>Leela</name>
  #       <title xml:space="preserve"
  #              xmlns="http://www.w3.org/2005/Atom">Captain</title>
  #     </activity:object>
  #     <title type="xhtml">
  #       <div xmlns="http://www.w3.org/1999/xhtml">Fry loves Leela</div>
  #     </title>
  #     <summary xml:space="preserve">Now it&#39;s official!</summary>
  #     <published>2013-03-08T14:01:14Z</published>
  #   </entry>
  #  </feed>


=head1 DESCRIPTION

L<XML::Loy::ActivityStreams> is an extension
to L<XML::Loy::Atom> and provides additional functionality
for the work with L<Atom ActivityStreams|http://activitystrea.ms/>.

B<This module is an early release! There may be significant changes in the future.>

=head1 METHODS

L<XML::Loy::ActivityStreams> inherits all methods
from L<XML::Loy> and implements the following new ones.


=head2 actor

  my $person = $atom->new_person(
    name => 'Bender',
    uri  => 'acct:bender@example.org'
  );
  my $actor = $atom->actor($person);

  print $atom->actor->at('name')->text;


Sets the actor of the ActivityStreams object or returns it.
Accepts a person construct
(see L<new_person|XML::Loy::Atom/new_person>) or the
parameters accepted by
L<new_person|XML::Loy::Atom/new_person>.


=head2 verb

  $atom->verb('follow');
  print $atom->verb;

Sets the verb of the ActivityStreams object or returns it.
Accepts a verb string.
Relative verbs will be prefixed with the ActivityStreams
namespace.


=head2 object

  $atom->object(
    'object-type' => 'person',
    'displayName' => 'Leela'
  );
  print $atom->object->at('object-type')->text;

Sets object information to the ActivityStreams object
or returns it.
Accepts a hash with various parameters
depending on the object's type. The object's type is
given by the C<object-type> parameter.
Relative object types will be prefixed with the ActivityStreams
namespace.


=head2 target

  $atom->target(
    'object-type' => 'robot',
    'displayName' => 'Bender'
  );
  print $atom->target->at('object-type')->text;

Sets target information to the ActivityStreams object
or returns it.
Accepts a hash with various parameters
depending on the target's type. The target's type is
given by the C<object-type> parameter.
Relative object types will be prefixed with the ActivityStreams
namespace.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 LIMITATIONS

L<XML::Loy::ActivityStreams> has currently no support for
JSON serialization, neither on reading nor writing.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
