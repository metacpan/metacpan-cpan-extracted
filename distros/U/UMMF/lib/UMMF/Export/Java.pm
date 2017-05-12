package UMMF::Export::Java;

use 5.6.1;
use strict;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/03 };
our $VERSION = do { my @r = (q$Revision: 1.15 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Java - A code generator for JavaTemplate.

=head1 SYNOPSIS

  use UMMF::Export::Java;

  my $exporter = UMMF::Export::Java->new('output' => *STDOUT);
  my $exporter->export_Model($model);

=head1 DESCRIPTION

This package allow UML models to be represented as Java code.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 TO DO

=over 4

=item Implement AssociationClass

=back

=head1 AUTHOR

Kurt Stephens, kstephens@sourceforge.net 2003/05/03

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>

=head1 VERSION

$Revision: 1.15 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Export::Template);

#######################################################################

#use UMMF::Core::Util qw(:all);

#######################################################################

sub export_kind { 'Java' }

sub package_sep { '.' }
sub package_file_name_suffix { '.java' }

sub comment_char { ' * '; }

sub package_name
{
  my ($self, $cls, $sep, $cls_scope) = @_;
  
  #
  # In Java, a Class that references its own type,
  # cannot use a fully-qualified name, it must
  # use its short name.
  #
  if ( $cls_scope eq $cls ) {
    $cls = [ $cls->name ];
  }

  $self->SUPER::package_name($cls, $sep, $cls_scope);
}


sub identifier_name_filter
{
  my ($self, $obj, $name) = @_;

  my $prefix_it;

  $prefix_it = grep($name eq $_,
		    'package',
		    'class',
		    'interface',
		    'extends',
		    'implements',
		    'if',
		    'while',
		    'return',
		    'else',
		    'assert',
		    #'byte',
		    #'char',
		    #'short',
		    #'int',
		    #'long',
		    #'float',
		    #'double',
		    );

  $name = "_ummf_$name" if $prefix_it;

  $name;
}


#######################################################################

sub model_filters
{
  qw(
     AssocClassLinks
     AssociationNames 
     FoldMultipleInheritance
     );
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

