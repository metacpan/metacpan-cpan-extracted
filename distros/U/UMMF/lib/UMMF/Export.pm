package UMMF::Export;

use 5.6.0;
use strict;
use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/15 };
our $VERSION = do { my @r = (q$Revision: 1.22 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export - Base exporter class for UMMF::Core::MetaModel;

=head1 SYNOPSIS

  use base qw(UMMF::Export::...);
  my $code = UMMF::Export::...->new(...);
  $code->export_Model($model);

=head1 DESCRIPTION

This package allow UML models and meta-models to be exported, to XMI or other implementation languages.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/15

=head1 SEE ALSO

L<UMMF::Core::MetaModel|UMMF::Core::MetaModel>

=head1 VERSION

$Revision: 1.22 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Configurable);

#######################################################################

use UMMF::Core::Util qw(:all);
use IO::Handle; # *STDOUT below.
use Carp qw(confess);

#######################################################################


sub initialize
{
  my ($self) = @_;
  
  $self->SUPER::initialize;

  $self->{'output'} ||= *STDOUT;
  $self->{'output'} = UMMF::Export::EvalIO->new()
  if ( $self->{'output'} eq 'EVAL' );

  $self->{'packagePrefix'} ||= [ ];

  $self;
}



#######################################################################


sub export_Model
{
  my ($self, $model) = @_;

  # Filter the model.
  $model = $self->model_filter($model);

  # Generate code for each class.
  eval {
    #$DB::single = 1;
    for my $cls ( Namespace_interface($model) ) {
      $self->export_Interface($cls);
      $self->{'output'}->flush;
    }
    for my $cls ( Namespace_class($model) ) {
      $self->export_Class($cls);
      $self->{'output'}->flush;
    }
    for my $cls ( Namespace_associationClass($model) ) {
      $self->export_AssociationClass($cls);
      $self->{'output'}->flush;
    }
    for my $cls ( Namespace_enumeration($model) ) {
      $self->export_Enumeration($cls);
      $self->{'output'}->flush;
    }

    delete $self->{'.attr'};
    delete $self->{'.oper'};
    delete $self->{'.literal'};
  };
  if ( $@ ) {
    die("While generating Model:\n$@");
  }

  #print STDERR "\n# DONE!\n";
  $self;
}




#######################################################################


sub model_filters
{
  ();
}

sub model_filter
{
  my ($self, $model) = @_;;
 
  my @filters = $self->model_filters;

  if ( @filters ) {
    $model = Model_clone($model);

    for my $filter ( @filters ) {
      unless ( ref($filter) ) {
	$filter = "UMMF::XForm::$filter" unless $filter =~ /::/;
	eval "use $filter;"; die if $@;
	$filter = $filter->new('verbose' => 0);
      }

      print STDERR "Export: Applying filter: " . ref($filter) . "\n";
      $model = $filter->apply_Model($model);
      print STDERR "Export: Applying filter: " . ref($filter) . ": DONE\n";
    }

  }

  $model;
}

#######################################################################


sub export_Interface
{
  my ($self, $cls) = @_;

  confess(ref($self) . "->export_Interface(): not implemented");
}


sub export_Class
{
  my ($self, $cls) = @_;

  confess(ref($self) . "->export_Class(): not implemented");
}


sub export_AssociationClass
{
  my ($self, $cls) = @_;

  confess(ref($self) . "->export_AssociationClass(): not implemented");
}


sub export_Enumeration
{
  my ($self, $cls) = @_;

  confess(ref($self) . "->export_Enumeration(): not implemented");
}


#######################################################################



=head2 attribute

Returns a list of Attributes of a Classifier.

=cut
sub attribute
{
  my ($self, $cls) = @_;

  my $x = $self->{'.attr'}{$cls} ||= 
  [
   Classifier_attribute($cls),
   ];

  wantarray ? @$x : $x;
}


=head2 operation

Returns a list of Operations of a Classifier.

=cut
sub operation
{
  my ($self, $cls) = @_;

  my $x = $self->{'.oper'}{$cls} ||= 
  [
   Classifier_operation($cls),
   ];

  wantarray ? @$x : $x;
}


=head2 method

Returns a list of Methods of a Classifier.

=cut
sub method
{
  my ($self, $cls) = @_;

  my $x = $self->{'.meth'}{$cls} ||= 
  [
   Classifier_method($cls),
   ];

  wantarray ? @$x : $x;
}


=head2 enumerationLiteral

Returns a list of EnumerationLiterals of an Enumeration.

=cut
sub enumerationLiteral
{
  my ($self, $cls) = @_;

  my $x = $self->{'.literal'}{$cls} ||= $cls->literal;

  wantarray ? @$x : $x;
}


#######################################################################

sub export_enabled
{
  my ($self, @args) = @_;

  $self->config_enabled(@args);
}


sub export_value
{
  my ($self, @args) = @_;

  $self->config_value(@args);
}


sub export_value_inherited
{
  my ($self, @args) = @_;

  $self->config_value_inherited(@args);
}


sub export_value_true
{
  my ($self, @args) = @_;

  $self->config_value_true(@args);
}


sub export_value_inherited_true
{
  my ($self, @args) = @_;

  $self->config_value_inherited_true(@args);
}


sub export_kind
{
  my ($self) = @_;

  confess(ref($self) . "->export_kind(): not implemented");
}


sub config_kind
{
  $_[0]->export_kind;
}


#######################################################################


sub package_sep
{
  my ($self) = @_;

  confess(ref($self) . "->package_sep(): not implemented");
}


sub package_name
{
  my ($self, $cls, $sep, $cls_scope) = @_;
  
  shift @_; # eat $self from @_.

  $sep ||= $self->package_sep;

  my @x;
  if ( ref($cls) eq 'ARRAY' ) {
    @x = @$cls;
  } else { 
    @x = (
	  ref($self->{'packagePrefix'}) ? @{$self->{'packagePrefix'}} : $self->{'packagePrefix'},
	  ModelElement_name_qualified($cls, 
				      undef, # No separator
				      sub {  # Use package_name_filter
					$self->package_name_filter(@_)
				      },
				     ),
	  );
  }

  # Incase ModelElement names have spaces or other junk chars, 
  # which appears to be possible.
  # Perl doesn't like spaces in identifiers.
  # Neither does any other implementation language I can think of.
  grep(s/[^a-z0-9_]/_/sgi, @x);

  my $x = join($sep, @x);
  
  $x;  
}


=head1 package_name_filter

  $name = $self->package_name_filter($obj, $name);

Transforms a ModelElement's C<$obj> name into something appropriate for the
exporter's target language.

Subclasses may override this.

=cut
sub package_name_filter
{
  my ($self, $obj, $name) = @_;

  $self->identifier_name_filter($obj, $name);
}


=head1 identifer_name_filter

  $name = $self->package_name_filter($obj, $name);

Transforms a ModelElement's C<$obj> name into something appropriate for the
exporter's target language.

Subclasses may override this.

=cut
sub identifier_name_filter
{
  my ($self, $obj, $name) = @_;

  $name;
}


#######################################################################


sub comment_char
{
  my ($self) = @_;

  confess(ref($self) . "->comment_char(): not implemented");
}


sub package_file_name_sep { '/' }

sub package_file_name_suffix 
{
  my ($self) = @_;

  confess(ref($self) . "->package_file_name_suffix(): not implemented");
}


sub package_dir_name
{
  my ($self, $package) = @_;

  # If it package path or an object,
  # convert to package name with '::' sep.
  if ( ref($package) ) {
    $package = $self->package_name($package, '::');
  }

  my $file = $package;
  my $sep = $self->package_file_name_sep;
  $file =~ s/::/$sep/sge;
  
  $file;
}


sub package_file_name
{
  my ($self, $package) = @_;

  my $file = $self->package_dir_name($package);
  $file .= $self->package_file_name_suffix;
  
  $file;
}


#######################################################################

package UMMF::Export::EvalIO;


sub new
{
  my ($self, %opts) = @_;
  $self = bless(\%opts, ref($self) || $self);
  $self->__initialize;
}


sub __initialize
{
  my ($self) = @_;

  $self->{'code'} ||= '';
  #$self->{'debug'} = 0;

  $self;
}


sub print
{
  my ($self, @args) = @_;

  $self->{'code'} .= join('', @args);

  1;
}


sub close
{
  shift->flush;
}


sub __linenos
{
  my ($c) = @_;

  my $line = 0;

  $c = join("\n",
	    map(sprintf("%-4d ", ++ $line) . $_,
		split("\n", $c, 99999),
		),
	    '',
	    );
  my $sep = '#-' x 40;
  $c = "$sep\n$c$sep\n";

  $c;
}


sub flush 
{
  my ($self) = @_;

  my $code = $self->{'code'};
  $self->{'code'} = '';

  if ( 1 ) {
    $code =~ /^.*\n.*\n(.*\n).*\n/;
    my $package = $1;
    print STDERR $package;
    if ( 0 && $package =~ /Classifier|ModelElement|Integer|String|Name|Kind/ ) {
      print STDERR $code;
      $DB::single = 1;
    }
  }

  eval($code);
  if ( $@ ) {
    $code = __linenos($code);
    die "$code\nin eval of code above:\n$@";
  }
  if ( $self->{'debug'} ) {
    print STDERR __linenos($code);
  }


  1;
}

#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

