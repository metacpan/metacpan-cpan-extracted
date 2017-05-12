<!ENTITY % attributes SYSTEM "shared/attributes.mod">
%attributes;

<!ENTITY % dirtree "(directory)">
<!ENTITY % dirtree.attrs "">

<!ENTITY % directory "(directory|file)*">
<!ENTITY % directory.attrs "%attr.name;">

<!ENTITY % file.attrs "%attr.name;">

<!ELEMENT dirtree %dirtree;>
<!ATTLIST dirtree %dirtree.attrs;>

<!ELEMENT directory %directory;>
<!ATTLIST directory %directory.attrs;>

<!ELEMENT file EMPTY>
<!ATTLIST file %file.attrs;>
