{

=head1 NAME

XML::Filter::XML_Directory_Pruner - SAX2 filter for restricting the output of the XML::Directory::SAX

=head1 SYNOPSIS

 use XML::SAX::Writer;
 use XML::Directory::SAX;
 use XML::Filter::XML_Directory_Pruner;

 my $output = "";

 my $writer = XML::SAX::Writer->new(Output=>\$output);
 my $pruner = XML::Filter::XML_Directory_Pruner->new(Handler=>$writer);

 $pruner->exclude(matching=>["(.*)\\.ph\$"]);
 $pruner->include(ending=>[".pm"]);

 my $directory = XML::Directory::SAX->new(Handler => $pruner,
                                          detail  => 2,
                                          depth   => 1);

 $directory->parse_dir($INC[0]);

=head1 DESCRIPTION

XML::Filter::XML_Directory_Pruner is a SAX2 filter for restricting the output of the XML::Directory::SAX handler.

=cut

package XML::Filter::XML_Directory_Pruner;
use strict;

use Exporter;
use XML::SAX::Base;
use MIME::Types;

$XML::Filter::XML_Directory_Pruner::VERSION   = '1.3';
@XML::Filter::XML_Directory_Pruner::ISA       = qw (Exporter XML::SAX::Base);
@XML::Filter::XML_Directory_Pruner::EXPORT    = qw ();
@XML::Filter::XML_Directory_Pruner::EXPORT_OK = qw ();

my %__typeof = ();
my $__mtypes = undef;

=head1 PACKAGE METHODS 

=head2 __PACKAGE__->mtype($file)

Return the media type, as defined by the I<MIME::Types> package, associated with I<$file>.

=cut

sub mtype {
  my $pkg   = shift;
  my $fname = shift;

  #

  $fname =~ /^(.*)\.([^\.]+)$/;
  if (! $2) { return undef; }

  if (exists($__typeof{$2})) {
    return $__typeof{$2};
  }

  $__mtypes ||= MIME::Types->new()
    || return undef;


  #

  my $mime = $__mtypes->mimeTypeOf($2);
  
  if (! $mime) {
    $__typeof{$2} = undef;
    return $__typeof{$2};
  }
  
  #

  $__typeof{$2} = $mime->mediaType();
  return $__typeof{$2};
}

=head1 OBJECT METHODS

=head2 $pkg = __PACKAGE__->new()

Inherits from I<XML::SAX::Base>

=head2 $pkg->include(%args)

Include *only* that files that match either the starting or ending pattern.

Valid arguments are 

=over

=item *

B<include>

Array ref.

=item *

B<matching>

Array ref. One or more regular expressions.

I<note that when this expression is compared, leaning toothpicks (e.g. : /$pattern/) are provided for you.>

In earlier releases, only a string was expected. Newer releases are backward compatible.

=item *

B<starting>

Array ref.

=item *

B<ending>

Array ref.

=back

=cut

sub include {
    my $self = shift;
    my $args = { @_ };

    if (ref($args->{'include'})  eq "ARRAY") {
      push (@{$self->{__PACKAGE__.'__include'}},@{$args->{'include'}});
    }

    if ($args->{'matching'}) {
      $self->{__PACKAGE__.'__include_matching'} = (ref($args->{'matching'} eq "ARRAY")) ? 
	$args->{'matching'} : [$args->{'matching'}];
    }

    if (ref($args->{'starting'}) eq "ARRAY") {
      push (@{$self->{__PACKAGE__.'__include_starting'}},@{$args->{'starting'}});
    }

    if (ref($args->{'ending'}) eq "ARRAY") {
	push (@{$self->{__PACKAGE__.'__include_ending'}},@{$args->{'ending'}});
    }

    if ($args->{'directories'}) {
      $self->{__PACKAGE__.'__include_subdirs'} = 1;
    }

    return 1;
}

=head2 $pkg->exclude(%args)

Exclude files with a particular name or pattern from being included in the directory listing.

Valid arguments are

=over

=item *

B<exclude>

Array ref.

=item *

B<matching>

Array ref. One or more regular expressions.

I<note that when this expression is compared, leaning toothpicks (e.g. : /$pattern/) are provided for you.>

In earlier releases, only a string was expected. Newer releases are backward compatible.

=item *

B<starting>

Array ref.

=item *

B<ending>

Array ref.

=item * 

B<directories>

Boolean. Default is false.

B<files>

Boolean. Default is false.

=back

=cut

sub exclude {
    my $self = shift;
    my $args  = { @_ };

    if (ref($args->{'exclude'})  eq "ARRAY") {
      push (@{$self->{__PACKAGE__.'__exclude'}},@{$args->{'exclude'}});
    }

    if ($args->{'matching'}) {
      $self->{__PACKAGE__.'__exclude_matching'} = (ref($args->{'matching'}) eq "ARRAY") ? 
	$args->{'matching'} : [ $args->{'matching'}];
    }

    if (ref($args->{'starting'}) eq "ARRAY") {
      push (@{$self->{__PACKAGE__.'__exclude_starting'}},@{$args->{'starting'}});
    }

    if (ref($args->{'ending'})   eq "ARRAY") {
      push (@{$self->{__PACKAGE__.'__exclude_ending'}},@{$args->{'ending'}});
    }

    $self->{__PACKAGE__.'__exclude_subdirs'} = $args->{'directories'};
    $self->{__PACKAGE__.'__exclude_files'}   = $args->{'files'};
    return 1;
}

=head2 $pkg->ima($what)

=cut

sub ima {
  my $self = shift;
  my $what = shift;

  if ($what) {
    $self->{__PACKAGE__.'__ima'} = $what;
  }

  return $self->{__PACKAGE__.'__ima'};
}

=head2 $pkg->current_level()

Read-only.

=cut

sub current_level {
  my $self = shift;
  return $self->{__PACKAGE__.'__level'};
}

=head2 $pkg->skip_level()

=cut

sub skip_level {
  return $_[0]->{__PACKAGE__.'__skip'};
}

=head2 $pkg->debug($int)

Read/write debugging flags.

By default, the package watches and performs actions if the debug level is greater than or equal to :

=over

=item *

I<1>

Nothing.

=item *

I<2>

Prints to STDERR the type, name and level of the current element.

=item *

I<3>

Prints to STDERR the results of checks in $pkg->_compare()

=back

=cut

sub debug {
  my $self = shift;
  my $debug = shift;

  if (defined($debug)) {
    $self->{__PACKAGE__.'__debug'} = ($debug) ? (int($debug)) ? $debug : 1 : 0;
  }

  return $self->{__PACKAGE__.'__debug'};
}

=head1 PRIVATE METHODS

=head2 $pkg->start_element($data)

=cut

sub start_element {
  my $self  = shift;
  my $data  = shift;

  $self->on_enter_start_element($data);
  $self->compare($data);

  unless ($self->{__PACKAGE__.'__skip'}) {
    $self->{__PACKAGE__.'__last'} = $data->{'Name'};
    $self->SUPER::start_element($data);
  }

  return 1;
}

sub on_enter_start_element {
  my $self = shift;
  my $data = shift;

  $self->{__PACKAGE__.'__level'} ++;

#  if ($data->{Name} =~ /^(directory|file)$/) {
#    $self->{__PACKAGE__.'__'.$1} ++;
#    map { print " "; } (0..$self->{__PACKAGE__.'__'.$1});
#    print $self->{__PACKAGE__.'__'.$1} ." [$1] $data->{Attributes}->{'{}name'}->{Value} ".__PACKAGE__."\n";
#  }

  if ($self->debug() >= 2) {
    map { print STDERR " "; } (0..$self->current_level);
    print STDERR "[".$self->current_level."] $data->{Name} : ";
    # Because sometimes auto-vivification
    # is not what you want.
    if (exists($data->{Attributes}->{'{}name'})) {
      print STDERR $data->{Attributes}->{'{}name'}->{Value};
    }

    print STDERR "\n";
  }

  return 1;
}

=head2 $pkg->end_element($data)

=cut

sub end_element {
  my $self = shift;
  my $data = shift;

  unless ($self->{__PACKAGE__.'__skip'}) {
    $self->SUPER::end_element($data);
  }

  $self->on_exit_end_element($data);
  return 1;
}

=head2 $pkg->_on_exit_end_element()

=cut

sub on_exit_end_element {
  my $self = shift;
  my $data = shift;

  if ($self->{__PACKAGE__.'__skip'} == $self->{__PACKAGE__.'__level'}) {
    $self->{__PACKAGE__.'__skip'} = 0;
  }

  if ($data->{Name} =~ /^(directory|file)$/) {
    $self->{__PACKAGE__.'__'.$1} --;
  }

  $self->{__PACKAGE__.'__level'} --;
  return 1;
}

=head2 $pkg->characters($data)

=cut

sub characters {
  my $self = shift;
  my $data = shift;

  unless ($self->{__PACKAGE__.'__skip'}) {
    $self->SUPER::characters($data);
  }
  
  return 1;
}

=head2 $pkg->compare(\%data)

=cut

sub compare {
  my $self = shift;
  my $data = shift;

  if ($data->{'Name'} =~ /^(file|directory)$/) {
    # map { print " "; } (0..$self->{__PACKAGE__.'__'.$1});
    # print $self->{__PACKAGE__.'__'.$1} ." <$1> $data->{Attributes}->{'{}name'}->{Value} ($self->{__PACKAGE__.'__skip'})\n";

    if (! $self->{__PACKAGE__.'__skip'}) {
      $self->{__PACKAGE__.'__ima'} = $1;
      $self->_compare($data->{Attributes}->{'{}name'}->{Value});
    }
  }

  return 1;
}

=head2 $pkg->_compare($data)

=cut

sub _compare {
  my $self = shift;
  my $data = shift;

  my $ok = 1;

  # Note the check on __level. We have to do
  # this, so that filtering the output for
  # /foo/bar won't fail with :
  #
  # 101 ->./dir-machine
  # 1 dirtree
  #  2 head
  #   3 path
  #   3 details
  #   3 depth
  # Comparing 'bar' (directory)...failed directory test...'0' (2)

  if ($self->{__PACKAGE__.'__level'} == 2) { return 1; }

  #

  if ($self->{__PACKAGE__.'__ima'} eq "directory") {
    if (($ok) && ($self->{__PACKAGE__.'__exclude_subdirs'})) {
      print STDERR "10 - EXCLUDING $data BECAUSE I AM A DIRECTORY\n"
	if ($self->debug() >= 3);
      $ok = 0;
    }
  }

  if (($ok) && ($self->{__PACKAGE__.'__ima'} eq "file" && $self->{__PACKAGE__.'__exclude_files'})) {
    print STDERR "20 - EXCLUDING $data BECAUSE I AM A FILE\n"
      if ($self->debug() >= 3);
    $ok = 0;
  }

  #

  if (($ok) && ($self->{__PACKAGE__.'__include_matching'} eq "ARRAY")) {
    foreach my $pattern (@{$self->{__PACKAGE__.'__include_matching'}}) {
      $ok = ($data =~ /$pattern/) ? 1 : 0;

      if ($ok) {
	print STDERR "20 - INCLUDING $data BECAUSE IT MATCHES PATTERN '$pattern'\n"
	  if ($self->debug() >= 3);
	last;
      }
    }
  }

  if (($ok) && (ref($self->{__PACKAGE__.'__include'}) eq "ARRAY")) {
    foreach my $match (@{$self->{__PACKAGE__.'__include'}}) {
      $ok = ($data =~ /^($match)$/) ? 0 : 1;

      if ($ok) {
	print STDERR "30 - INCLUDING $data BECAUSE IT MATCHES '$match'\n"
	  if ($self->debug() >= 3);
	last;
      }
    }
  }

  if (($ok) && (ref($self->{__PACKAGE__.'__include_starting'}) eq "ARRAY")) {
    foreach my $match (@{$self->{__PACKAGE__.'__include_starting'}}) {
      $ok = ($data =~ /^($match)(.*)$/) ? 1 : 0;

      if ($ok) {
	print STDERR "40 - INCLUDING $data BECAUSE IT STARTS WITH '$match'\n"
	  if ($self->debug() >= 3);
	last;
      }
    }
  }

  if (($ok) && (ref($self->{__PACKAGE__.'__include_ending'}) eq "ARRAY")) {
    foreach my $match (@{$self->{__PACKAGE__.'__include_ending'}}) {
      $ok = ($data =~ /^(.*)($match)$/) ? 1 : 0;

      if ($ok) {
	print STDERR "50 - INCLUDING $data BECAUSE IT ENDS WITH '$match'\n"
	  if ($self->debug() >= 3);
	last;
      }
    }
  }

  #

  if (($ok) &&(ref($self->{__PACKAGE__.'__exclude_matching'}) eq "ARRAY")) {

    foreach  my $pattern (@{$self->{__PACKAGE__.'__exclude_matching'}}) {

      print STDERR "25 - COMPARING '$data' w/ '$pattern'\n"
	if ($self->debug() >= 4);

      $ok = ($data =~ /$pattern/) ? 0 : 1;

      if (! $ok) {
	print STDERR "30 - EXCLUDING $data BECAUSE IT MATCHES PATTERN '$pattern'\n"
	  if ($self->debug() >= 3);

	last;
      }
    }
  }

  if (($ok) && (ref($self->{__PACKAGE__.'__exclude'}) eq "ARRAY")) {
    foreach my $match (@{$self->{__PACKAGE__.'__exclude'}}) {
      $ok = ($data =~ /^($match)$/) ? 0 : 1;

      if (! $ok) {
	print STDERR "40 - EXCLUDING $data BECAUSE IT MATCHES '$match'\n"
	  if ($self->debug() >= 3);
	last;
      }
    }
  }

  if (($ok) && (ref($self->{__PACKAGE__.'__exclude_starting'}) eq "ARRAY")) {
    foreach my $match (@{$self->{__PACKAGE__.'__exclude_starting'}}) {
      $ok = ($data =~ /^($match)(.*)$/) ? 0 : 1;

      if (! $ok) {
	print STDERR "50 - EXCLUDING $data BECAUSE IT STARTS WITH '$match'\n"
	  if ($self->debug() >= 3);
	last;
      }
    }
  }

  if (($ok) && (ref($self->{__PACKAGE__.'__exclude_ending'}) eq "ARRAY")) {
    foreach my $match (@{$self->{__PACKAGE__.'__exclude_ending'}}) {
      $ok = ($data =~ /^(.*)($match)$/) ? 0 : 1;

      if (! $ok) {
	print STDERR "60 - EXCLUDING $data BECAUSE IT ENDS WITH '$match'\n"
	  if ($self->debug() >= 3);
	last;
      }
    }
  }

  #

  if (! $ok) {
    print STDERR "SKIPPING '$data' at $self->{__PACKAGE__.'__level'}\n"
      if ($self->debug() >= 2);

    $self->{__PACKAGE__.'__skip'} = $self->{__PACKAGE__.'__level'};
  }

  return 1;
}


=head1 VERSION

1.3

=head1 DATE

July 20, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over

=item *

Allow for inclusion/exclusion based on MIME and/or media type

=back

=head1 SEE ALSO

L<XML::Directory::SAX>

L<XML::SAX::Base>

L<MIME::Types>

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
