ATSCC=$(PATSHOME)/bin/patscc
ATSOPT=$(PATSHOME)/bin/patsopt

ATSFLAGS+=

CFLAGS+=-DATS_MEMALLOC_LIBC -D_DEFAULT_SOURCE -I $(PATSHOME)/ccomp/runtime -I $(PATSHOME) -O3 -I src $(INCLUDES)
LDFLAGS+=-L $(PATSHOME)/ccomp/atslib/lib
LIBS+=-latslib -ldl -lpthread

NAME := tests
SRCDIR  := 
vpath %.dats src
vpath %.dats src/DATS
vpath %.sats src/SATS
SRCS    := $(shell find $(SRCDIR) -name '*.dats' -type f -exec basename {} \;)
DDIR    := .build
OBJ    := $(patsubst %.dats,$(DDIR)/%.o,$(SRCS))

.PHONY: all clean fclean re 

all: $(NAME)

$(NAME): $(OBJ)
	$(CC) $(LDFLAGS) $^ $(LIBS) -o $@

$(DDIR)/%.o: %.c | $(DDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

%.c: %.dats
	$(ATSOPT) $(ATSFLAGS) -o $(@F) -d $<

$(SDIR) $(DDIR):
	@mkdir $@

clean:
	$(RM) -r $(SDIR) $(DDIR)

fclean: clean
	$(RM) $(NAME)

re: fclean all

