<!ENTITY % attributes SYSTEM "shared/attributes.mod">
%attributes;

<!ENTITY % entities SYSTEM "shared/entities-levels2to3.mod">
%entities;

<!--  Level 3 specific entities -->

<!ENTITY % directory "(path,modify-time,access-time,(directory|file)*)">
<!ENTITY % directory.attrs "%attr.name;
	                    depth NMTOKEN #REQUIRED
			    %attr.ids;">

<!ENTITY % head "(path, details, depth)">
<!ENTITY % head.attrs "version CDATA #REQUIRED">

<!ENTITY % file "(mode,size,modify-time)">
<!ENTITY % file.attrs "%attr.name;
	               %attr.ids;">

<!ENTITY % access-time "(#PCDATA)">
<!ENTITY % access-time.attrs "%attr.epoch;">

<!-- -->

<!ELEMENT dirtree %dirtree;>
<!ATTLIST dirtree %dirtree.attrs;>

<!ELEMENT directory %directory;>
<!ATTLIST directory %directory.attrs;>

<!ELEMENT file %file;>
<!ATTLIST file %file.attrs;>

<!ELEMENT head %head;>
<!ATTLIST head %head.attrs;>

<!ELEMENT path    %path;>
<!ELEMENT details %details;>
<!ELEMENT depth   %depth;>

<!ELEMENT modify-time %modify-time;>
<!ATTLIST modify-time %modify-time.attrs;>

<!ELEMENT mode %mode;>
<!ATTLIST mode %mode.attrs;>

<!ELEMENT size %size;>
<!ATTLIST size %size.attrs;>

<!ELEMENT access-time %access-time;>
<!ATTLIST access-time %access-time.attrs;>
