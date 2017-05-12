#include "cmdbase.h"

const long lMinKeyFileSize	= 164;//smallest size of the keysfaile
const long lKiloByte		= 1024;//1 kilobyte in bytes
const long lMegaByte		= lKiloByte*lKiloByte;//1 megabyte in bytes
const long lScrollZoom		= 100;
const long lMaxKeyFileSize	= 10*lMegaByte;//10 Mb in this version
const szptr szOptionKeyFileSize = "KeyFileSize";
const unsigned int uiKWNHeaderOffset = 2;
const unsigned int uiKWNHeaderSize = uiKWNHeaderOffset + lMinKeyFileSize;
const unsigned int uiBlockSizeOffset = 1;

class Signer
{
protected:
  szptr m_szUserName;
  szptr m_szPassword;
  szptr m_szKeyFileName;
  short m_siErrorCode;
  Keys keys;
  bool SecureKeyByIDPW(char *buf, DWORD dwBuf);  
	bool SecureKeyByIDPWHalf(char *buf, DWORD dwBuf);  
  int virtual LoadKeys();

public:
  Signer(const char *szLogin, const char *szPassword, const char *szKeyFileName);
  bool Sign(const char *szIn, szptr& szSign);
  short ErrorCode();
};

class Signer2: public Signer
{
protected:
  szptr m_strKeyData;
  short m_siErrorCode;
  int virtual LoadKeys();

public:
  Signer2(const char *szLogin, const char *szPassword, const char *szKeyData);
  short ErrorCode();
};
