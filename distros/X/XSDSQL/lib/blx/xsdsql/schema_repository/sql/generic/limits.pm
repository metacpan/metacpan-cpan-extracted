package blx::xsdsql::schema_repository::sql::generic::limits;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use Storable;

use blx::xsdsql::ios::debuglogger;
use blx::xsdsql::ut::ut qw(nvl);

use base qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( get_xsd_based_types get_normalized_type ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


my %LIMITS=( #default limits if key  is not spec
				string			=>  {  SIZE => -1 }  # -1 => unlimited
				,fixedstring	=>  {  FIXSIZE => -1 }
				,boolean		=>  {  SIZE => 5 }
				,string50		=>  {  SIZE => 50 }
				,sizestring		=>  {  SIZE => -1 }     # size string have the size in bytes not in characters
				,sizestring50	=>  {  SIZE => 50 }
				,number3		=>  {  INT => 3		,DEC 	=> 0 }
				,number5		=>  {  INT => 5		,DEC 	=> 0 }
				,number10		=>  {  INT => 10	,DEC 	=> 0 }
				,number20		=>  {  INT => 20	,DEC	=> 0 }
				,unumber3		=>  {  INT => 3		,DEC 	=> 0 }
				,unumber5		=>  {  INT => 5		,DEC 	=> 0 }
				,unumber10		=>  {  INT => 10	,DEC 	=> 0 }
				,unumber20		=>  {  INT => 20	,DEC	=> 0 }
				,decimal		=>  {  INT => 36	,DEC	=> 18}
				,number   		=>  {  INT => 36	,DEC 	=> 18}
				,integer		=>  {  INT => 36	,DEC	=> 0}
);

my %MAXLIMITS=( # max limits of types
); 


my %SQL_TRANSLATE=(
			string 			=> 'varchar(%d)'
			,fixedstring 	=> 'char(%d)'
			,string50		=> 'varchar(%d)'
			,sizestring		=> 'varchar(%d)'
			,sizestring50	=> 'varchar(%d)'
			,decimal		=> 'decimal(%i,%d)'
);

use constant {
	NORMALIZED_TYPES => {
		anyURI					=> 'string'                      
		,base64Binary			=> 'sizestring'                  
		,boolean				=> 'boolean'                     
		,byte					=> 'number3'                                    
		,dateTime				=> 'sizestring50'                
		,date          			=> 'sizestring50'                
		,decimal				=> 'decimal'                     
		,double      			=> 'sizestring'                  
		,duration				=> 'string' 
		,ENTITIES				=> 'string'
		,ENTITY					=> 'string'                      
		,float					=> 'sizestring'                  
		,gDay					=> 'sizestring50'                
		,gMonth					=> 'sizestring50'                
		,gMonthDay  			=> 'sizestring50'                
		,gYearMonth   			=> 'sizestring50'                
		,gYear        			=> 'sizestring50'                
		,hexBinary				=> 'sizestring'                  
		,IDREFS					=> 'string'                      
		,IDREF					=> 'string'                      
		,ID						=> 'string'                      
		,integer				=> 'integer'                     
		,int 					=> 'number10'                    
		,language				=> 'string'                      
		,long					=> 'number20'                    
		,Name					=> 'string'                      
		,NCName					=> 'string'                      
		,negativeInteger		=> 'integer'                     
		,NMTOKENS				=> 'string'                      
		,NMTOKEN				=> 'string'                      
		,nonNegativeInteger		=> 'number10'                    
		,nonPositiveInteger  	=> 'number10'                    
		,normalizedString		=> 'string'
		,NOTATION				=> 'string'                     
		,positiveInteger		=> 'number10'                    
		,QName					=> 'string'                      
		,short					=> 'number5'                     
		,string					=> 'string'                      
		,time         			=> 'string50'                    
		,token					=> 'string'                      
		,unsignedByte			=> 'unumber3'                    
		,unsignedInt			=> 'unumber10'                   
		,unsignedLong			=> 'unumber20'                   
		,unsignedShort			=> 'unumber5'
	}
};


use constant {
	A_BASED_TYPES	=> [sort keys %{&NORMALIZED_TYPES}]
};

use constant {
	H_BASED_TYPES	=> {map { ($_,undef) }  @{&A_BASED_TYPES} }
};

my %CONSTRUCTOR_PARAMS=map { ($_,undef) } qw(LOG DEBUG);

sub _check_params {
	my (%params)=@_;
	return grep(!exists $CONSTRUCTOR_PARAMS{$_},keys %params);
}


sub _get_sql_translate {  croak "abstract method\n"; }

sub _get_limits	 { croak "abstract method\n"; }

sub _get_maxlimits { croak "abstract method\n"; }

sub _new {
	my ($class,%params)=@_;
	affirm { scalar(_check_params(%params)) == 0 } join(' ',_check_params(%params)).": this params are not permitted"; 
	$params{LOG}=blx::xsdsql::ios::debuglogger->new(DEBUG => $params{DEBUG}) unless defined $params{LOG};
	return bless \%params,$class;
}

sub new { croak "abstract method"; }

sub get_xsd_based_types {
	my %params=@_;
	$params{FORMAT}='ARRAY' unless defined $params{FORMAT};
	for ($params{FORMAT}) {
		/^HASH$/ && return wantarray ? %{&H_BASED_TYPES} : H_BASED_TYPES;
		/^ARRAY$/ && return wantarray ? @{&A_BASED_TYPES} : A_BASED_TYPES;
		affirm { 0 } $params{FORMAT}.q(: value param FORMAT must be the string 'HASH' or 'ARRAY') 
	}
	undef;
}

{
	my %norm_type=();
	sub get_normalized_type {
		my ($xsd_type,%params)=@_;
		affirm { defined $xsd_type } "1^ param not set";
		affirm { defined NORMALIZED_TYPES->{$xsd_type} } "$xsd_type: is not a simple base type";
		unless (scalar(%norm_type)) {
			for my $k(keys %{&NORMALIZED_TYPES}) {
				local $_;
				for (NORMALIZED_TYPES->{$k}) {
					/string/ && do { $norm_type{$k}='string'; last; };
					/boolean/ && do { $norm_type{$k}='boolean'; last; };
					/int|number/ && do { $norm_type{$k}='integer';last; };
					/decimal/ && do { $norm_type{$k}='decimal';last; };
					affirm { 0 } "$k: not normalized";
				}
			}
		}
		affirm { defined $norm_type{$xsd_type} } "$xsd_type: not normalized";
		return $norm_type{$xsd_type};
	}
}

sub get_translated_type {
	my ($self,$xsd_type,%params)=@_;
	affirm { ref($self) ne __PACKAGE__ } "this method must be called from a subclass";
	my $tag=ref($params{COLUMN})=~/::column$/ 
		? nvl($params{COLUMN}->get_path,$params{COLUMN}->get_name) 
		: undef;
	$tag=defined $tag ? " column '$tag': " :''; 
	{
		my ($nt,$lm,$sqlt,$ml,$t)=();
		unless (defined $self->{_DATA_CONVERSION}) {
			$lm=Storable::dclone(\%LIMITS);
			$t=$self->_get_limits;
			for my $k(keys %$t) {
				$lm->{$k}=$t->{$k};
			}
			$sqlt=Storable::dclone(\%SQL_TRANSLATE);
			$t=$self->_get_sql_translate;
			for my $k(keys %$t) {
				$sqlt->{$k}=$t->{$k};
			}
			$ml=Storable::dclone(\%MAXLIMITS);
			$t=$self->_get_maxlimits;
			for my $k(keys %$t) {
				$ml->{$k}=$t->{$k};
			}
			$self->{_DATA_CONVERSION}->{LIMITS}=$lm;
			$self->{_DATA_CONVERSION}->{SQL_TRANSLATE}=$sqlt;
			$self->{_DATA_CONVERSION}->{MAXLIMITS}=$ml;
		}
	}
	affirm {  defined $xsd_type } "$tag 1^ param not set";
	affirm {  exists H_BASED_TYPES->{$xsd_type} } "$xsd_type: is not a based type";
	
	my $user_limits=nvl($params{LIMITS},{});
	affirm { ref($user_limits) eq 'HASH' } $tag.ref($user_limits).': param LIMITS must be an hash';
	affirm {!exists $user_limits->{SQL_SIZE}} "SQL_SIZE is obsolete";
	my $norm=NORMALIZED_TYPES->{$xsd_type};
	affirm { defined $norm } "$tag$xsd_type: unknow xsd type";
	$norm='fixedstring' if defined $user_limits->{FIXSIZE} and get_normalized_type($xsd_type) eq 'string';
	my $lm=defined $self->{_DATA_CONVERSION}->{LIMITS}->{$norm} ? Storable::dclone($self->{_DATA_CONVERSION}->{LIMITS}->{$norm}) : undef;
	affirm { defined $lm } "$tag.$norm: this internal type has not entry in limits"; 
	my $maxlimits=$self->{_DATA_CONVERSION}->{MAXLIMITS}->{$norm};
	$maxlimits=Storable::dclone($lm) unless defined $maxlimits;
	affirm { defined $maxlimits } "$tag no max limit for internal type '$norm'";
	for my $k(keys %$user_limits) {
		next unless defined $user_limits->{$k};
		affirm { $user_limits->{$k}=~/^\d+$/ } $tag.$user_limits->{$k}.": the value of attribute '$k' of param LIMITS must a absolute number";
		affirm { $k eq 'DEC' || $user_limits->{$k} > 0} $tag.$user_limits->{$k}.": the value of attribute '$k' of param LIMITS must be positive number"; 
		my $ml=$maxlimits->{$k};
		affirm { defined $ml } "$tag: no MAXLIMIT for key '$k' in type '$norm'";
		affirm { $ml == -1 || $user_limits->{$k} <= $ml } $tag.$user_limits->{$k}.": the value of attribute '$k' of param LIMITS exceded the max value of ".$ml;		
		affirm { $lm->{$k} == -1 || $user_limits->{$k} <= $lm->{$k} } $tag.$user_limits->{$k}.": the value of attribute '$k' of param LIMITS exceded the max value of ".$lm->{$k};	
		$lm->{$k}=$user_limits->{$k};
	}
	my $sqltype=$self->{_DATA_CONVERSION}->{SQL_TRANSLATE}->{$norm};
	affirm { defined $sqltype } "$tag$norm: this internal type is not know for conversion into sqltype";
	local $_;
	for ($norm) {
		/fixedstring/ && do {
				affirm { defined $maxlimits->{FIXSIZE} } "$tag$norm: attribute FIXSIZE of MAXLIMITS is not set"; 
				if ($maxlimits->{FIXSIZE} != -1) { 
					my $sz=defined $lm->{FIXSIZE} ? $lm->{FIXSIZE} : $maxlimits->{FIXSIZE};
					affirm { defined $sz } "$tag$norm: attribute FIXSIZE of MAXLIMITS is not set"; 					
					$sqltype=$self->{_DATA_CONVERSION}->{SQL_TRANSLATE}->{fixedstring}; 
					affirm { defined $sqltype } "sql_translate: fixedstring not found";
					$sqltype=~s/\%d/$sz/g;
				}
				last;
		};
		/string|boolean/ && do { 
				affirm { defined $maxlimits->{SIZE} } "$tag$norm: attribute SIZE of MAXLIMITS is not set"; 
				if ($maxlimits->{SIZE} != -1) { 
					my $sz=$lm->{SIZE} == -1 ? $maxlimits->{SIZE} : $lm->{SIZE};
					affirm { defined $sz } "$tag$norm: attribute SIZE/FIXSIZE of MAXLIMITS is not set"; 					
					$sqltype=$self->{_DATA_CONVERSION}->{SQL_TRANSLATE}->{fixedstring} 
						if defined $user_limits->{FIXSIZE}
					;
					affirm { defined $sqltype } "sql_translate: fixedstring not found";
					$sqltype=~s/\%d/$sz/g;
				}
				last;
		};
		/decimal/ && do {
				for my $k(qw(INT DEC)) {
					affirm { defined $maxlimits->{$k} } "$tag$norm: attribute $k of MAXLIMITS is not set";		
					if ($maxlimits->{$k} != -1) {
						affirm { defined $lm->{$k} } "$tag$norm: attribute $k of MAXLIMITS is not set";		
						my $n=$lm->{$k} == -1 ? $maxlimits->{$k} : $lm->{$k};
						affirm { defined $n } "$tag$norm: attribute $k of MAXLIMITS is not set";		
						local $_;
						SW:
						for($k) {
							/^INT$/ && do { $sqltype=~s/\%i/$n/g;last SW; };
							/^DEC$/ && do { $sqltype=~s/\%d/$n/g;last SW; };
							affirm { 0 } "$tag$norm: who is '$k' ?";
						}
					}
				}
				last;
		};
		/integer|number/ && do {
				for my $k(qw(INT)) {
					affirm { defined $maxlimits->{$k} } "$tag$norm: attribute $k of MAXLIMITS is not set";		
					if ($maxlimits->{$k} != -1) {
						affirm { defined $lm->{$k} } "$tag$norm: attribute $k of MAXLIMITS is not set";		
						my $n=$lm->{$k} == -1 ? $maxlimits->{$k} : $lm->{$k};
						affirm { defined $n } "$tag$norm: attribute $k of MAXLIMITS is not set";		
						local $_;
						SW:
						for($k) {
							/^INT$/ && do { $sqltype=~s/\%i/$n/g;last SW; };
							/^DEC$/ && do { $sqltype=~s/\%d/$n/g;last SW; };
							affirm { 0 } "$tag$norm: who is '$k' ?";
						}
					}
				}
				last;		
		};
		affirm { 0 }  "$tag$norm: the conversion is not implemented";
	}
	return $sqltype;
}





1;


__END__

=head1  NAME

blx::xsdsql::schema_repository::sql::generic::limits -  class base for limits values

=cut

=head1 SYNOPSIS

use blx::xsdsql::schema_repository::sql::generic::limits
=cut


=head1 DESCRIPTION

this package is a class - instance it with the method new



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

get_xsd_based_types - class method - return the xsd based types

    PARAMS
            FORMAT - return the xsd based types into the format specify
                     HASH - return hash with values set at undef
                     ARRAY - return a list (default)


get_normalized_type return the normalized type  (string|boolean|decimal|integer) of an xsd_type

    ARGUMENTS:
            the first argument is an xsd_type


get_translated_type  - translate an xsd type into sql type

    the firt argument must be a valid xsd type

    PARAMS
            LIMITS  => a hash of restriction for type
            COLUMN  => a column  object - this param is used if is set only for debug


=head1 EXPORT

None by default.


=head1 EXPORT_OK

none

=head1 SEE ALSO

none

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut




