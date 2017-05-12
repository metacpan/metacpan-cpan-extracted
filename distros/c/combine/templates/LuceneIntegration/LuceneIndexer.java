import org.apache.lucene.document.*;
import org.apache.lucene.index.*;
import org.apache.lucene.store.*;
import org.apache.lucene.analysis.standard.*;
import java.util.*;
import java.io.*; 
public class LuceneIndexer
{
  Map<String,Field.Index> indexMap = new TreeMap<String,Field.Index>();
  Map<String,Field.Store> storeMap = new TreeMap<String,Field.Store>();
  IndexWriter indexWriter;
  public LuceneIndexer(String path,int createStr,int maxFieldLength) throws CorruptIndexException,LockObtainFailedException,IOException
  {
    makeMaps();
    boolean create = (createStr == 1);
    indexWriter = new IndexWriter(path,new StandardAnalyzer(),true,
                                  new IndexWriter.MaxFieldLength(maxFieldLength));
  }
  private void makeMaps()
  {
    storeMap.put("YES",Field.Store.YES);
    storeMap.put("NO",Field.Store.NO);
    storeMap.put("COMPRESS",Field.Store.COMPRESS);
    indexMap.put("ANALYZED",Field.Index.ANALYZED);
    indexMap.put("ANALYZED_NO_NORMS",Field.Index.ANALYZED_NO_NORMS);
    indexMap.put("NO",Field.Index.NO);
    indexMap.put("NOT_ANALYZED_NO_NORMS",Field.Index.NOT_ANALYZED_NO_NORMS);
  }
  public Document newDocument()
  {
    Document doc = new Document();
    return doc;
  }  
  public Field newField(String key,String value,String storeDesp,String indexDesp)
  {
    Field.Store store = storeMap.get(storeDesp);
    Field.Index index = indexMap.get(indexDesp);
    return new Field(key,value,store,index);
  }
  public void addField(Document doc,Field field)
  {
    doc.add(field);
  }
  public void addDocument(Document doc) throws CorruptIndexException,IOException
  {
    indexWriter.addDocument(doc);
  }
  public void deleteDocuments(String value,String key) throws CorruptIndexException,IOException
  {
    indexWriter.deleteDocuments(new Term(value,key));
  }
  public void close() throws CorruptIndexException,IOException
  {
    indexWriter.optimize();
    indexWriter.close();
  }
}



