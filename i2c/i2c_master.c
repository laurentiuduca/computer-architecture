// Copyright (C) 2018 Laurentiu-Cristian Duca
// Date: 2018-10-30, 14:20.
// SPDX-License-Identifier: MIT

#include <stdio.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <unistd.h>

#define I2C_ADDR 0x72

int main (void) {
    char buffer[3];
    int fd;
    int i;

    fd = open("/dev/i2c-1", O_RDWR);

    if (fd < 0) {
        printf("Error opening file: %s\n", strerror(errno));
        return 1;
    }

    if (ioctl(fd, I2C_SLAVE, I2C_ADDR) < 0) {
        printf("ioctl error: %s\n", strerror(errno));
        return 1;
    }

    buffer[0]=0x25;
    write(fd, buffer, 1);

    buffer[0]=buffer[1]=buffer[2]=0;
    read(fd, buffer, 1);
    for(i=0; i<1; i++)
        printf("buffer[%d]=0x%02X\n", i, buffer[i]);
    return 0;
}

