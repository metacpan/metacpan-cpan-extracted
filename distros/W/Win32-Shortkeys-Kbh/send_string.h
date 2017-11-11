typedef struct delayed {
	INPUT data;
	struct delayed * next;
} delayed;
typedef unsigned char byte;
void send_string (const wchar_t * str);
void send_cmd(int time, byte vkcode);
void sendDelayedKeys();
void paste_from_clpb(int dk);

