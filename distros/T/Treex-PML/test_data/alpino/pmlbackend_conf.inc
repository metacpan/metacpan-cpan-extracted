<?xml version="1.0"?>
<pmlbackend xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
  <head>
    <schema href="pmlbackend_conf_schema.xml"/>
  </head>
  <transform_map>
    <!-- 
      Conversion from Aplino XML format.
    -->
    <transform id="alpino" test="alpino_ds[@version='1.3']">
      <in type="xslt" href="alpino2pml.xsl"/>
      <out type="xslt" href="pml2alpino.xsl"/>
    </transform>
  </transform_map>
</pmlbackend>
