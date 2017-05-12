package XML::Table2XML;

use 5.006001; use strict; use warnings;
use Encode 'decode';
use Carp;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parseHeaderForXML addXMLLine commonParent offsetNodesXML);
our $VERSION = '1.4';
my $LINEFEED = "";
my $XMLDIRECTIVE = '<?xml version="1.0"?>';
my $ENCODING = 'iso-8859-1';

=head1 NAME

XML::Table2XML - Generic conversion of tabular data to XML by reverting Excel's flattener methodology.

=head1 SYNOPSIS

	use XML::Table2XML;
	my $outXML = "";
	# first parse column path headers for attribute names, id columns and special common sibling mark ("//")
	parseHeaderForXML("rootNodeName", ['/@id','/@name2','/a']);
	# then walk through the whole data to build the actual XML string into $outXML
	my @datarows = ([1,"testName","testA"],
					[1,"testName","testB"],
					[1,"testName","testC"]);
	for my $lineData (@datarows) {
		$outXML.=addXMLLine($lineData);
	}
	#finally finish the XML and reset the static vars
	$outXML.=addXMLLine(undef);
	print $outXML;
	# yields:
	# <?xml version="1.0"?>
	# <rootNodeName id="1" name2="testName"><a>testA</a><a>testB</a><a>testC</a></rootNodeName>

=head1 DESCRIPTION

table2xml is an algorithm having two functions that allow the conversion of tabular data to XML
without using XSLT. This is achieved by reverting the "Flattener" methodology used by Microsoft Excel
to convert the XML tree format to a two-dimensional table
(see Opening XML Files in Excel and INFO: Microsoft Excel 2002 and XML).

This reversion is achieved by:

1. (possibly) modifying the flattened table a bit to enable a simpler processing of the data,

2. sequentially processing the data column- and row wise. 

The whole algorithm is done without the aid of any XML library, so it lends itself to easy translation
into other environments and languages.

Producing the XML:

1. invoke parseHeaderForXML, using a line with the rootnode and path information.

2. After parsing the header info, the table data can be processed row by row by calling addXMLLine.
The current data row is provided in the single argument lineData, the built XML is string returned and can be collected/written.

3. A final call to addXMLLine with lineData == undef restores the static variables and finalizes the XML string (closes any still open tags).

=head2 Public Functions

=head3 parseHeaderForXML ($rootNodeName,\@header,$LINEBREAKS,$XMLDIRECTIVE,$ENCODING)

B<rootNodeName> is the name of the common root node. Any I</@rootAttributes> and I</#text> will be placed under
respectively after this root node.

B<header> is a list of paths denoting the "place" of the data in the targeted XML. Following special cases are allowed:

=over

=item * Plain elements

are denoted by I</node/subnode/subsubnode/etc.../elementName>

=item * Attributes

are denoted by I</node/subnode/subsubnode/etc.../@attributeName>

=item * "ID" nodes

are denoted by I</node/subnode/subsubnode/etc.../#id> (they are not being ouptut) 

=item * special common sibling nodes

are denoted by a leading double slash (I<//>)
special common sibling nodes are used for nested common sibling nodes (e.g., C<< <root><a><b>test</b></a><otherData>...<root> >> 
or C<< <root><a><b>test1</b><z>test2</z></a><otherData>...<root> >> ) must be located at the beginning of the last node within the nested sibling.

=item * a root text element

is denoted by I</#text>

=item * root attributes

are given as I</@rootNodeAttribute>

=back

B<LINEBREAKS> specifies whether '\n' should be added after each datarow for easier readablity, default is no linebreaks

B<XMLDIRECTIVE> specifies any header being inserted before the root element, default is C<'<?xml version="1.0"?>'>.

B<ENCODING> denotes the Unicode Codification used to encode the string(s) returned by B<addXMLLine()>, default is C<'iso-8859-1'>


=head3 $returnedXML = addXMLLine(\@lineData)

B<lineData> is a list of data elements that are converted to XML following the parsed header information.

The produced XML is returned as a function value which can be concatenated or written to a file.
Bear in mind that the returned XML is just a part of a larger structure, so only after the last line has been processed and
B<addXMLLine(undef)> has been called, the XML structure is finished.

=head2 Prerequisites for column order and data layout

The layout of the columns (header = "data paths" and respective column data below) has to follow a certain layout:

=over

=item * child nodes always have to follow their parent nodes (i.e. /a/b/c is after /a or /a/b).

=item * "#id" columns and attributes belong to the same element node (e.g. /a/b/#id, /a/b/@att1 and /a/b/@att2) and therefore
have to be given consecutively and with the "#id" column first (attributes and  element node order is not important).

=item * related subnodes have to be grouped together (i.e. /a/b, /a/c, /a/x, /a/x/@att, ...), other subnodes have to follow.

The layout of the data below has to be as follows (recursively similar within the blocks for any sub-blocks):

 Block1PathHeaders            Block2PathHeaders       Block3PathHeaders
 Block1Data                   EMPTY                   EMPTY
 ...                          EMPTY                   EMPTY
 Block1Data                   EMPTY                   EMPTY
 EMPTY                        Block2Data              EMPTY
 EMPTY                        ...                     EMPTY
 EMPTY                        Block2Data              EMPTY
 EMPTY                        EMPTY                   Block3Data
 EMPTY                        EMPTY                   ...
 EMPTY                        EMPTY                   Block3Data
 
where the corresponding XML would then look like:

 <root>
 	<Block1>
 		<Block1subnode>
 		...
 		</Block1subnode>
 		<Block1subnode>
 		...
 		</Block1subnode>
 		..
 	</Block1>
 	<Block2>
 		<Block2subnode>
 		...
 		</Block2subnode>
 		<Block2subnode>
 		...
 		</Block2subnode>
 		..
 	</Block2>
 	<Block3>
 		<Block3subnode>
 		...
 		</Block3subnode>
 		<Block3subnode>
 		...
 		</Block3subnode>
 		..
 	</Block3>
 </root>

=item * Sibling nodes that are "common" to a whole subnode (e.g. C<< <subnode><commonSibling>value1</commonSibling><otherNodes>...</otherNodes></subnode> >>)
have to be first in the subnode and need to "span" the data there.

Example for subnode <a>:

 <?xml version="1.0"?>
 <root>
  <a>
   <z>TestB</z>
   <c>TestA1</c>
   <c>TestA2</c>
   <c>TestA3</c>
   <c>TestA4</c>
  </a>
 </root>
 
 /root
 /a/z/@x	/a/c
 TestB		TestA1
 TestB		TestA2
 TestB		TestA3
 TestB		TestA4


=item * In case you happen to own MS Excel, the easiest way to get that layout is to follow the steps below:

=over

=item 1. Open Target XML File in Excel (don't forget the XML directive there: "<?xml version="1.0"?>" !!!!)

=item 2. remove any "#agg" columns (used to differentiate between numerical common siblings and "real" data) 

=item 3. move the common root (or the common subnode) siblings leftmost of the root (or resp. Subnode)

Examples:

 <?xml version="1.0"?>
 <root>
 <x z="testAttX">testX</x>
 <a><b><c>TestA1</c>
 <c>TestA2</c>
 <c>TestA3</c>
 <c>TestA4</c></b></a>
 </root>
 
 /root						/root
 /a/b/c	/x	/x/@z				/x	/x/@z		/a/b/c
 TestA1	testX	testAttX			testX	testAttX	TestA1
 TestA2	testX	testAttX	modify to->	testX	testAttX	TestA2
 TestA3	testX	testAttX			testX	testAttX	TestA3
 TestA4	testX	testAttX			testX	testAttX	TestA4
 
 <?xml version="1.0"?>
 <root>
 <a><z x="TestB"></z><b><c>TestA1</c>
 <c>TestA2</c>
 <c>TestA3</c>
 <c>TestA4</c></b></a>
 </root>
 
 /root				/root
 /a/b/c	/a/z/@x			/a/z/@x	/a/b/c
 TestA1	TestB			TestB	TestA1
 TestA2	TestB	modify to->	TestB	TestA2
 TestA3	TestB			TestB	TestA3
 TestA4	TestB			TestB	TestA4

=item 4. For nested common sibling nodes (e.g., C<< <root><a><b>test</b></a><otherData>...<root> >> or
C<< <root><a><b>test1</b><c>test2</c></a><otherData>...<root> >>), write a double slash at the beginning of the last node within the nested sibling.

Example (also includes column moving as in the examples above):

 <?xml version="1.0"?>
 <root>
 <a n=""CW""><l c=""oalp""><p v=""A1""></p></l>
 <f c=""oalvl""><p v=""W""></p></f>
 <p n=""target""></p></a>
 <a n=""CD""><l c=""oalp""><p v=""A1""></p></l>
 <f c=""oalvl""><p v=""D""></p></f></a>
 <r><pr v=""TEST""></pr>
 <ar r=""test2""></ar>
 <ar r=""test4""></ar></r>
 </root>
 
 /root
 /a/@n	/a/f/@c	/a/f/p/@v	/a/l/@c	/a/l/p/@v	/a/p/@n	/r/ar/@r	/r/pr/@v
 CW	oalvl	W		oalp	A1		target		
 CD	oalvl	D		oalp	A1			
								test2		TEST
								test4		TEST
 modify to -->
 
 /root
 /a/@n	/a/l/@c	//a/l/p/@v	/a/f/@c	//a/f/p/@v	/a/p/@n	/r/pr/@v	/r/ar/@r
 CW	oalp	A1		oalvl	W		target		
 CD	oalp	A1		oalvl	D			
								TEST		test2
								TEST		test4


=item 5. For a first column of a subnode list that is not being a "primary key" column
(i.e., having empty cells or continuous equal values), introduce an artificial #id column.

Examples:

 <?xml version="1.0"?>
 <root>
 <a x="test1">testA</a>
 <a x="test2"></a>
 </root>
 
 /root				/root				
 /a	/a/@x	modify to->	/a/#id	/a	/a/@x		
 testA	test1			1	testA	test1		
 	test2			2		test2		
 
 <?xml version="1.0"?>
 <root>
 <co><f><a>Numeric</a></f></co>
 <co><f><a>VarChar</a></f></co>
 <co><f><a>VarChar</a></f></co>
 <co><f><a>VarChar</a></f></co>
 <co><f><a>VarChar</a></f></co>
 <co><f><a>DBTimeStamp</a></f></co>
 <co><f><a>VarChar</a><fk>JOB_ID</fk><fl>JOB_TITLE</fl></f></co>
 <co><f><a>Numeric</a><fk>TESTID</fk><fl>TESTn</fl></f></co>
 <co><f><a>Numeric</a></f></co>
 <co><f><a>Numeric</a><fk>EMPLOYEE_ID</fk><fl>FIRST_n</fl></f></co>
 <co><f><a>Numeric</a><fk>DEPARTMENT_ID</fk><fl>DEPARTMENT_n</fl></f></co>
 </root>
 
 /root					modify to->	/root			
 /co/f/a	/co/f/fk	/co/f/fl		/co/#id	/co/f/a	/co/f/fk	/co/f/fl
 Numeric						1	Numeric		
 VarChar						2	VarChar		
 VarChar						3	VarChar		
 VarChar						4	VarChar		
 VarChar						5	VarChar		
 DBTimeStamp						6	DBTimeStamp	
 VarChar	JOB_ID	JOB_TITLE			7	VarChar	JOB_ID		JOB_TITLE
 Numeric	TESTID	TESTn				8	Numeric	TESTID		TESTn
 Numeric						9	Numeric		
 Numeric	EMPLOYEE_ID	FIRST_n			10	Numeric	EMPLOYEE_ID	FIRST_n
 Numeric	DEPARTMENT_ID	DEPARTMENT_n		11	Numeric	DEPARTMENT_ID	DEPARTMENT_n

=item 6. Use the header row and rootnodeName for your data layout.

=back

=back

=head1 LIMITATIONS

Generally, pay close attention to the ordering of columns and constraints on the data as described above, 
since the algorithm in writeLine doesn't check for validity, thus producing invalid XML in case of failing to follow preparation steps correctly.

In mixed content nodes, the only way to correctly (re)produce the XML is for ONE content being right after the node name.
There's currently no way to produce mixed content nodes with more than one text node (e.g., C<< <node>text1<subnode>Test</subnode>text2</node> >> and the like).

Same sequential parent nodes are "factored" out by the flattener, so the unflattening algorithm treats them as being factored out,
which means there is no way to exactly reproduce (C<< <a><b>test1</b></a><a><b>test2</b></a> >>, this would be processed as C<< <a><b>test1</b><b>test2</b></a> >>, which is semantically equal, but not the same...).

=head1 REFERENCE

for a detailed discussion of the flattening algorithmm in Excel see L<http://support.microsoft.com/kb/282161/EN-US> and L<http://support.microsoft.com/kb/288215/EN-US>

=head1 AUTHOR

Roland Kapl, rkapl@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Roland Kapl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

my $rootNodeName;
my @colPaths; # the path informations in the columns
my @specialCommonSibling; # specifies columns marked with "//" at beginning
my @isIDCol; # whether the current column is an "id" column (../#id)
my @attrNames; # attribute name if column path specifies attribute (../@name)
 
# parseHeaderForXML
#
# parses the column path headers (header) for attributes (attrNames), whether headers are id columns (isIDCol) and
# special common sibling marks ("//", specialCommonSibling), also strips the attributes and ids from the
# node path (put into colPaths).
sub parseHeaderForXML {
	my ($rootNode,$header,$LINEBREAKS,$XMLDIR,$ENCODE) = @_;
	
	$LINEFEED = "\n" if $LINEBREAKS;
	$XMLDIRECTIVE = $XMLDIR if $XMLDIR;
	$ENCODING = $ENCODE if $ENCODE;
	undef(@colPaths);undef(@attrNames);undef(@isIDCol);undef(@specialCommonSibling);
	croak "no rootnode name given !" unless $rootNode;
	$rootNodeName=$rootNode;
	my $colCount = scalar @$header;
	croak "no list of headers given !" unless $colCount > 0;
	# Loop accross columns...
	for my $colCounter (1..$colCount) {
		my $thisCellValue = $header->[$colCounter-1];
		croak "no valid header given: ". $thisCellValue unless $thisCellValue =~ /\//;
		$specialCommonSibling[$colCounter] = 0;
		if ($thisCellValue =~ /^\/\//) {
			$specialCommonSibling[$colCounter] = 1;
			$thisCellValue =~ s/^\///;
		}
		$isIDCol[$colCounter] = 0;
		$colPaths[$colCounter] = $thisCellValue;
		if ($thisCellValue =~ /\/#id$/) {
			$colPaths[$colCounter] = $thisCellValue;
			$colPaths[$colCounter] =~ s/\/#id$//;
			$isIDCol[$colCounter] = 1;
		}
		$attrNames[$colCounter] = "";
		if ($thisCellValue =~ /@/) {
			($attrNames[$colCounter]) = ($thisCellValue =~ /@(.*)/);
			($colPaths[$colCounter]) = ($thisCellValue =~ /(.*)\/@/);
		}
	}
}

# addXMLLine
#
# outputs (and optionally attaches) XML for a single data line (lineData), XML structure defined in rootNodeName,
# colPaths , attrNames, isIDCol And specialCommonSibling (see new)
{
	# static vars..
	my $lastNodePath = ""; # the path of the last written column (after modification by siblingCloseXML)
	my $lastNodeColPath = ""; # the path of the last written column (without modification by siblingCloseXML)
	my $rowCounter = 0; # rowCounter is needed for checking whether we#re in first row (for attribute of rootnode)
	my @lastColValue; # previous row's values
	my $siblingCloseReset = 0; # did we reset siblingCloseXML after the last row?

	sub addXMLLine {
		my ($lineData) = @_;
		my $strXML="";
		my $colCount = (scalar @colPaths) -1;
		# use this (lineData = NULL) for resetting static vars and finishing resultXML
		if (!defined($lineData)) {
			my $retXML = decode($ENCODING,offsetNodesXML($lastNodePath, "", 1).$LINEFEED."</$rootNodeName>");
			undef @lastColValue; $rowCounter = 0; $lastNodePath = ""; $lastNodeColPath = ""; $siblingCloseReset = 0;
			return $retXML;
		}
		if (!@lastColValue) {
		  $lastColValue[$_] = "" for (0..$colCount);
		}
		$rowCounter++;
		# Now loop accross columns...
		my $openXML = ""; my $attrXML = ""; my $closeXML = "";

		my $curColPath = ""; my $parentPath = ""; my $lastCommonNode = ""; my $curNode = ""; my $curPath = "";
		my $parentWasCreated = 0; my $allowSiblingClose = 0; my $addAnIDNode = 0; my $LFwritten = 0; my $noNodeYetCreated = 1;
		my $curNodeValue = ""; my $lastPossibleParent = ""; my $preventCommonNodeClose = 0; my $siblingCloseXML = "";
		my $rootAttXML = ""; my $rootText = "";
		
		for my $colCounter (1 .. $colCount) {
			my $thisCellValue = xmlCorrectChars($lineData->[$colCounter-1]);

			# we have a different common node, so finish previous and begin a new common node
			if ($curColPath ne $colPaths[$colCounter]) {
				# reset parentPath
				$parentPath = "" if commonParent($colPaths[$colCounter], $parentPath) ne $parentPath;

				# find max. common parent against last column,
				# if nothing found and lastPossibleParent not contained in current col then set to lastPossibleParent
				# store current path as lastPossibleParent
				$curPath = $colPaths[$colCounter];
				if ($thisCellValue ne "") {
					$parentPath = commonParent($curPath, $lastPossibleParent);
					$lastPossibleParent = $curPath;
				}

				# write combined previous colPath's XML parts and reset them, also do setting of siblingClose right after
				if ($curNodeValue ne "" or $attrXML ne "" or $addAnIDNode) {
					$strXML.= $closeXML.($rowCounter > 1 and !$LFwritten ? $LINEFEED : "").$openXML."<".$curNode.$attrXML.">".$curNodeValue;
					$lastNodePath = $curColPath; $LFwritten = 1; $lastNodeColPath = $curColPath; $noNodeYetCreated = 0;
					my $potCommonParent = commonParent($curColPath, $curPath);
					$parentWasCreated = 0;
					$parentWasCreated = 1 if $potCommonParent ne "";

					# siblingCloseXML is for closing nodes not being parent of next, thus allowing nodes to be a common sibling to a whole complex subelement!
					# entry if last column (curColPath) not contained in current (curPath)
					if ($allowSiblingClose and $potCommonParent ne $curColPath) {
						if ($specialCommonSibling[$colCounter - 1]) {
							$siblingCloseXML = offsetNodesXML($curColPath, $potCommonParent, 1);
							# lastNodePath: /a/b/c/d -> potCommonParent: /a/b -> lastNodePath /a/b
							$lastNodePath = $potCommonParent;
						}
						else {
							my ($cutLastNode) = ($curColPath =~ /.*\/(.*?)$/);
							$siblingCloseXML = "</$cutLastNode>";
							($lastNodePath) = ($lastNodePath =~ /(.*)\//) if ($lastNodePath ne "");
						}
					}
				}

				# if we have remembered a siblingClose across rows (is closed at the end of the row and may not cause
				# closing of the common root in the normal closeXML
				if ($specialCommonSibling[$colCounter - 1] and $siblingCloseReset) {
					$preventCommonNodeClose = 1;
				}

				# if we have a siblingClose, do it here
				# (as it could also happen after some empty same common node columns, which wouldn#t enter into set siblingClose)
				if ($siblingCloseXML ne "" and $thisCellValue ne "") {
					$strXML.= $siblingCloseXML;
					$siblingCloseXML = "";
				}
				$curNodeValue = ""; $closeXML = ""; $openXML = ""; $attrXML = ""; $addAnIDNode = 0;

				# creation of XML parts for new common node
				$curColPath = $colPaths[$colCounter];
				($curNode) = ($curColPath =~ /.*\/(.*?)$/);

				# need that for closing common sibling (contained in current column) during next loop run
				$allowSiblingClose = 0;
				if ($thisCellValue ne "" and
					($thisCellValue ne $lastColValue[$colCounter] or $parentWasCreated) and
					$colPaths[$colCounter] ne "/#text") {
					$allowSiblingClose = 1;
				}

				# make the openXML and closeXML parts for current column (written to strXML in next loop)
				#
				# parentWasCreated is for cases where columns accidentally have the same value as above,
				# but we know we are in a subnode of a parent (parentWasCreated = true)
				if ($thisCellValue ne $lastColValue[$colCounter] or $parentWasCreated) {

					# open new nodes from current parent to current path when stepping down subnodes into openXML
					# only for nonempty cells and if we're in the same column as before, there's no need for open part
					if ($thisCellValue ne "" and $lastNodeColPath ne $curColPath and
						($parentWasCreated or $parentPath eq "" or $noNodeYetCreated)) {
						$openXML = offsetNodesXML($curColPath, $parentPath);
					}

					# close Nodes from last open path to current path into closeXML
					if ($thisCellValue ne "" and $lastNodePath ne "" and !$parentWasCreated and $siblingCloseXML eq "") {
						my $potCommonParent = commonParent($lastNodePath, $curColPath);
						# decide whether to close last node of common parent:
						# No closing if we are in the same column as before
						my $notSameColumn = ($lastNodeColPath ne $curColPath);
						# current column is parent of lastNodePath -> common node close !
						my $curColIsParentOfLastNode = ($potCommonParent eq $curColPath);
						# to prevent premature closing for "parent rows",
						# BUT ONLY if commonSibling was not closed in previous row
						my $parentIsNotCommon = ($potCommonParent ne $lastCommonNode and !$preventCommonNodeClose);
						my $commonNodeClose = ($notSameColumn and ($parentIsNotCommon or $curColIsParentOfLastNode));
						$closeXML = offsetNodesXML($lastNodePath, $curColPath, 1,$commonNodeClose);
					}
				}

				# lastCommonNode: determines whether we can close up to common parent
				# (common parent of lastNodePath and current column may not be the last common Node path)
				if ($thisCellValue ne "" and ($thisCellValue eq $lastColValue[$colCounter]) and $noNodeYetCreated) {
					$lastCommonNode = $colPaths[$colCounter];
				}
			}

			# now for the content: id columns, plain elements and attributes...
			if ($thisCellValue ne "" and ($thisCellValue ne $lastColValue[$colCounter] or $parentWasCreated)) {
				# check whether last column was id column -> ceate node...
				if ($isIDCol[$colCounter]) {
					$addAnIDNode = 1; $parentWasCreated = 1;
				}

				# if we have a plain element node, remember value for later
				if (!$isIDCol[$colCounter] and $attrNames[$colCounter] eq "") {
					if ($rowCounter == 1 and $colPaths[$colCounter] eq "/#text") {
						$rootText = $thisCellValue;
					}
					else {
						$curNodeValue = $thisCellValue;
					}
				}

				# for attribute nodes create either with node name or just the attribute (if other was set before
				if ($attrNames[$colCounter] ne "") {
					if ($rowCounter == 1 and $colPaths[$colCounter] eq "") {
						$rootAttXML.= " " . $attrNames[$colCounter] . '="' . $thisCellValue . '"';
					}
					else {
						$attrXML.= " " . $attrNames[$colCounter] . "=\"$thisCellValue\"";
					}
					$parentWasCreated = 1;
				}
			}
			$lastColValue[$colCounter] = $thisCellValue;
		}# column

		# at end of row, write combined previous colPath's XML parts and reset
		if ($curNodeValue ne "" or $attrXML ne "" or $addAnIDNode) {
			 $strXML.= $closeXML.($rowCounter > 1 and !$LFwritten ? $LINEFEED : "").$openXML."<".$curNode.$attrXML.">".$curNodeValue;
			 $lastNodePath = $curColPath; $LFwritten = 1; $lastNodeColPath = $curColPath;
		}
		# write out siblingCloseXML if it wasn't closed already (meaning that remainder of row was empty !)
		$siblingCloseReset = 0;
		if ($siblingCloseXML ne "") {
			$siblingCloseReset = 1;
			$strXML.= $siblingCloseXML;
			$siblingCloseXML = ""
		}
		# only in first row: create root node attributes and root element
		if ($rowCounter == 1) {
			$strXML = $XMLDIRECTIVE.$LINEFEED."<".$rootNodeName.$rootAttXML.">".$rootText.$LINEFEED.$strXML;
		}
		return decode($ENCODING,$strXML);
	}
}

# commonParent
#
# return potential common parent path, e.g.
# /a/b/c/d and /a/b/g/j return common parent /a/b
sub commonParent {
	my ($currentPath, $potParent) = @_;
	my $commonParent = "";

	my @curColPathNodes = split ("\/", $currentPath);
	my @parentPathNodes = split("\/", $potParent);
	my $curColPathNodesCount = scalar(@curColPathNodes);
	my $parentPathNodesCount = scalar(@parentPathNodes);
	for my $i (1 .. $curColPathNodesCount - 1) {
		last if $i > $parentPathNodesCount;
		last if !defined($parentPathNodes[$i]) or $curColPathNodes[$i] ne $parentPathNodes[$i];
		$commonParent.= "/".$curColPathNodes[$i];
	}
	return $commonParent;
}

# offsetNodesXML
#
# return offset path of NodesCurrent after subtracting NodesParent in XML opening or closing form (closeFlag=True)
# e.g.  /a/b/ and /a/b/g/j (offset g/j) return <g><j> or </j></g>
# the last node is ignored for opening (as it is seperately treated by the algortithm)
# Additionally include the last node of the common root for closing if includeCommonRoot=True
# Following special cases exist:
# NodesParent = "": open or close NodesCurrent
# NodesCurrent = NodesParent and in case of closing: close the common last node
# NodesCurrent and NodesParent have no common parent: open or close NodesCurrent
sub offsetNodesXML {
	my ($NodesCurrent, $NodesParent, $closeFlag, $includeCommonRoot) = @_;

	my $theOffset; my $additionalTopNode = ""; my $offsetNodesXML;
	my $potCommonParent = commonParent($NodesCurrent, $NodesParent);
	if ($NodesParent eq "") {
		$theOffset = $NodesCurrent;
		# for closing same node columns, we use only the leaf node
	} elsif ($NodesCurrent eq $NodesParent and $closeFlag) {
		($theOffset) = ($NodesParent =~ /.*(\/.*?)$/);
		$potCommonParent = "";
	} elsif ($potCommonParent ne "") {
		if ($includeCommonRoot and $closeFlag) {
			($additionalTopNode) = ($potCommonParent =~ /.*\/(.*?)$/);
		}
		$theOffset = $NodesCurrent;
		$theOffset =~ s/^$potCommonParent//;
	} else {
		$theOffset = $NodesCurrent;
	}
	my @offsetNodes = split("\/", $theOffset);
	my $closeFlagSign = ($closeFlag ? "/" : "");
	my $stepDir = ($closeFlag ? -1 : 1);
	my $startNode = ($closeFlag ? scalar(@offsetNodes) -1 : 1);  # when closing, always from last node down to common
	my $endNode = ($closeFlag ? 1 : scalar(@offsetNodes) - 2);  # when opening, open only up one before current (currentNode is set specially)
	if (scalar(@offsetNodes) > 1) {
		for (my $t = $startNode; ($endNode - $t + $stepDir) != 0; $t+=$stepDir) {
			$offsetNodesXML.= "<" . $closeFlagSign . $offsetNodes[$t] . ">";
		}
	}
	# add common node as final closing when closing and includeCommonRoot
	$offsetNodesXML.= ($additionalTopNode ne "" ? "</$additionalTopNode>" : "")
}

# xmlCorrectChars
#
# return corrected (= quoted) XML special characters contained in nodeValue
sub xmlCorrectChars {
	my ($nodeValue) = @_;
	$nodeValue = "" if !defined($nodeValue);
	$nodeValue =~ s/&/&amp;/;
	$nodeValue =~ s/</&lt;/;
	$nodeValue =~ s/>/&gt;/;
	$nodeValue =~ s/"/&quot;/;
	$nodeValue =~ s/#/&apos;/;
	return $nodeValue;
}

1;