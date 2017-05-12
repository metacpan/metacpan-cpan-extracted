#ifndef PPERSIST_H_INCLUDED
#define PPERSIST_H_INCLUDED

/*
 * Create a persistence wrapper suitable for passing to MQIsdp_connect
 * which invokes the methods of the given Perl object
 */
MQISDP_PERSIST *new_persistence_wrapper(SV *object);

#endif /* PPERSIST_H_INCLUDED */
