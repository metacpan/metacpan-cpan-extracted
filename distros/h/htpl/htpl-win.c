#include "htpl.h"

struct pair {
    pchar key, value;
};

struct vector wparams;
struct vector uploads;

pchar s_data, s_name;
#define IFIT(key) if (!strcmp(key, s_name))

void splitpair(line)
    STR line; {

    s_name = line;
    s_data = strchr(s_name, '=');
    if (!s_data) return;
    *s_data++ = '\0';
}



void dosystem() {

    IFIT("Output File") {
        FILE *o;
        o = FOPEN(s_data, "w");
        close(1);
        dup(fileno(o));
        fclose(o);
    }
}

void convertit(src, dst)
    STR src, dst; {

    while (*src) {
        *dst++ = (*src == ' ' ? '_' : toupper(*src));
        src++;
    }
    *dst = '\0';
}

void docgi() {
    TOKEN mine;
/*
    IFIT("Logical Path") {
        SETENV("PATH_INFO", s_data);
        return;
    }
    IFIT("Physical Path") {
        SETENV("PATH_TRANSLATED", s_data);
        return;
    }
*/
    convertit(s_name, mine);
    SETENV(mine, s_data);
}

void doform() {
    struct pair *p = malloc(sizeof(struct pair));
    p->key = strdup(s_name);
    p->value = strdup(s_data);
    vectorpush(&wparams, p);
}

void doformext() {
    struct pair *p = malloc(sizeof(struct pair));
    FILE *in = FOPEN(s_data, "r");
    TOKEN line;

    p->key = strdup(s_name);
    pushbuffer();
    while (!feof(in)) {
        fgets(line, sizeof(TOKEN), in);
        printcode(line);
    }
    fclose(in);
    p->value = strdup(result);
    popbuffer();
}

void doformupload() {
    struct pair *p = malloc(sizeof(struct pair));
    p->key = strdup(s_name);
    p->value = strdup(s_data);
    vectorpush(&wparams, p);
}

void domultipart(o)
    FILE *o; {

    TOKEN boundary;
    struct pair **ptr;
    STR del = "-----------------------------";
    FILE *i;

    sprintf(boundary, "%d%d%d", random(), time(NULL), getpid());
    fprintf(o, "%s%s\n", del, boundary);
    ptr = (struct pair **)wparams.data;
    while (*ptr) {
        fprintf(o, "Content-Disposition: form-data; name=\"%s\"\n\n", (*ptr)->key);
        fprintf(o, "%s\n", (*ptr)->value);
        fprintf(o, "%s%s\n", del, boundary);
        ptr++;
    }
    ptr = (struct pair **)uploads.data;
    while (*ptr) {
        makepersist((*ptr)->value);
        fprintf(o, "Content-Disposition: form-data; name=\"%s\"; filename=\"%s\"\n", (*ptr)->key, gettoken(5));
        fprintf(o, "Content-Type: %s\n\n", gettoken(3));
        i = FOPEN(gettoken(1), "r");
        fcpy(i, o, 0);
        fprintf(o, "\n%s%s\n", del, boundary);
        ptr++;
        destroypersist();
    }
    fprintf(o, "--\n");
}

void dosimple(o)
    FILE *o; {
    TOKEN key, val;
    struct pair **p = (struct pair **)wparams.data;
    short flag = 0;

    pushbuffer();
    while (*p) {
        if (flag) printcode("?");
        htencode((*p)->key, key);
        htencode((*p)->value, val);
        printfcode("%s=%s", key, val);
        flag = 1;
        p++;
    }
    fprintf(o, "%s", result);
}

void getinput() {
    FILE *o;
    int d[2];
    if (strcmp(GETENV("REQUEST_METHOD"), "POST")) return;
    pipe(d);    
    close(0);
    dup(d[0]);
    o = fdopen(d[1], "w");
    if (uploads.num) domultipart(); else dosimple();
    vectorkill(&uploads);
    vectorkill(&wparams);
}

void bootwin(filename)
    STR filename; {

    FILE *i;

    TOKEN section;
    TOKEN line;
    pchar value;
    int l;
    struct pair *p;

    vectorinit(&wparams);
    vectorinit(&uploads);

    i = FOPEN(filename, "r");
    while (!feof(i)) {
        fgets(line, sizeof(line), i);
        line[l = (strlen(line) -1)] = '\0';
        if (line[0] == '[' && line[l - 1] == ']') {
            line[l - 1] = '\0';
            strcpy(section, &line[1]);
            continue;
        }
        if (!line[0]) {
            strcpy(section, "");
            continue;
        }
        splitpair(line);
        if (!strcmp(section, "CGI")) docgi();
        else if (!strcmp(section, "System")) dosystem();
        else if (!strcmp(section, "Form Literas")) doform();
        else if (!strcmp(section, "Form External")) doformext();
        else if (!strcmp(section, "Form File")) doformupload();
    }
}

STR getperlpath() {
    FILENAME config;
    FILE *i;
    static FILENAME perl_bin = "";

    if (perl_bin[0]) return perl_bin;

    sprintf(config, "%s\\perlpath.win", bindir);
    i = FOPEN(config, "r");
    fscanf(i, "%s", perl_bin);
    fclose(i);
    return perl_bin;
}
