/*
* IP Search client for QQWry.Dat
* Author: Windix Feng [windix AT gmail.com]
* http://www.douzi.org
* 30/06/2005 [GPL]
*
* Running with QQWry.Dat (http://www.cz88.net)
* Referring from "Structure of IP DB" by Luma
* http://lumaqq.linuxsir.org/article/qqwry_format_detail.html
*
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "QQWry.h"

/**********************************************************/

unsigned long ip_str2dec(char *ip_in) {
	char *ip = strdup(ip_in);
	unsigned long ip_dec = 0;
	char *p;
	int i;
	for(i=0; i<3; i++) {
		p = strrchr(ip, '.');
		ip_dec |= atoi(p+1) << (8*i);
		*p = '\0';
	}
	ip_dec |= atoi(ip) << (8*i);
	free(ip);
	return ip_dec;
}

unsigned long ip_arr2dec(char **ip_arr) {
	unsigned long ip_dec = 0;
	int i;
	for(i=0; i<4; i++) {
		ip_dec |= atoi(ip_arr[i]) << (8*(3-i));
	}
	return ip_dec;
}
	
unsigned long ip_arr2dec_r(unsigned char *ip_arr) {
	unsigned long ip_dec = 0;
	int i;
	for(i=0; i<4; i++) {
		ip_dec |= ip_arr[i] << (8*i);
	}
	return ip_dec;
}

unsigned long get_long_addr3(unsigned char *buf) {
	unsigned long addr = 0;
	/* addr = buf[0] + buf[1]*256 + buf[2]*65536; */
	addr = buf[0] | buf[1] << 8 | buf[2] << 16;
	return addr;
}

char* get_string_by_addr(long addr, FILE *fp) {
	unsigned char buffer[1024];
	fseek(fp, addr, SEEK_SET);
	if (fread(buffer, 1024, 1, fp)) {
		return strdup((const char *)buffer);
	} else {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		return NULL;
	}
}

IP_INFO *get_ip_by_index(unsigned long index_addr, FILE *fp) {
	IP_INFO *ipinfo = (IP_INFO *)malloc(sizeof(IP_INFO));
	unsigned char ip[4];
	unsigned char addr[3];
	unsigned long record_addr = 0;
	unsigned char buffer[1024];
	unsigned long country_addr;
	fseek(fp, index_addr, SEEK_SET);
	if (!fread(ip, 4, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		return ipinfo;
	}
	if (!fread(addr, 3, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		return ipinfo;
	}
	record_addr = get_long_addr3(addr);
	//printf("%u\n", ip[3]);
	sprintf(ipinfo->start_ip, "%u.%u.%u.%u", ip[3], ip[2], ip[1], ip[0]);
	fseek(fp, record_addr, SEEK_SET);
	if (!fread(ip, 4, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		return ipinfo;
	}
	if (!fread(buffer, 1024, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		return ipinfo;
	}
	sprintf(ipinfo->end_ip, "%u.%u.%u.%u", ip[3], ip[2], ip[1], ip[0]);
	if (buffer[0] == 1) {
		country_addr = get_long_addr3(buffer + 1);
		fseek(fp, country_addr, SEEK_SET);
		if (!fread(buffer, 1024, 1, fp)) {
			fprintf(stderr, "fread is error: %d\n", ferror(fp));
			return ipinfo;
		}
		if (buffer[0] == 2) {
			ipinfo->country = get_string_by_addr(get_long_addr3(buffer + 1), fp);
			ipinfo->area = get_area(buffer + 4, fp);
			ipinfo->mode = "1 + 2";
		} else {
			ipinfo->country = get_string_by_addr(country_addr, fp);
			ipinfo->area = get_area(buffer + strlen(ipinfo->country) + 1, fp);
			ipinfo->mode = "1 + D";
		}
	} else if (buffer[0] == 2) {
		ipinfo->country = get_string_by_addr(get_long_addr3(buffer + 1), fp);
		ipinfo->area = get_area(buffer + 4, fp);
		ipinfo->mode = "2 + D";
	} else {
		ipinfo->country = strdup((const char *)buffer);
		ipinfo->area = get_area(buffer + strlen(ipinfo->country) + 1, fp);
		ipinfo->mode = "D + D";
	}
	return ipinfo;
}

char* get_area(unsigned char* buffer, FILE *fp) {
	if (buffer[0] == 1 || buffer[0] == 2) {
		return get_string_by_addr(get_long_addr3(buffer + 1), fp);
	} else {
		return strdup((const char *)buffer);
	}
}

void print_iptable(FILE *fp) {
	unsigned long index_start, index_end;
	unsigned long i;
	IP_INFO *ipinfo;
	fseek(fp, 0, SEEK_SET);
	if (!fread(&index_start, 4, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		exit(1);
	}
	if (!fread(&index_end, 4, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		exit(1);
	}
	/* printf("%lu %lu\n", index_start, index_end); */
	for(i=index_start; i<=index_end; i+=7) {
		ipinfo = get_ip_by_index(i, fp);
		printf("%s - %s\n%s, %s\n", ipinfo->start_ip, ipinfo->end_ip, ipinfo->country, ipinfo->area);
		free(ipinfo);
	}
}

unsigned long search_ip(char *ip_in, FILE *fp) {
	unsigned long index_start, index_end, lo, hi, i, ip_i, ip_dest;
	unsigned char ip_arr[4];
	fseek(fp, 0, SEEK_SET);
	if (!fread(&index_start, 4, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		return 0;
	}
	if (!fread(&index_end, 4, 1, fp)) {
		fprintf(stderr, "fread is error: %d\n", ferror(fp));
		return 0;
	}
	lo = 0;
	hi = (index_end - index_start) / 7;
	ip_dest = ip_str2dec(ip_in);
	while(lo <= hi) {
		i = (lo + hi) / 2;
		fseek(fp, index_start + i * 7, SEEK_SET);
		if (!fread(ip_arr, 4, 1, fp)) {
			fprintf(stderr, "fread is error: %d\n", ferror(fp));
			return 0;
		}
		ip_i = ip_arr2dec_r(ip_arr);
		if (ip_i == ip_dest)
			return index_start + i * 7;
		else if (ip_i < ip_dest)
			lo = i + 1;
		else
			hi = i - 1;
	}
	/* hi*/
	return index_start + hi * 7;
}

char * getipwhere (char *filename, char *ip){
	char buff[256];
	FILE *fp = fopen(filename, "r");
	if (fp == NULL) return NULL;
	IP_INFO *ipinfo = get_ip_by_index(search_ip(ip, fp), fp);
	sprintf(buff, "%s %s", ipinfo->country, ipinfo->area);
	free(ipinfo);
	fclose(fp);
	return strdup(buff);
}

