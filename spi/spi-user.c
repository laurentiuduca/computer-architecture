// SPDX-License-Identifier: GPL-2.0
// Author: L-C. Duca
// Date: 2019/07/05

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/spi/spidev.h>

#define TRANSFER_SIZE 1

int spi_config(int fd)
{
    int spi_mode, freq, bits_per_word, ret, lsb_first;

	spi_mode = SPI_MODE_0;
    if((ret = ioctl(fd, SPI_IOC_WR_MODE, &spi_mode)) < 0) {
		perror("SPI_IOC_WR_MODE");
        return -1;
    }

	bits_per_word = 8;
    if((ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits_per_word)) < 0) {
		perror("SPI_IOC_WR_BITS_PER_WORD");
        return -1;
    }

	/* use MSB first instead of LSB first */
	lsb_first = 0;
    if((ret = ioctl(fd, SPI_IOC_WR_LSB_FIRST, &lsb_first)) < 0) {
		perror("SPI_IOC_WR_LSB_FIRST");
        return -1;
    }
	
	freq = 50000; 
    if((ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &freq)) < 0 ) {
		perror("SPI_IOC_WR_MAX_SPEED_HZ");
        return -1;
    }
	
    return 0;
}

void spi_run(int fd)
{
    int i, ret;
    char buf_send[TRANSFER_SIZE] = {0, };
    char buf_recv[TRANSFER_SIZE] = {0, };

    struct spi_ioc_transfer msg[1] = {
        [0] = {
            .tx_buf = (unsigned long)buf_send,
            .rx_buf = (unsigned long)buf_recv,
            .len = TRANSFER_SIZE,
            .cs_change = 1, /* change CS between transfers */
            .delay_usecs = 0, /* delay after each transfer */
            .bits_per_word = 8,
        },
    };
    for(i = 0; i < TRANSFER_SIZE; i++) {
	    buf_recv[i] = 0;
	    buf_send[i] = i+1;
    }
	// SPI_IOC_MESSAGE(1) => one SPI transfer
    ret = ioctl(fd, SPI_IOC_MESSAGE(1), &msg);
    printf("ioctl returns %d \n", ret);
    if (ret != TRANSFER_SIZE){
        perror("SPI_IOC_MESSAGE");
        exit(1);
    }
    for (i = 0; i < TRANSFER_SIZE; i++) {
        printf("i=%d rx=%x, ", i, buf_recv[i]);
		if((i % 10) == 0)
			printf("\n");
    }
    printf("\n");
}

int main(int argc, char **argv)
{
    char *spi_dev = "/dev/spidev0.0";
    int ret, fd;
    
    if(argc >= 2) {
        printf("argc=%d argv[1]=%s \n", argc, argv[1]);
        spi_dev = argv[1];
    }
    printf("spi_dev=%s \n", spi_dev);

	if((fd = open(spi_dev, O_RDWR)) < 0) {
		perror("open");
		return -1;
	}
    if((ret = spi_config(fd)) < 0) {
        printf("error spi_device_setup\n");
        exit (1);
    }
    spi_run(fd);
    close(fd);
	
    return 0;
}
