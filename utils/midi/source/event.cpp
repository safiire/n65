#include "event.h"

namespace Midi {

////
//  Default constructor
Event::Event(void) : 
    m_delta(0), m_size(0), 
    m_data_size(0), m_status(0),
    m_meta_type(0), m_parameter1(0),
    m_parameter2(0), m_data(NULL) { } 


////
//  Constructor to set specific fields
Event::Event(int delta, int status, int parameter1, int parameter2) :
    m_delta(delta), m_size(4), 
    m_data_size(0), m_status(status),
    m_meta_type(0), m_parameter1(parameter1),
    m_parameter2(parameter2), m_data(NULL) { } 


////
//  Use a file pointer to initialize 
void Event::init_from_file(FILE *fp, unsigned char last_status){
    fpos_t saved_position;
    unsigned int value_size;
    //  All types of events are preceeded by a uintvar delta time
    m_delta = read_variable_length(fp, &value_size);
    m_size += value_size;

    //  All types then have a status byte, unless they are reusing
    //  the previous status, get ready to rewind if this is the case.
    fgetpos(fp, &saved_position);
    fread(&m_status, sizeof(unsigned char), 1, fp);
    m_size++;

    if(!is_status_byte(m_status)){
        //  This is not a status byte, so it must be reusing the previous one, Rewind
        m_status = last_status;  
        fsetpos(fp, &saved_position);
        m_size--;
    }

    switch(m_status){
        case 0xFF: // Meta
            //  This will have a meta sub type
            fread(&m_meta_type, sizeof(unsigned char), 1, fp);
            m_size++;
            //  Now a variable size for data
            m_data_size = read_variable_length(fp, &value_size);
            m_size += value_size;
            //  Finally, read the meta data
            m_data = malloc(sizeof(unsigned char) * m_data_size);
            fread(m_data, sizeof(unsigned char), m_data_size, fp);
            m_size += m_data_size;
            break;
        case 0xF0: // Sysex
        case 0xF7: // Sysex
            //  Sysex data runs until the next 0xF0 or 0xF7, count how many byte to allocate, and rewind
            fgetpos(fp, &saved_position);
            while(m_status != fgetc(fp)){
                m_data_size++;
            }
            fsetpos(fp, &saved_position);

            m_data = malloc(sizeof(unsigned char) * m_data_size);
            fread(m_data, sizeof(unsigned char), m_data_size, fp);
            m_size += (m_data_size + 1);
            fgetc(fp); //  Throw away the end byte, although it counts for size
            break;
        default:   // Midi
            fread(&m_parameter1, sizeof(unsigned char), 1, fp);
            fread(&m_parameter2, sizeof(unsigned char), 1, fp);
            m_size += 2;
            break;
    }
}


void Event::init_midi(int delta, int status, int parameter1, int parameter2){
    m_delta = delta;
    m_status = status;
    m_parameter1 = parameter1;
    m_parameter2 = parameter2;
    m_size = 4;
}


Event::~Event(void){
    if(m_data){
        free(m_data);
    }
}

}
