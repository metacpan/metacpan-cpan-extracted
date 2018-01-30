#ifndef H_NTFS_READLINK
#define H_NTFS_READLINK 1

char * _ntfs_readlink    (CONST TCHAR * LinkPath);
DWORD  _ntfs_reparse_tag (CONST TCHAR * LinkPath);
BOOL   _is_ntfs_symlink  (CONST TCHAR * LinkPath);
BOOL   _is_ntfs_junction (CONST TCHAR * LinkPath);

#endif
