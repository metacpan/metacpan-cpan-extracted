////////////////////////////////////////////////////////////////////////
//    test
//    Author: Vlado Keselj (c) 2000-2001

//<? $Star->defineMacros() !>

package stefy.avm;
import java.io.*;

/**
   Tokenizer class (DD) is an advanced tokenizer similar to the
   standard StringTokenizer or StreamTokenizer.

   @author Vlado Keselj
*/
public class Tokenizer {

  //////////////////////////////////////////////////////////////////////
  // TOKENIZER CONFIGURATION
  //
  Config next = null;
  Config config = new Config();

  /**...*/

  public int nextToken() throws IOException {
    sval = saval = null;

    // A...
    //m!newdefe bufExtend
    if (i >= buf.length) {
      char nb[] = new char[buf.length * 2];
      System.arraycopy(buf, 0, nb, 0, buf.length);
      buf = nb;
    }
    //m!end

    //...
    {
      //expand bufExtend
    }

    //m!define jos jedan
    Ovo je tekst makroa 1;
    2;kraj;
    //m!end

    //m!expand bufExtend

    //m!defe test defea
    Red prvi;
    red zadnji;
    //m!end

  } // end of nextToken

}
