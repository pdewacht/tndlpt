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
  char bios_id;
  unsigned psp;
  enum emm_type emm_type;
  int emm386_virt_io_handle;
};

_Packed struct emm386_handler {
  short port;
  void (*f)();
};

extern struct config config;

extern struct iisp_header amis_handler;
extern char amis_header[];
extern char amis_id;

extern struct emm386_handler emm386_table[];
extern struct iisp_header qemm_handler;

extern char resident_end[];
