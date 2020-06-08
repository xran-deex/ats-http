ATSHOMEQ=$(PATSHOME)
export PATSRELOCROOT=$(HOME)/ATS
ATSCC=$(ATSHOMEQ)/bin/patscc
ATSOPT=$(ATSHOMEQ)/bin/patsopt
ATSCCFLAGS=-DATS_MEMALLOC_LIBC -D_DEFAULT_SOURCE -IATS node_modules -I src -fPIC -O3
LIBS=-lpthread -latslib -shared
ifdef ATSLIB
	LIBS := -L $(PATSHOME)/ccomp/atslib/lib -latslib
endif
ifdef PTHREAD
	LIBS := -lpthread
endif
APP     = libats-http.so
EXEDIR  = target
SRCDIR  = src
OBJDIR  = .build
vpath %.dats src
vpath %.dats src/DATS
vpath %.sats src/SATS
dir_guard=@mkdir -p $(@D)
SRCS    := $(shell find $(SRCDIR) -name '*.dats' -type f -exec basename {} \;)
OBJS    := $(patsubst %.dats,$(OBJDIR)/%.o,$(SRCS))
.PHONY: clean setup
all: $(EXEDIR)/$(APP)
$(EXEDIR)/$(APP): $(OBJS) 
	$(dir_guard)
	$(ATSCC) $(ATSCCFLAGS) -o $@ $(OBJS) $(LIBS)
.SECONDEXPANSION:
$(OBJDIR)/%.o: %.dats #$$(wildcard src/SATS/$$*.sats)
	$(dir_guard)
	$(ATSCC) $(ATSCCFLAGS) -c $< -o $(OBJDIR)/$(@F) -cleanaft
RMF=rm -f
clean: 
	$(RMF) $(EXEDIR)/$(APP)
	$(RMF) $(OBJS)
run: $(EXEDIR)/$(APP)
	./$(EXEDIR)/$(APP)
.SILENT: run
