
typedef struct ip_info
{
	char ip[16];
	char *country;
	char *area;
	char start_ip[16]; // For debug
	char end_ip[16]; // For debug
	char *mode; // For debug
} IP_INFO;

unsigned long get_long_addr3(unsigned char *buf);
char* get_string_by_addr(long addr, FILE *fp);
IP_INFO *get_ip_by_index(unsigned long index_addr, FILE *fp);
char* get_area(unsigned char* buffer, FILE *fp);
void print_iptable(FILE *fp);
unsigned long search_ip(char *ip_in, FILE *fp);
char* getipwhere (char *filename, char *ip);

