package Util::Medley::Exec;
$Util::Medley::Exec::VERSION = '0.030';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Util::Medley::Crypt;
use Util::Medley::Number;
use Util::Medley::Module::Overview;
use Text::ASCIITable;

with 'Util::Medley::Roles::Attributes::String';

=head1 NAME

Util::Medley::Exec - proxy for cmdline to libs

=head1 VERSION

version 0.030

=cut

method moduleOverview (Str  :$moduleName!,
                       Bool :$showInheritedPrivateAttributes,
                       Bool :$showInheritedPrivateMethods,
                       Str  :$hideModules = 'Moose::Object') {

	my @hide;
	if ($hideModules) {
		foreach my $pkg ( split( /,/, $hideModules ) ) {
			push @hide, $self->String->trim($pkg);
		}
	}

	my $mo = Util::Medley::Module::Overview->new(
		moduleName  => $moduleName,
		hideModules => \@hide
	);

	my $isMooseModule = $mo->isMooseModule;

	my $t = Text::ASCIITable->new( { headingText => "\n$moduleName\n " } );
	$t->setOptions( { hide_HeadLine => 0, hide_HeadRow => 1 } );
	$t->setCols(qw(a b c d));

	$self->_moduleOverviewAddSection(
		table   => $t,
		section => 'parents',
		rows    => [ $mo->getParents ]
	);

	$t->addRowLine;

	$self->_moduleOverviewAddSection(
		table   => $t,
		section => 'uses',
		rows    => [ $mo->getImportedModules ],
	);

	$t->addRowLine;

	$self->_moduleOverviewAddSection(
		table   => $t,
		section => 'constants',
		rows    => [ $mo->getConstants ],
	);

	if ($isMooseModule) {
		$t->addRowLine;

		$self->_moduleOverviewAddSection(
			table      => $t,
			section    => 'attributes',
			subsection => 'public',
			rows       => [ $mo->getPublicAttributes ]
		);

		$t->addRow('');

		$self->_moduleOverviewAddSection(
			table      => $t,
			section    => '',
			subsection => 'private',
			rows       => [ $mo->getPrivateAttributes ]
		);
	}

	$t->addRowLine;

	$self->_moduleOverviewAddSection(
		table      => $t,
		section    => $isMooseModule ? 'methods' : 'subs',
		subsection => 'public',
		rows       => [ $mo->getPublicMethods ]
	);

	$t->addRow('');

	$self->_moduleOverviewAddSection(
		table      => $t,
		section    => '',
		subsection => 'private',
		rows       => [ $mo->getPrivateMethods ]
	);

	########## inherited ###########

	if ($isMooseModule) {
		$t->addRowLine;

		$self->_moduleOverviewAddSection(
			table      => $t,
			section    => 'inherited attributes',
			subsection => 'public',
			rows       => [ $mo->getInheritedPublicAttributes ]
		);

		if ($showInheritedPrivateAttributes) {
			$t->addRow('');

			$self->_moduleOverviewAddSection(
				table      => $t,
				section    => '',
				subsection => 'private',
				rows       => [ $mo->getInheritedPrivateAttributes ]
			);
		}
	}

	$t->addRowLine;

    my $section;
    if ($isMooseModule) {
        $section = "inherited methods"; 	
    }
    else {
        $section = "imported subs";
    } 
    
	$self->_moduleOverviewAddSection(
		table => $t,
		section => $section,
		subsection => 'public',
		rows       => [ $mo->getInheritedPublicMethods ]
	);

	if ($showInheritedPrivateMethods) {
		$t->addRow('');

		$self->_moduleOverviewAddSection(
			table      => $t,
			section    => '',
			subsection => 'private',
			rows       => [ $mo->getInheritedPrivateMethods ]
		);
	}

	print $t;
}

method _moduleOverviewAddSection (Object   :$table!,
                                  Str      :$section, 
                                  Str      :$subsection,
                                  ArrayRef :$rows!) {

	push @$rows, '' if !@$rows;

	my $first = 1;
	foreach my $row (@$rows) {

		if ($first) {
			$first = 0;
		}
		else {
			$section    = '';
			$subsection = '';
		}

		if ( ref($row) eq 'ARRAY' ) {
			$table->addRow( $section, $subsection, @$row );
		}
		else {
			$table->addRow( $section, $subsection, $row );
		}
	}
}

method commify (Num :$val!) {

	my $num = Util::Medley::Number->new;
	say $num->commify($val);
}

method decommify (Str :$val!) {

	my $num = Util::Medley::Number->new;
	say $num->decommify($val);
}

method encryptStr (Str :$str!,
				   Str :$key) {

	my %a;
	$a{str} = $str;
	$a{key} = $key if $key;

	my $crypt = Util::Medley::Crypt->new;
	say $crypt->encryptStr(%a);
}

method decryptStr (Str :$str!,
				   Str :$key) {

	my %a;
	$a{str} = $str;
	$a{key} = $key if $key;

	my $crypt = Util::Medley::Crypt->new;
	say $crypt->decryptStr(%a);
}

1;
