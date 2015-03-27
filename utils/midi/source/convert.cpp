#include <stdio.h>
#include "file.h"

int main(int argc, char **argv){

  if(argc < 1){
    printf("Need a midi file argument\n");
    exit(1);
  }

  Midi::File midi_file;
  midi_file.init_from_file(argv[1]);
  midi_file.print_yaml();

  return 0;
}
