CC = arm-linux-gcc

all: i2c_master.out lat-preempt_rt.out i2c_master.out
i2c_master.out: i2c_master.o
	$(CC) -o i2c_master.out i2c_master.o
i2c_master.o: i2c_master.c
	$(CC) -c -o i2c_master.o i2c_master.c

.PHONY: clean all

clean:
	rm -rf *.out *.so *.o
