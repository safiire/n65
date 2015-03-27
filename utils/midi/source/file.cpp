#include "file.h"

namespace Midi {

File::File(void){
    m_header.cookie[0] = m_header.cookie[1] = m_header.cookie[2] = m_header.cookie[3] = 0;
    m_header.size = 0;
}


void File::init_from_file(const char *filename){
    FILE *fp = fopen(filename, "rb");
    fread(&m_header, sizeof(midi_header_t), 1, fp);
    //  Fix up this Big Endian stuff
    m_header.size = swap_endian_32(m_header.size);
    m_header.format = swap_endian_16(m_header.format);
    m_header.track_count = swap_endian_16(m_header.track_count);
    m_header.ticks_per_quarter_note = swap_endian_16(m_header.ticks_per_quarter_note);

    //  Read each track
    Track *track;
    for(int i = 0; i < m_header.track_count; i++){
        track = new Track();
        track->init_from_file(fp);
        m_tracks.push_back(track);
    }
}


File::~File(void){
    //  Free all the midi tracks
    for(unsigned int i = 0; i < m_tracks.size(); i++){
        delete m_tracks[i];
    }
}

}
