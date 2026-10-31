/*
 * These chars are those found in iso8859-15.
 * They are encoded in iso8859-15 right in this file and sorted
 * by ascending value, _keep_ them sorted this way, a dichotomic
 * search rely on this to locate the glyphs and infos.
 */
static unsigned char *ZnDefaultCharset =
  "\x00\x01\x02\x03\x04\x05\x06\x07"
  "\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
  "\x10\x11\x12\x13\x14\x15\x16\x17"
  "\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
  " !\"#$%&'()*+,-./"
  "0123456789"
  ":;<=>?@"
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  "[\\]^_`"
  "abcdefghijklmnopqrstuvwxyz"
  "{|}~"
  "¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿"
  "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞß"
  "àáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ";

