#include "helpers.h"


namespace Midi {

////
//  I have eliminated any doubt that this function works on variable
//  length uintvars up to 4 bytes.
unsigned int read_variable_length(FILE *fp, unsigned int *value_size) {
    unsigned int value;
    *value_size = 1;

    if((value = fgetc(fp)) & 0x80){
        unsigned char c;
        value &= 0x7F;
        do{
            (*value_size)++;
            value = (value << 7) + ((c = fgetc(fp)) & 0x7F);
        } while (c & 0x80);
    }
    return(value);
}


////
//  Swap 4 bytes
int swap_endian_32(int big_endian){
    register int little_endian;
    little_endian =  (big_endian & 0x000000FF);
    little_endian = ((big_endian & 0x0000FF00) >> 0x08) | (little_endian << 0x08);
    little_endian = ((big_endian & 0x00FF0000) >> 0x10) | (little_endian << 0x08);
    little_endian = ((big_endian & 0xFF000000) >> 0x18) | (little_endian << 0x08);
    return(little_endian);
}


////
//  Swap 2 bytes
short swap_endian_16(short big_endian){
  register short little_endian;
  little_endian =  (big_endian & 0x00FF);
  little_endian = ((big_endian & 0xFF00) >> 0x08) | (little_endian << 0x08);
  return(little_endian);
}

}
