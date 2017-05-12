Packaging Examples for IMS ePortfolio v1p0 Public Draft
--------------------------------------------------------------------------------

These examples are designed as a guide to the user.  More comprehensive examples will be included in the final draft. 

Basic Packaging/Files Structure
--------------------------------------------
An IMS ePortfolio package contains one or more packaged instances of portfolios.  These may be one instance per owner or otherwise.  There is no implication as to whether the instances are related to each other or not and each may contain any instance valid according to the XSD.

For each ePortfolio instance there is a separate organization within organizations.

Each ePortfolio organization element should contain an item for the XML instance for the portfolio.  It should be at the outer item-level within the organization (not nested within other items) but it can be in any position in the sequence of items. The resource for that item should point to the actual XML instance. The resource element should have a type of "ims-epInstance" It is likely that in the public specification a mechanism will be provided whereby the resource can contain multiple files to be aggregated to form the instance but at the time of draft that mechanism is still to be decided.

An ePortfolio package can contain 0 or more views.  A view is a transformation that can be applied to the reconstructed ePortfolio instance.  Commonly a view will select and order content for presentation. The referenced resource element should have an attribute of type="ims-epView"

An ePortfolio package can contain style files representing presentation style information.  These can occur in different ways:

1. At the level of the ePortfolio.  These appear within an organization but at the outer level.

2. Associated with an ePortfolio element such as a view or a product but not explicitly linked with the product (for example not as in 3. below).  These are associated with an item listed in organizations by nesting inside that item.

3. Explicitly linked to a product for example with "link rel" in html content.

It is implied that the application of multiple style files cascade with the outer (organization level) being applied first, the item level (for products and views) being applied next, and finally the explicitly associated product level.

Each style file is given an attribute of type="presentationStyle" in its resource element.

Structure and Content of the provided examples
-----------------------------------------------------------------

Each example is provided as an IMS Content Package in its own directory for ease of unpacking.  At time of draft the content of the examples is partially complete.  Some detail and explanation of the examples follows.

1. Minimal example
This shows an absolute minimal portfolio for exporting just one product, an assignment essay.  The XML instance is in the file Minimal.xml for which the resource has attribute type="ims-epInstance". The product is a single word file. There are no views or style files.

2 hasReflectNassert example
This example has the same structure as the minimal example but as well as a product the instance contains a reflection, an assertion and an Accessibility Preferences instance for the portfolio owner.

3. hasViewsNstyle example
This is a more extensive example provided here to show the structure of files for packaging where views and presentations are involved.  At time of draft most of the files are provided as stubs without valid data content.

The package contains three portfolios.  These are "Joanna Hunt", Gayle Beneville" and "Company Competencies".  The first two are associated with individuals and the third with a group of individuals and shows the competencies the group have between them but not associated with each individual.

Taking Joanna Hunt's example for discussion the organization contains several elements.  The first four listed are all products.

Rubric is a view and points to a resource with type ims-epView which is an XSL file.  Associated with rubric is a CSS style sheet (nested in the item).  The logical element has been called rubricStyle here and the actual file in the package is called rubric.xsl.  The type of the resource is "presentationStyle.

There is another style sheet referred to here as main.  For the view rubric, the stylesheets that apply in order are main and rubric.

The instance for this portfolio is referred to in the organization element as joannaHuntepinst and the corresponding resource element has type="ims-epInstance" 

Gayle Benneville's ePortfolio is simpler.  She has a series of products and no style files.  The organization item for her XML instance is epInstancexml and this points to a resource GayleBenneville.xml .

The CompanyCompetencies portfolio contains no products just one instance that describes the collective competencies for a very small company of programmers.

Rubric
---------
The RUbric example is a simple sample file for a Rubric instance.



These examples have been constructed to explain possibilities and names chosen accordingly.  In practice naming schemes for portfolios and instances would be according to some consistent scheme for the implementation.
