#ifndef MIDI_HELPERS_H
#define MIDI_HELPERS_H

#include <stdio.h>
#include <stdlib.h>

namespace Midi {

unsigned int read_variable_length(FILE *fp, unsigned int *value_size);
short swap_endian_16(short big_endian);
int swap_endian_32(int big_endian);

}
#endif
