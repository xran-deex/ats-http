ATSCC=$(PATSHOME)/bin/patscc
ATSOPT=$(PATSHOME)/bin/patsopt

ATSFLAGS=-IATS node_modules -IATS ../node_modules

CFLAGS=-DATS_MEMALLOC_LIBC -D_DEFAULT_SOURCE -I $(PATSHOME)/ccomp/runtime -I $(PATSHOME) -I ../src -I node_modules/ats-sqlite3 -L ../node_modules/shared_vt/target -O3
LIBS=-L $(ARMLIBS)/ -L $(PATSHOME)/ccomp/atslib/lib -lpthread -latslib

APP     = libats-http.a
ifndef STATICLIB
	CFLAGS+=-fpic
	LIBS+=-shared
	APP     = libats-http.so
endif

EXEDIR  = $(PWD)/.libs
ifdef OUTDIR
	EXEDIR = $(OUTDIR)
endif
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

$(EXEDIR)/$(APP): $(OBJS) deps
	$(dir_guard)
ifdef STATICLIB
	ar rcs $@ $(OBJS)
endif
ifndef STATICLIB
	$(CC) $(CFLAGS) -o $(EXEDIR)/$(APP) $(OBJS) $(LIBS)
endif

.SECONDEXPANSION:
$(OBJDIR)/%.o: %.c
	$(dir_guard)
	$(CC) $(CFLAGS) -c $< -o $(OBJDIR)/$(@F) 

$(OBJDIR)/%.c: %.dats node_modules
	$(dir_guard)
	$(ATSOPT) $(ATSFLAGS) -o $(OBJDIR)/$(@F) -d $<

node_modules:
	npm install

deps: node_modules
	+OUTDIR=$(EXEDIR) make -C node_modules/shared_vt
	+OUTDIR=$(EXEDIR) make -C node_modules/ats-epoll

RMF=rm -f

clean: 
	$(RMF) $(EXEDIR)/$(APP)
	$(RMF) $(OBJS)
	+OUTDIR=$(EXEDIR) make -C node_modules/shared_vt clean
	+OUTDIR=$(EXEDIR) make -C node_modules/ats-epoll clean
	+OUTDIR=$(EXEDIR) make -C tests clean

test: all
	+make -C tests

runtest: test
	+make -C tests run