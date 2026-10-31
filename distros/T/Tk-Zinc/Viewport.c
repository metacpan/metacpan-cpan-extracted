/*
 * Viewport.c -- Implementation of viewport item.
 *
 * Authors              : Roland Tomczak.
 * Creation date        : Fri Dec  2 14:47:42 1994
 *
 * $Id$
 */

/*
 *  Copyright (c) 1994 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * Doc : A Viewport item is an item, which rendering is performed by a Third-Party API.
 * The third-Party Library must respect the API defined by the RendererApi.h file, and
 * export the corresponding functions.
 * 
 * A Viewport item may be rendered in two way :
 *  - DirectAccess rendering : In this case, the Third-Party rendering function is directly 
 *    called during the "Rendering" process of the tree. This is the most efficient way, but
 *    has some limitation :
 *      - As OpenGl viewport can't be others than "straight" rectangle, the item will be rendered
 *        in its bounding box rect, and clipped so as it appears to its right position, inclucling
 *        possible transforms. So, if the Viewport is rotated, its content WONT be rotated, but will
 *        appear in the "clipped rotated" position defined.
 *
 *      - Rotations aren't taken in accound for the item count, so as Alpha value
 
 *      - The API MUST be very careful when manipulating stencil buffer, otherwhise its display may
 *        overlap its container, or affect the rendering of the following tree items. The current clipping 
 *        level is passed as an argument : When entering the API Rendering, if this clipping level is > 0, 
 *        the clipping test is configured as glStencilFunc(GL_EQUAL, (GLint) num_clips, 0xFF); You must 
 *        add/remove clipping levels with glStencilOp(GL_KEEP, GL_INCR, GL_INCR) and glStencilOp(GL_KEEP, 
 *        GL_DECR, GL_DECR); If the incoming clipping level is = 0, then GL_STENCIL_TEST is disabled.
 *      - The API process MUST be very careful when changing glViewport ! It is set so that the item appears
 *        to its right position onto TkZinc rendering.
 *    If the displayed item is bellow all the others, especially when its cover the entire background, the two last 
 *    limitations aren't to be take in account. So, DirectAccess is specially dedicated to background items.
 *  - Non DirectAccess rendering : Viewport is rendered onto a texture during a Pre-rendering phase, and then,
 *    is copied onto screen. It's less efficient, but don't have any constraint.
  */


#include "Item.h"
#include "Geo.h"
#include "Draw.h"
#include "Types.h"
#include "Image.h"
#include "Color.h"
#include "WidgetInfo.h"
#include "tkZinc.h"



// Function prototypes definitions
typedef void    (*API_INITIALIZE_SIGNATURE)(int nID);
typedef void    (*API_RENDER_SIGNATURE)(int nID, int nClipLevel);
typedef char *  (*API_COMMAND_SIGNATURE)(int nID, const char * pchCommand );
typedef void    (*API_FINALIZE_SIGNATURE)(int nID);

/*
 * Bit offset of flags.
 */
#define ALIGNED_BIT     1

static int nNextViewportId = 0; 

/*
 **********************************************************************************
 *
 * Specific Viewport item record
 *
 **********************************************************************************
 */

typedef struct _ViewportItemStruct {
  ZnItemStruct  header;

  /* Public data */
  ZnPoint         coords[2];
  unsigned short  flags;

  char          * module_name;            // Viewport module name ( DLL or .so to be loaded )
  char          * command;                // Command to be send to module
  char          * command_result;         // Command result ( string )
    
  unsigned short  refresh;          // Set it to force display refresh
  unsigned short  directaccess;     // Direct Access or Memory access
  unsigned short  texture_width;    // Non direct Access texture Width
  unsigned short  texture_height;   // Non direct Access texture Height
  unsigned short  texture_opacity;  // Non direct Access texture opacity( 0..100 )


  /* Private data */
  ZnPoint       dev[4];
  char          cInitialized;     // 1 when initialized
  int           nViewportId;      // Our viewport ID
  unsigned int  nTextureId;       // Texture ID for non-direct Access
  int           nPrevTextureWidth;  // Non direct Access texture Width
  int           nPrevTextureHeight; // Non direct Access texture Height

  // External functions
  API_INITIALIZE_SIGNATURE  pApiInitializeFunc;
  API_RENDER_SIGNATURE      pApiRenderFunc;
  API_COMMAND_SIGNATURE     pApiCommandFunc;
  API_FINALIZE_SIGNATURE    pApiFinalizeFunc;

} ViewportItemStruct, *ViewportItem;


static ZnAttrConfig     viewport_attrs[] = {
  { ZN_CONFIG_BOOL, "-catchevent", NULL,
    Tk_Offset(ViewportItemStruct, header.flags), ZN_CATCH_EVENT_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(ViewportItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(ViewportItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(ViewportItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(ViewportItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(ViewportItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(ViewportItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(ViewportItemStruct, header.flags), ZN_VISIBLE_BIT,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG|ZN_VIS_FLAG, False },

  { ZN_CONFIG_BOOL, "-refresh", NULL,
    Tk_Offset(ViewportItemStruct, refresh), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_SHORT, "-directaccess", NULL,
    Tk_Offset(ViewportItemStruct, directaccess), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_SHORT, "-texturewidth", NULL,
    Tk_Offset(ViewportItemStruct, texture_width), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_SHORT, "-textureheight", NULL,
    Tk_Offset(ViewportItemStruct, texture_height), 0, ZN_DRAW_FLAG, False }, 
  { ZN_CONFIG_SHORT, "-textureopacity", NULL,
    Tk_Offset(ViewportItemStruct, texture_opacity), 0, ZN_DRAW_FLAG, False },
  
  { ZN_CONFIG_STRING, "-modulename", NULL,
    Tk_Offset(ViewportItemStruct, module_name), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_STRING, "-command", NULL,
    Tk_Offset(ViewportItemStruct, command), 0, 0, False },
  { ZN_CONFIG_STRING, "-commandresult", NULL,
    Tk_Offset(ViewportItemStruct, command_result), 0, 0, False },
  
  { ZN_CONFIG_END, NULL, NULL, 0, 0, 0, False }
};



/*
 **********************************************************************************
 *
 * Init --
 *
 **********************************************************************************
 */
static int
Init(ZnItem             item,
     int                *argc,
     Tcl_Obj *const     *args[])
{
  ZnWInfo       *wi = item->wi;
  ViewportItem  rect = (ViewportItem) item;
  unsigned int  num_points;
  ZnPoint       *points;

  /* Init attributes */
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_CATCH_EVENT_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->priority = 1;
  
  if (*argc < 1) {
    Tcl_AppendResult(wi->interp, " viewport coords expected", (char *) NULL);
    return TCL_ERROR;
  }
  if (ZnParseCoordList(wi, (*args)[0], &points,
                       NULL, &num_points, NULL) == TCL_ERROR) {
    return TCL_ERROR;
  }
  if (num_points != 2) {
    Tcl_AppendResult(wi->interp, " malformed viewport coords", (char *) NULL);
    return TCL_ERROR;
  };
  rect->coords[0] = points[0];
  rect->coords[1] = points[1];
  (*args)++;
  (*argc)--;

  rect->module_name     = NULL;
  rect->command         = NULL;
  rect->command_result  = NULL;

  rect->directaccess        = 0;

  
  rect->texture_width       = 128;
  rect->texture_height      = 128;
  rect->texture_opacity     = 100;

  // Initialize our internal attributes
  rect->cInitialized        = 0;
  rect->nViewportId         = nNextViewportId ++;
  rect->nTextureId          = 0;
  rect->nPrevTextureWidth   = 128;
  rect->nPrevTextureHeight  = 128;

  // API callbacks functions
  rect->pApiInitializeFunc  = NULL;
  rect->pApiRenderFunc      = NULL;
  rect->pApiCommandFunc     = NULL;
  rect->pApiFinalizeFunc    = NULL;
  
  // Increase number of viewport item
  wi->nb_of_viewport_items++;

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Clone --
 *
 **********************************************************************************
 */
static void
Clone(ZnItem    item)
{
  ViewportItem  rect = (ViewportItem) item;
  ZnWInfo       *wi = item->wi;
  char        * str;

  // Set a new Id..
  rect->nViewportId = nNextViewportId ++;
  // .. and reset internal texture
  rect->nTextureId  = 0; 
  
  // Increase number of viewport item
  wi->nb_of_viewport_items++;

  // Copy our strings attributs
  if (rect->module_name) {
    str = ZnMalloc((strlen(rect->module_name) + 1) * sizeof(char));
    strcpy(str, rect->module_name);
    rect->module_name = str;
  }
  if (rect->command) {
    str = ZnMalloc((strlen(rect->command) + 1) * sizeof(char));
    strcpy(str, rect->command);
    rect->command = str;
  }
  if (rect->command_result) {
    str = ZnMalloc((strlen(rect->command_result) + 1) * sizeof(char));
    strcpy(str, rect->command_result);
    rect->command_result = str;
  }

  // .. Finally, initialize the viewport to the library
  if ( rect->pApiInitializeFunc != NULL )
  {
    rect->pApiInitializeFunc ( rect->nViewportId );
  }
}


/*
 **********************************************************************************
 *
 * Destroy --
 *
 **********************************************************************************
 */
static void
Destroy(ZnItem  item)
{
  ViewportItem rect = (ViewportItem) item;
  ZnWInfo       *wi = item->wi;

  // Decrease number of viewport item
  wi->nb_of_viewport_items--;

  rect->cInitialized = 0;

  if ( rect->nTextureId != 0 )
  {
    glDeleteTextures(1, &rect->nTextureId);
    rect->nTextureId = 0;
  }

  if (rect->module_name) 
  {
    ZnFree(rect->module_name);
  }
  if (rect->command) 
  {
    ZnFree(rect->command);
  }
  if (rect->command_result) 
  {
    ZnFree(rect->command_result);
  }
}


/*
 **********************************************************************************
 *
 * Configure --
 *
 **********************************************************************************
 */
static int
Configure(ZnItem        item,
          int           argc,
          Tcl_Obj *const argv[],
          int           *flags)
{
  ZnWInfo       * wi = item->wi;
  ViewportItem    rect = (ViewportItem) item;
  int             status = TCL_OK;
  char *          pOldModuleName = rect->module_name;

  status = ZnConfigureAttributes(wi, item, item, viewport_attrs, argc, argv, flags);

  // If library name has changed, load callback functions or realease them
  if ( rect->module_name != pOldModuleName )
  {
    // Finalize our viewport for current module
    if ( rect->pApiFinalizeFunc != NULL )
    {
      rect->pApiFinalizeFunc ( rect->nViewportId );
    }

    // Release existing callbacks
    rect->pApiInitializeFunc  = NULL;
    rect->pApiRenderFunc      = NULL;
    rect->pApiCommandFunc     = NULL;
    rect->pApiFinalizeFunc    = NULL;  

    if ( rect->module_name )
    {

#ifdef _WIN32
      // There's a module name, let's load the librairie and recover function name
      char *pchLibraryName = ZnMalloc(strlen(rect->module_name) + sizeof(".dll"));
      HMODULE handle = NULL;

      strcpy ( pchLibraryName, rect->module_name );
      strcat ( pchLibraryName, ".dll" );

      handle = LoadLibraryA(pchLibraryName);
      ZnFree(pchLibraryName);

      if (handle != NULL)
      {
        // printf ( "\nLibrary Loaded !");

        // The Librarie has been loaded : let's recover callback functions
        rect->pApiInitializeFunc  = ( API_INITIALIZE_SIGNATURE ) (GetProcAddress (handle, "apiInitialize" ));
        rect->pApiRenderFunc      = ( API_RENDER_SIGNATURE ) (GetProcAddress (handle, "apiRender" ));
        rect->pApiCommandFunc     = ( API_COMMAND_SIGNATURE ) (GetProcAddress (handle, "apiCommand" ));
        rect->pApiFinalizeFunc    = ( API_FINALIZE_SIGNATURE ) (GetProcAddress (handle, "apiFinalize" ));
      }
      else
      {
        // printf ( "\nLibrary Loading failed !!");
      }
#endif /* ifdef _WIN32 */

    }
  }

  // If a command needs to be executed, let's do it
  if ( rect->pApiCommandFunc != NULL )
  {
    if ( rect->command )
    {
      char * pchCommandResult = rect->pApiCommandFunc ( rect->nViewportId, rect->command );

      // Free requested command...
      ZnFree(rect->command);
      rect->command = NULL;

      // ..Clean the result..
      if (rect->command_result) 
      {
        ZnFree(rect->command_result);
        rect->command_result = NULL;
      }

      // ..And, eventually, retrieve the new result
      if ( pchCommandResult != NULL )
      {
        rect->command_result = ZnMalloc ( strlen ( pchCommandResult ) + 1 );
        strcpy(rect->command_result, pchCommandResult);
      }
    }
  }

  return status;
}


/*
 **********************************************************************************
 *
 * Query --
 *
 **********************************************************************************
 */
static int
Query(ZnItem            item,
      int               argc,
      Tcl_Obj *const    argv[])
{
  if (ZnQueryAttribute(item->wi->interp, item, viewport_attrs, argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * ComputeCoordinates --
 *
 **********************************************************************************
 */
static void
ComputeCoordinates(ZnItem       item,
                   ZnBool       force)
{
  ZnWInfo       *wi = item->wi;
  ViewportItem  rect = (ViewportItem) item;
  ZnPoint       p[4];
  int           i;
  ZnBool        aligned;
  ZnDim         delta, lw2;
  
  ZnResetBBox(&item->item_bounding_box);

  p[0] = rect->coords[0];
  p[2] = rect->coords[1];
  p[1].x = p[2].x;
  p[1].y = p[0].y;
  p[3].x = p[0].x;
  p[3].y = p[2].y;
  ZnTransformPoints(wi->current_transfo, p, rect->dev, 4);
  for (i = 0; i < 4; i++) {
    rect->dev[i].x = ZnNearestInt(rect->dev[i].x);
    rect->dev[i].y = ZnNearestInt(rect->dev[i].y);
  }

  /*
   * Add all points to the bounding box. Then expand by the line
   * width to account for mitered corners. This is an overestimate.
   */
  ZnAddPointsToBBox(&item->item_bounding_box, rect->dev, 4);

  item->item_bounding_box.orig.x -= 0.5;
  item->item_bounding_box.orig.y -= 0.5;
  item->item_bounding_box.corner.x += 0.5;
  item->item_bounding_box.corner.y += 0.5;
  
  delta = rect->dev[0].y - rect->dev[1].y;
  delta = ABS(delta);
  aligned = delta < X_PRECISION_LIMIT;
  delta = rect->dev[0].x - rect->dev[3].x;
  delta = ABS(delta);
  aligned &= delta < X_PRECISION_LIMIT;
  ASSIGN(rect->flags, ALIGNED_BIT, aligned);
}


/*
 **********************************************************************************
 *
 * ToArea --
 *      Tell if the object is entirely outside (-1),
 *      entirely inside (1) or in between (0).
 *
 **********************************************************************************
 */
static int
ToArea(ZnItem   item,
       ZnToArea ta)
{
  ViewportItem  rect = (ViewportItem) item;
  int           result, result2;
  ZnBBox        *area = ta->area;

  result = -1;

  result = ZnPolygonInBBox(rect->dev, 4, area, NULL);
  if (result == 0) {
    return 0;
  }

  return result;
}


/*
 **********************************************************************************
 *
 * Draw --
 *
 **********************************************************************************
 */
static void
Draw(ZnItem     item)
{
  ZnWInfo       *wi  = item->wi;
  ViewportItem  rect = (ViewportItem) item;
  XGCValues     values;
  unsigned int  i, gc_mask;
  XRectangle    r;
  XPoint        xp[5];
  
  if (ISSET(rect->flags, ALIGNED_BIT)) {
    if (rect->dev[0].x < rect->dev[2].x) {
      r.x = (int) rect->dev[0].x;
      r.width = ((int) rect->dev[2].x) - r.x;
    }
    else {
      r.x = (int) rect->dev[2].x;
      r.width = ((int) rect->dev[0].x) - r.x;
    }
    if (rect->dev[0].y < rect->dev[2].y) {
      r.y = (int) rect->dev[0].y;
      r.height = ((int) rect->dev[2].y) - r.y;
    }
    else {
      r.y = (int) rect->dev[2].y;
      r.height = ((int) rect->dev[0].y) - r.y;
    }
  }
  else {
    for (i = 0; i < 4; i++) {
      xp[i].x = (int) rect->dev[i].x;
      xp[i].y = (int) rect->dev[i].y;
    }
    xp[i] = xp[0];
  }
  
  /* XDraw method have to be implemented */
}


/*
 **********************************************************************************
 *
 * PreRender --
 *
 **********************************************************************************
 */
 
#ifdef GL
static void
PreRender(ZnItem   item)
{
  ZnWInfo         *wi  = item->wi;
  ViewportItem    rect = (ViewportItem) item;
  int             i;
  unsigned short  alpha;

  // Initialize the Viewport when accessing for the first time
  if ( rect->cInitialized == 0 )
  {
    // Initialize our viewport
    if (  rect->pApiInitializeFunc != NULL )
    {
      rect->pApiInitializeFunc ( rect->nViewportId );
    }

    rect->cInitialized = 1;
  }

  // We only proceed if a Rendering function is defined
  if ( rect->pApiRenderFunc != NULL )
  {
    if ( rect->directaccess == 0 )
    {
      // Our texture is "non DirectAccess"

      // Clean up our texture if dimensions have changed
      if (  ( rect->texture_width != rect->nPrevTextureWidth )
        || ( rect->texture_height != rect->nPrevTextureHeight ) )
      {
        if ( rect->nTextureId != 0 )
        {
          glDeleteTextures(1, &rect->nTextureId);
          rect->nTextureId = 0;
        }
      }

      // If no texture is associated with our viewport ( or if we'd just destroy the current one ), let's create one
      // ( Thanks to http://www.cppfrance.com/codes/RENDU-SUR-TEXTURE-OPENGL-VCPLUSPLUS_11278.aspx )
      if ( rect->nTextureId == 0 )
      {
        // Create a new empty RGBA texture buffer
        unsigned int *pTextureBuffer = NULL;
   
        pTextureBuffer = malloc (  sizeof ( unsigned int ) * rect->texture_width * rect->texture_height * 4 );
        memset(pTextureBuffer, 0, rect->texture_width * rect->texture_height * 4 * sizeof(unsigned int));
   
        glGenTextures(1, &(rect->nTextureId));		  // Genere un nom de texture
        glBindTexture(GL_TEXTURE_2D, rect->nTextureId);	  // Active la texture que nous venons de generer
   
        // Definition of our 2D RGBA texture
        glTexImage2D(GL_TEXTURE_2D, 0, 4, rect->texture_width, rect->texture_height, 0, GL_RGBA, GL_UNSIGNED_INT, pTextureBuffer);
   
        // Texture processing parameters
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
      	
	      // As the texture is stored onto OpenGL, no need to keep it in memory
        free ( ( void * ) pTextureBuffer );

        // Let's save its dimension, if an user decide to change them ( in this case, it'll be regenerated )
        rect->nPrevTextureWidth = rect->texture_width;
        rect->nPrevTextureHeight = rect->texture_height;
      }

      // Now, render the Viewport onto this texture
      // Set our viewport on texture size
      if ( rect->nTextureId != 0 )
      {
        glViewport (  0, 0, rect->texture_width, rect->texture_height );

        rect->pApiRenderFunc ( rect->nViewportId,  0 );

        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D,rect->nTextureId);
		  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, rect->texture_width, rect->texture_height, 0);
        glDisable(GL_TEXTURE_2D);
      }
    }
    else
    {
      // Clean up our texture if any
      if ( rect->nTextureId != 0 )
      {
        glDeleteTextures(1, &rect->nTextureId);
        rect->nTextureId = 0;
      }
    }
  }
}

#else
static void
PreRender(ZnItem   item)
{
}
#endif


/*
 **********************************************************************************
 *
 * Render --
 *
 **********************************************************************************
 */
#ifdef GL
static void
ViewportRenderCB(void *closure)
{
  ViewportItem  rect = (ViewportItem) closure;
  ZnItem        item = (ZnItem) closure;

  // Proceed only if an rendering function has been found
  if ( rect->pApiRenderFunc != NULL )
  {
    if ( rect->directaccess == 1 )
    {
      // Window info. Needed because we've to retrieve its height, when changing
      // our viewport to set it on our object bounding box
      ZnWInfo *     wi  = item->wi;
      // Window width and height.
      int           int_width = Tk_Width(wi->win);
      int           int_height = Tk_Height(wi->win);
      // This point array will contain our viewport mask coordinates
      ZnPoint       *points;
      // This triangle strip will contain our specific viewport clipping zone.
      ZnTriStrip    tristrip;

      // Clip the region, so that only the viewport rect will be displayed
      // First of all, build our clipping triangle point list 
      ZnListAssertSize(ZnWorkPoints, 4);
      points = ZnListArray(ZnWorkPoints);
      points[0] = rect->dev[1];
      points[1] = rect->dev[2];
      points[2] = rect->dev[0];
      points[3] = rect->dev[3];
      ZnTriStrip1(&tristrip, points, 4, False);
      // Then, push this clipping level
      ZnPushClip(wi, &tristrip, False, True);

      // Store our global state : Push all rendering attributes...
      glPushAttrib (  GL_ACCUM_BUFFER_BIT
                    | GL_COLOR_BUFFER_BIT
                    | GL_CURRENT_BIT
                    | GL_DEPTH_BUFFER_BIT 
                    | GL_ENABLE_BIT
                    | GL_EVAL_BIT 
                    | GL_FOG_BIT 
                    | GL_HINT_BIT
                    | GL_LIGHTING_BIT
                    | GL_LINE_BIT
                    | GL_LIST_BIT
                    | GL_PIXEL_MODE_BIT
                    | GL_POINT_BIT
                    | GL_POLYGON_BIT
                    | GL_POLYGON_STIPPLE_BIT
                    | GL_SCISSOR_BIT
                    | GL_STENCIL_BUFFER_BIT
                    | GL_TEXTURE_BIT
                    | GL_TRANSFORM_BIT
                    | GL_VIEWPORT_BIT );

      // ... And the model transform matrix
      glMatrixMode(GL_MODELVIEW);
      glPushMatrix();

      // ... And the projection transform matrix
      glMatrixMode(GL_PROJECTION);
      glPushMatrix( );

      // Set our viewport on the whole object bounding box.
      glViewport ( ( GLint ) ( item->item_bounding_box.orig.x ),
                  ( GLint ) ( int_height - item->item_bounding_box.corner.y ),
                  ( GLsizei ) ( item->item_bounding_box.corner.x - item->item_bounding_box.orig.x ),
                  ( GLsizei ) ( item->item_bounding_box.corner.y - item->item_bounding_box.orig.y )
                );
   
      // ... And invoke our rendering function !
      rect->pApiRenderFunc ( rect->nViewportId,  ZnListSize(wi->clip_stack) );
      
      // ... Restore tje projection matrix
      glMatrixMode(GL_PROJECTION);
      glPopMatrix();

      // ... And the model transform matrix
      glMatrixMode(GL_MODELVIEW);
      glPopMatrix();

      // ... Our attributs
      glPopAttrib ();
      
      // ... And stop clipping !
      ZnPopClip(wi, True);
    }
    else
    {
      // If Viewport is Non-DirectAccess, we just have to display prerendered
      // texture onto screen

      // Retrieve window information ( for alpha value )
      ZnWInfo *     wi  = item->wi;
      
      // Item is displayed only if our texture is available
      if ( rect->nTextureId != 0 )
      {
        unsigned short  alpha;

        alpha = ( float ) rect->texture_opacity;     
        alpha = ZnComposeAlpha(alpha, wi->alpha);

        // .. Prepare OGL for texture drawing...
        glEnable(GL_TEXTURE_2D);  
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, rect->nTextureId );
      
        glColor4us(65535, 65535, 65535, alpha);

        // ... and display our quad !!!
        glBegin(GL_QUADS);
  		  glTexCoord2f(  0, 1);
			  glVertex2d(rect->dev[0].x, rect->dev[0].y);
        glTexCoord2f(  1,  1);
			  glVertex2d(rect->dev[1].x, rect->dev[1].y);
        glTexCoord2f( 1,   0);
			  glVertex2d(rect->dev[2].x, rect->dev[2].y);
        glTexCoord2f( 0, 0);
        glVertex2d(rect->dev[3].x, rect->dev[3].y);
        glEnd();
        glDisable(GL_TEXTURE_2D);  
      }
    }
  }
}
#endif



#ifdef GL
static void
Render(ZnItem   item)
{
  ZnWInfo         *wi  = item->wi;
  ViewportItem    rect = (ViewportItem) item;
  int             i;
  unsigned short  alpha;

#ifdef GL_LIST
  if (!item->gl_list) {
    item->gl_list = glGenLists(1);
    glNewList(item->gl_list, GL_COMPILE);
#endif
    
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    
    // Viewport Item rendering callback
    ViewportRenderCB(rect);
    
#ifdef GL_LIST    
    glEndList();
  }
  
  glCallList(item->gl_list);
#endif
}
#else
static void
Render(ZnItem   item)
{
}
#endif
 

/*
 **********************************************************************************
 *
 * IsSensitive --
 *
 **********************************************************************************
 */
static ZnBool
IsSensitive(ZnItem      item,
            int         item_part)
{
  return (ISSET(item->flags, ZN_SENSITIVE_BIT) &&
          item->parent->class->IsSensitive(item->parent, ZN_NO_PART));
}


/*
 **********************************************************************************
 *
 * Pick --
 *
 **********************************************************************************
 */
static double
Pick(ZnItem     item,
     ZnPick     ps)
{
  ViewportItem rect = (ViewportItem) item;
  double        best_dist;
  ZnPoint       *p = ps->point;

  best_dist = ZnPolygonToPointDist(rect->dev, 4, p);

  if (best_dist <= 0.0) {
    return 0.0;
  }
    
  best_dist = ABS(best_dist);
  
  return best_dist;
}


/*
 **********************************************************************************
 *
 * PostScript --
 *
 **********************************************************************************
 */
static int
PostScript(ZnItem item,
           ZnBool prepass,
           ZnBBox *area)
{
  ZnWInfo       *wi = item->wi;
  ViewportItem  rect = (ViewportItem) item;
  char          path[500];

  /*
   * Create the viewport rectangle path...
   */
  sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto %.15g %.15g lineto %.15g %.15g lineto closepath\n",
          rect->dev[0].x, rect->dev[0].y, rect->dev[1].x, rect->dev[1].y,
          rect->dev[2].x, rect->dev[2].y, rect->dev[3].x, rect->dev[3].y);
  Tcl_AppendResult(wi->interp, path, (char *) NULL);

  /*
   * And emit code code to stroke the outline... Viewport content won't be displayed, only the rectangle area
   */
  /*
  Tcl_AppendResult(wi->interp, "0 setlinejoin 2 setlinecap\n", (char *) NULL);
  if (ZnPostscriptOutline(wi->interp, wi->ps_info, wi->win,
                          rect->line_width, rect->line_style,
                          rect->line_color, rect->line_pattern) != TCL_OK) {
    return TCL_ERROR;
  }
  */
  
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * GetClipVertices --
 *      Get the clipping shape.
 *      Never ever call ZnTriFree on the tristrip returned by GetClipVertices.
 *
 **********************************************************************************
 */
static ZnBool
GetClipVertices(ZnItem          item,
                ZnTriStrip      *tristrip)
{
  ViewportItem  rect = (ViewportItem) item;
  ZnPoint       *points;

  if (ISSET(rect->flags, ALIGNED_BIT)) {
    ZnListAssertSize(ZnWorkPoints, 2);
    points = ZnListArray(ZnWorkPoints);
    ZnTriStrip1(tristrip, points, 2, False);
    tristrip->strips[0].fan = False;
  
    if (rect->dev[0].x < rect->dev[2].x) {
      points[0].x = rect->dev[0].x;
      points[1].x = rect->dev[2].x+1.0;
    }
    else {
      points[0].x = rect->dev[2].x;
      points[1].x = rect->dev[0].x+1.0;
    }
    if (rect->dev[0].y < rect->dev[2].y) {
      points[0].y = rect->dev[0].y;
      points[1].y = rect->dev[2].y+1.0;
    }
    else {
      points[0].y = rect->dev[2].y;
      points[1].y = rect->dev[0].y+1.0;
    }
  }
  else {
    ZnListAssertSize(ZnWorkPoints, 4);
    points = ZnListArray(ZnWorkPoints);
    points[0] = rect->dev[1];
    points[1] = rect->dev[2];
    points[2] = rect->dev[0];
    points[3] = rect->dev[3];
    ZnTriStrip1(tristrip, points, 4, False);
  }

  return ISSET(rect->flags, ALIGNED_BIT);
}


/*
 **********************************************************************************
 *
 * Coords --
 *      Return or edit the item vertices.
 *
 **********************************************************************************
 */
static int
Coords(ZnItem           item,
       int              contour,
       int              index,
       int              cmd,
       ZnPoint          **pts,
       char             **controls,
       unsigned int     *num_pts)
{
  ViewportItem rect = (ViewportItem) item;

  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp, " viewports can't add or remove vertices", (char *) NULL);
    return TCL_ERROR;
  }
  else if (cmd == ZN_COORDS_REPLACE_ALL) {
    if (*num_pts != 2) {
      Tcl_AppendResult(item->wi->interp, " coords command need 2 points on viewports", (char *) NULL);
      return TCL_ERROR;
    }
    rect->coords[0] = (*pts)[0];
    rect->coords[1] = (*pts)[1];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if (cmd == ZN_COORDS_REPLACE) {
    if (*num_pts < 1) {
      Tcl_AppendResult(item->wi->interp, " coords command need at least 1 point", (char *) NULL);
      return TCL_ERROR;
    }
    if (index < 0) {
      index += 2;
    }
    if ((index < 0) || (index > 1)) {
    range_err:
      Tcl_AppendResult(item->wi->interp," incorrect coord index, should be between -2 and 1", (char *) NULL);
      return TCL_ERROR;
    }
    rect->coords[index] = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if (cmd == ZN_COORDS_READ_ALL) {
    *num_pts = 2;
    *pts = rect->coords;
  }
  else if (cmd == ZN_COORDS_READ) {
    if (index < 0) {
      index += 2;
    }
    if ((index < 0) || (index > 1)) {
      goto range_err;
    }
    *num_pts = 1;
    *pts = &rect->coords[index];
  }

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * GetAnchor --
 *
 **********************************************************************************
 */
static void
GetAnchor(ZnItem        item,
          Tk_Anchor     anchor,
          ZnPoint       *p)
{
  ZnBBox *bbox = &item->item_bounding_box;

  ZnOrigin2Anchor(&bbox->orig,
                  bbox->corner.x - bbox->orig.x,
                  bbox->corner.y - bbox->orig.y,
                  anchor, p);
}


/*
 **********************************************************************************
 *
 * Exported functions struct --
 *
 **********************************************************************************
 */ 
static ZnItemClassStruct VIEWPORT_ITEM_CLASS = {
  "viewport",
  sizeof(ViewportItemStruct),
  viewport_attrs,
  0,                    /* num_parts */
  0,                    /* flags */
  -1,
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  NULL,                 /* GetFieldSet */
  GetAnchor,
  GetClipVertices,
  NULL,                 /* GetContours */
  Coords,
  NULL,                 /* InsertChars */
  NULL,                 /* DeleteChars */
  NULL,                 /* Cursor */
  NULL,                 /* Index */
  NULL,                 /* Part */
  NULL,                 /* Selection */
  NULL,                 /* Contour */
  ComputeCoordinates,
  ToArea,
  Draw,
  PreRender,            /* Pre-render */
  Render,
  IsSensitive,
  Pick,
  NULL,                 /* PickVertex */
  PostScript
};

ZnItemClassId ZnViewport = (ZnItemClassId) &VIEWPORT_ITEM_CLASS;
