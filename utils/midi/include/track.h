#ifndef MIDI_TRACK_H
#define MIDI_TRACK_H

#include "event.h"
#include <vector>

namespace Midi {

/***
 *   Spec:
 *   MidiTrack = <midi_track_header_t> + <MidiEvent> [+ <MidiEvent> ...]
 *   midi_track_header_t = "MTrk" + <size (4 bytes)>
 *
 ***/

typedef struct midi_track_header_t {
    char cookie[4];
    unsigned int size;
} __attribute__((packed)) midi_track_header_t;


class Track {
    private:
    unsigned int m_total_size;
    midi_track_header_t m_header;

    public:
    Track(void);
    ~Track(void);
    void init_from_file(FILE *fp);
    std::vector<Event *> m_events;

    void print_yaml(){
      printf("    - :header: MTrk\n");
      printf("      :total_size: %u\n", m_header.size);
      printf("      :events:\n");

      for(int i = 0; i < m_events.size(); i++){ 
        m_events[i]->print_yaml(); 
      } 
    }
};

}
#endif
