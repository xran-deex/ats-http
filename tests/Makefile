ATSCC=$(PATSHOME)/bin/patscc
ATSOPT=$(PATSHOME)/bin/patsopt
ATSFLAGS=-IATS node_modules -IATS ../node_modules

CFLAGS=-DATS_MEMALLOC_LIBC -D_DEFAULT_SOURCE -I $(PATSHOME)/ccomp/runtime -I $(PATSHOME) -I ../src -I node_modules/ats-sqlite3 -O3 -fpic
ATSCCFLAGS=-DATS_MEMALLOC_LIBC -D_DEFAULT_SOURCE -IATS node_modules -IATS ../node_modules -I ../src -I node_modules/ats-sqlite3 -O3 -fpic
LIBS :=-L $(ARMLIBS)/ -L $(PATSHOME)/ccomp/atslib/lib -L ../.libs -lats-http -lats-shared-vt -lpthread -lsqlite3 -lz -lats-epoll -latslib

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

$(EXEDIR)/$(APP): $(OBJS)
	$(dir_guard)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LIBS)

.SECONDEXPANSION:
$(OBJDIR)/%.o: %.c
	$(dir_guard)
	$(CC) $(CFLAGS) -c $< -o $(OBJDIR)/$(@F) 

$(OBJDIR)/%.c: %.dats node_modules
	$(dir_guard)
	$(ATSOPT) $(ATSFLAGS) -o $(OBJDIR)/$(@F) -d $<

RMF=rm -f

clean: 
	$(RMF) $(EXEDIR)/$(APP)
	$(RMF) $(OBJS)
	$(RMF) ./**/*.c

run: $(EXEDIR)/$(APP)
	LD_LIBRARY_PATH=../.libs ./$(EXEDIR)/$(APP)

.SILENT: run

node_modules:
	npm install

deps: node_modules
	+OUTDIR=$(EXEDIR) make -C node_modules/ats-sqlite3