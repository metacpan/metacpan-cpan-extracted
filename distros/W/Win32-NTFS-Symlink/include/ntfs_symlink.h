#ifndef H_NTFS_SYMLINK
#define H_NTFS_SYMLINK 1

int _ntfs_junction(const char * oldpath, const char * newpath);
int _ntfs_symlink(const char * oldpath, const char * newpath);
//void _last_win32_error(PVOID pv);

#endif
