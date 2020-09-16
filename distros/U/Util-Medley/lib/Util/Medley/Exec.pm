package Util::Medley::Exec;
$Util::Medley::Exec::VERSION = '0.041';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Util::Medley::Crypt;
use Util::Medley::Number;
use Util::Medley::Module::Overview;
use Util::Medley::YAML;
use Text::ASCIITable;
use Text::Table;

with 
    'Util::Medley::Roles::Attributes::String',
    'Util::Medley::Roles::Attributes::List';

=head1 NAME

Util::Medley::Exec - proxy for cmdline to libs

=head1 VERSION

version 0.041

=cut

method moduleOverview (Str  :$moduleName!,
                       Bool :$showInheritedPrivateAttributes,
                       Bool :$showInheritedPrivateMethods,
                       Bool :$viewClean,
                       Bool :$merged,
                       Str  :$hideModules = 'Moose::Object') {

	my @hide;
	if ($hideModules) {
		foreach my $pkg ( split( /,/, $hideModules ) ) {
			push @hide, $self->String->trim($pkg);
		}
	}

	local $SIG{__WARN__} = 'ignore';
	my $mo;
	$mo = Util::Medley::Module::Overview->new(
		moduleName  => $moduleName,
		hideModules => \@hide
	);

	if ($viewClean) {
		if ($merged) {
			$self->_moduleOverviewCleanViewMerged(
				moduleName     => $moduleName,
				moduleOverview => $mo,
				showInheritedPrivateAttributes =>
				  $showInheritedPrivateAttributes,
				showInheritedPrivateMethods => $showInheritedPrivateMethods,
			);
		}
		else {
			$self->_moduleOverviewCleanView(
				moduleName     => $moduleName,
				moduleOverview => $mo,
				showInheritedPrivateAttributes =>
				  $showInheritedPrivateAttributes,
				showInheritedPrivateMethods => $showInheritedPrivateMethods,
			);
		}
	}
	else {
		if ($merged) {
			$self->Logger->fatal("merged not yet implemented for default view");
		}
		else {
			$self->_moduleOverviewDefaultView(
				moduleName     => $moduleName,
				moduleOverview => $mo,
				showInheritedPrivateAttributes =>
				  $showInheritedPrivateAttributes,
				showInheritedPrivateMethods => $showInheritedPrivateMethods,
			);
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

method yamlBeautifyFile (Str :$file!,
                         Int :$sortDepth = 0) {

	my $yaml = Util::Medley::YAML->new;
	$yaml->yamlBeautifyFile(path => $file, sortDepth => $sortDepth);
}

###############################################################

method _printTextTable (Int      :$indent = 0,
                        ArrayRef :$rows,
                        Str      :$onEmpty = '[none]') {

	my $indentPadding = ' ' x $indent;
	my @lines;

	foreach my $row (@$rows) {

		my @line;
		push @line, $indentPadding;    #' ' x $indent if $indent;

		if ( ref($row) eq 'ARRAY' ) {
			push @line, @$row;
		}
		else {
			push @line, $row;
		}

		push @lines, \@line;
	}

	if ( !@lines ) {
		push @lines, [ $indentPadding, $onEmpty ];
	}

	if (@lines) {
		my $t = Text::Table->new;
		$t->load(@lines);
		print $t;
	}
}

method _moduleOverviewCleanViewMerged (
                                  Str  :$moduleName!,
                                  Bool :$showInheritedPrivateAttributes,
                                  Bool :$showInheritedPrivateMethods,
        Util::Medley::Module::Overview :$moduleOverview!
) {

	my $mo            = $moduleOverview;
	my $isMooseModule = $mo->isMooseModule;

	my $header   = "MODULE OVERVIEW";
	my $remWidth = 80 - length($header);
	my $padding  = ' ' x int( $remWidth / 2 );
	$header = sprintf '%s%s%s', $padding, $header, $padding;

	my $t = Text::ASCIITable->new( { headingText => $header } );
	$t->setOptions( { hide_HeadLine => 1, hide_HeadRow => 1 } );
	$t->setCols('a');    # must set a column even though we block it
	print $t;

	say "Module Name:";
	$self->_printTextTable( indent => 4, rows => [$moduleName] );

	say '';
	say "Parents:";
	$self->_printTextTable( indent => 4, rows => [ $mo->getParents ] );

	say '';
	say "Uses:";
	$self->_printTextTable( indent => 4, rows => [ $mo->getImportedModules ] );

	say '';
	say "Constants:";
	$self->_printTextTable( indent => 4, rows => [ $mo->getConstants ] );

	if ($isMooseModule) {

		say '';
		say "Attributes:";
		$self->_printTextTable( indent => 4, rows => ['public:'] );
		$self->_printTextTable(
			indent => 8,
			rows   => [ $mo->getAllPublicAttributes ],
		);

		say '';
		$self->_printTextTable( indent => 4, rows => ['private:'] );
		$self->_printTextTable(
			indent => 8,
			rows   => [ $mo->getPrivateAttributes ]
		);
	}

	say '';
	say "Methods:";
	$self->_printTextTable( indent => 4, rows => ['public:'] );
	$self->_printTextTable(
		indent => 8,
		rows   => [ $mo->getAllPublicMethods ]
	);

	say '';
	$self->_printTextTable( indent => 4, rows => ['private:'] );
	$self->_printTextTable(
		indent => 8,
		rows   => [ $mo->getPrivateMethods ]
	);
}

method _moduleOverviewCleanView (
                                  Str  :$moduleName!,
                                  Bool :$showInheritedPrivateAttributes,
                                  Bool :$showInheritedPrivateMethods,
        Util::Medley::Module::Overview :$moduleOverview!
) {

	my $mo            = $moduleOverview;
	my $isMooseModule = $mo->isMooseModule;

	my $header   = "MODULE OVERVIEW";
	my $remWidth = 80 - length($header);
	my $padding  = ' ' x int( $remWidth / 2 );
	$header = sprintf '%s%s%s', $padding, $header, $padding;

	my $t = Text::ASCIITable->new( { headingText => $header } );
	$t->setOptions( { hide_HeadLine => 1, hide_HeadRow => 1 } );
	$t->setCols('a');    # must set a column even though we block it
	print $t;

	say "Module Name:";
	$self->_printTextTable( indent => 4, rows => [$moduleName] );

	say '';
	say "Parents:";
	$self->_printTextTable( indent => 4, rows => [ $mo->getParents ] );

	say '';
	say "Uses:";
	$self->_printTextTable( indent => 4, rows => [ $mo->getImportedModules ] );

	say '';
	say "Constants:";
	$self->_printTextTable( indent => 4, rows => [ $mo->getConstants ] );

	if ($isMooseModule) {

		say '';
		say "Attributes:";
		$self->_printTextTable( indent => 4, rows => ['public:'] );
		$self->_printTextTable(
			indent => 8,
			rows   => [ $mo->getPublicAttributes ]
		);

		say '';
		$self->_printTextTable( indent => 8, rows => ['inherited:'] );

		my %map;
		foreach my $aref ( $mo->getInheritedPublicAttributes ) {
			my ( $method, $from ) = @$aref;
			push @{ $map{$from} }, $method;
		}

		my $first = 1;
		foreach my $from ( $self->List->nsort( keys %map ) ) {

			if ($first) {
				$first = 0;
			}
			else {
				say '';
			}

			$self->_printTextTable( indent => 12, rows => [$from] );

			my @rows;
			foreach my $method ( $self->List->nsort( @{ $map{$from} } ) ) {
				push @rows, $method;
			}

			$self->_printTextTable( indent => 16, rows => \@rows );
		}

		say '';
		$self->_printTextTable( indent => 4, rows => ['private:'] );
		$self->_printTextTable(
			indent => 8,
			rows   => [ $mo->getPrivateAttributes ]
		);
	}

	say '';
	say "Methods:";
	$self->_printTextTable( indent => 4, rows => ['public:'] );
	$self->_printTextTable(
		indent => 8,
		rows   => [ $mo->getPublicMethods ]
	);

	say '';
	$self->_printTextTable( indent => 8, rows => ['inherited:'] );

	my %map;
	foreach my $aref ( $mo->getInheritedPublicMethods ) {
		my ( $method, $from ) = @$aref;
		push @{ $map{$from} }, $method;
	}

	my $first = 1;
	foreach my $from ( $self->List->nsort( keys %map ) ) {

		if ($first) {
			$first = 0;
		}
		else {
			say '';
		}

		$self->_printTextTable( indent => 12, rows => [$from] );

		my @rows;
		foreach my $method ( $self->List->nsort( @{ $map{$from} } ) ) {
			push @rows, $method;
		}

		$self->_printTextTable( indent => 16, rows => \@rows );
	}

	say '';
	$self->_printTextTable( indent => 4, rows => ['private:'] );
	$self->_printTextTable(
		indent => 8,
		rows   => [ $mo->getPrivateMethods ]
	);
}

method _moduleOverviewDefaultView (
                                  Str  :$moduleName!,
                                  Bool :$showInheritedPrivateAttributes,
                                  Bool :$showInheritedPrivateMethods,
        Util::Medley::Module::Overview :$moduleOverview!
    ) {

	my $mo            = $moduleOverview;
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
		table      => $t,
		section    => $section,
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

1;
