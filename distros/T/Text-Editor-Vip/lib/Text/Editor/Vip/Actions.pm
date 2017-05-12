
package Text::Editor::Vip::Actions;

use strict;
use warnings ;

use File::Slurp ;
use Data::TreeDumper ;

use Text::Editor::Vip::Buffer ;

BEGIN 
{
use Exporter ();

use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01;
@ISA         = qw (Exporter);
@EXPORT      = qw (DoAction LoadActions);
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

=head1 NAME

Text::Editor::Vip::Actions::Actions - loads actions from files

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 MEMBER FUNCTIONS

=cut

#------------------------------------------------------------------------------------------------------

sub new
{
my ($class, $key_lookup, @file_names) = @_ ;

my $actions = bless({}, $class) ;

$actions->Load($key_lookup, @file_names) ;

return($actions) ;
}

#------------------------------------------------------------------------------------------------------

sub Run
{
my ($actions, $action_name, @args) = @_ ;

if(exists $actions->{PREACTION})
	{
	print "PREACTION: $actions->{PREACTION}{COMMENT}.\n" ;
	($action_name, @args) = $actions->{PREACTION}{SUB}($actions, $action_name,@args) ;
	}

if(exists $actions->{$action_name})
	{
	print "Action: $actions->{$action_name}{COMMENT}.\n" ;
	$actions->{$action_name}{SUB}->($actions, @args) ;
	}
else
	{
	print "No Action for '$action_name'.\n" ;
	}
}

#------------------------------------------------------------------------------------------------------

sub Load
{
my ($actions, $key_lookup, $view, @file_names) = @_;

my $exceptions ;

for my $file (@file_names)
	{
	eval
		{
		$actions->DoActionFile($key_lookup, $view, $file) ;
		} ;
		
	$exceptions .= "$@ \n" if $@ ;
	}

die $exceptions if defined $exceptions ;
}

#------------------------------------------------------------------------------------------------------

{ # private block

my $load = 0 ;
sub DoActionFile
{
#~ print DumpTree \@_, "DoActionFile args:", MAX_DEPTH => 2 ;

my ($actions, $key_lookup, $view, $file) = @_ ;

$load++ ;

my $pre_code = <<EOC ;

use strict ; 
use warnings ;

EOC

my $package = "View::LoadActions::${file}_$load"  ;
$package =~ s/[^a-zA-Z:0-9]/_/g ;

LoadFileInPackage
	(
	  $file
	, $package
	, $pre_code
	) ;

my $init_function ;
eval "\$init_function= *${package}::Init{CODE} ;" ;

if($init_function)
	{
	$actions->{CURRENT_KEY_LOOKUP} = $key_lookup ;
	$init_function->($view) ;
	delete $actions->{CURRENT_KEY_LOOKUP} ;
	}
else
	{
	die "No 'Init' function to call in actions file '$file'.\n" ;
	}
}

#------------------------------------------------------------------------------------------------------

sub RegisterActions
{
my (undef, $filename, $line) = caller() ;

my ($actions, @actions_to_register) = @_ ;

for my $action (@actions_to_register)
	{
	my ($comment, $key, $modifier, $sub, $modifier2) = @$action ;
	
	if(defined $actions->{CURRENT_KEY_LOOKUP} && exists $actions->{CURRENT_KEY_LOOKUP}{$key})
		{
		$key = $actions->{CURRENT_KEY_LOOKUP}{$key} ;
		}
		
	#~ print "RegisterActions '$comment' $key\n" ;
	
	$comment = defined $comment ? $comment : "$key-$modifier" ;

	my $new_action ;
	
	if('CODE' eq ref $sub)
		{
		$new_action = {COMMENT => "'$comment' at $filename:$line" , SUB => $sub} ;
		}
	elsif('' eq ref $sub && '' eq ref $modifier2)
		{
		my $alias_to = "$sub-$modifier2" ;
		
		if(exists $actions->{$alias_to})
			{
			$new_action = {ALIAS => $alias_to, COMMENT => "'$comment' at $filename:$line" , SUB => $actions->{$alias_to}{SUB}} ;
			}
		else
			{
			$new_action = {ALIAS => $alias_to, COMMENT => "'$comment' at $filename:$line" , SUB => sub{print "!! Print aliased '$comment' to unexisting '$alias_to'\n"}} ;
			}
		}
	else
		{
		die "Invalid RegisterActions '$comment' $key @ $filename:$line\n" ;
		}
		
	if(exists $actions->{"$key-$modifier"})
		{
		my $old_definition = $actions->{"$key-$modifier"}{COMMENT} ;
		my $new_definition = $new_action->{COMMENT} ;
		
		print "Overriding '$key-$modifier' defined as: $old_definition with new definition: $new_definition\n" ;
		}
		
	$actions->{"$key-$modifier"} = $new_action ;
	}
}

} # private block

#------------------------------------------------------------------------------------------------------

sub LoadFileInPackage
{
my ($file, $package, $pre_code) = @_ ;

my $file_body = read_file($file) or die "LoadFileInPackage: Error opening $file: $!\n" ;

my $source = <<EOS ;
#>>>>> start of file '$file'

#line 0 '$file'
package $package ;
$pre_code

#line 1 '$file' 
$file_body
#<<<<< end of file '$file'

EOS

my $result = eval $source ;

#~confess "$@ ." if $@ ;
#~ PrintError $@ if $@ ;

die "" if $@ ;

unless(defined $result && $result == 1)
	{
	$result ||= 'undef' ;
	die "$file didn't return OK [$result] (did you forget '1 ;' at the last line?)\n"  ;
	}
}

#------------------------------------------------------------------------------------------------------

=head1 BUGS

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net
	http:// no web site

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

#------------------------------------------------------------------------------------------------------
1 ;