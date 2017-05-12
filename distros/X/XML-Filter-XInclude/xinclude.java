/*--

 Copyright 2001 Elliotte Rusty Harold.
 All rights reserved.

 I haven't yet decided on a license.
 It will be some form of open source.

 THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED.  IN NO EVENT SHALL ELLIOTTE RUSTY HAROLD OR ANY
 OTHER CONTRIBUTORS TO THIS PACKAGE
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 */

package com.macfaq.xml;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.Locator;
import org.xml.sax.helpers.XMLReaderFactory;
import org.xml.sax.helpers.XMLFilterImpl;
import org.xml.sax.helpers.NamespaceSupport;

import java.net.URL;
import java.net.URLConnection;
import java.net.MalformedURLException;
import java.io.UnsupportedEncodingException;
import java.io.IOException;
import java.io.InputStream;
import java.io.BufferedInputStream;
import java.io.InputStreamReader;
import java.util.Stack;

/**
 * <p>
 *  This is a SAX filter which resolves all XInclude include elements
 *  before passing them on to the client application. Currently this
 *  class has the following known deviation from the XInclude specification:
 * </p>
 *  <ol>
 *   <li>XPointer is not supported.</li>
 *  </ol>
 *
 *  <p>
 *    Furthermore, I would definitely use a new instance of this class
 *    for each document you want to process. I doubt it can be used
 *    successfully on multiple documents. Furthermore, I can virtually
 *    guarantee that this class is not thread safe. You have been
 *    warned.
 *  </p>
 *
 *  <p>
 *    Since this class is not designed to be subclassed, and since
 *    I have not yet considered how that might affect the methods 
 *    herein or what other protected methods might be needed to support 
 *    subclasses, I have declared this class final. I may remove this 
 *    restriction later, though the use-case for subclassing is weak.
 *    This class is designed to have its functionality extended via a
 *    a horizontal chain of filters, not a 
 *    vertical hierarchy of sub and superclasses.
 *  </p>
 *
 *  <p>
 *    To use this class: 
 *  </p>
 *  <ol>
 *   <li>Construct an <code>XIncludeFilter</code> object with a known base URL</li>
 *   <li>Pass the <code>XMLReader</code> object from which the raw document will 
 *       be read to the <code>setParent()</code> method of this object. </li>
 *   <li>Pass your own <code>ContentHandler</code> object to the 
 *       <code>setContentHandler()</code> method of this object. This is the 
 *       object which will receive events from the parsed and included
 *       document.
 *   </li>
 *   <li>Optional: if you wish to receive comments, set your own 
 *       <code>LexicalHandler</code> object as the value of this object's
 *       http://xml.org/sax/properties/lexical-handler property.
 *       Also make sure your <code>LexicalHandler</code> asks this object 
 *       for the status of each comment using <code>insideIncludeElement</code>
 *       before doing anything with the comment. 
 *   </li>
 *   <li>Pass the URL of the document to read to this object's 
 *       <code>parse()</code> method</li>
 *  </ol>
 * 
 *  <p> e.g.</p>
 *  <pre><code>XIncludeFilter includer = new XIncludeFilter(base); 
 *  includer.setParent(parser);
 *  includer.setContentHandler(new SAXXIncluder(System.out));
 *  includer.parse(args[i]);</code>
 *  </pre>
 * </p> *
 * @author Elliotte Rusty Harold
 * @version 1.0d8
 */
public final class XIncludeFilter extends XMLFilterImpl {

    public final static String XINCLUDE_NAMESPACE
     = "http://www.w3.org/2001/XInclude";

    private Stack bases = new Stack();
    private Stack locators = new Stack();
    
    // what if this isn't called????
    // do I need to check this in startDocument() and push something
    // there????
    public void setDocumentLocator(Locator locator) {
        locators.push(locator);
        String base = locator.getSystemId();
        try {
             bases.push(new URL(base));
        }
        catch (MalformedURLException e) {
            throw new UnsupportedOperationException("Unrecognized SYSTEM ID: " + base);
        }
        super.setDocumentLocator(locator);
    }
    
    
    // necessary to throw away contents of non-empty XInclude elements
    private int level = 0;

  /**
    * <p>
* This utility method returns true if and only if this reader is 
    * currently inside a non-empty include element. (This is <strong>
* not</strong> the same as being inside the node set whihc replaces
    * the include element.) This is primarily needed for comments
    * inside include elements. It must be checked by the actual
    * LexicalHandler to see whether a comment is passed or not.
    * </p>
*
    * @return boolean  
    */
    public boolean insideIncludeElement() {
      
        return level != 0;
      
    }
    
    
    public void startElement(String uri, String localName,
      String qName, Attributes atts) throws SAXException {
    
        if (level == 0) { // We're not inside an xi:include element

            // Adjust bases stack by pushing either the new
            // value of xml:base or the base of the parent
            String base = atts.getValue(NamespaceSupport.XMLNS, "base");
            URL parentBase = (URL) bases.peek();
            URL currentBase = parentBase;
            if (base != null) {
                try {
                    currentBase = new URL(parentBase, base); 
                }
                catch (MalformedURLException e) {
                    throw new SAXException("Malformed base URL: " 
                     + currentBase, e);
                }
            }
            bases.push(currentBase);
          
            if (uri.equals(XINCLUDE_NAMESPACE) && localName.equals("include")) {
                // include external document
                String href = atts.getValue("href");
                // Verify that there is an href attribute
                if (href==null) { 
                    throw new SAXException("Missing href attribute");
                }
                
                String parse = atts.getValue("parse");
                if (parse == null) parse = "xml";
                
                if (parse.equals("text")) {
                    String encoding = atts.getValue("encoding");
                    includeTextDocument(href, encoding); 
                }
                else if (parse.equals("xml")) {
                    includeXMLDocument(href); 
                }
                // Need to check this also in DOM and JDOM????
                else {
                    throw new SAXException(
                      "Illegal value for parse attribute: " + parse);
                }
                level++;
            }
            else {
                super.startElement(uri, localName, qName, atts);
            } 
        
        }  
      
    }

    public void endElement (String uri, String localName, String qName)
      throws SAXException {
        
        if (uri.equals(XINCLUDE_NAMESPACE) 
           && localName.equals("include")) {
            level--;
        }
        else if (level == 0) {
            bases.pop();
            super.endElement(uri, localName, qName);
        }
        
    }

    private int depth = 0;
     
    public void startDocument() throws SAXException {
        level = 0;
        if (depth == 0) super.startDocument(); 
        depth++;        
    }
    
    public void endDocument() throws SAXException {
      
        locators.pop();
        depth--;
        if (depth == 0) super.endDocument();
                
    }
    
    // how do prefix mappings move across documents????
    public void startPrefixMapping(String prefix, String uri)
      throws SAXException {
        if (level == 0) super.startPrefixMapping(prefix, uri);
    }
    
    public void endPrefixMapping(String prefix)
      throws SAXException {
        if (level == 0) super.endPrefixMapping(prefix);        
    }

    public void characters(char[] ch, int start, int length) 
      throws SAXException {
        
        if (level == 0) super.characters(ch, start, length);
    
    }

    public void ignorableWhitespace(char[] ch, int start, int length)
      throws SAXException {
        if (level == 0) super.ignorableWhitespace(ch, start, length);
    }

    public void processingInstruction(String target, String data)
      throws SAXException {
        if (level == 0) super.processingInstruction(target, data);
    }

    public void skippedEntity(String name) throws SAXException {
        if (level == 0) super.skippedEntity(name);
    }

    // convenience method for error messages
    private String getLocation() {
      
        String locationString = "";
        Locator locator = (Locator) locators.peek();
        String publicID = "";
        String systemID = "";
        int column = -1;
        int line = -1;
        if (locator != null) {
            publicID = locator.getPublicId();
            systemID = locator.getSystemId();
            line = locator.getLineNumber();
            column = locator.getColumnNumber();
        }
        locationString = " in document included from " + publicID
          + " at " + systemID 
          + " at line " + line + ", column " + column;

        return locationString;
        
    }
    
    
  /**
    * <p>
* This utility method reads a document at a specified URL
    * and fires off calls to <code>characters()</code>.
    * It's used to include files with <code>parse="text"</code>
* </p>
*
    * @param  url          URL of the document that will be read
    * @param  encoding     Encoding of the document; e.g. UTF-8, 
    *                      ISO-8859-1, etc.
    * @return void  
    * @throws SAXException if the requested document cannot
                           be downloaded from the specified URL
                           or if the encoding is not recognized
    */
    private void includeTextDocument(String url, String encoding) 
      throws SAXException {

        if (encoding == null || encoding.trim().equals("")) encoding = "UTF-8"; 
        URL source;
        try {
            URL base = (URL) bases.peek();
            source = new URL(base, url);
        }
        catch (MalformedURLException e) {
            UnavailableResourceException ex =
              new UnavailableResourceException("Unresolvable URL " + url
              + getLocation());
            ex.setRootCause(e);
            throw new SAXException("Unresolvable URL " + url + getLocation(), ex);
        }
        
        try {
            URLConnection uc = source.openConnection();
            InputStream in = new BufferedInputStream(uc.getInputStream());
            String encodingFromHeader = uc.getContentEncoding();
            String contentType = uc.getContentType();
            if (encodingFromHeader != null) encoding = encodingFromHeader;
            else {
                // What if file does not have a MIME type but name ends in .xml????
                // MIME types are case-insensitive
                // Java may be picking this up from file URL
                if (contentType != null) {
                    contentType = contentType.toLowerCase();
                    if (contentType.equals("text/xml") 
                      || contentType.equals("application/xml")   
                      || (contentType.startsWith("text/") && contentType.endsWith("+xml") ) 
                      || (contentType.startsWith("application/") && contentType.endsWith("+xml"))) {
                         encoding = EncodingHeuristics.readEncodingFromStream(in);
                    }
                }
            }
            InputStreamReader reader = new InputStreamReader(in, encoding);
            char[] c = new char[1024];
            while (true) {
                int charsRead = reader.read(c, 0, 1024);
                if (charsRead == -1) break;
                if (charsRead > 0) this.characters(c, 0, charsRead);
            }
        }
        catch (UnsupportedEncodingException e) {
            throw new SAXException("Unsupported encoding: " 
             + encoding + getLocation(), e);
        }
        catch (IOException e) {
            throw new SAXException("Document not found: " 
             + source.toExternalForm() + getLocation(), e);
        }

    }

  /**
    * <p>
* This utility method reads a document at a specified URL
    * and fires off calls to various <code>ContentHandler</code> methods.
    * It's used to include files with <code>parse="xml"</code>
* </p>
*
    * @param  url          URL of the document that will be read
    * @return void  
    * @throws SAXException if the requested document cannot
                           be downloaded from the specified URL.
    */
    private void includeXMLDocument(String url) 
      throws SAXException {

        URL source;
        try {
            URL base = (URL) bases.peek();
            source = new URL(base, url);
        }
        catch (MalformedURLException e) {
            UnavailableResourceException ex =
              new UnavailableResourceException("Unresolvable URL " + url
              + getLocation());
            ex.setRootCause(e);
            throw new SAXException("Unresolvable URL " + url + getLocation(), ex);
        }
        
        try {
            // make this more robust
            XMLReader parser; 
            try {
                parser = XMLReaderFactory.createXMLReader();
            } 
            catch (SAXException e) {
                try {
                    parser = XMLReaderFactory.createXMLReader(
                      "org.apache.xerces.parsers.SAXParser"
                    );
                }
                catch (SAXException e2) {
                    System.err.println("Could not find an XML parser");
                    return;
                }
            }
            parser.setContentHandler(this);
            // save old level and base
            int previousLevel = level;
            this.level = 0;
            if (bases.contains(source)) {
                Exception e = new CircularIncludeException(
                  "Circular XInclude Reference to " + source + getLocation()
                );
                throw new SAXException("Circular XInclude Reference", e);
            }
            bases.push(source);
            parser.parse(source.toExternalForm());
            // restore old level and base
            this.level = previousLevel;
            bases.pop();
        }
        catch (IOException e) {
            throw new SAXException("Document not found: " 
             + source.toExternalForm() + getLocation(), e);
        }

    }
        
}

