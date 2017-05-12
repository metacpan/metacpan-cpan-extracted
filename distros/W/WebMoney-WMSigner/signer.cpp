#ifdef WIN32
#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#define __open _open
#define __read _read
#define __close _close
#else
#include <errno.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#define __open open
#define __read read
#define __close close
#endif

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <time.h>
#include "signer.h"

bool Signer::SecureKeyByIDPW(char *buf, DWORD dwBuf)
{
  if(((KeyFileFormat *)buf)->wSignFlag == 0)
  {
    m_siErrorCode = -2;
    return false;
  };
  DWORD dwCRC[4];
  szptr szIDPW = m_szUserName;
  szIDPW += m_szPassword;
  Keys::CountCrcMD4(dwCRC, szIDPW, szIDPW.strlen());
  char *ptrKey = ((KeyFileFormat *)buf)->ptrBuffer;
  DWORD dwKeyLen = dwBuf-(ptrKey-buf) - 6;
  ptrKey += 6;
  for(DWORD dwProc=0; dwProc<dwKeyLen; dwProc+=sizeof(dwCRC))
    for(int k=0; k<sizeof(dwCRC)&&(dwProc+k)<dwKeyLen; k++)
      *(ptrKey+dwProc+k) ^= ((char *)dwCRC)[k];
  return true;
}


bool Signer::SecureKeyByIDPWHalf(char *buf, DWORD dwBuf)
{
  if(((KeyFileFormat *)buf)->wSignFlag == 0)
  {
    m_siErrorCode = -2;
    return false;
  };
  DWORD dwCRC[4];
  szptr szIDPW = m_szUserName;
  int len = strlen(m_szPassword)/2 + 1;
  char *pBuf = NULL;
  if (len > 1)
  {
    pBuf = new char[len];
    memset(pBuf, 0, len);
    strncpy(pBuf, m_szPassword, len-1);
    szIDPW += pBuf;
  }
  Keys::CountCrcMD4(dwCRC, szIDPW, szIDPW.strlen());
  char *ptrKey = ((KeyFileFormat *)buf)->ptrBuffer;
  DWORD dwKeyLen = dwBuf-(ptrKey-buf) - 6;
  ptrKey += 6;
  for(DWORD dwProc=0; dwProc<dwKeyLen; dwProc+=sizeof(dwCRC))
    for(int k=0; k<sizeof(dwCRC)&&(dwProc+k)<dwKeyLen; k++)
      *(ptrKey+dwProc+k) ^= ((char *)dwCRC)[k];
  return true;
}



int Signer::LoadKeys()
{
  bool bKeysReaded = false, bNotOldFmt = false;
  int nReaden;
  int errLoadKey;
  int fh;
  m_siErrorCode = 0;

  #ifdef O_BINARY
  fh = __open( m_szKeyFileName, O_RDONLY | O_BINARY);
  #else
  fh = __open( m_szKeyFileName, O_RDONLY);
  #endif

  if( fh == -1 )
  {
    m_siErrorCode = errno;
    fprintf( stderr, "Can't open %s", (const char*)m_szKeyFileName );
    return false;
  }


  const int nMaxBufLen = sizeof(Keys) + KeyFileFormat::sizeof_header;
  char *pBufRead = new char[nMaxBufLen];   // Here Keys must be

  int st_size = lseek(fh, 0, SEEK_END);
  lseek(fh, 0, SEEK_SET);

  if (st_size == lMinKeyFileSize)
  {
    // load 164 bytes from "small" keys file

    nReaden = __read( fh, pBufRead, nMaxBufLen );
    bKeysReaded = (nReaden == lMinKeyFileSize);
  }
  else
  {
    //load key data from "BIG" keys file

    // bufer for a part of BIG file filled by random data,
    // excluding single mentioned byte of key
    char  *MapBuf;
    // size of this buffer
    DWORD dwMapBufSize;
    // result key buffer setting to 164 bytes size
    pBufRead = new char [lMinKeyFileSize];
    // header buffer that contain key map and other info
    DWORD *header = new DWORD [uiKWNHeaderSize];
    //fill all bufers by zero values
    memset(header, 0, sizeof(DWORD)*uiKWNHeaderSize);
    memset(pBufRead, 0, sizeof(char)*lMinKeyFileSize);

    bKeysReaded = false;
    // trying to read header info
    if (__read(fh, header, sizeof(DWORD)*(uiKWNHeaderSize)))
    {
      if (header[0] == 777)//if thist file is file of type of "BIG" kwm
      {
        bKeysReaded = true;
        dwMapBufSize = header[1];
        MapBuf = new char [dwMapBufSize];
        //Собираем ключик буквально по-крупицам:-)
        for (int i = 0; i < lMinKeyFileSize; i++)
        {
          //now we trying to read part of "BIG" file first and extract key value using key map then
          memset(MapBuf, 0, sizeof(char)*dwMapBufSize);
          if(__read(fh, MapBuf, sizeof(char)*dwMapBufSize))
          {
            pBufRead[i] = MapBuf[header[i+uiKWNHeaderOffset]];
          }
          else
          {
            m_siErrorCode = -1;
            bKeysReaded = false;
          }
        }
      }
    }
    //delete memory allocated using new operator
    delete [] MapBuf;
    delete [] header;
  }


  //*************************************************************************
  if(bKeysReaded)
  {
    SecureKeyByIDPWHalf(pBufRead, lMinKeyFileSize);
    SWORD old_SignFlag;
    old_SignFlag = ((KeyFileFormat *)pBufRead)->wSignFlag;
    ((KeyFileFormat *)pBufRead)->wSignFlag = 0;
    errLoadKey = keys.LoadFromBuffer( pBufRead, lMinKeyFileSize );
    if(errLoadKey)
    {
      // Restore for correct Loading (CRC) !
      ((KeyFileFormat *)pBufRead)->wSignFlag = old_SignFlag;
      SecureKeyByIDPWHalf(pBufRead, lMinKeyFileSize); // restore buffer
      SecureKeyByIDPW(pBufRead, lMinKeyFileSize);
      ((KeyFileFormat *)pBufRead)->wSignFlag = 0;
      errLoadKey = keys.LoadFromBuffer( pBufRead, lMinKeyFileSize );
    }

    delete pBufRead;
    if( !errLoadKey )
      bKeysReaded = true;
    else
    {
      Keys flushKey;
      keys = flushKey;
      m_siErrorCode = -3;
    }
  }
  __close( fh );

  return bKeysReaded;
}

Signer::Signer(const char * szLogin, const char *szPassword, const char *szKeyFileName)
 : m_szUserName(szLogin), m_szPassword(szPassword), m_szKeyFileName(szKeyFileName)
{
  m_siErrorCode = 0;
}

short Signer::ErrorCode()
{
  return m_siErrorCode;
}

bool Signer::Sign(const char *szIn, szptr& szSign)
{
  DWORD dwCRC[14];

  if (!LoadKeys())
  {
    puts("!LoadKeys");
    return false;
  }
  if(!keys.wEKeyBase || !keys.wNKeyBase)
    return false;

#ifdef _DEBUG
  char *szInHex = new char [(strlen(szIn)+1)*2+1];
  us2sz((const unsigned short *)szIn, (strlen(szIn)+1)/2, szInHex);
  puts("Input:\n");
  puts(szIn);
  puts("\nin hex:\n");
  puts(szInHex);
  puts("\n");
#endif

  if(Keys::CountCrcMD4(dwCRC, szIn, strlen(szIn)))
  {
    DWORD dwCrpSize = GetCLenB(sizeof(dwCRC), keys.arwNKey);
    char *ptrCrpBlock = new char[dwCrpSize];
#ifdef _DEBUG
    for(int i=4; i<14; i++) dwCRC[i] = 0;
#else
    srand((unsigned)time(NULL));
  for(int i=4; i<14; i++) dwCRC[i] = rand();
#endif
    CrpB(ptrCrpBlock, (char *)dwCRC, sizeof(dwCRC), keys.arwEKey, keys.arwNKey);
    char *charCrpBlock = new char[dwCrpSize*2+1];
    us2sz((const unsigned short *)ptrCrpBlock, dwCrpSize/2, charCrpBlock);
    szSign = charCrpBlock;
    return true;
  }

  return false;
}

Signer2::Signer2(const char *szLogin, const char *szPassword, const char *szKeyData)
  :Signer(szLogin, szPassword, ""), m_strKeyData(szKeyData)
{
  m_siErrorCode = 0;
}

int Signer2::LoadKeys()
{
  bool bKeysReaded = false, bNotOldFmt = false;
  int errLoadKey;

  int nStrKeyDataLen = m_strKeyData.strlen();
  const int nMaxBufLen = sizeof(Keys) + KeyFileFormat::sizeof_header;
  if ((nStrKeyDataLen>0) && (nStrKeyDataLen < nMaxBufLen*2))
  {
    BYTE *bKeyData = new BYTE[nMaxBufLen];
    sz2us(m_strKeyData, (unsigned short*)bKeyData);
    SecureKeyByIDPW((char*)bKeyData, nStrKeyDataLen / 2);
    ((KeyFileFormat *)bKeyData)->wSignFlag = 0;
    errLoadKey = keys.LoadFromBuffer((char*)bKeyData, nStrKeyDataLen / 2);
    delete bKeyData;
    if( !errLoadKey )
      bKeysReaded = true;
    else {
      Keys flushKey;
      keys = flushKey;
    m_siErrorCode = -2;
    }
  }
  else
  {
    errLoadKey = -1;
  m_siErrorCode = -1;
  }
  return (bKeysReaded);
}

short Signer2::ErrorCode()
{
  return m_siErrorCode;
}
