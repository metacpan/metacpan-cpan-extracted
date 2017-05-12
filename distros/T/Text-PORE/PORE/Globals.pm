#
# Text::PORE::Globals.pm
#
#  implements global variables for the template system

package Text::PORE::Globals;

use Exporter;
use Text::PORE::Volatile;

@Text::PORE::Globals::ISA = qw(Exporter);

my $envObj = new Text::PORE::Volatile();
my $indexObj = new Text::PORE::Volatile();

# default template root dir
my $_templateRootDir = ".";

$Text::PORE::Globals::globalVariables = new Text::PORE::Volatile
    (
     '_env'    => $envObj,
     '_index'  => $indexObj,
     );

##########################################
# setTemplateRoot($templateRoot)
##########################################
sub setTemplateRootDir($) {
	my ($templateRootDir) = shift;
	$_templateRootDir = $templateRootDir;
}

##########################################
# getTemplateRoot()
##########################################
sub getTemplateRootDir {
	return $_templateRootDir;
}

1;


