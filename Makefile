CLANG ?= clang
IFINDEX ?= 2
CFLAGS = -O2 -g -target bpf -Wall -Werror -DIFINDEX=$(IFINDEX)

all: mirror_tc.o

mirror_tc.o: mirror_tc.c
	$(CLANG) $(CFLAGS) -c $< -o $@

clean:
	rm -f mirror_tc.o
