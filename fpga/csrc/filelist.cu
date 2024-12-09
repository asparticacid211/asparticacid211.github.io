PIC_LD=ld

ARCHIVE_OBJS=
ARCHIVE_OBJS += _40730_archive_1.so
_40730_archive_1.so : archive.0/_40730_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40730_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40730_archive_1.so $@


ARCHIVE_OBJS += _40752_archive_1.so
_40752_archive_1.so : archive.0/_40752_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40752_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40752_archive_1.so $@


ARCHIVE_OBJS += _40753_archive_1.so
_40753_archive_1.so : archive.0/_40753_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40753_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40753_archive_1.so $@


ARCHIVE_OBJS += _40754_archive_1.so
_40754_archive_1.so : archive.0/_40754_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40754_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40754_archive_1.so $@


ARCHIVE_OBJS += _40755_archive_1.so
_40755_archive_1.so : archive.0/_40755_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40755_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40755_archive_1.so $@


ARCHIVE_OBJS += _40756_archive_1.so
_40756_archive_1.so : archive.0/_40756_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40756_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40756_archive_1.so $@


ARCHIVE_OBJS += _40757_archive_1.so
_40757_archive_1.so : archive.0/_40757_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40757_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40757_archive_1.so $@


ARCHIVE_OBJS += _40758_archive_1.so
_40758_archive_1.so : archive.0/_40758_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40758_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40758_archive_1.so $@


ARCHIVE_OBJS += _40759_archive_1.so
_40759_archive_1.so : archive.0/_40759_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -o .//../simv.daidir//_40759_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_40759_archive_1.so $@






%.o: %.c
	$(CC_CG) $(CFLAGS_CG) -c -o $@ $<
CU_UDP_OBJS = \


CU_LVL_OBJS = \
SIM_l.o 

MAIN_OBJS = \
amcQwB.o objs/amcQw_d.o 

CU_OBJS = $(MAIN_OBJS) $(ARCHIVE_OBJS) $(CU_UDP_OBJS) $(CU_LVL_OBJS)

