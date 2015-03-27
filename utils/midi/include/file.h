#ifndef MIDI_FILE_H
#define MIDI_FILE_H

#include <vector>
#include "track.h"

namespace Midi {

/***
 *   Spec:
 *   MidiFile = <midi_header_t> + <MidiTrack> [+ <MidiTrack> ...]
 *
 *   midi_header_t = "MThd" + <size (4 bytes)> + <format (2 bytes)> + <track_count (2 bytes)> + <ticks_per_quarter_note (2 bytes)>
 *
 ***/

typedef struct midi_header_t {
    char cookie[4];
    unsigned int  size;
    unsigned short format;
    unsigned short track_count;
    unsigned short ticks_per_quarter_note;
} __attribute__((packed)) midi_header_t;


class File {
    private:
    midi_header_t m_header;

    public:
    File(void);
    ~File(void);
    std::vector<Track *> m_tracks;
    void init_from_file(const char *filename);

    void print_yaml(){
      printf("---\n");
      printf(":midi_file:\n");
      printf("  :header: Mthd\n");
      printf("  :size: %u\n", m_header.size);
      printf("  :format: %u\n", m_header.format);
      printf("  :track_count: %u\n", m_header.track_count);
      printf("  :ticks_per_quarter_note: %u\n", m_header.ticks_per_quarter_note);
      printf("  :tracks:\n");

      for(int i = 0; i < m_tracks.size(); i++){
        if(i == 0){
          m_tracks[i]->print_yaml(); 
        }else{
          m_tracks[i]->print_yaml(); 
        }
      }
    }
};

}
#endif
