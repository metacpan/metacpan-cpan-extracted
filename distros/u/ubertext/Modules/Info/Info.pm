#
# Package Definition
#

package Text::UberText::Modules::Info;

#
# Compiler Directives
#

use strict;
use warnings;

#
# Global Variables
#

use vars qw/$Dispatch $VERSION /;

$Dispatch={
	"version" => \&version,
	"environment" => \&environment,
	"copyright" => \&copyright,
};

$VERSION=0.95;

#
# Methods
#

sub new
{
my ($class)=shift;
my ($object);
$object={};
bless ($object,$class);
$object->_init(@_);
return $object;
}

sub uberText
{
my ($self)=shift;
return ($self,"uber.info",$Dispatch);
}

#
# UberText Methods
#

sub version
{
my ($output);
$output="UberText Version $Text::UberText::VERSION";
return $output;
}

sub environment
{
my ($output);
$output="Perl version $] ($^O)\n";
return $output;
}

sub copyright
{
my ($output);
$output=<<EO
Text::UberText -- Copyright 2002, Chris Josephes
EO
;
return $output;
}

#
# Hidden Methods
#

sub _init
{
my ($self)=shift;
return;
}


#
# Exit Block
#
1;

#
# POD Documentation
#

=head1 NAME

Text::UberText::Modules::Info - UberText Info Commands

=head1 SYNOPSIS

[uber.info version]

[uber.info environment]

=head1 DESCRIPTION

The Info module is used to get information regarding the UberText 
environment.

=head1 DOCOUMENT COMMANDS

The following commands are available in the uber.info namespace.

=over 4

=item [uber.info version]

Returns the version number of Text::UberText.

=item [uber.info environment]

Returns the language environment, language version, and the operating system 
UberText is running on.

=back

=head1 AUTHOR

Chris Josephes E<lt>cpj1@visi.comE<gt>     

=head1 SEE ALSO

L<Text::UberText>

=head1 COPYRIGHT

Copyright 2002, Chris Josephes.  All rights reserved.
This module is free software.  It may be used, redistributed, 
and/or modified under the same terms as Perl itself.
~
