///////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2001 Artifactus Ltd
// 
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//////////////////////////////////////////////////////////////////////////////
import opennlp.common.*;
import opennlp.common.util.*;

import java.io.*;
import java.util.*;

/**
 * 
 *
 * @author      Joerg Tiedemann
 * @version     $Revision: 1.1.1.1 $, $Date: 2004/05/03 15:47:28 $
 */
public class GrokChunkerEN {

    public static void main (String[] args) {

	opennlp.grok.preprocess.chunk.EnglishChunkerME chunker = 
	    new opennlp.grok.preprocess.chunk.EnglishChunkerME();

	try {

	    Reader d = new FileReader(args[0]);
	    BufferedReader br = new BufferedReader(d);
	    String line;
	    try {
		while((line=br.readLine())!=null) {
		    System.out.println(chunker.tag(line));
		}
	    } catch (IOException E) { E.printStackTrace(); }

            d.close();
        }
        catch (IOException e) { System.err.println(e); }
    }
}
