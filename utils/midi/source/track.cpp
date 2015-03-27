#include "track.h"

namespace Midi {

Track::Track(void){
    m_header.cookie[0] = m_header.cookie[1] = m_header.cookie[2] = m_header.cookie[3] = 0;
    m_header.size = 0;
    m_total_size = 0;
}


void Track::init_from_file(FILE *fp){
    Event *track_event;
    unsigned int bytes_read = 0;
    unsigned char last_status = 0x0;

    fread(&m_header, sizeof(midi_track_header_t), 1, fp);
    m_header.size = swap_endian_32(m_header.size);
    if(m_header.size == 0) return;

    while(bytes_read < m_header.size){
        track_event = new Event();
        track_event->init_from_file(fp, last_status);
        m_events.push_back(track_event);
        last_status = track_event->status();
        bytes_read += track_event->bytes_read();
    }
}

Track::~Track(void){
    //  Free all the track events
    for(unsigned int i = 0; i < m_events.size(); i++){
        delete m_events[i];
    }
}

}
