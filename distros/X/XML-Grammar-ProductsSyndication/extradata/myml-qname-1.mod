<!-- file: myml-qname-1.mod -->

<!-- Bring in the datatypes - we use the URI.datatype PE for declaring the
     xmlns attributes. -->
<!ENTITY % MyML-datatypes.mod
         SYSTEM "xhtml-datatypes-1.mod" >
%MyML-datatypes.mod;

<!-- By default, disable prefixing of this module -->
<!ENTITY % NS.prefixed "IGNORE" >
<!ENTITY % MyML.prefixed "%NS.prefixed;" >

<!-- Declare the actual namespace of this module -->
<!ENTITY % MyML.xmlns "http://www.example.com/xmlns/myml" >

<!-- Declare the default prefix for this module -->
<!ENTITY % MyML.prefix "myml" >

<!-- If this module's namespace is prefixed -->
<![%MyML.prefixed;[
  <!ENTITY % MyML.pfx  "%MyML.prefix;:" >
]]>
<!ENTITY % MyML.pfx  "" >

<!-- This entity is ALWAYS prefixed, for use when adding our
     attributes to an element in another namespace -->
<!ENTITY % MyML.xmlns.attrib.prefixed
   "xmlns:%MyML.prefix;  %URI.datatype;  #FIXED '%MyML.xmlns;'"
>

<!-- Declare a Parameter Entity (PE) that defines any external namespaces 
     that are used by this module -->
<!ENTITY % MyML.xmlns.extra.attrib "" >

<!-- Declare a PE that defines the xmlns attributes for use by MyML. -->
<![%MyML.prefixed;[
<!ENTITY % MyML.xmlns.attrib
   "%MyML.xmlns.attrib.prefixed;
    %MyML.xmlns.extra.attrib;"
>
<!-- Make sure that the MyML namespace attributes are included on the XHTML
     attribute set -->
<!ENTITY % XHTML.xmlns.extra.attrib
	"%MyML.xmlns.attrib;" >
]]>
<!-- if we are not prefixed, then our elements should have the default
     namespace AND the prefixed namespace is added to the XHTML set
	 because our attributes can be referenced on those elements
-->
<!ENTITY % MyML.xmlns.attrib
   "xmlns	%URI.datatype;	#FIXED '%MyML.xmlns;'
   	%MyML.xmlns.extra.attrib;"
>
<!ENTITY % XHTML.xmlns.extra.attrib
   "%MyML.xmlns.attrib.prefixed;"
>
<!-- Now declare the element names -->

<!ENTITY % MyML.myelement.qname "%MyML.pfx;myelement" >
<!ENTITY % MyML.myotherelement.qname "%MyML.pfx;myotherelement" >
