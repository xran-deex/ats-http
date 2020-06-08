ATSHOMEQ=$(PATSHOME)
export PATSRELOCROOT=$(HOME)/ATS
ATSCC=$(ATSHOMEQ)/bin/patscc
ATSOPT=$(ATSHOMEQ)/bin/patsopt
ATSCCFLAGS=-DATS_MEMALLOC_LIBC -D_DEFAULT_SOURCE -IATS node_modules -IATS ../node_modules -I ../src -I node_modules/ats-sqlite3 -L ../node_modules/shared_vt/target -O3
LIBS :=-latslib -lshared_vt -lpthread -lsqlite3 -lz
APP     = tests
EXEDIR  = target
SRCDIR  = .
OBJDIR  = .build
vpath %.dats .
dir_guard=@mkdir -p $(@D)
SRCS    := tests.dats 
OBJS    := $(patsubst %.dats,$(OBJDIR)/%.o,$(SRCS))
.PHONY: clean setup
all: $(EXEDIR)/$(APP)
	make -C ..
$(EXEDIR)/$(APP): $(OBJS) 
	$(dir_guard)
	$(ATSCC) $(ATSCCFLAGS) -o $@ $(OBJS) $(LIBS)
.SECONDEXPANSION:
$(OBJDIR)/%.o: %.dats
	$(dir_guard)
	$(ATSCC) $(ATSCCFLAGS) -c $< -o $(OBJDIR)/$(@F) -cleanaft
RMF=rm -f
clean: 
	make -C .. clean
	$(RMF) $(EXEDIR)/$(APP)
	$(RMF) $(OBJS)
run: $(EXEDIR)/$(APP)
	./$(EXEDIR)/$(APP)
.SILENT: run
