CC = arm-linux-gcc

all: spi-user.out lat-preempt_rt.out i2c_master.out
spi-user.out: spi-user.o
	$(CC) -o spi-user.out spi-user.o
spi-user.o: spi-user.c
	$(CC) -c -o spi-user.o spi-user.c

.PHONY: clean all

clean:
	rm -rf *.out *.so *.o
