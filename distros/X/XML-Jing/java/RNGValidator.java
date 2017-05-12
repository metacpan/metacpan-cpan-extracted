
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.net.URLClassLoader;

import javax.xml.XMLConstants;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.xml.sax.SAXException;

public class RNGValidator
{
	
	Validator validator;
	/**
	 * 
	 * @param schemaLocation Path to RNG file to be used to validate XML files
	 * @param compact True if the given RNG file uses compact syntax, false if XML.
	 * @throws SAXException 
	 */
	public RNGValidator(String schemaLocation, boolean compact) throws SAXException{
		if(compact)
			System.setProperty(SchemaFactory.class.getName() + ":" + XMLConstants.RELAXNG_NS_URI, "com.thaiopensource.relaxng.jaxp.CompactSyntaxSchemaFactory");
		else
			System.setProperty(SchemaFactory.class.getName() + ":" + XMLConstants.RELAXNG_NS_URI, "com.thaiopensource.relaxng.jaxp.XMLSyntaxSchemaFactory");
		
		SchemaFactory factory = SchemaFactory.newInstance(XMLConstants.RELAXNG_NS_URI);
        Schema schema = factory.newSchema(new File(schemaLocation));

        //get a validator from the schema
        validator = schema.newValidator();
	}

	/**
	 * 
	 * @param xmlFileName Name of XML file to validate
	 * @return Error thrown by validator if the file was invalid, or null if the file was valid
	 * @throws IOException 
	 */
	public String validate(String xmlFileName) throws IOException{

            // Check the document
            try
            {
                validator.validate(new StreamSource(new File(xmlFileName)));
            }
            catch (SAXException ex)
            {
                return ex.getMessage();
            }
            return null;
	}
	
    public static void main(String[] args) throws SAXException, IOException
    {
    	RNGValidator validator = new RNGValidator(args[0],false);
    	System.out.println(validator.validate(args[1]));
    }

}