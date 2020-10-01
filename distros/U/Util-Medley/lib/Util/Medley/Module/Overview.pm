package Util::Medley::Module::Overview;
$Util::Medley::Module::Overview::VERSION = '0.044';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';
use Module::Overview;
use constant;
use Module::Load;

with
  'Util::Medley::Roles::Attributes::List',
  'Util::Medley::Roles::Attributes::String';

=head1 NAME

Util::Medley::Module::Overview

=head1 VERSION

version 0.044

=cut

=head1 SYNOPSIS

  my $mo = Util::Medley::Module::Overview->new(
      moduleName  => 'My::Module',
      hideModules => [ 'Moose::Object' ],
  );

  foreach my $pm ($mo->getPublicMethods) {
      say $pm;	
  }
    
=cut

########################################################

=head1 DESCRIPTION

This is simply a wrapper for Module::Overview with enhancements.

=cut

########################################################

=head1 ATTRIBUTES

=head2 moduleName (required)

The module you want an overview for.

=over

=item type: Str

=back

=cut

has moduleName => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

=head2 hideModules (optional)

List of modules you want to exclude.

=over

=item type: ArrayRef[Str]

=back

=cut

has hideModules => (
	is  => 'rw',
	isa => 'ArrayRef[Str]',
);

########################################################

has _myAttributes => (
	is      => 'rw',
	isa     => 'ArrayRef',
	lazy    => 1,
	builder => '_buildMyAttributes',
);

has _myMethods => (
	is      => 'rw',
	isa     => 'ArrayRef',
	lazy    => 1,
	builder => '_buildMyMethods',
);

has _myMethodsAndAttributes => (
	is      => 'rw',
	isa     => 'ArrayRef',
	lazy    => 1,
	builder => '_buildMyMethodsAndAttributes',
);

has _myConstants => (
	is      => 'rw',
	isa     => 'ArrayRef',
	lazy    => 1,
	builder => '_buildMyConstants',
);

###

has _inheritedAttributes => (
	is      => 'rw',
	isa     => 'ArrayRef',
	lazy    => 1,
	builder => '_buildInheritedAttributes',
);

has _inheritedMethods => (
	is      => 'rw',
	isa     => 'ArrayRef',
	lazy    => 1,
	builder => '_buildInheritedMethods',
);

has _inheritedMethodsAndAttributes => (
	is      => 'rw',
	isa     => 'ArrayRef',
	lazy    => 1,
	builder => '_buildInheritedMethodsAndAttributes',
);

###

has _moduleOverview => (
	is      => 'ro',
	isa     => 'HashRef',
	builder => '_buildModuleOverview',
);

has _mooseMetaCache => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { {} }
);

has _classTypeCache => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { {} }
);

########################################################

=head1 METHODS

=head2 getImportedModules
    
Returns a list of modules used by the module.

=cut

method getImportedModules {

	my $mo = $self->_moduleOverview;

	my @imported;
	if ( $mo->{uses} ) {
		@imported = @{ $mo->{uses} };
	}

	return $self->List->nsort(@imported);
}

=head2 getParents

Returns a list of parent modules.

=cut

method getParents {

	my $mo = $self->_moduleOverview;

	my @parents;
	if ( $mo->{parents} ) {
		push @parents, @{ $mo->{parents} };
	}

	if ( $mo->{classes} ) {
		push @parents, @{ $mo->{classes} };
	}

	return @parents;
}

=head2 getConstants

Returns a list of constants.

=cut

method getConstants {

	return @{ $self->_getMyConstants };
}

=head2 getAllPublicAttributes

Combines and sorts the results from getPublicAttributes() and  
getInheritedPublicAttributes().

=cut

method getAllPublicAttributes {

	my @all = $self->getPublicAttributes;
	push @all, $self->getInheritedPublicAttributes;

	#
	# build a map
	#
	my %map;
	foreach my $aref (@all) {
		$map{ $aref->[0] } = [@$aref];
	}

	#
	# get a sorted list of map keys
	#
	my @keys = $self->List->nsort( keys %map );

	#
	# prepare sorted list of arrayrefs
	#
	my @sorted;
	foreach my $key (@keys) {
		push @sorted, $map{$key};
	}

	return @sorted;    # Array[ArrayRef]
}

=head2 getPublicAttributes

Returns a list of public attributes.  Each item in the list is an ArrayRef
of [ name, src ].

=cut

method getPublicAttributes {

	my $modname = $self->moduleName;
	my $meta    = $modname->meta();

	my @public;
	foreach my $name ( @{ $self->_getMyAttributes } ) {

		next if $name =~ /^_/;

		my $from = 'this';
		my $attr = $meta->get_attribute($name);
		if ( $attr->has_role_attribute ) {
			$from = $attr->{definition_context}->{package};
		}

		my $aref = [ $name, $from ];    # convert to aref and add empty source
		push @public, $aref;
	}

	return @public;
}

=head2 getInheritedPublicAttributes

Returns a list of inherited public attributes.  Each item in the list is an 
ArrayRef of [ name, src ]. 

=cut

method getInheritedPublicAttributes {

	my @public;
	foreach my $attr ( @{ $self->_getInheritedAttributes } ) {

		my ( $name, $from ) = @$attr;
		if ( $name !~ /^_/ ) {
			push @public, $attr;
		}
	}

	return @public;
}

=head2 getPrivateAttributes

Returns a list of private attributes.  Each item in the list is an ArrayRef
of [ name, src ].

=cut

method getPrivateAttributes {

	my @private;
	foreach my $attr ( @{ $self->_getMyAttributes } ) {

		if ( $attr =~ /^_/ ) {
			push @private, $attr;
		}
	}

	return @private;
}

=head2 getInheritedPrivateAttributes

Returns a list of inherited private attributes.  Each item in the list 
is an ArrayRef of [ name, src ].

=cut

method getInheritedPrivateAttributes {

	my @private;
	foreach my $aref ( @{ $self->_getInheritedAttributes } ) {

		my ( $name, $from ) = @$aref;
		if ( $name =~ /^_/ ) {
			push @private, [@$aref];
		}
	}

	return @private;
}

=head2 getAllPublicMethods

Combines and sorts the results from getPublicMethods() and  
getInheritedPublicMethods().

=cut

method getAllPublicMethods {

	my @all = $self->getPublicMethods;
	push @all, $self->getInheritedPublicMethods;

	#
	# build a map
	#
	my %map;
	foreach my $aref (@all) {
		$map{ $aref->[0] } = $aref;
	}

	#
	# get a sorted list of map keys
	#
	my @keys = $self->List->nsort( keys %map );

	#
	# prepare sorted list of arrayrefs
	#
	my @sorted;
	foreach my $key (@keys) {
		push @sorted, $map{$key};
	}

	return @sorted;    # Array[ArrayRef]
}

=head2 getPublicMethods

Returns a list of public methods.  Each item in the list is an ArrayRef
of [ name, src ].

=cut

method getPublicMethods {

	my $meta;
	my @public;

	foreach my $name ( @{ $self->_getMyMethods } ) {

		# moose objects seems to end up with a public method called meta()
		# here we skip it if we encounter it.
		my $scrubbed = $self->_scrubParens($name);
		if ( $scrubbed ne 'meta' ) {

			next if $scrubbed =~ /^_/;

			my $from = 'this';

			if ( $self->isMooseModule ) {
				$meta = $self->moduleName->meta if !$meta;

				my $method = $meta->get_method($scrubbed);

				my $srcPkg = $method->original_package_name;
				if ( $srcPkg ne $self->moduleName ) {
					$from = $method->original_package_name;
				}
			}

			push @public, [ $scrubbed, $from ];
		}
	}

	return @public;
}

=head2 getInheritedPublicMethods

Returns a list of inherited public methods.  Each item in the list is an 
ArrayRef of [ name, src ].

=cut

method getInheritedPublicMethods {

	my @public;
	foreach my $aref ( @{ $self->_getInheritedMethods } ) {

		my ( $method, $from ) = @$aref;
		next if $from eq 'Moose::Object';
		next if $method =~ /^_/;

		push @public, [@$aref];
	}

	return @public;
}

=head2 getPrivateMethods

Returns a list of private methods.  Each item in the list is an ArrayRef
of [ name, src ].

=cut

method getPrivateMethods {

	my @private;
	foreach my $method ( @{ $self->_getMyMethods } ) {
		if ( $method =~ /^_/ ) {
			push @private, $method;
		}
	}

	return @private;
}

=head2 getInheritedPrivateMethods

Returns a list of inherited private methods.  Each item in the list is an 
ArrayRef of [ name, src ].

=cut

method getInheritedPrivateMethods {

	my @private;
	foreach my $aref ( @{ $self->_getInheritedMethods } ) {
		my ( $method, $from ) = @$aref;
		if ( $method =~ /^_/ ) {
			push @private, [@$aref];
		}
	}

	return @private;
}

method isMooseModule (Str $module?) {

	$module = $self->moduleName if !$module;
	load($module);

	my $c = $self->_classTypeCache;
	if ( !defined $c->{$module} ) {

		if ( $module->isa('Moose::Object') ) {
			$c->{$module} = 'moose';
		}
		else {
			$c->{$module} = 'notmoose';
		}
	}

	if ( $c->{$module} eq 'moose' ) {
		return 1;
	}

	return 0;
}

##############################################################

method _parseMethods (ArrayRef $aref) {

	my @parsed;
	foreach my $method (@$aref) {
		my ( $name, $from ) = split( /\s+/, $method );
		if ($from) {
			$from =~ s/\[//;
			$from =~ s/\]//;
		}

		push @parsed, [ $name, $from ];
	}

	return @parsed;
}

method _buildModuleOverview {

	my $mo   = Module::Overview->new( { module_name => $self->moduleName } );
	my $href = $mo->get( $self->moduleName );

	return $href;
}

method _isConstant (Str $pkg!,
                    Str $method!) {

	$method =~ s/\(\)//;    # remove parens;
	my $fullName = sprintf '%s::%s', $pkg, $method;

	if ( $constant::declared{$fullName} ) {
		return 1;
	}
	elsif ( $self->String->isUpper($method) ) {
		return 1;
	}

	return 0;
}

method _scrubParens (Str $value) {

	$value =~ s/\(\)//;
	return $value;
}

method _getInheritedMethods (--> ArrayRef) {

	return $self->_inheritedMethods;
}

method _getInheritedAttributes (--> ArrayRef) {

	return $self->_inheritedAttributes;
}

method _getMyMethods (--> ArrayRef) {

	return $self->_myMethods;
}

method _getMyConstants {

	return $self->_myConstants;
}

method _buildMyConstants {

	my @constants;

	foreach my $name ( @{ $self->_getMyMethodsAndAttributes } ) {
		
		if ( $self->_isConstant( $self->moduleName, $name ) ) {
			push @constants, $self->_scrubParens($name);
		}
	}

	return \@constants;
}

method _buildInheritedMethods {

	my @methods;

	foreach my $aref ( @{ $self->_getInheritedMethodsAndAttributes } ) {

		my ( $name, $from ) = @$aref;
		next if $self->_isConstant( $from, $name );
		next if $self->_isMooseAttribute( $from, $name );

		push @methods, $aref;
	}

	return \@methods;
}

method _buildInheritedAttributes {

	my @attr;

	foreach my $aref ( @{ $self->_getInheritedMethodsAndAttributes } ) {

		my ( $name, $from ) = @$aref;
		$name = $self->_scrubParens($name);

		next if $self->_isConstant( $from, $name );
		next if !$self->_isMooseAttribute( $from, $name );

		push @attr, [ $name, $from ];
	}

	return \@attr;
}

method _buildMyMethods {

	my @methods;

	foreach my $name ( @{ $self->_getMyMethodsAndAttributes } ) {

		if ( !$self->_isConstant( $self->moduleName, $name ) ) {
			if ( $self->isMooseModule ) {

				my $bool = $self->_isMooseAttribute( $self->moduleName, $name );
				if ( !$bool ) {
					push @methods, $name;
				}
			}
			else {
				push @methods, $name;
			}
		}
	}

	return \@methods;
}

method _getMooseMeta (Str $module) {

	if ( $self->isMooseModule($module) ) {

		my $c = $self->_mooseMetaCache;
		if ( !$c->{$module} ) {
			$c->{$module} = $module->meta;
		}

		return $c->{$module};
	}
}

method _isMooseAttribute (Str $module!,
                          Str $name!
                          -->  Bool) {

	$name = $self->_scrubParens($name);

	my $meta = $self->_getMooseMeta($module);
	if ($meta) {

		foreach my $attr ( $meta->get_all_attributes ) {
			if ( $attr->name eq $name ) {
				return 1;
			}
		}
	}

	return 0;
}

method _getMyAttributes (--> ArrayRef) {

	return $self->_myAttributes;
}

method _buildMyAttributes {

	my @attr;

	if ( $self->isMooseModule ) {

		foreach my $name ( @{ $self->_getMyMethodsAndAttributes } ) {

			my $bool = $self->_isMooseAttribute( $self->moduleName, $name );
			if ($bool) {
				push @attr, $self->_scrubParens($name);
			}
		}
	}

	return \@attr;
}

method _getInheritedMethodsAndAttributes {

	return $self->_inheritedMethodsAndAttributes;
}

method _getMyMethodsAndAttributes {

	return $self->_myMethodsAndAttributes;
}

=pod

method _buildMyMethodsAndAttributes {

	my $mo = $self->_moduleOverview;

	my @methods;
	push @methods, @{ $mo->{methods} }          if $mo->{methods};
    push @methods, @{ $mo->{methods_imported} } if $mo->{methods_imported};

	my @sorted = $self->List->nsort(@methods);
	my @parsed = $self->_parseMethods( \@sorted );

	my @mine;
	foreach my $aref (@parsed) {
		my ( $name, $from ) = @$aref;
		if ( !$from ) {
			push @mine, $name;
		}
	}

	return \@mine;
}

=cut

method _buildMyMethodsAndAttributes {

	my $mo = $self->_moduleOverview;

	my @methods;
	push @methods, @{ $mo->{methods} }          if $mo->{methods};
	push @methods, @{ $mo->{methods_imported} } if $mo->{methods_imported};

	my @sorted = $self->List->nsort(@methods);
	my @parsed = $self->_parseMethods( \@sorted );

	my @mine;
	foreach my $aref (@parsed) {
		my ( $name, $from ) = @$aref;

		if ( !$from ) {
			my $module = $self->_isImportedSub($name);
			if ( !$module ) {
				push @mine, $name;
			}
		}
	}

	return \@mine;
}

method _getModuleExports (Str $moduleName) {

	my @exports;

	if ( $moduleName->isa('Exporter') ) {

		# TODO: this could be improved by testing for exactly
		# what is imported.  For now, just assumes subs in
		# EXPORT_OK were imported.
		no strict 'refs';
		push @exports, @{ sprintf '%s::EXPORT',    $moduleName };
		push @exports, @{ sprintf '%s::EXPORT_OK', $moduleName };
		@exports = $self->List->uniq(@exports);
	}

	return @exports;
}

method _isImportedSub (Str $subName) {

	$subName = $self->_scrubParens($subName);

	foreach my $use ( $self->getImportedModules ) {

		my @exports = $self->_getModuleExports($use);
		my %map     = $self->List->listToMap(@exports);

		if ( $map{$subName} ) {
			return $use;
		}
	}

	return;
}

method _buildInheritedMethodsAndAttributes {

	my $mo = $self->_moduleOverview;

	my @methods;
	push @methods, @{ $mo->{methods} }          if $mo->{methods};
	push @methods, @{ $mo->{methods_imported} } if $mo->{methods_imported};

	my @sorted = $self->List->nsort(@methods);
	my @parsed = $self->_parseMethods( \@sorted );

	my @inherited;
	foreach my $aref (@parsed) {
		my ( $name, $from ) = @$aref;
		if ($from) {
			push @inherited, [@$aref];
		}
		else {
			my $module = $self->_isImportedSub($name);
			if ($module) {
				push @inherited, [ $name, $module ];
			}
		}
	}

	if ( $self->hideModules ) {

		my %map = $self->List->listToMap( @{ $self->hideModules } );

		my @pruned;
		foreach my $aref (@inherited) {
			my ( $name, $from ) = @$aref;
			if ( !$map{$from} ) {
				push @pruned, [@$aref];
			}
		}

		@inherited = @pruned;
	}

	return \@inherited;
}

1;
