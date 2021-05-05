ATSCC=$(PATSHOME)/bin/patscc
ATSOPT=$(PATSHOME)/bin/patsopt

ATSFLAGS+=-IATS src

CFLAGS+=-DATS_MEMALLOC_LIBC -D_DEFAULT_SOURCE -I $(PATSHOME)/ccomp/runtime -I $(PATSHOME) -O2 -I src -fno-stack-protector
LDFLAGS+=-L $(PATSHOME)/ccomp/atslib/lib
LIBS+=-latslib

NAME := libats-http
SNAME   :=  $(NAME).a
DNAME   :=  $(NAME).so
SRCDIR  := src
vpath %.dats src
vpath %.dats src/DATS
vpath %.sats src/SATS
SRCS    := $(shell find $(SRCDIR) -name '*.dats' -type f -exec basename {} \;)
SDIR    :=  build-static
SOBJ    := $(patsubst %.dats,$(SDIR)/%.o,$(SRCS))
DDIR    :=  build-shared
DOBJ    := $(patsubst %.dats,$(DDIR)/%.o,$(SRCS))

.PHONY: all clean fclean re 

all: $(SNAME) $(DNAME)

$(SNAME): $(SOBJ)
	$(AR) $(ARFLAGS) $@ $^

$(DNAME): CFLAGS += -fPIC
$(DNAME): LDFLAGS += -shared
$(DNAME): $(DOBJ)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(SDIR)/%.o: %.c | $(SDIR)
	$(CC) $(CFLAGS) -o $@ -c $<

$(DDIR)/%.o: %.c | $(DDIR)
	$(CC) $(CFLAGS) -o $@ -c $<

%.c: %.dats
	$(ATSOPT) $(ATSFLAGS) -o $(@F) -d $<

$(SDIR) $(DDIR):
	@mkdir $@

clean:
	$(RM) -r $(SDIR) $(DDIR)

fclean: clean
	$(RM) $(SNAME) $(DNAME)

re: fclean all

