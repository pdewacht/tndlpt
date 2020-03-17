#pragma enum minimum

union version {
  unsigned short word;
  struct {
    unsigned char minor;
    unsigned char major;
  };
};

_Packed struct iisp_header {
  unsigned short jump_to_start;
  void __far *next_handler;
  unsigned short signature;
  char eoi_flag;
  char jump_to_reset[2];
  char reserved[7];
};


enum emm_type {
  EMM_NONE = 0,
  EMM_EMM386,
  EMM_QEMM
};

_Packed struct config {
  unsigned lpt_port;
  char bios_id;
#ifdef _M_I86
  unsigned psp;
  enum emm_type emm_type;
  int emm386_virt_io_handle;
#endif
};


#define RESIDENT __based(__segname("RESIDENT"))

extern struct config RESIDENT config;

extern struct iisp_header RESIDENT amis_handler;
extern char RESIDENT amis_header[];
extern char RESIDENT amis_id;

extern char RESIDENT emm386_table[];
extern struct iisp_header RESIDENT qemm_handler;

extern char RESIDENT resident_end[];

#pragma enum pop
