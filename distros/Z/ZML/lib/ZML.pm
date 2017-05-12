package ZML;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

ZML - A simple, fast, and easy to read binary data storage format.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

The error handling is unified between all methods. If $object->{error} is
ever defined after a function is ran there has been an error. A description
of the error can be found in $object->{errorString}. The error string is
always defined, but set to "" when there is no error. The error is blanked
after each run.

    use ZML;

    my $zml = ZML->new();
    my $zmlstring="a=0\nb=1\n 2\n";
    if ($zml->error){
    	print "Parsing the string failed with a error, ".$zml->{error}.
    			", ".$zml->{errorString}."\n";
    };
    ...

=head1 METHODS

=head2 new

Creates a new ZML object.

	my $ZMLobject=$ZML->new;

=cut

sub new {
	my $self = {var=>{}, meta=>{}, comment=>{}, error=>undef, errorString=>""};

	bless $self;
	return $self;
}

=head2 addVar 

This adds a new meta variable for a variable. Two values are required for it.

The first variable is the name of the variable being added.

The second is the meeta data. This can contain any character.

	$ZMLobject->addVar("some/variable", "whatever");

=cut 

sub addVar{
	my $self=$_[0];
	my $var=$_[1];
	my $value=$_[2];

	$self->errorblank;

	if(!defined($var)){
		$self->{error}=10;
		$self->{errorString}="ZML addVar:10: Variable is not defined.";
		$self->warn;
		return undef;
	};

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if( $legit ){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	$self->{var}{$var}=$value;
	return 1;
};

=head2 addComment 

This adds a new comment for a variable. Three values are required for it.

The first variable is the name of the variable the comment is being added for.

The second is the name of the comment. This also has to be a legit variable name.

The third is the comment. This can contain any character.

	$ZMLobject->addComment("some/variable", "comment/variable","Some fragging comment.");

=cut 

sub addComment{
	my $self=$_[0];
	my $var=$_[1];
	my $comment=$_[2];
	my $value=$_[3];

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#check if the variable name is legit
	($legit, $errorString)=$self->varNameCheck($comment);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#add the domment
	if(defined($self->{comment}{$var})){
		#add it if $self->{comment}{$var}{$comment} has been added
		$self->{comment}{$var}{$comment}=$value;
	}else{
		#add it if $self->{comment}{$var}{$comment} has not been added
		$self->{comment}{$var}{$comment}={};
		$self->{comment}{$var}{$comment}=$value;
	};	

	return 1;
};

=head2 addMeta 

This adds a new meta variable for a variable. Three values are required for it.

The first variable is the name of the variable the meta variable is being added for.

The second is the meta variable. This also has to be a legit variable name.

The third is the meeta data. This can contain any character.

	$ZMLobject->addMeta("some/variable", "meta/variable","whatever");

=cut 

sub addMeta{
	my $self=$_[0];
	my $var=$_[1];
	my $meta=$_[2];
	my $value=$_[3];

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#check if the variable name is legit
	($legit, $errorString)=$self->varNameCheck($meta);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	#add the domment
	if(defined($self->{meta}{$var})){
		#add it if $self->{comment}{$var}{$meta} has been added
		$self->{meta}{$var}{$meta}=$value;
	}else{
		#add it if $self->{comment}{$var}{$meta} has not been added
		$self->{meta}{$var}{$meta}={};
		$self->{meta}{$var}{$meta}=$value;
	};	

	return 1;
};

=head2 clearComment

This removes a meta variable. Two values are required.

The first is the variable name.

	$ZMLobject->clearComment("some/variable");
	
=cut

sub clearComment{
	my $self=$_[0];
	my $var=$_[1];

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};

	delete($self->{comment}{$var});

	return 1;
};

=head2 clearMeta

This removes a meta. Two values are required.

This removes all meta values for a variable.

	$ZMLobject->clearMeta("some/variable");
	
=cut

sub clearMeta{
	my $self=$_[0];
	my $var=$_[1];

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};

	delete($self->{meta}{$var});

	return 1;
};

=head2 delVar 

This removes a variable. The only variable required is the
name of the variable.

	$ZMLobject->delVar("some/variable");
	
=cut 

sub delVar{
	my $self=$_[0];
	my $var=$_[1];

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	delete($self->{var}{$var});

	return 1;
};

=head2 delMeta 

This removes a meta variable. Two values are required.

The first is the variable name.

The second is the meta variable.

	$ZMLobject->delMeta("some/variable", "meta variable");
	
=cut 

sub delMeta{
	my $self=$_[0];
	my $var=$_[1];
	my $meta=$_[2];

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};

	#check if the variable name is legit
	($legit, $errorString)=$self->varNameCheck($meta);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	delete($self->{meta}{$var}{$meta});

	return 1;
};

=head2 delComment

This removes a comment name. Two values are required.

The first is the variable name.

The second is the comment name.

	$ZMLobject->delMeta("some/variable", "comment name");
	
=cut 

sub delComment{
	my $self=$_[0];
	my $var=$_[1];
	my $comment=$_[2];

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};

	#check if the variable name is legit
	($legit, $errorString)=$self->varNameCheck($comment);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	delete($self->{comment}{$var}{$comment});

	return 1;
}

=head2 getVar

Gets a value of a variable.

	my @variables=$zml->getVar("some variable");

=cut

sub getVar {
	my ($self, $var) = @_;

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}
	
	if(!defined($self->{var}{$var})){
		$self->{error}="10";
		$self->{errorString}="Variable '".$var."' is undefined,";
		$self->warn;
		return undef;		
	}
	
	return $self->{var}{$var};
}

=head2 getMeta

Gets a value for a meta variable.

	my @variables=$zml->getVar("some variable", "some meta variable");

=cut

sub getMeta {
	my ($self, $var, $meta) = @_;

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};	

	#check if the meta variable name is legit
	($legit, $errorString)=$self->varNameCheck($meta);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};
	
	if(!defined($self->{meta}{$var})){
		$self->{error}="10";
		$self->{errorString}="Variable '".$var."' is undefined,";
		$self->warn;
		return undef;		
	};

	if(!defined($self->{meta}{$var}{$meta})){
		$self->{error}="10";
		$self->{errorString}="Variable '".$var."' is undefined,";
		$self->warn;
		return undef;		
	};
	
	return $self->{meta}{$var}{$meta};
};

=head2 getComment

Gets the value for a comment

	my @variables=$zml->getComment("some variable", "some comment name");

=cut

sub getComment {
	my ($self, $var, $comment) = @_;

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};	

	#check if the meta variable name is legit
	($legit, $errorString)=$self->varNameCheck($comment);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	};
	
	if(!defined($self->{comment}{$var})){
		$self->{error}="10";
		$self->{errorString}="Variable '".$var."' is undefined,";
		$self->warn;
		return undef;		
	};

	if(!defined($self->{comment}{$var}{$comment})){
		$self->{error}="10";
		$self->{errorString}="Variable '".$var."' is undefined,";
		$self->warn;
		return undef;
	};
	
	return $self->{comment}{$var}{$comment};
};

=head2 keysVar

This gets a array containing the names of the variables.

	my @variables=$zml->keysVar();

=cut

sub keysVar {
	my ($self, $var) = @_;

	$self->errorblank;

	my @keys=keys(%{$self->{var}});

	return @keys;
};

=head2 keysMeta

This gets a list of variables with metas.

	my @variables=$zml->keysMeta();

=cut

sub keysMeta {
	my ($self, $var) = @_;

	$self->errorblank;

	my @keys=keys(%{$self->{meta}});

	return @keys;
};

=head2 keysComment

This gets a list of comments.

	my @variables=$zml->keysComment();

=cut

sub keysComment {
	my ($self, $var) = @_;

	$self->errorblank;

	my @keys=keys(%{$self->{comment}});

	return @keys;
};

=head2 keysMetaVar

This gets a list of variables for a meta. It required one variable, which is the name
of the meta to get the meta variables for.

	my @variables=$zml->keysMetaVar("some variable");

=cut

sub keysMetaVar {
	my ($self, $var) = @_;

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{meta}{$var}});

	return @keys;
};

=head2 keysCommentVar

This gets a list of comments for a variable. It requires one arguement, which is
the variable to get the comments for.

	my @variables=$zml->keysCommentVar("some variable");

=cut

sub keysCommentVar {
	my ($self, $var) = @_;

	$self->errorblank;

	#check if the variable name is legit
	my ($legit, $errorString)=$self->varNameCheck($var);
	if($legit){
		$self->{error}=$legit;
		$self->{errorString}=$errorString;
		$self->warn;
		return undef;
	}

	my @keys=keys(%{$self->{comment}{$var}});

	return @keys;
}

=head2 keyRegexDelComment

This searches a the comments for a match and removes it.

It requires two arguements. The first arguement is the regexp used
to match the variable. The second is a regexp to match a name.

	#checks every meta for any meta variable matching /^monkey/
	my %removed=keyRegexDelComment("", "^monkey")

	#prints the removed
	my @removedA=keys(%removed)
	my $removedInt=0;
	while(defined($removedA[$removedInt])){
		my $mvInt=0;
		while(defined($removed{$removedA[$removedInt]})){
			print $removed{$removedA[$removedInt]}[$mvInt]."\n";
			
			$mvInt++;
		};
		
		$removedInt++;
	};

=cut

sub keyRegexDelComment{
	my ($self, $creg, $vreg) = @_;
	
	#contains the removed variables
	my %removed;
	
	#get a list of variables
	my @ckeys=keys(%{$self->{comment}});
	
	my $ckeysInt=0;
	#goes through looking for matching metas
	while(defined($ckeys[$ckeysInt])){
		#check if the key matches
		if($ckeys[$ckeysInt] =~ /$creg/){
			my @vkeys=keys(%{$self->{comment}{$ckeys[$ckeysInt]}});
			my $vkeysInt=0;
			#goes through checking the meta variables
			while(defined($vkeys[$vkeysInt])){
				#removes it if it matches
				if($self->{comment}{$ckeys[$ckeysInt]}{$vkeys[$vkeysInt]}){
					#adds is to the list of removed variables
					if(!defined($removed{$ckeys[$ckeysInt]})){
						#adds it to the removed list if the key for the meta has not been added yet
						$removed{$ckeys[$ckeysInt]}=[$vkeys[$vkeysInt]];
					}else{
						#adds it if it has not been added yet
						push(@{$removed{$ckeys[$ckeysInt]}}, $vkeys[$vkeysInt]);
					}

		 			delete($self->{comment}{$ckeys[$ckeysInt]}{$vkeys[$vkeysInt]});
				}

				#checks all the meta variables have been removes it if it matched
				@vkeys=keys(%{$self->{comment}{$ckeys[$ckeysInt]}});
				if(defined($vkeys[0])){
					delete($self->{comment}{$ckeys[$ckeysInt]});
				}

				$vkeysInt++;
			}
		}

		$ckeysInt++;
	}

	return %removed;
}

=head2 keyRegexDelMeta

This searches a the metas for a match and removes it.

It requires two arguements. The first arguement is the regexp used
to match the meta. The second is the regexp used to match the meta
variable.

	#checks every meta for any meta variable matching /^monkey/
	my %removed=keyRegexDelMeta("", "^monkey")

	#prints the removed
	my @removedA=keys(%removed)
	my $removedInt=0;
	while(defined($removedA[$removedInt])){
		my $mvInt=0;
		while(defined($removed{$removedA[$removedInt]})){
			print $removed{$removedA[$removedInt]}[$mvInt]."\n";
			
			$mvInt++;
		};
		
		$removedInt++;
	};

=cut

sub keyRegexDelMeta{
	my ($self, $mreg, $vreg) = @_;
	
	#contains the removed variables
	my %removed;
	
	#get a list of variables
	my @mkeys=keys(%{$self->{meta}});
	
	my $mkeysInt=0;
	#goes through looking for matching metas
	while(defined($mkeys[$mkeysInt])){
		#check if the key matches
		if($mkeys[$mkeysInt] =~ /$mreg/){
			my @vkeys=keys(%{$self->{meta}{$mkeys[$mkeysInt]}});
			my $vkeysInt=0;
			#goes through checking the meta variables
			while(defined($vkeys[$vkeysInt])){
				#removes it if it matches
				if($self->{meta}{$mkeys[$mkeysInt]}{$vkeys[$vkeysInt]}){
					#adds is to the list of removed variables
					if(!defined($removed{$mkeys[$mkeysInt]})){
						#adds it to the removed list if the key for the meta has not been added yet
						$removed{$mkeys[$mkeysInt]}=[$vkeys[$vkeysInt]];
					}else{
						#adds it if it has not been added yet
						push(@{$removed{$mkeys[$mkeysInt]}}, $vkeys[$vkeysInt]);
					};
					
		 			delete($self->{meta}{$mkeys[$mkeysInt]}{$vkeys[$vkeysInt]});
				};
				
				#checks all the meta variables have been removes it if it matched
				@vkeys=keys(%{$self->{meta}{$mkeys[$mkeysInt]}});
				if(defined($vkeys[0])){
					delete($self->{meta}{$mkeys[$mkeysInt]});
				};
				
				$vkeysInt++;
			};
		};

		$mkeysInt++;
	};

	return %removed;
};

=head2 keyRegexDelVar

This searches a the variables for a match and removes it.

It requires one arguement, which is the regex to use.

It returns a array of removed variables.

	#remove any variables starting with the word monkey
	my @removed=keyRegexDelVar("^monkey")

=cut

sub keyRegexDelVar{
	my ($self, $regex) = @_;
	
	#contains the removed variables
	my @removed=();
	
	#get a list of variables
	my @keys=keys(%{$self->{var}});
	
	my $keysInt=0;
	while(defined($keys[$keysInt])){
		#check if the key matches
		if($keys[$keysInt] =~ /$regex/){
			#add the key to the array of removed variables
			push(@keys, $keys[$keysInt]);
			
			#removes the variable
			delete($self->{var}{$keys[$keysInt]});
		}
		
		$keysInt++;
	}
	
	return @removed;
}

=head2 parse

This parses a string in the ZML format. The only variable it requires is the
string that contains the data.

=cut

sub parse {
	my ($self, $zmlstring)= @_;

	#blanks any errors
	$self->errorblank;

	my %zml;
	
	#breaks down the zblstring per line
	my @rawdata=split(/\n/, $zmlstring);

	my $rdInt=0;
	my $prevVar=undef;
	my $prevVar2=undef;
	my $prevVar2type=undef;
	while (defined($rawdata[$rdInt])) {

		#handles it if it is a prevarious variable
		if ($rawdata[$rdInt] =~ /^\ /) {
			#clean it up
			chomp($rawdata[$rdInt]);
			$rawdata[$rdInt]=~s/^\ //;

			#ignore it if there is no previous variable
			if (defined($prevVar)) {
				if (defined($prevVar2)) {
					$self->{$prevVar2type}{$prevVar}{$prevVar2}=
                        $self->{$prevVar2type}{$prevVar}{$prevVar2}."\n".$rawdata[$rdInt];
				}else {
					$self->{var}{$prevVar}=$self->{var}{$prevVar}."\n".$rawdata[$rdInt];
				}
			}

		}else {
			
			my @split1=split(/\=/, $rawdata[$rdInt], 2);

			#handles it for a regular variable
			if (!($split1[0] =~ /^\#/)) {
				$prevVar=$split1[0];
				$prevVar2=undef;
				$prevVar2type=undef;

				#check if the variable name is legit
				my ($legit, $errorString)=$self->varNameCheck($prevVar);
				if($legit){
					$self->{error}=$legit;
					$self->{errorString}=$errorString;
					$self->warn;
					return undef;
				}

				chomp($split1[1]);

				$self->{var}{$prevVar}=$split1[1];
			}

			#handles a comment
			if ($split1[0] =~ /^##/){
				$prevVar=$split1[0];
				$prevVar=~s/^\#\#//;
				$prevVar2type='comment';

				my @split2=split(/\=/, $split1[1], 2);
				
				$prevVar2=$split2[0];

				#check if the variable name is legit
				my ($legit, $errorString)=$self->varNameCheck($prevVar);
				if($legit){
					$self->{error}=$legit;
					$self->{errorString}=$errorString;
					return undef;
				}
 				#check if the comment name is legit
				($legit, $errorString)=$self->varNameCheck($prevVar2);
				if($legit){
					$self->{error}=$legit;
					$self->{errorString}=$errorString;
					return undef;
				}
				
				chomp($split2[1]);

				if (!defined($self->{$prevVar2type}{$prevVar})) {
					$self->{$prevVar2type}{$prevVar}={};
				}

				$self->{$prevVar2type}{$prevVar}{$prevVar2}=$split2[1];
			}

			#handles a comment
			if ($split1[0] =~ /^#!/){
				$prevVar=$split1[0];
				$prevVar=~s/^\#\!//;
				$prevVar2type='meta';

				my @split2=split(/\=/, $split1[1], 2);
				
				$prevVar2=$split2[0];
				
				#check if the variable name is legit
				my ($legit, $errorString)=$self->varNameCheck($prevVar);
				if($legit){
					$self->{error}=$legit;
					$self->{errorString}=$errorString;
					return undef;
				}
 				#check if the meta name is legit
				($legit, $errorString)=$self->varNameCheck($prevVar2);
				if($legit){
					$self->{error}=$legit;
					$self->{errorString}=$errorString;
					return undef;
				}

				chomp($split2[1]);

				if (!defined($self->{$prevVar2type}{$prevVar})) {
					$self->{$prevVar2type}{$prevVar}={};
				}

				$self->{$prevVar2type}{$prevVar}{$prevVar2}=$split2[1];
			}

		}

		$rdInt++;
	}

	return 1;
};

=head2 string

This function creates a string out of a the object.

	my $string=$zml->string;

=cut

sub string{
	my ($self, $var) = @_;

	$self->errorblank;

	#used to store the generated string
	my $string="";

	#generate the portion of the string for the comments
	my @keys=keys(%{$self->{comment}});
	my $keysInt=0;
	while(defined($keys[$keysInt])){
		my $comment=$keys[$keysInt];
		
		#builds string for comments
		my @commentKeys=keys(%{$self->{comment}{$comment}});
		my $commentKeysInt=0;
		while(defined($commentKeys[$commentKeysInt])){
			my $commentVar=$commentKeys[$commentKeysInt];
			my $data=$self->{comment}{$comment}{$commentVar};

			#sets it to '' if it is not defined... this will prevent
			#s/\n/\n /g from erroring
			if (!defined($data)) {
				$data='';
			}
			
			#turns the data contained in the comment into a storable string
			$data=~s/\n/\n /g ;

			$string=$string."##".$comment."=".$commentVar."=".$data."\n";

			$commentKeysInt++;
		};
		$keysInt++;
	};

	#generate the portion of the string for the metas
	@keys=keys(%{$self->{meta}});
	$keysInt=0;
	while(defined($keys[$keysInt])){
		my $meta=$keys[$keysInt];
		
		#builds string for
		my @metaKeys=keys(%{$self->{meta}{$meta}});
		my $metaKeysInt=0;
		while(defined($metaKeys[$metaKeysInt])){
			my $metaVar=$metaKeys[$metaKeysInt];
			my $data=$self->{meta}{$meta}{$metaVar};

			#sets it to '' if it is not defined... this will prevent
			#s/\n/\n /g from erroring
			if (!defined($data)) {
				$data='';
			}
			
			#turns the data contained in the meta into a storable string
			$data=~s/\n/\n /g ;

			$string=$string."#!".$meta."=".$metaVar."=".$data."\n";

			$metaKeysInt++;
		};
		$keysInt++;
	};

	#generate the portion of the string for the variables
	@keys=keys(%{$self->{var}});
	$keysInt=0;

	while(defined($keys[$keysInt])){
		my $var=$keys[$keysInt];

		my $data=$self->{var}{$var};

		#sets it to '' if it is not defined... this will prevent
		#s/\n/\n /g from erroring
		if (!defined($data)) {
			$data='';
		}

		#turns the data contained in the meta into a storable string
		$data=~s/\n/\n /g ;

		$string=$string.$var."=".$data."\n";

		$keysInt++;
	};

	return $string;
};

=head2 valRegexDelComment

This searches the comments for ones that have a value matching the regex.

It requires one arguement, which is the regex to use.

It returns a array of removed variables.

	#removes any variable in which the value matches /^monkey/
	my %removed=keyRegexDelMeta("^monkey")

	#prints the removed
	my @removedA=keys(%removed)
	my $removedInt=0;
	while(defined($removedA[$removedInt])){
		my $mvInt=0;
		while(defined($removed{$removedA[$removedInt]})){
			print $removed{$removedA[$removedInt]}[$mvInt]."\n";
			
			$mvInt++;
		};
		
		$removedInt++;
	};

=cut

sub valRegexDelComment{
	my ($self, $regex) = @_;
	
	#contains the removed variables
	my %removed;

	#get a list of variables
	my @keys=keys(%{$self->{var}});

	my $keysInt=0;
	while(defined($keys[$keysInt])){
		my @keys2=keys(%{$self->{var}{$keys[$keysInt]}});
		my $keys2Int=0;
		while(defined($keys2[$keys2Int])){
			#tests if the value equals the regexp
			if($self->{meta}{$keys[$keysInt]}{$keys2[$keys2Int]} =~ /$regex/){
				#adds is to the list of removed variables
				if(!defined($removed{$keys2[$keys2Int]})){
					#adds it to the removed list if the key for the meta has not been added yet
					$removed{$keys[$keysInt]}=[$keys2[$keys2Int]];
				}else{
					#adds it if it has not been added yet
					push(@{$removed{$keys[$keysInt]}}, $keys2[$keys2Int]);
				}

				delete($self->{var}{$keys[$keysInt]}{$keys2[$keys2Int]});
			}

			$keys2Int++;
		}

		#checks all the meta variables have been removes it if it matched
		@keys2=keys(%{$self->{var}{$keys[$keysInt]}});
		if(defined($keys2[0])){
			delete($self->{var}{$keys[$keysInt]});
		}
		
		$keysInt++;
	}
	
	return %removed;
}


=head2 valRegexDelMeta

This searches the variables for ones that have a value matching the regex.

It requires one arguement, which is the regex to use.

It returns a array of removed variables.

	#removes any variable in which the value matches /^monkey/
	my %removed=keyRegexDelMeta("^monkey")

	#prints the removed
	my @removedA=keys(%removed)
	my $removedInt=0;
	while(defined($removedA[$removedInt])){
		my $mvInt=0;
		while(defined($removed{$removedA[$removedInt]})){
			print $removed{$removedA[$removedInt]}[$mvInt]."\n";
			
			$mvInt++;
		};
		
		$removedInt++;
	};

=cut

sub valRegexDelMeta{
	my ($self, $regex) = @_;
	
	#contains the removed variables
	my %removed;
	
	#get a list of variables
	my @keys=keys(%{$self->{meta}});
	
	my $keysInt=0;
	while(defined($keys[$keysInt])){
		my @keys2=keys(%{$self->{meta}{$keys[$keysInt]}});
		my $keys2Int=0;
		while(defined($keys2[$keys2Int])){
			#tests if the value equals the regexp
			if($self->{meta}{$keys[$keysInt]}{$keys2[$keys2Int]} =~ /$regex/){
				#adds is to the list of removed variables
				if(!defined($removed{$keys2[$keys2Int]})){
					#adds it to the removed list if the key for the meta has not been added yet
					$removed{$keys[$keysInt]}=[$keys2[$keys2Int]];
				}else{
					#adds it if it has not been added yet
					push(@{$removed{$keys[$keysInt]}}, $keys2[$keys2Int]);
				};

				delete($self->{meta}{$keys[$keysInt]}{$keys2[$keys2Int]});
			};

			$keys2Int++;
		};

		#checks all the meta variables have been removes it if it matched
		@keys2=keys(%{$self->{meta}{$keys[$keysInt]}});
		if(defined($keys2[0])){
			delete($self->{meta}{$keys[$keysInt]});
		};
		
		$keysInt++;
	};
	
	return %removed;
};

=head2 valRegexDelVar

This searches the variables for ones that have a value matching the regex.

It requires one arguement, which is the regex to use.

It returns a array of removed variables.

	#remove any variables starting with the word monkey
	my @removed=valRegexDelVar("^monkey")

=cut

sub valRegexDelVar{
	my ($self, $regex) = @_;
	
	#contains the removed variables
	my @removed=();
	
	#get a list of variables
	my @keys=keys(%{$self->{var}});
	
	my $keysInt=0;
	while(defined($keys[$keysInt])){
		#check if the key matches
		if($self->{var}{$keys[$keysInt]} =~ /$regex/){
			#add the key to the array of removed variables
			push(@keys, $keys[$keysInt]);
			
			#removes the variable
			delete($self->{var}{$keys[$keysInt]});
		};
		
		$keysInt++;
	};
	
	return @removed;
};

=head2 varNameCheck

This checks a variable name to see if it is legit. It requires
one variable, which the name of the variable. It returns two
values.

The first is a integer which represents the of the error. If
it is false, there is no error.

The second return is the string that describes the error.

	my ($legit, $errorString)=varNameCheck($name);

=cut

#checks the config name
sub varNameCheck{
	my ($self, $name) = @_;

	#make sure it is defined
	if (!defined($name)) {
		return('10', 'No name defined');
	}

	#checks for ,
	if($name =~ /,/){
		return("11", "variavble name,'".$name."', contains ','");
	};
		
	#checks for /.
	if($name =~ /\/\./){
		return("1", "variavble name,'".$name."', contains '/.'");
	};

	#checks for //
	if($name =~ /\/\//){
		return("2", "variavble name,'".$name."', contains '//'");
	};

	#checks for ../
	if($name =~ /\.\.\//){
		return("3", "variavble name,'".$name."', contains '../'");
	};

	#checks for /..
	if($name =~ /\/\.\./){
		return("4", "variavble name,'".$name."', contains '/..'");
	};

	#checks for ^./
	if($name =~ /^\.\//){
		return("5", "variavble name,'".$name."', matched /^\.\//");
	};

	#checks for /$
	if($name =~ /\/$/){
		return("6", "variavble name,'".$name."', matched /\/$/");
	};

	#checks for ^/
	if($name =~ /^\//){
		return("7", "variavble name,'".$name."', matched /^\//");
	};

	#checks for \\n
	if($name =~ /\n/){
		return("8", "variavble name,'".$name."', matched /\\n/");
	};

	#checks for 
	if($name =~ /=/){
		return("9", "variavble name,'".$name."', matched /=/");
	};

	return('0', "");
};

=head1 ZML FORMAT

There is no whitespace.

A line starting with a " " is a continuation of the last variable.

A line starting with ## indicates it is a comment.

A line starting with a #! indicates it is a meta.

Any line not starting with a /^#/ or " " is a variable.

=head2 comments

A line starting with ## indicates it is a comment, as stated above.

It is broken down into three parts, variable, comment name, and the value. Each is sperated
by a "=". Any thing after the second "=" is considered to be part of the  value.

=head2 meta

A line starting with #! indicates it is a comment, as stated above.

It is broken down into three parts, meta, meta variable, and data. Each is sperated
by a "=". The first field is the meta. The second is the meta variable. The third is the value.

=head2 variable

Any line not starting with a /^#/ or " " is a variable, as stated above.

It is broken down into two parts seperated by a "=". Any thing after the "=" is considered
part of the value.

=head2 multi-line data

Any line matching /^ / is considered to be a continuation of the last value section of
the value part of the variable. When a string is created s/\n/\n /g is ran over the
value to transform it to a storable state.

=head1 variable naming

A variable name is considered non-legit if it matches any of the following regexs.

	/,/
	/\/\./
	/\/\//
	/\.\.\//
	/\/\.\./
	/^\.\//
	/\/$/
	/^\//
	/\n/
	/=/

=head1 ERROR HANDLING/CODES

This module uses L<Error::Helper> for error handling. Below are the
error codes returned by the error method.

=head2 1

The variable name matches /\/\./.

=head2 2

The variable name matches /\/\//.

=head2 3

The variable name matches /\.\.\//.

=head2 4

The variable name matches /\/\.\./.

=head2 5

The variable name matches /^\.\//.

=head2 6

The variable name matches /\/$/.

=head2 7

The variable name matches  /^\//.

=head2 8

The variable name matches /\n/.

=head2 9

The variable name matches /=/.

=head2 10

Undefined variable.

=head2 11

This means the variable name matches /,/.

=cut

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZML>

=item * Search CPAN

L<http://search.cpan.org/dist/ZML>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZML
